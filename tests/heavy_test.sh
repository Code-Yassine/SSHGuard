#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$ROOT_DIR/tests/tmp/heavy"
AUTH_LOG="$TMP_DIR/auth.log"
LOG_DIR="$TMP_DIR/logs"
SUSPECTS_FILE="${TMPDIR:-/tmp}/sshguard_${EUID:-$(id -u)}_suspects.tmp"

mkdir -p "$TMP_DIR" "$LOG_DIR"
: > "$AUTH_LOG"

for i in $(seq 1 300); do
    if (( i <= 160 )); then
        ip="203.0.113.10"
    elif (( i <= 260 )); then
        ip="198.51.100.23"
    else
        ip="10.0.0.$((i % 30 + 1))"
    fi

    printf "Jan  1 00:00:01 host sshd[%s]: Failed password for invalid user load from %s port 22 ssh2\n" "$i" "$ip" >> "$AUTH_LOG"
done

LOG_FILE="$AUTH_LOG" THRESHOLD=50 bash "$ROOT_DIR/src/sshguard.sh" -d -f -l "$LOG_DIR"

for _ in $(seq 1 50); do
    if grep -q '^203\.0\.113\.10:160$' "$SUSPECTS_FILE" 2>/dev/null &&
        grep -q '^198\.51\.100\.23:100$' "$SUSPECTS_FILE" 2>/dev/null; then
        echo "Heavy test passed."
        exit 0
    fi
    sleep 0.1
done

echo "Heavy test failed: expected suspicious IPs were not detected." >&2
exit 1
