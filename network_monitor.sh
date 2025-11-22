#!/data/data/com.termux/files/usr/bin/bash

# Network Monitor - Detects IP changes and triggers email

LOG_FILE="$HOME/network_monitor.log"
CHECK_INTERVAL=300  # Check every 5 minutes

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_msg "Network monitor started"

while true; do
    # Get current IP
    CURRENT_IP=$(curl -s --connect-timeout 10 ifconfig.me 2>/dev/null)
    
    if [ -n "$CURRENT_IP" ]; then
        # Check if IP changed
        LAST_IP=""
        if [ -f "$HOME/.last_ip" ]; then
            LAST_IP=$(cat "$HOME/.last_ip")
        fi
        
        if [ "$CURRENT_IP" != "$LAST_IP" ]; then
            log_msg "IP change detected: $LAST_IP -> $CURRENT_IP"
            # Trigger immediate email
            $HOME/scripts/email.sh
            log_msg "Email notification sent"
        fi
    fi
    
    sleep $CHECK_INTERVAL
done
