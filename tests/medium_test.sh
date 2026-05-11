#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$ROOT_DIR/tests/tmp/medium"
AUTH_LOG="$TMP_DIR/auth.log"
LOG_DIR="$TMP_DIR/logs"
SUSPECTS_FILE="/tmp/sshguard_suspects.tmp"

mkdir -p "$TMP_DIR" "$LOG_DIR"

cat > "$AUTH_LOG" <<'LOG'
Jan  1 00:00:01 host sshd[1]: Failed password for invalid user test from 192.168.1.50 port 111 ssh2
Jan  1 00:00:02 host sshd[2]: Failed password for invalid user test from 192.168.1.50 port 112 ssh2
Jan  1 00:00:03 host sshd[3]: Failed password for invalid user test from 192.168.1.50 port 113 ssh2
Jan  1 00:00:04 host sshd[4]: Failed password for invalid user test from 192.168.1.50 port 114 ssh2
Jan  1 00:00:05 host sshd[5]: Failed password for invalid user test from 192.168.1.50 port 115 ssh2
Jan  1 00:00:06 host sshd[6]: Failed password for invalid user test from 192.168.1.51 port 116 ssh2
LOG

LOG_FILE="$AUTH_LOG" THRESHOLD=5 bash "$ROOT_DIR/src/sshguard.sh" -d -t -l "$LOG_DIR"

grep -q '^192\.168\.1\.50:5$' "$SUSPECTS_FILE"
grep -q "1 IP(s) suspecte(s)" "$LOG_DIR/history.log"
echo "Medium test passed."
