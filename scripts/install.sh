#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

mkdir -p logs
touch logs/history.log logs/blocked_ips.log
chmod +x src/securewatch.sh src/lib/*.sh tests/*.sh scripts/*.sh

echo "SSHGuard setup complete."
