## AbuseIPDB Ban Script

This script fetches IP addresses from AbuseIPDB with a specified minimum confidence score and bans them by adding blackhole routes. Both IPv4 and IPv6 addresses are supported. The script logs its actions and provides detailed debugging information.
Requirements

    Operating System: Debian-based distributions (Ubuntu, Debian, etc.) or AlmaLinux
    Packages: curl, jq, iproute2
    API Key: AbuseIPDB API key


# Installation
# Step 1: Install Required Packages

Ensure curl, jq, and iproute2 are installed on your system.

Debian-based Distributions

```
sudo apt-get update
sudo apt-get install curl jq iproute2 -y
```

AlmaLinux

```
sudo dnf install curl jq iproute -y
```

# Step 2: Download the Script

Download the [ban_abuseipdb.sh](ban_abuseipdb.sh) to following directory:
/usr/local/bin/ban_abuseipdb.sh

Make the script executable:

```
sudo chmod +x /usr/local/bin/ban_abuseipdb.sh
```

# Step 3: Set Up Logging (optional)

Ensure the log directory and file are created with appropriate permissions:

```
sudo mkdir -p /var/log
sudo touch /var/log/ban_abuseipdb.log
sudo chmod 666 /var/log/ban_abuseipdb.log
```

# Step 4: Run the Script Manually

Run the script manually to ensure it works:

```
sudo /usr/local/bin/ban_abuseipdb.sh
```

Check the log file for output and any potential errors:

```
cat /var/log/ban_abuseipdb.log
```

# Step 5: Set Up a Cron Job

To run the script periodically, set up a cron job:

```
sudo crontab -e
```

Add the following line to run the script every hour:

```
@daily /usr/local/bin/ban_abuseipdb.sh
```

Save and exit the crontab editor.

# Troubleshooting


   - API Key Issues:
        Ensure your API key is correct and active. Test with a basic curl command:

```
        API_KEY="your_abuseipdb_api_key"
        curl -G https://api.abuseipdb.com/api/v2/blacklist \
            --data-urlencode "confidenceMinimum=25" \
            -H "Key: ${API_KEY}" \
            -H "Accept: application/json"
```

   - Permissions:
        Ensure the script and log file have the correct permissions.

   - Logs:
        Check the log file /var/log/ban_abuseipdb.log for detailed information about script execution.

   - System Requirements:
        Ensure all required packages (curl, jq, iproute2) are installed.


For any issues or questions, please create an issue!
