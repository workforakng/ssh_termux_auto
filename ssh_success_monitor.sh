#!/data/data/com.termux/files/usr/bin/bash

# Monitor successful SSH logins

LOG_FILE="$HOME/ssh_success.log"
AUTH_LOG="$PREFIX/var/log/auth.log"
LAST_SUCCESS_FILE="$HOME/.last_ssh_success"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Initialize
if [ ! -f "$LAST_SUCCESS_FILE" ]; then
    echo "0" > "$LAST_SUCCESS_FILE"
fi

log_msg "SSH Success Monitor started"

while true; do
    if [ -f "$AUTH_LOG" ]; then
        CURRENT_COUNT=$(grep -c "Accepted password|Accepted publickey" "$AUTH_LOG" 2>/dev/null || echo "0")
        LAST_COUNT=$(cat "$LAST_SUCCESS_FILE")
        
        if [ "$CURRENT_COUNT" -gt "$LAST_COUNT" ]; then
            # Get last successful login
            LAST_LOGIN=$(grep "Accepted password|Accepted publickey" "$AUTH_LOG" | tail -1)
            
            EMAIL_SUBJECT="✅ SSH Connection Established"
            EMAIL_BODY="═══════════════════════════════════════
"
            EMAIL_BODY="${EMAIL_BODY}   ✅ SUCCESSFUL SSH CONNECTION
"
            EMAIL_BODY="${EMAIL_BODY}═══════════════════════════════════════

"
            EMAIL_BODY="${EMAIL_BODY}Someone successfully connected to your device.

"
            EMAIL_BODY="${EMAIL_BODY}Connection Details:
"
            EMAIL_BODY="${EMAIL_BODY}$LAST_LOGIN

"
            EMAIL_BODY="${EMAIL_BODY}Time: $(date '+%Y-%m-%d %H:%M:%S %Z')
"
            EMAIL_BODY="${EMAIL_BODY}Device IP: $(curl -s ifconfig.me)
"
            
            echo -e "Subject: $EMAIL_SUBJECT

$EMAIL_BODY" | msmtp RECIPIENT1_EMAIL RECIPIENT2_EMAIL
            
            log_msg "ALERT: New successful SSH connection detected"
            echo "$CURRENT_COUNT" > "$LAST_SUCCESS_FILE"
        fi
    fi
    
    sleep 30
done

