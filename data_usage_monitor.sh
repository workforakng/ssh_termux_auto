#!/data/data/com.termux/files/usr/bin/bash

# Data Usage Monitor - Tracking Only (No Limits)

LOG_FILE="$HOME/data_usage.log"
CHECK_INTERVAL=3600  # Log every hour
INTERFACE="wlan0"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_msg "Data Usage Monitor started for $INTERFACE (Unlimited - Tracking Only)"

# Initial update
vnstat -u -i $INTERFACE > /dev/null 2>&1

while true; do
    # Update vnstat database
    vnstat -u -i $INTERFACE > /dev/null 2>&1
    
    # Get JSON data
    VNSTAT_JSON=$(vnstat -i $INTERFACE --json 2>/dev/null)
    
    if [ -n "$VNSTAT_JSON" ]; then
        # Parse today's data
        TODAY_RX=$(echo "$VNSTAT_JSON" | jq -r '.interfaces[0].traffic.day[0].rx // 0' 2>/dev/null)
        TODAY_TX=$(echo "$VNSTAT_JSON" | jq -r '.interfaces[0].traffic.day[0].tx // 0' 2>/dev/null)
        
        # Parse this month's data
        MONTH_RX=$(echo "$VNSTAT_JSON" | jq -r '.interfaces[0].traffic.month[0].rx // 0' 2>/dev/null)
        MONTH_TX=$(echo "$VNSTAT_JSON" | jq -r '.interfaces[0].traffic.month[0].tx // 0' 2>/dev/null)
        
        if [ "$TODAY_RX" != "null" ] && [ "$TODAY_TX" != "null" ]; then
            # Convert KiB to MB
            TODAY_RX_MB=$((TODAY_RX / 1024))
            TODAY_TX_MB=$((TODAY_TX / 1024))
            TODAY_TOTAL_MB=$((TODAY_RX_MB + TODAY_TX_MB))
            
            MONTH_RX_GB=$((MONTH_RX / 1024 / 1024))
            MONTH_TX_GB=$((MONTH_TX / 1024 / 1024))
            MONTH_TOTAL_GB=$((MONTH_RX_GB + MONTH_TX_GB))
            
            log_msg "Today: ${TODAY_TOTAL_MB}MB (↓${TODAY_RX_MB}MB ↑${TODAY_TX_MB}MB) | Month: ${MONTH_TOTAL_GB}GB"
        else
            log_msg "Waiting for data collection..."
        fi
    else
        log_msg "vnstat not responding, updating..."
        vnstat -u -i $INTERFACE
    fi
    
    sleep $CHECK_INTERVAL
done
