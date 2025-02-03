#!/bin/bash

# URL of the IP list
IP_LIST_URL="https://raw.githubusercontent.com/stamparm/ipsum/refs/heads/master/levels/1.txt"

# Temporary files
IP_FILE="/tmp/blackhole_ips.txt"
OLD_IP_FILE="/tmp/blackhole_ips_old.txt"

# Function to remove old blackhole routes
remove_old_ips() {
    if [[ -f "$OLD_IP_FILE" ]]; then
        echo "Removing previously blackholed IPs..."
        while IFS= read -r ip; do
            [[ -z "$ip" || "$ip" =~ ^#.* ]] && continue  # Skip empty lines and comments
            sudo ip route del blackhole "$ip" 2>/dev/null
        done < "$OLD_IP_FILE"
    fi
}

# Function to add new blackhole routes
add_new_ips() {
    echo "Adding new blackhole IPs..."
    while IFS= read -r ip; do
        [[ -z "$ip" || "$ip" =~ ^#.* ]] && continue  # Skip empty lines and comments
        sudo ip route add blackhole "$ip" 2>/dev/null
    done < "$IP_FILE"
}

# Download the latest IP list
echo "Downloading IP list..."
if ! curl -s --fail "$IP_LIST_URL" -o "$IP_FILE"; then
    echo "Error: Failed to download IP list." >&2
    exit 1
fi

# Remove old blackholed IPs before updating
remove_old_ips

# Add new blackholed IPs
add_new_ips

# Save current IP list for future removal
mv "$IP_FILE" "$OLD_IP_FILE"

echo "Blackhole IPs updated successfully."
