#!/data/data/com.termux/files/usr/bin/bash

# Enhanced HTML Email Sender

CURRENT_IP=$(curl -s ifconfig.me)
BATTERY=$(termux-battery-status 2>/dev/null | jq -r '.percentage // "N/A"')
TEMP=$(termux-battery-status 2>/dev/null | jq -r '.temperature // "N/A"')
DISK=$(df -h $HOME | tail -1 | awk '{print $5}')

cat << EOF | msmtp RECIPIENT1_EMAIL RECIPIENT2_EMAIL
Subject: Termux SSH Connection Info
Content-Type: text/html; charset=utf-8

<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: 'Courier New', monospace; background: #0d1117; color: #58a6ff; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: #161b22; border: 2px solid #30363d; border-radius: 10px; padding: 30px; }
        h2 { color: #58a6ff; border-bottom: 2px solid #21262d; padding-bottom: 10px; }
        .command { background: #0d1117; padding: 15px; border-left: 4px solid #58a6ff; margin: 20px 0; font-size: 16px; }
        .info-block { background: #161b22; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .label { color: #8b949e; font-weight: bold; }
        .value { color: #58a6ff; }
        .success { color: #3fb950; }
        .warning { color: #f85149; }
    </style>
</head>
<body>
    <div class="container">
        <h2>🔐 SSH Connection Details</h2>
        
        <div class="command">
            <strong>Connection Command:</strong><br>
            <code style="color: #3fb950; font-size: 18px;">ssh YOUR_SSH_USER@$CURRENT_IP -p 9696</code>
        </div>
        
        <div class="info-block">
            <p><span class="label">IP Address:</span> <span class="value">$CURRENT_IP</span></p>
            <p><span class="label">Port:</span> <span class="value">9696</span></p>
            <p><span class="label">Username:</span> <span class="value">YOUR_SSH_USER</span></p>
        </div>
        
        <h2>📱 Device Status</h2>
        <div class="info-block">
            <p><span class="label">Battery:</span> <span class="value">$BATTERY%</span></p>
            <p><span class="label">Temperature:</span> <span class="value">${TEMP}°C</span></p>
            <p><span class="label">Disk Usage:</span> <span class="value">$DISK</span></p>
            <p><span class="label">Timestamp:</span> <span class="value">$(date '+%Y-%m-%d %H:%M:%S %Z')</span></p>
        </div>
        
        <p style="text-align: center; color: #8b949e; margin-top: 30px; font-size: 12px;">
            Automated notification from Termux SSH Notifier
        </p>
    </div>
</body>
</html>
EOF
