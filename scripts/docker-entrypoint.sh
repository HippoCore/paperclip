#!/bin/sh
set -e

mkdir -p /paperclip/instances/default/logs
mkdir -p /paperclip/instances/default/data/backups
mkdir -p /paperclip/instances/default/db
chown -R node:node /paperclip
chmod -R 755 /paperclip

PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

if [ "$(id -u node)" -ne "$PUID" ]; then
    usermod -o -u "$PUID" node
fi
if [ "$(id -g node)" -ne "$PGID" ]; then
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
fi

chown -R node:node /paperclip

CONFIG_PATH="/paperclip/instances/default/config.json"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "--- Creating config ---"
    python3 -c "
import json
config = {
    '\$meta': {'version': 1, 'source': 'onboard', 'updatedAt': '2026-01-01T00:00:00.000Z'},
    'database': {'mode': 'embedded-postgres'},
    'logging': {'mode': 'file'},
    'server': {'deploymentMode': 'authenticated', 'exposure': 'private'},
    'auth': {}, 'telemetry': {}, 'storage': {}, 'secrets': {}
}
print(json.dumps(config, indent=2))
" > "$CONFIG_PATH"
    chown node:node "$CONFIG_PATH"
fi

echo "--- Paperclip bootstrap starting ---"
gosu node node --import ./server/node_modules/tsx/dist/loader.mjs cli/src/index.js auth bootstrap-ceo 2>&1 || true
echo "--- Paperclip bootstrap complete ---"

exec gosu node "$@"
