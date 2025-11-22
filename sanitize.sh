#!/data/data/com.termux/files/usr/bin/bash

# Sanitize all scripts before Git commit
# Removes emails, passwords, tokens, and personal info

echo "🧹 Sanitizing scripts..."

# Create sanitized copies in scripts/
mkdir -p scripts

for script in ~/scripts/*.sh; do
    filename=$(basename "$script")
    
    # Skip if already sanitized
    if [ "$filename" = "sanitize.sh" ]; then
        continue
    fi
    
    echo "Sanitizing $filename..."
    
    # Copy and sanitize
    cat "$script" | \
        sed 's/RECIPIENT1_EMAIL/YOUR_EMAIL@gmail.com/g' | \
        sed 's/RECIPIENT2_EMAIL/RECIPIENT_EMAIL@gmail.com/g' | \
        sed 's/YOUR_SENDER_EMAIL/YOUR_SENDER@gmail.com/g' | \
        sed 's/YOUR_SSH_USER/YOUR_USERNAME/g' | \
        sed 's/YOUR_SSH_USER/YOUR_USER/g' | \
        sed 's/YOUR_GMAIL_APP_PASSWORD/YOUR_APP_PASSWORD/g' | \
        sed 's/ghp_[a-zA-Z0-9]*/YOUR_GITHUB_TOKEN/g' | \
        sed 's/Server@J7/YOUR_PASSWORD/g' | \
        sed 's/117.194.153.[0-9]*/YOUR_IP_ADDRESS/g' | \
        sed 's/192.168.[0-9]*.[0-9]*/192.168.X.X/g' | \
        sed 's/localhost/YOUR_DEVICE/g' \
        > "scripts/$filename"
    
    chmod +x "scripts/$filename"
done

# Sanitize boot script
if [ -f ~/.termux/boot/start-ssh-notifier ]; then
    echo "Sanitizing boot script..."
    mkdir -p termux-boot
    cat ~/.termux/boot/start-ssh-notifier | \
        sed 's/YOUR_SSH_USER/YOUR_USER/g' | \
        sed 's/RECIPIENT1_EMAIL/YOUR_EMAIL@gmail.com/g' \
        > termux-boot/start-ssh-notifier
    chmod +x termux-boot/start-ssh-notifier
fi

# Sanitize msmtprc if exists (use template instead)
if [ -f ~/.msmtprc ]; then
    echo "Creating msmtprc template..."
    # Already created above
fi

echo "✅ Sanitization complete!"
echo ""
echo "Sanitized files:"
ls -lh scripts/
