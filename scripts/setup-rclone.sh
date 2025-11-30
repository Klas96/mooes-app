#!/bin/bash

# Setup script for rclone Google Drive configuration
set -e

echo "🔧 Setting up rclone for Google Drive access..."
echo "================================================"

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "❌ rclone is not installed!"
    echo ""
    echo "Please install rclone first:"
    echo "1. Visit: https://rclone.org/install/"
    echo "2. Or run: curl https://rclone.org/install.sh | sudo bash"
    echo ""
    exit 1
fi

echo "✅ rclone is installed: $(rclone version | head -1)"

# Check if gdrive remote already exists
if rclone listremotes | grep -q "gdrive:"; then
    echo "✅ Google Drive remote 'gdrive' is already configured!"
    echo ""
    echo "Current remotes:"
    rclone listremotes
    echo ""
    echo "To reconfigure, run: rclone config"
    exit 0
fi

echo "📝 Setting up Google Drive remote..."
echo ""
echo "Follow these steps:"
echo "1. Go to https://console.developers.google.com/"
echo "2. Create a new project or select existing"
echo "3. Enable Google Drive API"
echo "4. Create OAuth 2.0 credentials"
echo "5. Download the client configuration file"
echo ""
echo "Then run: rclone config"
echo ""
echo "When configuring rclone:"
echo "- Choose 'n' for new remote"
echo "- Name it 'gdrive'"
echo "- Choose 'Google Drive' (drive)"
echo "- Choose 'n' for auto config"
echo "- Enter your client ID and secret"
echo "- Choose '1' for full access"
echo "- Choose 'n' for advanced config"
echo "- Choose 'y' to confirm"
echo ""

read -p "Press Enter when you're ready to configure rclone..."

# Start rclone configuration
rclone config

echo ""
echo "✅ rclone configuration complete!"
echo ""
echo "Test the connection:"
echo "rclone lsd gdrive:"
echo ""
echo "You can now run: ./build-apk.sh" 