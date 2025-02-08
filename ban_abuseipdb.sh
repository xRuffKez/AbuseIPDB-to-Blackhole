#!/bin/bash
# Author xRuffKez - https://github.com/xRuffKez
# License: Do whatever you want... but keep my credit, please :)

API_KEY="your_abuseipdb_api_key"  # Replace this with your actual AbuseIPDB API key
CONFIDENCE_MIN=25  # Set your confidence level here!
ENABLE_IPV6=true   # Set to false to disable IPv6 blackholes
FILE="/tmp/abuseipdb_blacklist.json"
PREVIOUS_BLACKHOLES_IPV4="/tmp/previous_blackholes_ipv4.txt"
PREVIOUS_BLACKHOLES_IPV6="/tmp/previous_blackholes_ipv6.txt"
LOG_FILE="/var/log/ban_abuseipdb.log"
IP_FILE="/tmp/ips.txt"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Requirement checks
check_requirements() {
    local missing=false

    if ! command -v curl >/dev/null 2>&1; then
        log "Error: curl is not installed."
        missing=true
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log "Error: jq is not installed."
        missing=true
    fi

    if ! command -v ip >/dev/null 2>&1; then
        log "Error: iproute2 tools are not installed."
        missing=true
    fi

    if [ "$missing" = true ]; then
        log "Please install the missing requirements and try again."
        exit 1
    fi

    log "All requirements are met."
}

# Fetch AbuseIPDB blacklist
fetch_blacklist() {
    log "Fetching data from AbuseIPDB with a confidence level >= $CONFIDENCE_MIN"
    response=$(curl -G https://api.abuseipdb.com/api/v2/blacklist \
        -d "confidenceMinimum=${CONFIDENCE_MIN}" \
        -d limit=9999999 \
        -H "Key: ${API_KEY}" \
        -H "Accept: application/json" -o $FILE -w "%{http_code}")

    if [ "$response" -ne 200 ]; then
        log "Failed to fetch data from AbuseIPDB, HTTP status code: $response"
        exit 1
    fi

    log "Data fetched successfully from AbuseIPDB"
}

# Validate JSON file
validate_json() {
    if ! jq empty $FILE 2>/dev/null; then
        log "Error: Downloaded data is not valid JSON."
        exit 1
    fi

    log "Validated JSON data successfully."
}

# Extract IP addresses
extract_ips() {
    log "Extracting IP addresses from JSON."
    jq -r '.data[] | .ipAddress' $FILE > $IP_FILE

    if [ $? -ne 0 ] || [ ! -s $IP_FILE ]; then
        log "Error: Failed to extract IP addresses or no IP addresses found."
        exit 1
    fi

    local total_ips=$(wc -l < $IP_FILE)
    log "Extracted $total_ips IP addresses from JSON."
}

# Remove previous blackholes
remove_previous_blackholes() {
    log "Removing previous IPv4 blackholes."
    if [ -f $PREVIOUS_BLACKHOLES_IPV4 ]; then
        while IFS= read -r ip; do
            ip route del blackhole $ip 2>/dev/null
            log "Removed IPv4 blackhole for $ip"
        done < $PREVIOUS_BLACKHOLES_IPV4
    fi

    if [ "$ENABLE_IPV6" = true ]; then
        log "Removing previous IPv6 blackholes."
        if [ -f $PREVIOUS_BLACKHOLES_IPV6 ]; then
            while IFS= read -r ip; do
                ip -6 route del blackhole $ip 2>/dev/null
                log "Removed IPv6 blackhole for $ip"
            done < $PREVIOUS_BLACKHOLES_IPV6
        fi
    fi

    # Clear files
    > $PREVIOUS_BLACKHOLES_IPV4
    > $PREVIOUS_BLACKHOLES_IPV6
    log "Cleared previous blackhole records."
}

# Add new blackholes
add_blackholes() {
    local ipv4_count=0
    local ipv6_count=0

    log "Adding new blackholes."
    while IFS= read -r ip; do
        if [[ "$ip" == *:* ]]; then
            # Process IPv6 only if enabled
            if [ "$ENABLE_IPV6" = true ]; then
                ip -6 route add blackhole $ip
                if [ $? -eq 0 ]; then
                    echo $ip >> $PREVIOUS_BLACKHOLES_IPV6
                    log "Added IPv6 blackhole for $ip"
                    ((ipv6_count++))
                else
                    log "Failed to add IPv6 blackhole for $ip"
                fi
            else
                log "Skipping IPv6 address $ip as IPv6 is disabled."
            fi
        else
            ip route add blackhole $ip
            if [ $? -eq 0 ]; then
                echo $ip >> $PREVIOUS_BLACKHOLES_IPV4
                log "Added IPv4 blackhole for $ip"
                ((ipv4_count++))
            else
                log "Failed to add IPv4 blackhole for $ip"
            fi
        fi
    done < $IP_FILE

    log "Added $ipv4_count IPv4 blackholes."
    if [ "$ENABLE_IPV6" = true ]; then
        log "Added $ipv6_count IPv6 blackholes."
    fi
}

# Main execution
main() {
    log "Script started."
    check_requirements
    fetch_blacklist
    validate_json
    extract_ips
    remove_previous_blackholes
    add_blackholes
    log "Script finished successfully."
}

# Run main
main
