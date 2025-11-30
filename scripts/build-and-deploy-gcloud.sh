#!/bin/bash

# Wrapper script for Google Cloud Storage deployment
# This script now uses the unified build-and-deploy.sh script

echo "🔄 Redirecting to unified build script..."
echo "📋 Parameters: --platform android --target all --upload gcs"

# Call the unified script with Google Cloud Storage parameters
"$(dirname "$0")/build-and-deploy.sh" --platform android --target all --upload gcs "$@" 