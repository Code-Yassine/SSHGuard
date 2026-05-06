# SSHGuard - Project Overview

SSHGuard is a Bash-based Linux security tool that protects SSH servers from brute force attacks. It reads the authentication log file `/var/log/auth.log`, searches for failed SSH login attempts, extracts attacker IP addresses, counts how many times each IP failed, and compares the result with a configurable threshold. When an IP address exceeds the limit, SSHGuard reports it as suspicious, saves the event in a history log, and can automatically block the attacker using `iptables`.

The project is divided into clear modules: `parser.sh` reads and extracts IP addresses, `detection.sh` identifies suspicious activity, `blocking.sh` blocks or restores IP addresses, `logging.sh` records events, and `securewatch.sh` controls the full program through options like `-d` for detection, `-b` for blocking, and `-r` for restore. This structure makes the tool easy to understand, test, and present.

In short, SSHGuard follows this workflow:

```text
Read SSH logs -> Detect failed attempts -> Count IPs -> Block attackers -> Save history
```
