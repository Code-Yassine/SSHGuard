#!/usr/bin/env bash

# Member 5 task (completed by Membre 4 context): implement the main controller.

SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ "$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"

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
    cat <<HELP
Usage:
  securewatch [options]
  LOG_FILE=/path/to/auth.log THRESHOLD=5 securewatch [options]

Description:
  SecureWatch analyse les journaux SSH, extrait les tentatives "Failed password",
  compte les echecs par adresse IP, detecte les IP suspectes selon un seuil,
  puis peut bloquer ou restaurer ces IP avec iptables.

Options principales:
  -h          Afficher cette aide detaillee
  -d          Executer la detection seulement
  -b          Detecter puis bloquer les IP suspectes avec iptables (admin)
  -r          Restaurer/debloquer les IP enregistrees dans la blacklist (admin)
  -i          Afficher la liste des IP actuellement bloquees
  -l <dir>    Specifier le repertoire de journalisation

Modes d'execution:
  -s          Executer l'action dans un sous-shell
  -f          Executer l'action en fork/background sans attendre la fin
  -t          Executer l'action en job background puis attendre avec wait

Donnees et configuration:
  LOG_FILE    Fichier d'authentification a analyser (defaut: /var/log/auth.log)
  THRESHOLD   Nombre minimal d'echecs pour marquer une IP suspecte (defaut: 5)
  history.log Format: yyyy-mm-dd-hh-mm-ss : username : INFOS|ERROR : message

Codes d'erreur:
  100         Option non existante
  101         Parametre obligatoire manquant
  102         Fichier ou ressource introuvable
  103         Permission refusee ou privileges administrateur requis

Exemples:
  securewatch -h
  LOG_FILE=/tmp/auth-demo.log THRESHOLD=5 securewatch -d -l ~/securewatch-logs
  LOG_FILE=/tmp/auth-demo.log THRESHOLD=5 securewatch -d -s -l ~/securewatch-logs
  LOG_FILE=/tmp/auth-demo.log THRESHOLD=5 securewatch -d -t -l ~/securewatch-logs
  LOG_FILE=/tmp/auth-demo.log THRESHOLD=50 securewatch -d -f -l ~/securewatch-logs
  sudo env LOG_FILE=/tmp/auth-demo.log THRESHOLD=5 securewatch -b -l /var/log/securewatch
  sudo securewatch -r -l /var/log/securewatch
HELP
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
        log_event "INFOS" "$suspects_count IP suspectes trouvees. Blocage automatique"
        block_suspicious_ips
    fi
}

main() {
    if [[ $# -eq 0 ]]; then
        print_error "Parametres manquants"
        log_event "ERROR" "Parametres manquants"
        show_help
        exit 101
    fi

    local action=""
    local bg_fork=0
    local bg_thread=0
    local subshell=0

    while getopts ":hdbl:rftsi" opt; do
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
             i)
                action="list"
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
                log_event "ERROR" "Option invalide: -$OPTARG"
                show_help
                exit 100
                ;;
            :)
                print_error "Parametre manquant pour l'option -$OPTARG"
                log_event "ERROR" "Parametre manquant pour l'option -$OPTARG"
                show_help
                exit 101
                ;;
        esac
    done

    if [[ -z "$action" ]]; then
        print_error "Mode d'execution non specifie (-d, -b ou -r)"
        log_event "ERROR" "Mode d'execution non specifie (-d, -b ou -r)"
        show_help
        exit 101
    fi

    execute_action() {
        local ret=0
        if [[ "$action" == "list" ]]; then
            show_blocked_ips
            ret=$?
        elif [[ "$action" == "restore" ]]; then
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
        log_event "INFOS" "Execution en mode subshell"
        ( execute_action )
    elif [[ "$bg_fork" -eq 1 ]]; then
        execute_action &
        print_info "Execution en mode fork (PID: $!)"
        log_event "INFOS" "Execution en mode fork (PID: $!)"
    elif [[ "$bg_thread" -eq 1 ]]; then
        execute_action &
        print_info "Execution en mode thread."
        log_event "INFOS" "Execution en mode thread"
        wait $!
    else
        execute_action
    fi
}

main "$@"
