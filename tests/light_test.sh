#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$ROOT_DIR/tests/tmp/light"
AUTH_LOG="$TMP_DIR/auth.log"
LOG_DIR="$TMP_DIR/logs"
SUSPECTS_FILE="${TMPDIR:-/tmp}/sshguard_${EUID:-$(id -u)}_suspects.tmp"

mkdir -p "$TMP_DIR" "$LOG_DIR"

cat > "$AUTH_LOG" <<'LOG'
Jan  1 00:00:01 host sshd[1]: Failed password for invalid user alice from 10.0.0.1 port 111 ssh2
Jan  1 00:00:02 host sshd[2]: Failed password for invalid user bob from 10.0.0.2 port 112 ssh2
Jan  1 00:00:03 host sshd[3]: Accepted password for user ok from 10.0.0.3 port 113 ssh2
LOG

LOG_FILE="$AUTH_LOG" THRESHOLD=5 bash "$ROOT_DIR/src/sshguard.sh" -d -s -l "$LOG_DIR"

if [[ -s "$SUSPECTS_FILE" ]]; then
    echo "Light test failed: no IP should reach the threshold." >&2
    exit 1
fi

grep -q "Aucune IP suspecte" "$LOG_DIR/history.log"
echo "Light test passed."
