# SSHGuard

SSHGuard is a Bash-based security project for detecting repeated failed SSH login attempts, reporting suspicious IP addresses, and optionally blocking attackers with `iptables`.

This repository is prepared as a team project skeleton. Each member has a specific file to complete.

## Structure

```text
SSHGuard/
├── README.md
├── .gitignore
├── docs/
├── src/
├── tests/
├── scripts/
└── logs/
```

## Usage

```bash
bash scripts/install.sh
sshguard -h
sshguard -d
sshguard -b
```

These commands will work after the team completes the Bash functions.

## Main Options

```text
-h  Show help
-d  Detect suspicious IPs
-b  Detect and block suspicious IPs
-l  Show log directory
-r  Restore/unblock IPs from blacklist
-f  Run detection in fork mode
-t  Run detection in thread-style background jobs
-s  Run detection in a subshell
```

## Default Config

Configuration is stored in `src/config/config.conf`.

```bash
THRESHOLD=5
LOG_FILE=/var/log/auth.log
HISTORY_LOG=logs/history.log
BLOCKED_IPS_LOG=logs/blocked_ips.log
```
