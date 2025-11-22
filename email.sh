#!/data/data/com.termux/files/usr/bin/bash

# SSH IP Notifier - With High Resource Usage Alerts

SENDER="YOUR_SENDER_EMAIL"
RECIPIENTS="RECIPIENT1_EMAIL RECIPIENT2_EMAIL"
LOG_FILE="$HOME/email_script.log"
LAST_IP_FILE="$HOME/.last_ip"
PASSWD_FILE="$PREFIX/etc/passwd"
LAST_PASSWD_HASH_FILE="$HOME/.last_passwd_hash"
SSH_PORT="9696"
SSH_USER="YOUR_SSH_USER"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S IST')] $1" >> "$LOG_FILE"
}

log_message "============ Script Started ============"

# Get IP
get_public_ip() {
    local ip=$(curl -s --connect-timeout 10 ifconfig.me 2>/dev/null)
    if [ -n "$ip" ]; then echo "$ip"; return 0; fi
    ip=$(curl -s --connect-timeout 10 icanhazip.com 2>/dev/null)
    if [ -n "$ip" ]; then echo "$ip"; return 0; fi
    return 1
}

CURRENT_IP=$(get_public_ip)

if [ -z "$CURRENT_IP" ]; then
    log_message "ERROR: Failed to retrieve IP"
    exit 1
fi

log_message "Current IP: $CURRENT_IP"

# Read last IP
LAST_IP=""
[ -f "$LAST_IP_FILE" ] && LAST_IP=$(cat "$LAST_IP_FILE")

# Check password
CURRENT_PASSWD_HASH=$(sha256sum "$PASSWD_FILE" 2>/dev/null | awk '{print $1}')
LAST_PASSWD_HASH=""
[ -f "$LAST_PASSWD_HASH_FILE" ] && LAST_PASSWD_HASH=$(cat "$LAST_PASSWD_HASH_FILE")

# Get system info
BATTERY=$(termux-battery-status 2>/dev/null | jq -r '.percentage // "N/A"')
TEMP=$(termux-battery-status 2>/dev/null | jq -r '.temperature // "N/A"')
BATTERY_STATUS=$(termux-battery-status 2>/dev/null | jq -r '.status // "N/A"')
DISK=$(df -h $HOME | tail -1 | awk '{print $5}')
DISK_AVAIL=$(df -h $HOME | tail -1 | awk '{print $4}')
UPTIME=$(uptime -p 2>/dev/null || echo "N/A")

# RAM info
if command -v free &> /dev/null; then
    MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
    MEM_USED=$(free -h | grep Mem | awk '{print $3}')
    MEM_FREE=$(free -h | grep Mem | awk '{print $4}')
    MEM_PERCENT=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100}')
else
    MEM_TOTAL="N/A"
    MEM_USED="N/A"
    MEM_FREE="N/A"
    MEM_PERCENT="N/A"
fi

# CPU info - Improved detection
CPU_USAGE="N/A"

# Method 1: Use /proc/stat for accurate CPU usage
if [ -f /proc/stat ]; then
    # Read initial values
    read cpu user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 rest < /proc/stat
    sleep 1
    # Read again after 1 second
    read cpu user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 rest < /proc/stat
    
    # Calculate totals
    TOTAL1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
    TOTAL2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
    IDLE_DIFF=$((idle2 - idle1))
    TOTAL_DIFF=$((TOTAL2 - TOTAL1))
    
    if [ $TOTAL_DIFF -gt 0 ]; then
        CPU_USAGE=$(echo "scale=1; 100 * ($TOTAL_DIFF - $IDLE_DIFF) / $TOTAL_DIFF" | bc 2>/dev/null)
    fi
fi

# Method 2: Fallback to top
if [ "$CPU_USAGE" = "N/A" ] || [ -z "$CPU_USAGE" ]; then
    CPU_USAGE=$(top -bn1 | grep -i "cpu" | head -1 | awk '{print $2}' | sed 's/%//' | sed 's/[^0-9.]//g' 2>/dev/null)
fi

