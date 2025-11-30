#!/bin/bash

# Wrapper script for APK upload to Google Drive
# This script now uses the unified build-and-deploy.sh script

echo "🔄 Redirecting to unified build script..."
echo "📋 Parameters: --platform android --target apk --upload gdrive"

# Call the unified script with Google Drive APK parameters
"$(dirname "$0")/build-and-deploy.sh" --platform android --target apk --upload gdrive "$@" 