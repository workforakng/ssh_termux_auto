#!/data/data/com.termux/files/usr/bin/bash

# Master Control Script for SSH Notifier System

clear
cat << "EOF"
╔═══════════════════════════════════════╗
║   TERMUX SSH NOTIFIER MANAGER        ║
║   Advanced Monitoring & Control      ║
╚═══════════════════════════════════════╝
EOF

echo ""
echo "1.  Start All Services"
echo "2.  Stop All Services"
echo "3.  Status Check"
echo "4.  Send Test Email (Text)"
echo "5.  Send Test Email (HTML)"
echo "6.  View Logs"
echo "7.  System Health Report"
echo "8.  Data Usage Statistics"
echo "9.  Restart Specific Service"
echo "10. Edit Configuration"
echo "0.  Exit"
echo ""
read -p "Select option [0-10]: " choice

case $choice in
    1)
        echo ""
        echo "Starting all services..."
        
        termux-wake-lock
        echo "✓ Wake lock acquired"
        
        if ! pgrep -x "crond" > /dev/null; then
            crond
            echo "✓ Cron daemon started"
        else
            echo "✓ Cron already running"
        fi
        
        # Start vnstatd if not running
        if ! pgrep -x "vnstatd" > /dev/null; then
            sudo vnstatd -d 2>/dev/null
            echo "✓ vnstat daemon started"
        fi
        
        # Start monitors only if not already running
        if ! pgrep -f "network_monitor.sh" > /dev/null; then
            nohup ~/scripts/network_monitor.sh > /dev/null 2>&1 &
            echo "✓ Network monitor started (PID: $!)"
        else
            echo "○ Network monitor already running"
        fi
        
        if ! pgrep -f "ssh_monitor.sh" > /dev/null; then
            nohup ~/scripts/ssh_monitor.sh > /dev/null 2>&1 &
            echo "✓ SSH monitor started (PID: $!)"
        else
            echo "○ SSH monitor already running"
        fi
        
        if ! pgrep -f "ssh_success_monitor.sh" > /dev/null; then
            nohup ~/scripts/ssh_success_monitor.sh > /dev/null 2>&1 &
            echo "✓ SSH success monitor started (PID: $!)"
        else
            echo "○ SSH success monitor already running"
        fi
        
        if ! pgrep -f "battery_monitor.sh" > /dev/null; then
            nohup ~/scripts/battery_monitor.sh > /dev/null 2>&1 &
            echo "✓ Battery monitor started (PID: $!)"
        else
            echo "○ Battery monitor already running"
        fi
        
        if ! pgrep -f "network_quality.sh" > /dev/null; then
            nohup ~/scripts/network_quality.sh > /dev/null 2>&1 &
            echo "✓ Network quality monitor started (PID: $!)"
        else
            echo "○ Network quality monitor already running"
        fi
        
        if ! pgrep -f "wifi_monitor.sh" > /dev/null; then
            nohup ~/scripts/wifi_monitor.sh > /dev/null 2>&1 &
            echo "✓ WiFi monitor started (PID: $!)"
        else
            echo "○ WiFi monitor already running"
        fi
        
        if ! pgrep -f "data_usage_monitor.sh" > /dev/null; then
            nohup ~/scripts/data_usage_monitor.sh > /dev/null 2>&1 &
            echo "✓ Data usage monitor started (PID: $!)"
        else
            echo "○ Data usage monitor already running"
        fi
        
        echo ""
        echo "✅ All services checked and started!"
        ;;
        
    2)
        echo ""
        echo "Stopping all services..."
        
        pkill -f network_monitor.sh && echo "✓ Network monitor stopped"
        pkill -f ssh_monitor.sh && echo "✓ SSH monitor stopped"
        pkill -f ssh_success_monitor.sh && echo "✓ SSH success monitor stopped"
        pkill -f battery_monitor.sh && echo "✓ Battery monitor stopped"
        pkill -f network_quality.sh && echo "✓ Network quality monitor stopped"
        pkill -f wifi_monitor.sh && echo "✓ WiFi monitor stopped"
        pkill -f data_usage_monitor.sh && echo "✓ Data usage monitor stopped"
        
        termux-wake-unlock
        echo "✓ Wake lock released"
        
        echo ""
        echo "✅ All services stopped"
        ;;
        
    3)
        echo ""
        echo "═══════════════════════════════════════"
        echo "   SYSTEM STATUS"
        echo "═══════════════════════════════════════"
        echo ""
        
        pgrep -x "crond" > /dev/null && echo "✓ Cron daemon: RUNNING" || echo "✗ Cron daemon: STOPPED"
        pgrep -x "vnstatd" > /dev/null && echo "✓ vnstat daemon: RUNNING" || echo "○ vnstat daemon: STOPPED"
        pgrep -f "network_monitor.sh" > /dev/null && echo "✓ Network monitor: RUNNING" || echo "✗ Network monitor: STOPPED"
        pgrep -f "ssh_monitor.sh" > /dev/null && echo "✓ SSH monitor: RUNNING" || echo "✗ SSH monitor: STOPPED"
        pgrep -f "ssh_success_monitor.sh" > /dev/null && echo "✓ SSH success monitor: RUNNING" || echo "✗ SSH success monitor: STOPPED"
        pgrep -f "battery_monitor.sh" > /dev/null && echo "✓ Battery monitor: RUNNING" || echo "✗ Battery monitor: STOPPED"
        pgrep -f "network_quality.sh" > /dev/null && echo "✓ Network quality: RUNNING" || echo "✗ Network quality: STOPPED"
        pgrep -f "wifi_monitor.sh" > /dev/null && echo "✓ WiFi monitor: RUNNING" || echo "✗ WiFi monitor: STOPPED"
        pgrep -f "data_usage_monitor.sh" > /dev/null && echo "✓ Data usage monitor: RUNNING" || echo "✗ Data usage monitor: STOPPED"
        
        echo ""
        echo "Current IP: $(curl -s --connect-timeout 5 ifconfig.me || echo 'Unable to fetch')"
        echo "Last sent IP: $(cat ~/.last_ip 2>/dev/null || echo 'None')"
        echo ""
        echo "Battery: $(termux-battery-status 2>/dev/null | jq -r '.percentage' || echo 'N/A')%"
        echo "Temperature: $(termux-battery-status 2>/dev/null | jq -r '.temperature' || echo 'N/A')°C"
        echo ""
        ;;
        
    4)
        echo "Sending text email..."
        ~/scripts/email.sh
        echo "✅ Email sent"
        ;;
        
    5)
        echo "Sending HTML email..."
        ~/scripts/send_html_email.sh
        echo "✅ HTML email sent"
        ;;
        
    6)
        clear
        echo "SELECT LOG TO VIEW:"
        echo "1. Main email log"
        echo "2. SSH monitor"
        echo "3. SSH success log"
        echo "4. Battery monitor"
        echo "5. Network quality"
        echo "6. WiFi monitor"
        echo "7. Data usage"
        echo "8. Network monitor"
        echo "9. Boot log"
        read -p "Choice: " log_choice
        
        case $log_choice in
            1) tail -50 ~/email_script.log 2>/dev/null || echo "No logs yet" ;;
            2) tail -50 ~/ssh_monitor.log 2>/dev/null || echo "No logs yet" ;;
            3) tail -50 ~/ssh_success.log 2>/dev/null || echo "No logs yet" ;;
            4) tail -50 ~/battery_monitor.log 2>/dev/null || echo "No logs yet" ;;
            5) tail -50 ~/network_quality.log 2>/dev/null || echo "No logs yet" ;;
            6) tail -50 ~/wifi_monitor.log 2>/dev/null || echo "No logs yet" ;;
            7) tail -50 ~/data_usage.log 2>/dev/null || echo "No logs yet" ;;
            8) tail -50 ~/network_monitor.log 2>/dev/null || echo "No logs yet" ;;
            9) tail -50 ~/boot.log 2>/dev/null || echo "No logs yet" ;;
        esac
        ;;
        
    7)
        echo ""
        echo "═══════════════════════════════════════"
        echo "   SYSTEM HEALTH REPORT"
        echo "═══════════════════════════════════════"
        echo ""
        BATTERY=$(termux-battery-status 2>/dev/null)
        echo "Battery: $(echo $BATTERY | jq -r '.percentage')%"
        echo "Temperature: $(echo $BATTERY | jq -r '.temperature')°C"
        echo "Status: $(echo $BATTERY | jq -r '.status')"
        echo "Health: $(echo $BATTERY | jq -r '.health')"
        echo ""
        echo "Disk Usage: $(df -h $HOME | tail -1 | awk '{print $5}')"
        echo "Available: $(df -h $HOME | tail -1 | awk '{print $4}')"
        echo ""
        echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        ;;
        
    8)
        echo ""
        echo "═══════════════════════════════════════"
        echo "   DATA USAGE STATISTICS"
        echo "═══════════════════════════════════════"
        echo ""
        vnstat -i wlan0 2>/dev/null || echo "vnstat not available"
        echo ""
        ;;
        
    9)
        echo ""
        echo "SELECT SERVICE TO RESTART:"
        echo "1. Network monitor"
        echo "2. SSH monitor"
        echo "3. Battery monitor"
        echo "4. WiFi monitor"
        echo "5. Data usage monitor"
        echo "6. All monitors"
        read -p "Choice: " svc_choice
        
        case $svc_choice in
            1) pkill -f network_monitor.sh; nohup ~/scripts/network_monitor.sh > /dev/null 2>&1 & ;;
            2) pkill -f ssh_monitor.sh; nohup ~/scripts/ssh_monitor.sh > /dev/null 2>&1 & ;;
            3) pkill -f battery_monitor.sh; nohup ~/scripts/battery_monitor.sh > /dev/null 2>&1 & ;;
            4) pkill -f wifi_monitor.sh; nohup ~/scripts/wifi_monitor.sh > /dev/null 2>&1 & ;;
            5) pkill -f data_usage_monitor.sh; nohup ~/scripts/data_usage_monitor.sh > /dev/null 2>&1 & ;;
            6) 
                pkill -f monitor.sh
                sleep 2
                nohup ~/scripts/network_monitor.sh > /dev/null 2>&1 &
                nohup ~/scripts/ssh_monitor.sh > /dev/null 2>&1 &
                nohup ~/scripts/ssh_success_monitor.sh > /dev/null 2>&1 &
                nohup ~/scripts/battery_monitor.sh > /dev/null 2>&1 &
                nohup ~/scripts/network_quality.sh > /dev/null 2>&1 &
                nohup ~/scripts/wifi_monitor.sh > /dev/null 2>&1 &
                nohup ~/scripts/data_usage_monitor.sh > /dev/null 2>&1 &
                ;;
        esac
        echo "✅ Service(s) restarted"
        ;;
        
    10)
        echo ""
        echo "SELECT FILE TO EDIT:"
        echo "1. Main email script"
        echo "2. msmtp config"
        echo "3. Crontab"
        echo "4. Boot script"
        read -p "Choice: " edit_choice
        
        case $edit_choice in
            1) nano ~/scripts/email.sh ;;
            2) nano ~/.msmtprc ;;
            3) crontab -e ;;
            4) nano ~/.termux/boot/start-ssh-notifier ;;
        esac
        ;;
        
    0)
        exit 0
        ;;
        
    *)
        echo "Invalid option"
        ;;
esac

echo ""
read -p "Press Enter to continue..."