# Method 3: Final fallback to load average
if [ "$CPU_USAGE" = "N/A" ] || [ -z "$CPU_USAGE" ]; then
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    CPU_CORES=$(nproc 2>/dev/null || echo "1")
    if [ -n "$LOAD_AVG" ]; then
        CPU_USAGE=$(echo "scale=1; ($LOAD_AVG / $CPU_CORES) * 100" | bc 2>/dev/null || echo "0.0")
    fi
fi

# Ensure CPU_USAGE is a valid number
if ! echo "$CPU_USAGE" | grep -qE '^[0-9]+.?[0-9]*$'; then
    CPU_USAGE="0.0"
fi

CPU_CORES=$(nproc 2>/dev/null || echo "N/A")

# Check for high resource usage
HIGH_RESOURCE_ALERT=""
RESOURCE_ALERT_TRIGGERED=0

# Check RAM usage
if [ "$MEM_PERCENT" != "N/A" ]; then
    MEM_INT=$(printf "%.0f" "$MEM_PERCENT" 2>/dev/null || echo "0")
    if [ "$MEM_INT" -ge 98 ]; then
        HIGH_RESOURCE_ALERT="${HIGH_RESOURCE_ALERT}⚠️ RAM usage is critically high: ${MEM_PERCENT}%<br>"
        RESOURCE_ALERT_TRIGGERED=1
        log_message "HIGH RAM USAGE ALERT: ${MEM_PERCENT}%"
    fi
fi

# Check CPU usage
if [ "$CPU_USAGE" != "N/A" ]; then
    CPU_INT=$(printf "%.0f" "$CPU_USAGE" 2>/dev/null || echo "0")
    if [ "$CPU_INT" -ge 98 ]; then
        HIGH_RESOURCE_ALERT="${HIGH_RESOURCE_ALERT}⚠️ CPU usage is critically high: ${CPU_USAGE}%<br>"
        RESOURCE_ALERT_TRIGGERED=1
        log_message "HIGH CPU USAGE ALERT: ${CPU_USAGE}%"
    fi
fi

# Get data usage
if command -v vnstat &> /dev/null; then
    DATA_TODAY=$(vnstat -i wlan0 --oneline 2>/dev/null | cut -d';' -f4 || echo "N/A")
    DATA_MONTH=$(vnstat -i wlan0 --oneline 2>/dev/null | cut -d';' -f11 || echo "N/A")
else
    DATA_TODAY="N/A"
    DATA_MONTH="N/A"
fi

# Determine status
IP_CHANGED=0
PASSWD_CHANGED=0
EMAIL_SUBJECT="🔐 Termux SSH Connection Info"

if [ "$CURRENT_IP" != "$LAST_IP" ] && [ -n "$LAST_IP" ]; then
    IP_CHANGED=1
    EMAIL_SUBJECT="🔄 IP Address Changed - SSH Update"
    log_message "IP CHANGED: $LAST_IP -> $CURRENT_IP"
fi

if [ "$CURRENT_PASSWD_HASH" != "$LAST_PASSWD_HASH" ] && [ -n "$LAST_PASSWD_HASH" ]; then
    PASSWD_CHANGED=1
    EMAIL_SUBJECT="🚨 ALERT: SSH Password Changed!"
    log_message "CRITICAL: Password changed"
fi

if [ $RESOURCE_ALERT_TRIGGERED -eq 1 ]; then
    EMAIL_SUBJECT="⚠️ HIGH RESOURCE USAGE - ${EMAIL_SUBJECT}"
fi
if [ $RESOURCE_ALERT_TRIGGERED -eq 1 ]; then
    EMAIL_SUBJECT="⚠️ HIGH RESOURCE USAGE - ${EMAIL_SUBJECT}"
fi

# ADD THESE LINES:
# Only send email if something changed
if [ $IP_CHANGED -eq 0 ] && [ $PASSWD_CHANGED -eq 0 ] && [ $RESOURCE_ALERT_TRIGGERED -eq 0 ]; then
    log_message "No changes detected. Email not sent."
    echo "ℹ️  No changes detected. Email not sent."
    # Still update tracking files
    echo "$CURRENT_IP" > "$LAST_IP_FILE"
    echo "$CURRENT_PASSWD_HASH" > "$LAST_PASSWD_HASH_FILE"
    exit 0
fi

# If we reach here, something changed - proceed with email
log_message "Change detected. Sending email..."

