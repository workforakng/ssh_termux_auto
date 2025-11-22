#!/data/data/com.termux/files/usr/bin/bash

# Network Quality Monitor

LOG_FILE="$HOME/network_quality.log"
CHECK_INTERVAL=600

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

test_connection() {
    # Ping test to Google DNS
    PING_RESULT=$(ping -c 4 8.8.8.8 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        AVG_PING=$(echo "$PING_RESULT" | tail -1 | awk -F '/' '{print $5}')
        PACKET_LOSS=$(echo "$PING_RESULT" | grep -oP 'd+(?=% packet loss)')
        
        log_msg "Ping: ${AVG_PING}ms | Packet Loss: ${PACKET_LOSS}%"
        
        # Alert if high packet loss
        if [ "$PACKET_LOSS" -gt 20 ]; then
            EMAIL_SUBJECT="⚠️ Network Quality Alert"
            EMAIL_BODY="High packet loss detected: ${PACKET_LOSS}%
"
            EMAIL_BODY="${EMAIL_BODY}Average Ping: ${AVG_PING}ms
"
            EMAIL_BODY="${EMAIL_BODY}Time: $(date)
"
            
            echo -e "Subject: $EMAIL_SUBJECT

$EMAIL_BODY" | msmtp RECIPIENT1_EMAIL RECIPIENT2_EMAIL
        fi
    else
        log_msg "ERROR: Unable to reach 8.8.8.8"
    fi
}

log_msg "Network Quality Monitor started"

while true; do
    test_connection
    sleep $CHECK_INTERVAL
done
