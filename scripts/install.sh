#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${INSTALL_BIN_DIR:-/usr/local/bin}"
COMMAND_NAME="${COMMAND_NAME:-securewatch}"
TARGET="$ROOT_DIR/src/securewatch.sh"
LINK_PATH="$BIN_DIR/$COMMAND_NAME"

cd "$ROOT_DIR"
mkdir -p logs
touch logs/history.log logs/blocked_ips.log
chmod +x src/securewatch.sh src/lib/*.sh tests/*.sh scripts/*.sh

if [[ ! -d "$BIN_DIR" ]]; then
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        mkdir -p "$BIN_DIR"
    elif command -v sudo >/dev/null 2>&1; then
        sudo mkdir -p "$BIN_DIR"
    else
        echo "Cannot create $BIN_DIR without root privileges." >&2
        exit 103
    fi
fi

if [[ -w "$BIN_DIR" ]]; then
    ln -sf "$TARGET" "$LINK_PATH"
elif command -v sudo >/dev/null 2>&1; then
    sudo ln -sf "$TARGET" "$LINK_PATH"
else
    echo "Cannot install $COMMAND_NAME to $BIN_DIR without root privileges." >&2
    exit 103
fi

echo "SSHGuard setup complete."
echo "Installed command: $LINK_PATH"
echo "Try: $COMMAND_NAME -h"
