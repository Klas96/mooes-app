#!/bin/bash

# Wrapper script for iOS IPA upload to Google Drive
# This script now uses the unified build-and-deploy.sh script

echo "🔄 Redirecting to unified build script..."
echo "📋 Parameters: --platform ios --target ipa --upload gdrive"

# Call the unified script with Google Drive iOS parameters
"$(dirname "$0")/build-and-deploy.sh" --platform ios --target ipa --upload gdrive "$@" 