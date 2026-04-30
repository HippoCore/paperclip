#!/bin/sh
set -e

PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

changed=0
if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi
if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi
if [ "$changed" = "1" ]; then
    chown -R node:node /paperclip
fi

CONFIG_PATH="/paperclip/instances/default/config.json"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "--- Creating config ---"
    mkdir -p "$(dirname "$CONFIG_PATH")"
    cat > "$CONFIG_PATH" <<EOF
{
  "\$meta": { "version": 1, "source": "onboard" },
  "database": { "mode": "embedded-postgres" },
  "logging": { "mode": "file" },
  "server": { "deploymentMode": "authenticated", "exposure": "private" },
  "auth": {}, "telemetry": {}, "storage": {}, "secrets": {}
}
EOF
fi

echo "--- Paperclip bootstrap starting ---"
gosu node node --import ./server/node_modules/tsx/dist/loader.mjs cli/src/index.js auth bootstrap-ceo 2>&1 || true
echo "--- Paperclip bootstrap complete ---"

exec gosu node "$@"
