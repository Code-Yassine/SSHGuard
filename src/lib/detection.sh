#!/usr/bin/env bash

# Member 3 task: implement attack detection logic.
#
# Required:
# - Use parser.sh output.
# - Count how many failed attempts each IP address has.
# - Compare the count with THRESHOLD from config.conf.
# - Print suspicious IP addresses.
#
# Example:
#   If THRESHOLD=5 and one IP appears 5 times, mark it suspicious.

readonly TEMP_SUSPECTS_FILE="${SSHGUARD_TEMP_SUSPECTS_FILE:-${TMPDIR:-/tmp}/sshguard_${EUID:-$(id -u)}_suspects.tmp}"

detect_suspicious_ips() {
    local threshold="$1"

    if [[ -z "$threshold" ]]; then
        print_error "Aucun seuil specifié"
        log_event "ERROR" "Aucun seuil specifié pour la detection"
        return 101
    fi

    if ! require_file "$TEMP_IPS_FILE"; then
        log_event "ERROR" "Fichier temporaire $TEMP_IPS_FILE introuvable"
        return 102
    fi

    log_event "INFOS" "Début de la détection des IP suspectes avec seuil : $threshold"

    > "$TEMP_SUSPECTS_FILE"

    local ip_count
    ip_count=$(wc -l < "$TEMP_IPS_FILE" | tr -d ' ')

    if [[ "$ip_count" -eq 0 ]]; then
        print_info "Aucune IP à analyser"
        log_event "INFOS" "Aucune IP à analyser"
        return 0
    fi

    local suspicious_count
    suspicious_count=0

    sort "$TEMP_IPS_FILE" | uniq -c | sort -rn | while read -r count ip; do
        if [[ "$count" -ge "$threshold" ]]; then
            echo "$ip:$count" >> "$TEMP_SUSPECTS_FILE"
            ((suspicious_count++))
        fi
    done

    suspicious_count=$(wc -l < "$TEMP_SUSPECTS_FILE" | tr -d ' ')

    if [[ "$suspicious_count" -eq 0 ]]; then
        print_info "Aucune IP suspecte détectée"
        log_event "INFOS" "Aucune IP suspecte détectée avec seuil : $threshold"
    else
        print_success "Détection terminée : $suspicious_count IP(s) suspecte(s) détectée(s)"
        log_event "INFOS" "Détection terminée : $suspicious_count IP(s) suspecte(s) avec seuil : $threshold"
    fi

    return 0
}

get_suspicious_ips() {
    if ! require_file "$TEMP_SUSPECTS_FILE"; then
        log_event "ERROR" "Fichier temporaire $TEMP_SUSPECTS_FILE introuvable"
        return 102
    fi

    cat "$TEMP_SUSPECTS_FILE"
    return 0
}

count_suspicious_ips() {
    if ! require_file "$TEMP_SUSPECTS_FILE"; then
        log_event "ERROR" "Fichier temporaire $TEMP_SUSPECTS_FILE introuvable"
        return 102
    fi

    wc -l < "$TEMP_SUSPECTS_FILE" | tr -d ' '
    return 0
}

validate_suspicious_ips() {
    local ip
    local invalid_count=0

    if ! require_file "$TEMP_SUSPECTS_FILE"; then
        return 102
    fi

    while IFS=':' read -r ip count; do
        if ! is_valid_ip "$ip"; then
            print_warning "IP suspecte invalide détectée : $ip"
            log_event "INFOS" "IP suspecte invalide détectée : $ip"
            ((invalid_count++))
        fi
    done < "$TEMP_SUSPECTS_FILE"

    if [[ "$invalid_count" -gt 0 ]]; then
        print_error "$invalid_count IP suspecte(s) invalide(s) trouvée(s)"
        log_event "ERROR" "$invalid_count IP suspecte(s) invalide(s) trouvée(s)"
        return 1
    fi

    print_success "Toutes les IP suspectes sont valides"
    log_event "INFOS" "Validation des IP suspectes : toutes valides"
    return 0
}
