#!/usr/bin/env bash
# Upgrade sub2api to the latest CI-tested upstream release + local thinking patch.
# Only the sub2api container is recreated; database/redis are left running.
set -Eeuo pipefail
MODE="${1:---check}"
REQUESTED_TAG="${2:-}"
ROOT=/root/sub2api
REPO=Yi-Lings/open-source-publish
COMPOSE="$ROOT/docker-compose.yml"
COMPAT="$ROOT/docker-compose.compat.yml"
case "$MODE" in --check|--apply) ;; *) echo "Usage: $0 --check | --apply [release-tag]" >&2; exit 2;; esac

# Read only successful, published releases with the expected asset names.
LATEST="$(python3 - "$REPO" <<'PY'
import requests,re,sys
url='https://api.github.com/repos/'+sys.argv[1]+'/releases?per_page=100'
r=requests.get(url,timeout=20,headers={'Accept':'application/vnd.github+json'})
r.raise_for_status()
choices=[]
for item in r.json():
  tag=item.get('tag_name','')
  m=re.fullmatch(r'sub2api-patched-v(\d+)\.(\d+)\.(\d+)-([a-f0-9]{12})',tag)
  names={a.get('name') for a in item.get('assets',[])}
  if m and not item.get('draft') and {'sub2api-patched-image.tar.gz','sub2api-patched-image.tar.gz.sha256'}<=names:
    choices.append((tuple(map(int,m.group(1,2,3))),item.get('published_at',''),tag))
if not choices:
  raise SystemExit('No verified patched release yet; check GitHub Actions')
print(sorted(choices)[-1][2])
PY
)"
TAG="${REQUESTED_TAG:-$LATEST}"
if [[ ! "$TAG" =~ ^sub2api-patched-v([0-9]+)\.([0-9]+)\.([0-9]+)-([a-f0-9]{12})$ ]]; then
  echo "Invalid release tag: $TAG" >&2; exit 2
fi
VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
HASH="${BASH_REMATCH[4]}"
IMAGE="local/sub2api:patched-${VERSION}-${HASH}"
CURRENT="$(docker inspect sub2api --format '{{.Config.Image}}' 2>/dev/null || true)"
echo "Current: $CURRENT"
echo "Latest tested release: $LATEST"
echo "Selected: $IMAGE"
if [[ "$MODE" == --check ]]; then exit 0; fi
if [[ "$EUID" != 0 ]]; then echo "Run --apply as root" >&2; exit 2; fi
exec 9>/var/lock/sub2api-maintained-deploy.lock
flock -n 9 || { echo "Another deployment is in progress" >&2; exit 1; }
if [[ "$CURRENT" == "$IMAGE" ]]; then echo "Already on this version"; exit 0; fi
if [[ "$CURRENT" =~ patched-([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  INSTALLED="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
  if [[ "$(printf '%s\n' "$VERSION" "$INSTALLED" | sort -V | tail -1)" != "$VERSION" ]]; then
    echo "Refusing downgrade from $INSTALLED to $VERSION" >&2; exit 1
  fi
fi
docker compose -f "$COMPOSE" -f "$COMPAT" config --quiet
FREE_MB="$(df -Pm "$ROOT" | awk 'END{print $4}')"
if (( FREE_MB < 1500 )); then echo "Less than 1.5GiB available, aborting" >&2; exit 1; fi
BACKUP="$ROOT/backups/sub2api-maintained/$(date -u +%Y%m%dT%H%M%SZ)"
install -d -m 700 "$BACKUP"
cp -p "$COMPOSE" "$BACKUP/docker-compose.before.yml"
echo "$CURRENT" > "$BACKUP/image.before.txt"
echo "Backing up database before migrations: $BACKUP"
docker exec sub2api-postgres pg_dump -U sub2api -d sub2api -Fc > "$BACKUP/sub2api.dump"
chmod 600 "$BACKUP/sub2api.dump"
if (( $(stat -c %s "$BACKUP/sub2api.dump") < 1024 )); then
  echo "Unexpectedly small database backup, abort" >&2; exit 1
fi
BASE="https://github.com/$REPO/releases/download/$TAG"
curl -fsSL --retry 4 --connect-timeout 20 "$BASE/sub2api-patched-image.tar.gz" -o "$BACKUP/image.tar.gz"
curl -fsSL --retry 4 --connect-timeout 20 "$BASE/sub2api-patched-image.tar.gz.sha256" -o "$BACKUP/image.tar.gz.sha256"
(cd "$BACKUP" && cp image.tar.gz sub2api-patched-image.tar.gz && cp image.tar.gz.sha256 sub2api-patched-image.tar.gz.sha256 && sha256sum -c sub2api-patched-image.tar.gz.sha256 && rm sub2api-patched-image.tar.gz sub2api-patched-image.tar.gz.sha256)
gzip -dc "$BACKUP/image.tar.gz" | docker load
docker image inspect "$IMAGE" >/dev/null
python3 - "$COMPOSE" "$IMAGE" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
lines=p.read_text().splitlines(keepends=True)
inside=False
changed=0
for i,line in enumerate(lines):
  if line.startswith('  sub2api:'): inside=True; continue
  if inside and line.startswith('  ') and not line.startswith('    ') and line.strip().endswith(':'): break
  if inside and line.startswith('    image: '):
    lines[i]='    image: '+sys.argv[2]+'\n'
    changed+=1
if changed!=1: raise SystemExit('Could not uniquely identify sub2api image in compose')
p.write_text(''.join(lines))
PY
rollback() {
  echo "Upgrade health check failed. Reverting compose and container image." >&2
  cp -p "$BACKUP/docker-compose.before.yml" "$COMPOSE"
  (cd "$ROOT"; docker compose -f "$COMPOSE" -f "$COMPAT" up -d --no-deps --force-recreate sub2api) || true
  echo "CAUTION: An upstream database migration may already have executed. Database backup: $BACKUP/sub2api.dump" >&2
  exit 1
}
echo "Recreating sub2api only ..."
if ! (cd "$ROOT"; docker compose -f "$COMPOSE" -f "$COMPAT" up -d --no-deps --force-recreate sub2api); then rollback; fi
HEALTHY=0
for _ in $(seq 1 120); do
  if [[ "$(docker inspect sub2api --format '{{.State.Health.Status}}' 2>/dev/null || true)" == healthy ]] &&
     [[ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:8080/health || true)" == 200 ]]; then
    HEALTHY=1
    break
  fi
  sleep 5
done
if [[ "$HEALTHY" != 1 ]]; then rollback; fi
docker ps --filter name='^/sub2api$' --format '{{.Names}} | {{.Image}} | {{.Status}}'
echo "DEPLOY_SUCCESS: $IMAGE"
echo "Database backup saved at: $BACKUP/sub2api.dump"