# Create email
EMAIL_CONTENT=$(cat << 'EMAILEOF'
Subject: EMAIL_SUBJECT_PLACEHOLDER
Content-Type: text/html; charset=utf-8
MIME-Version: 1.0

<!DOCTYPE html>
<html>
<body style="margin:0;padding:20px;font-family:Arial,sans-serif;background-color:#f4f4f4;">
<table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background-color:#ffffff;border-radius:8px;overflow:hidden;box-shadow:0 2px 4px rgba(0,0,0,0.1);">
<tr>
<td style="background-color:#0066cc;padding:20px;text-align:center;">
<h1 style="color:#ffffff;margin:0;font-size:24px;">🔐 Termux SSH Connection</h1>
<p style="color:#e6f2ff;margin:5px 0 0 0;font-size:14px;">Automated Monitoring System by AkNG</p>
</td>
</tr>
RESOURCE_ALERT_PLACEHOLDER
IP_CHANGE_ALERT
PASSWORD_CHANGE_ALERT
<tr>
<td style="padding:20px;">
<table width="100%" cellpadding="0" cellspacing="0" style="background-color:#e8f4f8;border-left:4px solid #0066cc;padding:15px;border-radius:4px;">
<tr>
<td>
<strong style="color:#333333;font-size:16px;">SSH Connection Command:</strong><br><br>
<code style="background-color:#f0f0f0;padding:10px;display:block;color:#d14;font-size:16px;border-radius:4px;">ssh SSH_USER_PLACEHOLDER@CURRENT_IP_PLACEHOLDER -p SSH_PORT_PLACEHOLDER</code>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td style="padding:20px;">
<h2 style="color:#0066cc;font-size:18px;margin:0 0 15px 0;border-bottom:2px solid #e0e0e0;padding-bottom:10px;">📡 Connection Details</h2>
<table width="100%" cellpadding="5" cellspacing="0">
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">IP Address:</td>
<td style="color:#0066cc;text-align:right;">CURRENT_IP_PLACEHOLDER</td>
</tr>
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">Username:</td>
<td style="color:#0066cc;text-align:right;">SSH_USER_PLACEHOLDER</td>
</tr>
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">Port:</td>
<td style="color:#0066cc;text-align:right;">SSH_PORT_PLACEHOLDER</td>
</tr>
<tr>
<td style="color:#666;font-weight:bold;">Protocol:</td>
<td style="color:#0066cc;text-align:right;">SSH</td>
</tr>
</table>
</td>
</tr>
<tr>
<td style="padding:20px;">
<h2 style="color:#0066cc;font-size:18px;margin:0 0 15px 0;border-bottom:2px solid #e0e0e0;padding-bottom:10px;">📱 Device Status</h2>
<table width="100%" cellpadding="5" cellspacing="0">
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">Battery:</td>
<td style="color:#28a745;text-align:right;">BATTERY_PLACEHOLDER% (BATTERY_STATUS_PLACEHOLDER)</td>
</tr>
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">Temperature:</td>
<td style="color:#0066cc;text-align:right;">TEMP_PLACEHOLDER°C</td>
</tr>
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">Storage Used:</td>
<td style="color:#0066cc;text-align:right;">DISK_PLACEHOLDER (DISK_AVAIL_PLACEHOLDER free)</td>
</tr>
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">Uptime:</td>
<td style="color:#0066cc;text-align:right;">UPTIME_PLACEHOLDER</td>
</tr>
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">RAM Usage:</td>
<td style="color:#0066cc;text-align:right;">MEM_USED_PLACEHOLDER / MEM_TOTAL_PLACEHOLDER (MEM_PERCENT_PLACEHOLDER%)</td>
</tr>
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">RAM Free:</td>
<td style="color:#28a745;text-align:right;">MEM_FREE_PLACEHOLDER</td>
</tr>
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">CPU Usage:</td>
<td style="color:#0066cc;text-align:right;">CPU_USAGE_PLACEHOLDER%</td>
</tr>
<tr>
<td style="color:#666;font-weight:bold;">CPU Cores:</td>
<td style="color:#0066cc;text-align:right;">CPU_CORES_PLACEHOLDER cores</td>
</tr>
</table>
</td>
</tr>
<tr>
<td style="padding:20px;">
<h2 style="color:#0066cc;font-size:18px;margin:0 0 15px 0;border-bottom:2px solid #e0e0e0;padding-bottom:10px;">📊 Network Usage</h2>
<table width="100%" cellpadding="5" cellspacing="0">
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">Today:</td>
<td style="color:#0066cc;text-align:right;">DATA_TODAY_PLACEHOLDER</td>
</tr>
<tr>
<td style="color:#666;font-weight:bold;">This Month:</td>
<td style="color:#0066cc;text-align:right;">DATA_MONTH_PLACEHOLDER</td>
</tr>
</table>
</td>
</tr>
<tr>
<td style="padding:20px;">
<h2 style="color:#0066cc;font-size:18px;margin:0 0 15px 0;border-bottom:2px solid #e0e0e0;padding-bottom:10px;">🕐 Timestamp</h2>
<table width="100%" cellpadding="5" cellspacing="0">
<tr style="border-bottom:1px solid #e0e0e0;">
<td style="color:#666;font-weight:bold;">Generated:</td>
<td style="color:#0066cc;text-align:right;">TIMESTAMP_PLACEHOLDER</td>
</tr>
<tr>
<td style="color:#666;font-weight:bold;">Device:</td>
<td style="color:#0066cc;text-align:right;">DEVICE_PLACEHOLDER</td>
</tr>
</table>
</td>
</tr>
<tr>
<td style="padding:20px;text-align:center;background-color:#f8f9fa;border-top:1px solid #e0e0e0;">
<p style="color:#666;margin:0;font-size:12px;">🤖 Automated notification from Termux SSH Notifier</p>
<p style="color:#999;margin:5px 0 0 0;font-size:11px;">Sent hourly and on IP changes • Made by <strong style="color:#0066cc;">AkNG</strong> • <a href="https://github.com/workforakng" style="color:#0066cc;text-decoration:none;">GitHub</a></p>
</td>
</tr>
</table>
</body>
</html>
EMAILEOF
)

