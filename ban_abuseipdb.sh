#!/bin/bash
# Author xRuffKez - https://github.com/xRuffKez
# License: Do what ever you want... but keep my credit please :)

API_KEY="your_abuseipdb_api_key"  # Replace this with your actual AbuseIPDB API key
CONFIDENCE_MIN=25 # Set your confidence level here!
FILE="/tmp/abuseipdb_blacklist.txt"
PREVIOUS_BLACKHOLES_IPV4="/tmp/previous_blackholes_ipv4.txt"
PREVIOUS_BLACKHOLES_IPV6="/tmp/previous_blackholes_ipv6.txt"
LOG_FILE="/var/log/ban_abuseipdb.log"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

log "Script started"

# Fetch IPs with the specified confidence level or higher
response=$(curl -G https://api.abuseipdb.com/api/v2/blacklist \
    --data-urlencode "confidenceMinimum=${CONFIDENCE_MIN}" \
    -H "Key: ${API_KEY}" \
    -H "Accept: application/json" -o $FILE -w "%{http_code}")

if [ "$response" -ne 200 ]; then
    log "Failed to fetch data from AbuseIPDB, HTTP status code: $response"
    exit 1
fi

log "Fetched data from AbuseIPDB"

# Verify the JSON file
if ! jq empty $FILE 2>/dev/null; then
    log "Downloaded data is not valid JSON"
    exit 1
fi

log "Downloaded data is valid JSON"

# Extract IP addresses
jq -r '.data[] | .ipAddress' $FILE > /tmp/ips.txt
if [ $? -ne 0 ]; then
    log "Failed to extract IP addresses from JSON"
    exit 1
fi

log "Extracted IP addresses from JSON"

# Remove previous IPv4 blackholes
if [ -f $PREVIOUS_BLACKHOLES_IPV4 ]; then
    while IFS= read -r ip; do
        ip route del blackhole $ip 2>/dev/null
        log "Removed IPv4 blackhole for $ip"
    done < $PREVIOUS_BLACKHOLES_IPV4
fi

# Remove previous IPv6 blackholes
if [ -f $PREVIOUS_BLACKHOLES_IPV6 ]; then
    while IFS= read -r ip; do
        ip -6 route del blackhole $ip 2>/dev/null
        log "Removed IPv6 blackhole for $ip"
    done < $PREVIOUS_BLACKHOLES_IPV6
fi

# Clear previous blackholes files
> $PREVIOUS_BLACKHOLES_IPV4
> $PREVIOUS_BLACKHOLES_IPV6

log "Cleared previous blackholes"

# Read the IPs and add them as blackholes
while IFS= read -r ip; do
    if [[ "$ip" == *:* ]]; then
        # IPv6 address
        ip -6 route add blackhole $ip
        if [ $? -eq 0 ]; then
            echo $ip >> $PREVIOUS_BLACKHOLES_IPV6
            log "Added IPv6 blackhole for $ip"
        else
            log "Failed to add IPv6 blackhole for $ip"
        fi
    else
        # IPv4 address
        ip route add blackhole $ip
        if [ $? -eq 0 ]; then
            echo $ip >> $PREVIOUS_BLACKHOLES_IPV4
            log "Added IPv4 blackhole for $ip"
        else
            log "Failed to add IPv4 blackhole for $ip"
        fi
    fi
done < /tmp/ips.txt

log "Script finished"
