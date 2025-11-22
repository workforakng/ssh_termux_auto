#!/data/data/com.termux/files/usr/bin/bash

# Git Push Script - Secure Upload
# Usage: ./gitpush.sh YOUR_GITHUB_TOKEN

REPO_NAME="ssh_termux_auto"
GITHUB_USERNAME="workforakng"
GITHUB_EMAIL="workforakng@gmail.com"

# Get token from argument or environment
if [ -n "$1" ]; then
    GITHUB_TOKEN="$1"
elif [ -n "$GITHUB_TOKEN" ]; then
    # Use environment variable
    GITHUB_TOKEN="$GITHUB_TOKEN"
else
    echo "❌ Error: No GitHub token provided"
    echo "Usage: ./gitpush.sh YOUR_GITHUB_TOKEN"
    echo "   or: export GITHUB_TOKEN=your_token && ./gitpush.sh"
    exit 1
fi

echo "╔═══════════════════════════════════════╗"
echo "║     GITHUB PUSH SCRIPT by AkNG       ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# Check if we're in the right directory
if [ ! -f "install.sh" ]; then
    echo "❌ Error: Run this from the ssh_termux_auto directory"
    exit 1
fi

# Remove any existing credentials from scripts
echo "🔒 Sanitizing scripts (removing credentials)..."

# Sanitize all .sh files
find . -name "*.sh" -type f | while read file; do
    if [ -f "$file" ] && [ "$file" != "./gitpush.sh" ]; then
        # Remove email addresses
        sed -i 's/sourodyutibiswassanyal2@gmail.com/YOUR_SENDER_EMAIL/g' "$file"
        sed -i 's/sourodyutibiswas2@gmail.com/YOUR_SENDER_EMAIL/g' "$file"
        sed -i 's/workforakng@gmail.com/RECIPIENT1_EMAIL/g' "$file"
        sed -i 's/sourodyuti.biswas.sanyal.14@gmail.com/RECIPIENT2_EMAIL/g' "$file"
        
        # Remove app password
        sed -i 's/czajqbmwfgfmjkxp/YOUR_GMAIL_APP_PASSWORD/g' "$file"
        
        # Remove SSH users
        sed -i 's/u0_a1961/YOUR_SSH_USER/g' "$file"
        sed -i 's/u0_a113/YOUR_SSH_USER/g' "$file"
    fi
done

echo "✓ Credentials sanitized"
echo ""

# Git operations
if [ ! -d ".git" ]; then
    echo "📦 Initializing Git repository..."
    git init
    git config user.name "$GITHUB_USERNAME"
    git config user.email "$GITHUB_EMAIL"
    git branch -M main
    echo "✓ Git initialized"
else
    echo "✓ Git already initialized"
fi

echo ""
echo "📝 Adding files..."
git add .

echo ""
echo "Files to be committed:"
git status --short

echo ""
read -p "Continue with commit? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
read -p "Commit message: " commit_msg
if [ -z "$commit_msg" ]; then
    commit_msg="Update from Termux"
fi

git commit -m "$commit_msg"

echo ""
echo "🔗 Setting up remote..."
git remote remove origin 2>/dev/null
git remote add origin https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${REPO_NAME}.git

echo ""
echo "🚀 Pushing to GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo ""
    echo "Repository: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
    echo ""
    
    # Clean up token from git config
    git remote set-url origin https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git
    
    echo "🔒 Token removed from git config"
else
    echo ""
    echo "❌ Push failed"
    exit 1
fi
