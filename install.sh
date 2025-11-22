#!/data/data/com.termux/files/usr/bin/bash

# Termux SSH Auto Notifier - Installation Script
# Created by AkNG

echo "╔═══════════════════════════════════════╗"
echo "║  TERMUX SSH AUTO NOTIFIER INSTALLER  ║"
echo "║           by AkNG                    ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# Check if running in Termux
if [ ! -d "$PREFIX" ]; then
    echo "❌ Error: This script must be run in Termux"
    exit 1
fi

echo "📦 Installing required packages..."
pkg update -y
pkg install -y msmtp cronie termux-services termux-api curl jq bc vnstat

echo ""
echo "📁 Creating directory structure..."
mkdir -p ~/scripts
mkdir -p ~/.termux/boot

echo ""
echo "📋 Copying scripts..."
cp *.sh ~/scripts/ 2>/dev/null
cp boot/start-ssh-notifier ~/.termux/boot/
chmod +x ~/scripts/*.sh
chmod +x ~/.termux/boot/start-ssh-notifier

echo ""
echo "⚙️  Configuration required:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Copy config_template.sh to config.sh:"
echo "   cp config_template.sh config.sh"
echo ""
echo "2. Edit config.sh with your details:"
echo "   nano config.sh"
echo ""
echo "3. Configure msmtp for email:"
echo "   nano ~/.msmtprc"
echo ""
echo "   Add the following (replace with your details):"
echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   defaults"
echo "   auth           on"
echo "   tls            on"
echo "   tls_trust_file /data/data/com.termux/files/usr/etc/tls/cert.pem"
echo "   logfile        ~/.msmtp.log"
echo ""
echo "   account        gmail"
echo "   host           smtp.gmail.com"
echo "   port           587"
echo "   from           your_email@gmail.com"
echo "   user           your_email@gmail.com"
echo "   password       your_16_char_app_password"
echo ""
echo "   account default : gmail"
echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "4. Set msmtp permissions:"
echo "   chmod 600 ~/.msmtprc"
echo ""
echo "5. Initialize vnstat:"
echo "   mkdir -p $PREFIX/var/lib/vnstat"
echo "   sudo vnstatd -d"
echo "   vnstat --add -i wlan0"
echo ""
echo "6. Install Termux:Boot app from F-Droid"
echo "   https://f-droid.org/packages/com.termux.boot/"
echo ""
echo "7. Disable battery optimization for Termux"
echo ""
echo "8. Start services:"
echo "   ~/scripts/manager.sh"
echo ""
echo "✅ Installation complete!"
echo ""
echo "📚 For more information, visit:"
echo "   https://github.com/workforakng/ssh_termux_auto"
echo ""
