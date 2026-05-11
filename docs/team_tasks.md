# Team Task Distribution

## Member 1 - Logging and Helpers

Files:

```text
src/lib/logging.sh
src/lib/utils.sh
```

Tasks:

- Create the event logging function.
- Save logs using the required format:

```text
YYYY-MM-DD-HH-MM-SS : USER : TYPE : MESSAGE
```

- Add helper functions for colors, errors, file checks, root checks, and IP validation.

## Member 2 - Log Parser

File:

```text
src/lib/parser.sh
```

Tasks:

- Read `/var/log/auth.log`.
- Find failed SSH login lines.
- Extract attacker IP addresses.
- Print one IP per line.

## Member 3 - Detection Logic

File:

```text
src/lib/detection.sh
```

Tasks:

- Use the parser output.
- Count failed login attempts per IP.
- Compare each count with `THRESHOLD`.
- Return suspicious IP addresses.

## Member 4 - Blocking System

File:

```text
src/lib/blocking.sh
```

Tasks:

- Block suspicious IPs using `iptables`.
- Save blocked IPs in `logs/blocked_ips.log`.
- Avoid duplicate blocks.
- Add restore/unblock functionality.

## Member 5 - Main Script Integration

File:

```text
src/sshguard.sh
```

Tasks:

- Connect all modules.
- Implement command options:

```text
-h help
-d detect
-b block
-l logs
-r restore
-f fork
-t thread/background
-s subshell
```

## Member 6 - Tests and Documentation

Files:

```text
tests/
README.md
docs/report.md
docs/presentation.md
```

Tasks:

- Create light, medium, and heavy test scenarios.
- Write README usage instructions.
- Prepare project report.
- Prepare one-slide presentation explanation.
