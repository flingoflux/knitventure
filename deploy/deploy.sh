#!/bin/bash
set -euo pipefail

tag=${1:-}
if [[ $# != 1 || ! $tag =~ ^[0-9a-f]{40}$ ]]; then
  echo 'Usage: deploy.sh <full commit SHA>' >&2
  exit 2
fi

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
exec 9>.deploy.lock
flock 9

candidate=$(mktemp .env.XXXXXX)
trap 'rm -f -- "$candidate"' EXIT
# Preserve settings other than the deployed tag and stack shape.
sed '/^KNITVENTURE_IMAGE_TAG=/d; /^KNITVENTURE_BACKEND_ENABLED=/d' .env > "$candidate"
printf '\nKNITVENTURE_IMAGE_TAG=%s\nKNITVENTURE_BACKEND_ENABLED=1\n' "$tag" >> "$candidate"
unset KNITVENTURE_IMAGE_TAG

http_url=${KNITVENTURE_DEPLOY_HTTP_URL:-http://127.0.0.1}

check_http() {
  local status
  status=$(curl --fail --silent --show-error --retry 5 --retry-all-errors \
    --retry-delay 1 --max-time 5 --output /dev/null --write-out '%{http_code}' "$http_url$1") &&
    [[ $status == 200 ]]
}

docker compose --env-file "$candidate" pull --policy missing caddy backend
if docker compose --env-file "$candidate" up -d caddy backend &&
    check_http / && check_http /api/status &&
    mv -f -- "$candidate" .env; then
  printf 'Deployed %s\n' "$tag"
  exit 0
fi

echo 'Deployment failed. Restoring the version recorded in .env.' >&2
if grep -qxF 'KNITVENTURE_BACKEND_ENABLED=1' .env; then
  if ! docker compose up -d caddy backend || ! check_http / || ! check_http /api/status; then
    echo 'Failed to restore the previous image pair.' >&2
  fi
else
  if ! docker compose up -d caddy || ! check_http /; then
    echo 'Failed to restore the previous Caddy release.' >&2
  fi
  if ! docker compose stop backend; then
    echo 'Failed to stop the backend after the first deployment.' >&2
  fi
fi
exit 1
