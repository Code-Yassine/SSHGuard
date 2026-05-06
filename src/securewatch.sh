#!/usr/bin/env bash

# Member 5 task (completed by Membre 4 context): implement the main controller.

SCRIPT_DIR="$(dirname "$0")"

# Charger les logs depuis les variables par defaut requises.
export HISTORY_LOG="${HISTORY_LOG:-/var/log/securewatch/history.log}"
export BLOCKED_IPS_LOG="${BLOCKED_IPS_LOG:-/var/log/securewatch/blacklist.txt}"


# Load config.conf
source "${SCRIPT_DIR}/config/config.conf"

# Source all files from src/lib.
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/parser.sh"
source "${SCRIPT_DIR}/lib/detection.sh"
source "${SCRIPT_DIR}/lib/blocking.sh"

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h          Afficher cette aide"
    echo "  -d          Executer la detection seulement"
    echo "  -b          Bloquer les IP suspectes"
    echo "  -l <dir>    Specifier un repertoire de logs personnalise"
    echo "  -r          Restaurer/debloquer toutes les IP"
    echo "  -f          Execution en fork (background)"
    echo "  -t          Execution en mode thread (background job)"
    echo "  -s          Execution en subshell"
}

run_detection() {
    extract_failed_ips "$LOG_FILE" || return $?
    detect_suspicious_ips "$THRESHOLD" || return $?
}

run_blocking() {
    local suspects_count

    run_detection || return $?

    if [[ ! -f "$TEMP_SUSPECTS_FILE" ]]; then
       return 0
    fi

    suspects_count=$(count_suspicious_ips 2>/dev/null || echo "0")
    if [[ "$suspects_count" -gt 0 ]]; then
        print_info "$suspects_count IP suspectes trouvées. Blocage automatique..."
        block_suspicious_ips
    fi
}

main() {
    if [[ $# -eq 0 ]]; then
        print_error "Parametres manquants"
        show_help
        exit 101
    fi

    local action=""
    local bg_fork=0
    local bg_thread=0
    local subshell=0

    while getopts ":hdbl:rfts" opt; do
        case ${opt} in
            h)
                show_help
                exit 0
                ;;
            d)
                action="detect"
                ;;
            b)
                action="block"
                ;;
            l)
                # Dossier de log specifique
                export HISTORY_LOG="${OPTARG}/history.log"
                export BLOCKED_IPS_LOG="${OPTARG}/blacklist.txt"
                source "${SCRIPT_DIR}/config/config.conf"
                ;;
            r)
                action="restore"
                ;;
            f)
                bg_fork=1
                ;;
            t)
                bg_thread=1
                ;;
            s)
                subshell=1
                ;;
            \?)
                print_error "Option invalide: -$OPTARG"
                show_help
                exit 100
                ;;
            :)
                print_error "Parametre manquant pour l'option -$OPTARG"
                show_help
                exit 101
                ;;
        esac
    done

    if [[ -z "$action" ]]; then
        print_error "Mode d'execution non specifie (-d, -b ou -r)"
        show_help
        exit 101
    fi

    execute_action() {
        local ret=0
        if [[ "$action" == "restore" ]]; then
            restore_blocked_ips
            ret=$?
        elif [[ "$action" == "block" ]]; then
            run_blocking
            ret=$?
        elif [[ "$action" == "detect" ]]; then
            run_detection
            ret=$?
        fi

        if [[ $ret -ge 100 && $ret -le 103 ]]; then
            echo ""
            show_help
            exit $ret
        fi
        return $ret
    }

    if [[ "$subshell" -eq 1 ]]; then
        ( execute_action )
    elif [[ "$bg_fork" -eq 1 ]]; then
        execute_action &
        print_info "Execution en mode fork (PID: $!)"
    elif [[ "$bg_thread" -eq 1 ]]; then
        execute_action &
        print_info "Execution en mode thread."
        wait $!
    else
        execute_action
    fi
}

main "$@"
