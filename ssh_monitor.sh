#!/data/data/com.termux/files/usr/bin/bash

# SSH Login Monitor - Security Alert System

LOG_FILE="$HOME/ssh_monitor.log"
AUTH_LOG="$PREFIX/var/log/auth.log"
FAILED_ATTEMPTS_FILE="$HOME/.failed_ssh_attempts"
ALERT_THRESHOLD=3
CHECK_INTERVAL=60

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Create auth log if doesn't exist
touch "$AUTH_LOG" 2>/dev/null

# Initialize counter
if [ ! -f "$FAILED_ATTEMPTS_FILE" ]; then
    echo "0" > "$FAILED_ATTEMPTS_FILE"
fi

log_msg "SSH Monitor started"

while true; do
    # Count failed attempts
    if [ -f "$AUTH_LOG" ]; then
        FAILED=$(grep -c "Failed password|authentication failure" "$AUTH_LOG" 2>/dev/null || echo "0")
        LAST_FAILED=$(cat "$FAILED_ATTEMPTS_FILE")
        
        if [ "$FAILED" -gt "$LAST_FAILED" ] && [ "$FAILED" -ge "$ALERT_THRESHOLD" ]; then
            NEW_ATTEMPTS=$((FAILED - LAST_FAILED))
            
            # Get recent failed attempts
            RECENT_FAILS=$(tail -20 "$AUTH_LOG" | grep "Failed password|authentication failure" | tail -5)
            
            # Send alert
            EMAIL_SUBJECT="🚨 SECURITY ALERT: Failed SSH Login Attempts"
            EMAIL_BODY="═══════════════════════════════════════
"
            EMAIL_BODY="${EMAIL_BODY}  ⚠️  UNAUTHORIZED ACCESS ATTEMPT  ⚠️
"
            EMAIL_BODY="${EMAIL_BODY}═══════════════════════════════════════

"
            EMAIL_BODY="${EMAIL_BODY}New failed attempts: $NEW_ATTEMPTS
"
            EMAIL_BODY="${EMAIL_BODY}Total failed attempts: $FAILED

"
            EMAIL_BODY="${EMAIL_BODY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
            EMAIL_BODY="${EMAIL_BODY}Recent Failed Attempts:
"
            EMAIL_BODY="${EMAIL_BODY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"
            EMAIL_BODY="${EMAIL_BODY}$RECENT_FAILS

"
            EMAIL_BODY="${EMAIL_BODY}Device: $(uname -n)
"
            EMAIL_BODY="${EMAIL_BODY}Time: $(date '+%Y-%m-%d %H:%M:%S %Z')
"
            EMAIL_BODY="${EMAIL_BODY}Current IP: $(curl -s ifconfig.me)
"
            
            echo -e "Subject: $EMAIL_SUBJECT

$EMAIL_BODY" | msmtp RECIPIENT1_EMAIL RECIPIENT2_EMAIL
            
            log_msg "ALERT SENT: $NEW_ATTEMPTS new failed login attempts"
            echo "$FAILED" > "$FAILED_ATTEMPTS_FILE"
        fi
    fi
    
    sleep $CHECK_INTERVAL
done
