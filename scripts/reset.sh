#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

: > logs/history.log
: > logs/blocked_ips.log
rm -f tests/auth_light.log tests/auth_medium.log tests/auth_heavy.log

echo "SSHGuard logs and generated test fixtures reset."
