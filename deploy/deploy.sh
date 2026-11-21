#!/bin/bash
set -euo pipefail

tag=${1:-}
if [[ $# != 1 || ! $tag =~ ^[0-9a-f]{40}$ ]]; then
  echo 'Usage: deploy.sh <full commit SHA>' >&2
  exit 2
fi

cd /opt/knitventure
exec 9>.deploy.lock
flock 9

candidate=$(mktemp .env.XXXXXX)
trap 'rm -f -- "$candidate"' EXIT
# Preserve other Compose settings from .env.
sed '/^KNITVENTURE_IMAGE_TAG=/d' .env > "$candidate"
printf '\nKNITVENTURE_IMAGE_TAG=%s\n' "$tag" >> "$candidate"
unset KNITVENTURE_IMAGE_TAG

check_http() {
  curl --fail --silent --show-error --retry 5 --retry-all-errors \
    --retry-delay 1 --max-time 5 http://127.0.0.1/ -o /dev/null
}

docker compose --env-file "$candidate" pull caddy
if docker compose --env-file "$candidate" up -d caddy && check_http && mv -f -- "$candidate" .env; then
  printf 'Deployed %s\n' "$tag"
  exit 0
fi

echo 'Deployment failed. Restoring the version recorded in .env.' >&2
docker compose up -d caddy
check_http
exit 1
