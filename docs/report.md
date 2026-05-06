# SSHGuard Report

## Project Overview

SSHGuard is a Bash security tool that monitors SSH authentication logs to detect brute force login attempts. When an IP address exceeds the configured failed-login threshold, the tool can report it, log the event, and optionally block it.

## Core Workflow

1. Read SSH logs.
2. Extract failed login attempts.
3. Count attempts by IP address.
4. Detect suspicious IP addresses.
5. Block suspicious IP addresses when requested.
6. Save activity history.

## Security Value

The project demonstrates practical Linux security concepts including log analysis, attack detection, firewall protection, and incident logging.
