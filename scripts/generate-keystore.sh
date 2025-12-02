#!/bin/bash

# Android Keystore Generation Script
# This script generates a new keystore for Android app signing

set -e

echo "🔐 Generating new Android keystore..."

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool not found. Please install Java JDK."
    exit 1
fi

# Set keystore path
KEYSTORE_PATH="android/app/key.jks"

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  Warning: Keystore already exists at $KEYSTORE_PATH"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Keystore generation cancelled."
        exit 1
    fi
    rm -f "$KEYSTORE_PATH"
fi

# Create android/app directory if it doesn't exist
mkdir -p android/app

# Generate keystore
echo "📝 Generating keystore..."
keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -alias upload \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -storetype JKS

echo "✅ Keystore generated successfully at $KEYSTORE_PATH"
echo ""
echo "🔑 Next steps:"
echo "1. Run: ./scripts/setup-keystore-passwords.sh"
echo "2. Test build: flutter build apk --release"
echo ""
echo "⚠️  Important: Keep your keystore passwords secure!"
echo "   You'll need them for future app updates." 