#!/usr/bin/env bash
set -euo pipefail

source_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
root=/root/sub2api
compose="$root/docker-compose.yml"
compat="$root/docker-compose.compat.yml"
mount=/run/sub2api-maintained-panel
unit=sub2api-maintained-panel.service

test "$(id -u)" -eq 0
test -x /usr/local/sbin/sub2api-maintained-upgrade
cd "$root"

install -D -m 0755 "$source_dir/panel-upgrade.py" /usr/local/libexec/sub2api-maintained-panel.py
install -m 0644 "$source_dir/$unit" "/etc/systemd/system/$unit"
systemctl daemon-reload
systemctl enable "$unit"
systemctl restart "$unit"
for _ in {1..30}; do
  if test -S "$mount/upgrade.sock"; then break; fi
  sleep 1
done
test -S "$mount/upgrade.sock"
curl --fail --silent --show-error --max-time 5 --unix-socket "$mount/upgrade.sock" http://localhost/status >/dev/null

candidate="$(mktemp "$root/.compose-panel-XXXXXX.yml")"
trap 'rm -f "$candidate"' EXIT
cp -p "$compose" "$candidate"
python3 - "$candidate" "$mount" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
mount = sys.argv[2]
text = p.read_text()
entry = f"{mount}:{mount}:ro"
if entry not in text:
    text, count = re.subn(r"(?m)^( +)(- \./data:/app/data(?::[^ \t#]+)?)([ \t]*)$",
                          lambda m: m[0] + f"\n{m[1]}- {entry}", text)
    if count != 1:
        raise SystemExit("Could not locate the unique Sub2API data volume.")
    p.write_text(text)
PY
docker compose -f "$candidate" -f "$compat" config --format json | python3 -c '
import json,sys
mount=sys.argv[1]
services=json.load(sys.stdin)["services"]
assert any(v.get("source")==mount and v.get("target")==mount and v.get("read_only") for v in services["sub2api"]["volumes"])
' "$mount"
if ! cmp -s "$candidate" "$compose"; then
  backup="$(mktemp -d "$root/backups/sub2api-panel-XXXXXX")"
  cp -p "$compose" "$backup/docker-compose.before.yml"
  mv -f "$candidate" "$compose"
  printf 'Compose backup: %s\n' "$backup/docker-compose.before.yml"
fi
printf 'Panel updater installed. The socket will be mounted at the next Sub2API deployment.\n'
