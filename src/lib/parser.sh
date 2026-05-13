#!/usr/bin/env bash

readonly DEFAULT_LOG_FILE="/var/log/auth.log"
readonly TEMP_IPS_FILE="${SSHGUARD_TEMP_IPS_FILE:-${TMPDIR:-/tmp}/sshguard_${EUID:-$(id -u)}_ips.tmp}"

extract_failed_ips() {
    local log_file="${1:-$DEFAULT_LOG_FILE}"

    if [[ -z "$log_file" ]]; then
        print_error "Aucun fichier de log specifie"
        log_event "ERROR" "Aucun fichier de log specifie"
        return 101
    fi

    if ! require_file "$log_file"; then
        log_event "ERROR" "Fichier de log introuvable : $log_file"
        return 102
    fi

    if [[ ! -r "$log_file" ]]; then
        print_error "Permission refusee pour lire : $log_file"
        log_event "ERROR" "Permission refusee pour lire : $log_file"
        return 103
    fi

    log_event "INFOS" "Debut de l'analyse du fichier : $log_file"

    > "$TEMP_IPS_FILE"

    grep "Failed password" "$log_file" 2>/dev/null | \
        grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
        > "$TEMP_IPS_FILE"

    local count
    count=$(wc -l < "$TEMP_IPS_FILE" | tr -d ' ')

    if [[ "$count" -eq 0 ]]; then
        print_info "Aucune tentative echouee detectee dans $log_file"
        log_event "INFOS" "Aucune tentative echouee detectee dans $log_file"
    else
        print_success "Extraction terminee : $count tentatives echouees detectees"
        log_event "INFOS" "Extraction terminee : $count tentatives echouees detectees"
    fi

    return 0
}

get_unique_ips() {
    if ! require_file "$TEMP_IPS_FILE"; then
        log_event "ERROR" "Fichier temporaire $TEMP_IPS_FILE introuvable"
        return 102
    fi

    sort "$TEMP_IPS_FILE" | uniq -c | sort -rn | awk '{print $2":"$1}'
    log_event "INFOS" "Liste des IP uniques generee"
    return 0
}

print_ips() {
    if ! require_file "$TEMP_IPS_FILE"; then
        log_event "ERROR" "Fichier temporaire $TEMP_IPS_FILE introuvable"
        return 102
    fi

    cat "$TEMP_IPS_FILE"
    return 0
}

count_ips() {
    if ! require_file "$TEMP_IPS_FILE"; then
        log_event "ERROR" "Fichier temporaire $TEMP_IPS_FILE introuvable"
        return 102
    fi

    wc -l < "$TEMP_IPS_FILE" | tr -d ' '
    return 0
}

validate_extracted_ips() {
    local ip
    local invalid_count=0

    if ! require_file "$TEMP_IPS_FILE"; then
        return 102
    fi

    while IFS= read -r ip; do
        if ! is_valid_ip "$ip"; then
            print_warning "IP invalide detectee : $ip"
            log_event "INFOS" "IP invalide detectee dans le parsing : $ip"
            ((invalid_count++))
        fi
    done < "$TEMP_IPS_FILE"

    if [[ "$invalid_count" -gt 0 ]]; then
        print_error "$invalid_count IP invalides trouvees"
        log_event "ERROR" "$invalid_count IP invalides trouvees dans l'extraction"
        return 1
    fi

    print_success "Toutes les IP extraites sont valides"
    log_event "INFOS" "Validation des IP : toutes valides"
    return 0
}
