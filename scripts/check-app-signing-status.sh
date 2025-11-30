#!/bin/bash

# Check App Signing by Google Play Status Script
# This script helps determine if App Signing by Google Play is enabled

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== App Signing by Google Play Status Check ===${NC}"
}

print_header

echo "The issue is that your AAB is being signed with a different keystore than what"
echo "Google Play Console expects. This means App Signing by Google Play might not be enabled."
echo ""

print_status "To resolve this issue, please follow these steps:"
echo ""

echo "1. Go to Google Play Console:"
echo "   https://play.google.com/console"
echo ""

echo "2. Navigate to your app → Setup → App signing"
echo ""

echo "3. Check if 'App Signing by Google Play' is enabled:"
echo "   - If ENABLED: You can use any keystore as upload key"
echo "   - If NOT ENABLED: You need the original keystore or contact Google Support"
echo ""

print_warning "If App Signing by Google Play is NOT enabled:"
echo ""
echo "Option A: Enable App Signing by Google Play"
echo "1. In Google Play Console → Setup → App signing"
echo "2. Click 'Enable App Signing by Google Play'"
echo "3. Upload your upload key (the keystore you use to sign AAB)"
echo "4. Let Google handle the final signing"
echo ""

echo "Option B: Contact Google Play Support"
echo "1. Go to: https://support.google.com/googleplay/android-developer"
echo "2. Select 'App signing & keys' category"
echo "3. Request a key reset for your app"
echo "4. Provide proof of ownership"
echo ""

print_status "Current keystore fingerprint: D9:A1:1F:8E:1B:3E:63:01:FD:69:8B:8A:9A:C8:47:CE:36:A2:1F:EC"
print_status "Expected keystore fingerprint: 36:2E:91:FC:73:02:34:31:BC:E9:15:35:5B:14:34:9B:B0:65:1F:FB"
echo ""

print_warning "IMPORTANT:"
echo "- Do NOT create a new app unless absolutely necessary"
echo "- Contact Google Play Support if you can't resolve this"
echo "- Keep your keystore files secure once you find them"
echo ""

print_status "After resolving the keystore issue, you can build AAB with:"
echo "flutter build appbundle --release" 