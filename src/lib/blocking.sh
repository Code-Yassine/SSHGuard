#!/usr/bin/env bash

# Member 4 task: implement IP blocking and restore.
# Blocks a single IP address with iptables, avoids duplicates, and saves to blacklist
block_ip() {
    local ip="$1"
    local blocked_log="${BLOCKED_IPS_LOG:-/var/log/securewatch/blacklist.txt}"

    # Valider l'IP
    if ! is_valid_ip "$ip"; then
        print_warning "IP invalide ignoree: $ip"
        return 1
    fi

    # Verifier les permissions
    require_root || return 103

    # Verifier si l'IP est deja bloquee par iptables
    if iptables -C INPUT -s "$ip" -j DROP 2>/dev/null; then
        print_info "L'IP $ip est deja bloquee par iptables."
    else
        # Bloquer avec iptables
        if iptables -A INPUT -s "$ip" -j DROP; then
            print_success "IP bloquee avec succes : $ip"
            log_event "INFOS" "IP bloquee : $ip"
        else
            print_error "Echec du blocage de l'IP : $ip"
            log_event "ERROR" "Echec du blocage de l'IP : $ip"
            return 1
        fi
    fi

    # Sauvegarder dans la blacklist si elle n'y est pas deja
    local log_directory="$(dirname "$blocked_log")"
    if [[ ! -d "$log_directory" ]]; then
        mkdir -p "$log_directory" 2>/dev/null
    fi

    if ! grep -q "^$ip$" "$blocked_log" 2>/dev/null; then
        echo "$ip" >> "$blocked_log"
    fi

    return 0
}

# Reads suspicious IPs and blocks them
block_suspicious_ips() {
    local suspects_file="${TEMP_SUSPECTS_FILE:-/tmp/securewatch_suspects.tmp}"
    local ip count

    if ! require_file "$suspects_file"; then
        return 102
    fi

    print_info "Debut du blocage des IP suspectes..."

    while IFS=':' read -r ip count; do
        if [[ -n "$ip" ]]; then
            block_ip "$ip"
        fi
    done < "$suspects_file"
}

# Restores all blocked IPs
restore_blocked_ips() {
    local blocked_log="${BLOCKED_IPS_LOG:-/var/log/securewatch/blacklist.txt}"
    local ip

    # Verifier les permissions root
    require_root || return 103

    if ! require_file "$blocked_log"; then
        return 102
    fi

    print_info "Restauration des IP bloquees..."

    while IFS= read -r ip; do
        if [[ -n "$ip" && "$ip" != "" ]]; then
            # Debloquer avec iptables
            if iptables -D INPUT -s "$ip" -j DROP 2>/dev/null; then
                print_success "IP debloquee : $ip"
                log_event "INFOS" "IP debloquee : $ip"
            else
                print_warning "Impossible de debloquer l'IP $ip (peut-etre non bloquee)."
            fi
        fi
    done < "$blocked_log"

    # Nettoyer le fichier blacklist
    > "$blocked_log"
    print_success "Toutes les IP ont ete restaurees et la blacklist a ete videe."
    log_event "INFOS" "Toutes les IP restaurees, blacklist videe"
}


# Displays currently blocked IPs
show_blocked_ips() {
    local blocked_log="${BLOCKED_IPS_LOG:-/var/log/securewatch/blacklist.txt}"

    print_info "Liste des IP actuellement bloquees :"
    if [[ -f "$blocked_log" ]]; then
        cat "$blocked_log"
    else
        print_info "Aucun fichier blacklist trouve dans $blocked_log"
    fi
}
