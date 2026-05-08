#!/usr/bin/env bash

# Logging functions for SSHGuard.

log_event() {
    local type="$1"
    local message="$2"
    local log_file="${HISTORY_LOG:-logs/history.log}"
    local mirror_log_file="${HISTORY_LOG_MIRROR:-logs/history.log}"
    local timestamp
    local user_name
    local status=0

    case "$type" in
        INFO)
            type="INFOS"
            ;;
        WARNING|WARN)
            type="INFOS"
            ;;
    esac

    timestamp="$(date '+%Y-%m-%d-%H-%M-%S')"
    user_name="${USER:-$(whoami 2>/dev/null || printf 'unknown')}"

    write_history_log "$log_file" "$timestamp" "$user_name" "$type" "$message" || status=1

    if [[ "$mirror_log_file" != "$log_file" ]]; then
        write_history_log "$mirror_log_file" "$timestamp" "$user_name" "$type" "$message" || status=1
    fi

    return "$status"
}

write_history_log() {
    local log_file="$1"
    local timestamp="$2"
    local user_name="$3"
    local type="$4"
    local message="$5"
    local log_directory

    log_directory="$(dirname "$log_file")"

    if [[ ! -d "$log_directory" ]]; then
        mkdir -p "$log_directory" || {
            print_error "Cannot create log directory: $log_directory"
            return 1
        }
    fi

    printf "%s : %s : %s : %s\n" "$timestamp" "$user_name" "$type" "$message" >> "$log_file" || {
        print_error "Cannot write to log file: $log_file"
        return 1
    }
}
