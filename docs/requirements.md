# Requirements

## Functional Requirements

- Read SSH authentication logs.
- Extract failed password attempts.
- Count failed attempts per IP address.
- Compare attempts against a configurable threshold.
- Log security events.
- Optionally block suspicious IP addresses.
- Restore/unblock previously blocked IP addresses.

## System Requirements

- Linux environment.
- Bash shell.
- Access to `/var/log/auth.log` or another configured auth log file.
- `iptables` for blocking features.
- Root privileges for blocking and restoring firewall rules.
