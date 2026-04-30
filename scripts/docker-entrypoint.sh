#!/bin/sh
set -e

# Always ensure /paperclip exists and is writable
mkdir -p /paperclip/instances/default/logs
mkdir -p /paperclip/instances/default/data
mkdir -p /paperclip/instances/default/data/backups
mkdir -p /paperclip/instances/default/db
chown -R node:node /paperclip
chmod -R 755 /paperclip

# Handle UID/GID remapping
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

if [ "$(id -u node)" -ne "$PUID" ]; then
    usermod -o -u "$PUID" node
fi
if [ "$(id -g node)" -ne "$PGID" ]; then
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
fi

# Re-apply ownership after any UID/GID changes
chown -R node:node /paperclip

# Create config if it does not exist
CONFIG_PATH="/paperclip/instances/default/config.json"
if [ ! -f "$CONFIG_PATH" ]; then
    echo "--- Creating config ---"
    cat > "$CONFIG_PATH" <<EOF
{
  "\$meta": { "version": 1, "source": "\$meta": { "version": 1, "source": "onboard", "updatedAt": "2026-01-01T00:00:00.000Z" },"onboard" },
  "database": { "mode": "embedded-postgres" },
  "logging": { "mode": "file" },
  "server": { "deploymentMode": "authenticated", "exposure": "private" },
  "auth": {}, "telemetry": {}, "storage": {}, "secrets": {}
}
EOF
    chown node:node "$CONFIG_PATH"
fi

# Run bootstrap to generate admin invite URL
echo "--- Paperclip bootstrap starting ---"
gosu node node --import ./server/node_modules/tsx/dist/loader.mjs cli/src/index.js auth bootstrap-ceo 2>&1 || true
echo "--- Paperclip bootstrap complete ---"

exec gosu node "$@"
