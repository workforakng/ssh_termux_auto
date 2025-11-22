#!/data/data/com.termux/files/usr/bin/bash

# Configuration Template
# Copy this to config.sh and fill in your details

# Email Configuration
SENDER="your_email@gmail.com"
RECIPIENT1="recipient1@gmail.com"
RECIPIENT2="recipient2@gmail.com"

# Gmail App Password (16 characters)
# Generate at: https://myaccount.google.com/apppasswords
GMAIL_APP_PASSWORD="your_16_char_app_password"

# SSH Configuration
SSH_USER="YOUR_SSH_USER"  # Change to your user
SSH_PORT="9696"     # Change if needed

# Monitoring Thresholds
TEMP_THRESHOLD=45        # Alert if temperature exceeds this (°C)
BATTERY_THRESHOLD=15     # Alert if battery below this (%)
CPU_THRESHOLD=98         # Alert if CPU usage above this (%)
RAM_THRESHOLD=98         # Alert if RAM usage above this (%)