# Add resource alert if needed
if [ $RESOURCE_ALERT_TRIGGERED -eq 1 ]; then
    RESOURCE_ALERT='<tr><td style="padding:20px;"><table width="100%" cellpadding="0" cellspacing="0" style="background-color:#fff3cd;border-left:4px solid #ff6b6b;padding:15px;border-radius:4px;"><tr><td><strong style="color:#721c24;">⚠️ HIGH RESOURCE USAGE WARNING</strong><br>RESOURCE_ALERT_MESSAGE</td></tr></table></td></tr>'
    RESOURCE_ALERT="${RESOURCE_ALERT//RESOURCE_ALERT_MESSAGE/$HIGH_RESOURCE_ALERT}"
    EMAIL_CONTENT="${EMAIL_CONTENT//RESOURCE_ALERT_PLACEHOLDER/$RESOURCE_ALERT}"
else
    EMAIL_CONTENT="${EMAIL_CONTENT//RESOURCE_ALERT_PLACEHOLDER/}"
fi

# Add IP change alert if needed
if [ $IP_CHANGED -eq 1 ]; then
    IP_ALERT='<tr><td style="padding:20px;"><table width="100%" cellpadding="0" cellspacing="0" style="background-color:#d1ecf1;border-left:4px solid #0c5460;padding:15px;border-radius:4px;"><tr><td><strong style="color:#0c5460;">🔄 IP Address Changed</strong><br>Previous: <code>LAST_IP_PLACEHOLDER</code><br>New: <code style="color:#28a745;">CURRENT_IP_PLACEHOLDER</code></td></tr></table></td></tr>'
    IP_ALERT="${IP_ALERT//LAST_IP_PLACEHOLDER/$LAST_IP}"
    EMAIL_CONTENT="${EMAIL_CONTENT//IP_CHANGE_ALERT/$IP_ALERT}"
else
    EMAIL_CONTENT="${EMAIL_CONTENT//IP_CHANGE_ALERT/}"
fi

