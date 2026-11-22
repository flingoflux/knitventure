#!/bin/bash
set -euo pipefail

frontend=${1:?Pass the frontend image}
backend=${2:?Pass the backend image}
command -v flock >/dev/null

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
export COMPOSE_PROJECT_NAME="knitventure-rollback-$$"
legacy=1111111111111111111111111111111111111111
working=2222222222222222222222222222222222222222
broken=3333333333333333333333333333333333333333
unset KNITVENTURE_IMAGE_TAG

cleanup() {
  docker compose down -v --remove-orphans || true
  docker image rm "$KNITVENTURE_FRONTEND_IMAGE:$legacy" "$KNITVENTURE_FRONTEND_IMAGE:$working" \
    "$KNITVENTURE_FRONTEND_IMAGE:$broken" "$KNITVENTURE_BACKEND_IMAGE:$working" \
    "$KNITVENTURE_BACKEND_IMAGE:$broken" >/dev/null 2>&1 || true
  rm -rf -- "$work"
}

cp "$repo/deploy/compose.yaml" "$repo/deploy/deploy.sh" "$work/"
cd "$work"
printf 'KNITVENTURE_IMAGE_TAG=%s\n' "$legacy" > .env
export KNITVENTURE_FRONTEND_IMAGE="$COMPOSE_PROJECT_NAME/frontend"
export KNITVENTURE_BACKEND_IMAGE="$COMPOSE_PROJECT_NAME/backend"
trap cleanup EXIT

port=$(python3 - <<'PY'
import socket
with socket.socket() as listener:
    listener.bind(("127.0.0.1", 0))
    print(listener.getsockname()[1])
PY
)
export KNITVENTURE_HTTP_BIND="127.0.0.1:$port"
export KNITVENTURE_DEPLOY_HTTP_URL="http://$KNITVENTURE_HTTP_BIND"

# Candidate Caddy serves the SPA but deliberately fails the API HTTP check.
mkdir fixture
cat > fixture/Caddyfile <<'CADDY'
:80 {
    respond /api/status 503
    root * /srv
    file_server
}
CADDY
docker build --build-arg "FRONTEND=$frontend" -t "$KNITVENTURE_FRONTEND_IMAGE:$broken" -f - fixture <<'DOCKER'
ARG FRONTEND=caddy:2-alpine
FROM ${FRONTEND}
COPY Caddyfile /etc/caddy/Caddyfile
DOCKER

docker tag "$frontend" "$KNITVENTURE_FRONTEND_IMAGE:$legacy"
docker tag "$frontend" "$KNITVENTURE_FRONTEND_IMAGE:$working"
docker tag "$backend" "$KNITVENTURE_BACKEND_IMAGE:$working"
docker tag "$backend" "$KNITVENTURE_BACKEND_IMAGE:$broken"
docker compose up -d caddy
expect_failed_deploy() {
  local result=0
  bash deploy.sh "$broken" || result=$?
  [[ $result == 1 ]]
}
assert_image() {
  local container
  container=$(docker compose ps -q "$1")
  [[ $(docker inspect --format '{{.Config.Image}}' "$container") == "$2" ]]
}
assert_http() {
  curl --fail --silent --show-error --max-time 5 "$KNITVENTURE_DEPLOY_HTTP_URL$1" >/dev/null
}

expect_failed_deploy
grep -qxF "KNITVENTURE_IMAGE_TAG=$legacy" .env
[[ -z $(docker compose ps -q --status running backend) ]]
assert_image caddy "$KNITVENTURE_FRONTEND_IMAGE:$legacy"
assert_http /
echo 'A27: restored Caddy and stopped the backend after the first failed deployment'

bash deploy.sh "$working"
grep -qxF "KNITVENTURE_IMAGE_TAG=$working" .env
grep -qxF 'KNITVENTURE_BACKEND_ENABLED=1' .env
expect_failed_deploy
grep -qxF "KNITVENTURE_IMAGE_TAG=$working" .env
grep -qxF 'KNITVENTURE_BACKEND_ENABLED=1' .env
assert_image caddy "$KNITVENTURE_FRONTEND_IMAGE:$working"
assert_image backend "$KNITVENTURE_BACKEND_IMAGE:$working"
assert_http /
assert_http /api/status
echo 'A28: restored both images after a subsequent failed deployment'
