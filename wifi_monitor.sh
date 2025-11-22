#!/data/data/com.termux/files/usr/bin/bash

# WiFi Network Change Monitor

LOG_FILE="$HOME/wifi_monitor.log"
LAST_SSID_FILE="$HOME/.last_wifi_ssid"
CHECK_INTERVAL=60

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_msg "WiFi Monitor started"

while true; do
    WIFI_INFO=$(termux-wifi-connectioninfo 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$WIFI_INFO" ]; then
        CURRENT_SSID=$(echo "$WIFI_INFO" | jq -r '.ssid // "UNKNOWN"')
        CURRENT_BSSID=$(echo "$WIFI_INFO" | jq -r '.bssid // "UNKNOWN"')
        IP_ADDRESS=$(echo "$WIFI_INFO" | jq -r '.ip // "UNKNOWN"')
        LINK_SPEED=$(echo "$WIFI_INFO" | jq -r '.link_speed // "UNKNOWN"')
        
        # Read last known SSID
        if [ -f "$LAST_SSID_FILE" ]; then
            LAST_SSID=$(cat "$LAST_SSID_FILE")
        else
            LAST_SSID=""
        fi
        
        # Check if network changed
        if [ "$CURRENT_SSID" != "$LAST_SSID" ] && [ -n "$LAST_SSID" ]; then
            log_msg "WiFi network changed: $LAST_SSID -> $CURRENT_SSID"
            
            # Send notification
            EMAIL_SUBJECT="📡 WiFi Network Changed"
            EMAIL_BODY="═══════════════════════════════════════
"
            EMAIL_BODY="${EMAIL_BODY}   📡 WiFi NETWORK CHANGED
"
            EMAIL_BODY="${EMAIL_BODY}═══════════════════════════════════════

"
            EMAIL_BODY="${EMAIL_BODY}Previous Network: $LAST_SSID
"
            EMAIL_BODY="${EMAIL_BODY}New Network:      $CURRENT_SSID

"
            EMAIL_BODY="${EMAIL_BODY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
            EMAIL_BODY="${EMAIL_BODY}Connection Details:
"
            EMAIL_BODY="${EMAIL_BODY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"
            EMAIL_BODY="${EMAIL_BODY}SSID:         $CURRENT_SSID
"
            EMAIL_BODY="${EMAIL_BODY}BSSID:        $CURRENT_BSSID
"
            EMAIL_BODY="${EMAIL_BODY}Local IP:     $IP_ADDRESS
"
            EMAIL_BODY="${EMAIL_BODY}Link Speed:   ${LINK_SPEED} Mbps
"
            EMAIL_BODY="${EMAIL_BODY}Time:         $(date '+%Y-%m-%d %H:%M:%S %Z')

"
            
            # Get public IP
            PUBLIC_IP=$(curl -s --connect-timeout 10 ifconfig.me)
            EMAIL_BODY="${EMAIL_BODY}Public IP:    $PUBLIC_IP
"
            EMAIL_BODY="${EMAIL_BODY}SSH Command:  ssh YOUR_SSH_USER@$PUBLIC_IP -p 9696
"
            
            echo -e "Subject: $EMAIL_SUBJECT

$EMAIL_BODY" | msmtp RECIPIENT1_EMAIL RECIPIENT2_EMAIL
        fi
        
        # Update last SSID
        echo "$CURRENT_SSID" > "$LAST_SSID_FILE"
        log_msg "Current network: $CURRENT_SSID"
    else
        log_msg "Not connected to WiFi"
    fi
    
    sleep $CHECK_INTERVAL
done
