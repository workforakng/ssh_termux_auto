#!/data/data/com.termux/files/usr/bin/bash

# Battery & Temperature Health Monitor

LOG_FILE="$HOME/battery_monitor.log"
TEMP_THRESHOLD=45
BATTERY_THRESHOLD=15
CHECK_INTERVAL=300
ALERT_COOLDOWN=1800

LAST_ALERT_TIME=0

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_msg "Battery Monitor started"

while true; do
    BATTERY=$(termux-battery-status 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$BATTERY" ]; then
        PERCENTAGE=$(echo "$BATTERY" | jq -r '.percentage // 0')
        TEMP=$(echo "$BATTERY" | jq -r '.temperature // 0')
        STATUS=$(echo "$BATTERY" | jq -r '.status // "UNKNOWN"')
        HEALTH=$(echo "$BATTERY" | jq -r '.health // "UNKNOWN"')
        PLUGGED=$(echo "$BATTERY" | jq -r '.plugged // "UNPLUGGED"')
        
        log_msg "Battery: ${PERCENTAGE}% | Temp: ${TEMP}°C | Status: $STATUS | Health: $HEALTH"
        
        ALERT=0
        ALERT_MSG=""
        CURRENT_TIME=$(date +%s)
        
        # Check temperature
        if (( $(echo "$TEMP > $TEMP_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
            ALERT=1
            ALERT_MSG="🔥 HIGH TEMPERATURE: ${TEMP}°C (Threshold: ${TEMP_THRESHOLD}°C)
"
            log_msg "HIGH TEMP ALERT: ${TEMP}°C"
        fi
        
        # Check battery level
        if [ "$PERCENTAGE" -lt "$BATTERY_THRESHOLD" ] && [ "$STATUS" != "CHARGING" ]; then
            ALERT=1
            ALERT_MSG="${ALERT_MSG}⚠️ LOW BATTERY: ${PERCENTAGE}% (Threshold: ${BATTERY_THRESHOLD}%)
"
            log_msg "LOW BATTERY ALERT: ${PERCENTAGE}%"
        fi
        
        # Check battery health
        if [ "$HEALTH" != "GOOD" ] && [ "$HEALTH" != "UNKNOWN" ]; then
            ALERT=1
            ALERT_MSG="${ALERT_MSG}⚠️ BATTERY HEALTH ISSUE: ${HEALTH}
"
            log_msg "BATTERY HEALTH ISSUE: ${HEALTH}"
        fi
        
        # Send alert if conditions met and cooldown passed
        TIME_SINCE_ALERT=$((CURRENT_TIME - LAST_ALERT_TIME))
        
        if [ "$ALERT" -eq 1 ] && [ "$TIME_SINCE_ALERT" -gt "$ALERT_COOLDOWN" ]; then
            EMAIL_SUBJECT="⚠️ Device Health Alert - Battery/Temperature"
            EMAIL_BODY="═══════════════════════════════════════
"
            EMAIL_BODY="${EMAIL_BODY}    ⚠️  DEVICE HEALTH ALERT  ⚠️
"
            EMAIL_BODY="${EMAIL_BODY}═══════════════════════════════════════

"
            EMAIL_BODY="${EMAIL_BODY}$ALERT_MSG
"
            EMAIL_BODY="${EMAIL_BODY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
            EMAIL_BODY="${EMAIL_BODY}Current Device Status:
"
            EMAIL_BODY="${EMAIL_BODY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"
            EMAIL_BODY="${EMAIL_BODY}Battery Level:  ${PERCENTAGE}%
"
            EMAIL_BODY="${EMAIL_BODY}Temperature:    ${TEMP}°C
"
            EMAIL_BODY="${EMAIL_BODY}Status:         ${STATUS}
"
            EMAIL_BODY="${EMAIL_BODY}Health:         ${HEALTH}
"
            EMAIL_BODY="${EMAIL_BODY}Plugged:        ${PLUGGED}
"
            EMAIL_BODY="${EMAIL_BODY}Time:           $(date '+%Y-%m-%d %H:%M:%S %Z')
"
            
            echo -e "Subject: $EMAIL_SUBJECT

$EMAIL_BODY" | msmtp RECIPIENT1_EMAIL RECIPIENT2_EMAIL
            
            log_msg "HEALTH ALERT SENT"
            LAST_ALERT_TIME=$CURRENT_TIME
        fi
    else
        log_msg "WARNING: Unable to read battery status"
    fi
    
    sleep $CHECK_INTERVAL
done
