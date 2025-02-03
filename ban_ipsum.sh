#!/bin/bash

# URL of the IP list
IP_LIST_URL="https://raw.githubusercontent.com/stamparm/ipsum/refs/heads/master/levels/1.txt"

# Temporary file to store the downloaded IPs
IP_FILE="/tmp/blackhole_ips.txt"
OLD_IP_FILE="/tmp/blackhole_ips_old.txt"

# Function to remove old IPs
remove_old_ips() {
    if [[ -f "$OLD_IP_FILE" ]]; then
        echo "Removing previously blackholed IPs..."
        while IFS= read -r ip; do
            [[ -z "$ip" || "$ip" =~ ^#.* ]] && continue  # Skip empty lines and comments
            if sudo ipset test blackhole "$ip" &>/dev/null; then
                sudo ipset del blackhole "$ip"
            fi
        done < "$OLD_IP_FILE"
    fi
}

# Function to add new IPs
add_new_ips() {
    echo "Adding new blackhole IPs..."
    while IFS= read -r ip; do
        [[ -z "$ip" || "$ip" =~ ^#.* ]] && continue  # Skip empty lines and comments
        sudo ipset add blackhole "$ip" -exist  # Prevent duplicate entries
    done < "$IP_FILE"
}

# Download the latest IP list
echo "Downloading IP list..."
if ! curl -s --fail "$IP_LIST_URL" -o "$IP_FILE"; then
    echo "Error: Failed to download IP list." >&2
    exit 1
fi

# Ensure ipset exists
sudo ipset create blackhole hash:ip -exist

# Remove old IPs before updating
remove_old_ips

# Add new IPs
add_new_ips

# Save current IP list for future removal
mv "$IP_FILE" "$OLD_IP_FILE"

echo "Blackhole IPs updated successfully."