# Add password alert if needed
if [ $PASSWD_CHANGED -eq 1 ]; then
    PASS_ALERT='<tr><td style="padding:20px;"><table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f8d7da;border-left:4px solid #dc3545;padding:15px;border-radius:4px;"><tr><td><strong style="color:#721c24;">⚠️ SSH PASSWORD CHANGED!</strong><br>Detected change in SSH authentication. Verify this was authorized.</td></tr></table></td></tr>'
    EMAIL_CONTENT="${EMAIL_CONTENT//PASSWORD_CHANGE_ALERT/$PASS_ALERT}"
else
    EMAIL_CONTENT="${EMAIL_CONTENT//PASSWORD_CHANGE_ALERT/}"
fi

# Replace all placeholders
EMAIL_CONTENT="${EMAIL_CONTENT//EMAIL_SUBJECT_PLACEHOLDER/$EMAIL_SUBJECT}"
EMAIL_CONTENT="${EMAIL_CONTENT//CURRENT_IP_PLACEHOLDER/$CURRENT_IP}"
EMAIL_CONTENT="${EMAIL_CONTENT//SSH_USER_PLACEHOLDER/$SSH_USER}"
EMAIL_CONTENT="${EMAIL_CONTENT//SSH_PORT_PLACEHOLDER/$SSH_PORT}"
EMAIL_CONTENT="${EMAIL_CONTENT//BATTERY_PLACEHOLDER/$BATTERY}"
EMAIL_CONTENT="${EMAIL_CONTENT//TEMP_PLACEHOLDER/$TEMP}"
EMAIL_CONTENT="${EMAIL_CONTENT//BATTERY_STATUS_PLACEHOLDER/$BATTERY_STATUS}"
EMAIL_CONTENT="${EMAIL_CONTENT//DISK_PLACEHOLDER/$DISK}"
EMAIL_CONTENT="${EMAIL_CONTENT//DISK_AVAIL_PLACEHOLDER/$DISK_AVAIL}"
EMAIL_CONTENT="${EMAIL_CONTENT//UPTIME_PLACEHOLDER/$UPTIME}"
EMAIL_CONTENT="${EMAIL_CONTENT//MEM_TOTAL_PLACEHOLDER/$MEM_TOTAL}"
EMAIL_CONTENT="${EMAIL_CONTENT//MEM_USED_PLACEHOLDER/$MEM_USED}"
EMAIL_CONTENT="${EMAIL_CONTENT//MEM_FREE_PLACEHOLDER/$MEM_FREE}"
EMAIL_CONTENT="${EMAIL_CONTENT//MEM_PERCENT_PLACEHOLDER/$MEM_PERCENT}"
EMAIL_CONTENT="${EMAIL_CONTENT//CPU_USAGE_PLACEHOLDER/$CPU_USAGE}"
EMAIL_CONTENT="${EMAIL_CONTENT//CPU_CORES_PLACEHOLDER/$CPU_CORES}"
EMAIL_CONTENT="${EMAIL_CONTENT//DATA_TODAY_PLACEHOLDER/$DATA_TODAY}"
EMAIL_CONTENT="${EMAIL_CONTENT//DATA_MONTH_PLACEHOLDER/$DATA_MONTH}"
EMAIL_CONTENT="${EMAIL_CONTENT//TIMESTAMP_PLACEHOLDER/$(date '+%A, %B %d, %Y at %I:%M:%S %p %Z')}"
EMAIL_CONTENT="${EMAIL_CONTENT//DEVICE_PLACEHOLDER/$(uname -n)}"

# Send email silently
echo "$EMAIL_CONTENT" | msmtp $RECIPIENTS 2>&1 | grep -v "^<" | grep -v "html" | grep -v "body" | grep -v "table" | grep -v "EOF"

if [ ${PIPESTATUS[1]} -eq 0 ]; then
    log_message "✓ Email sent successfully (CPU: ${CPU_USAGE}%, RAM: ${MEM_PERCENT}%)"
    echo "$CURRENT_IP" > "$LAST_IP_FILE"
    echo "$CURRENT_PASSWD_HASH" > "$LAST_PASSWD_HASH_FILE"
    echo "✅ Email sent successfully!"
else
    log_message "✗ ERROR: Failed to send email"
    echo "❌ Failed to send email"
    exit 1
fi

log_message "============ Script Completed ============"
exit 0
