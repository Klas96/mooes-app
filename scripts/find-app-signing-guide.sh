#!/bin/bash

# Find App Signing Setup Guide
# This script provides detailed instructions to find App Signing in Google Play Console

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
    echo -e "${BLUE}=== How to Find App Signing in Google Play Console ===${NC}"
}

print_header

echo "The App Signing section can be found in different locations depending on your"
echo "Google Play Console version. Here are the most common paths:"
echo ""

print_status "Method 1: Direct Navigation"
echo "1. Go to Google Play Console: https://play.google.com/console"
echo "2. Select your app"
echo "3. Look for 'Setup' or 'Settings' in the left sidebar"
echo "4. Click on 'App signing' or 'Signing'"
echo ""

print_status "Method 2: Through Release Management"
echo "1. Go to Google Play Console: https://play.google.com/console"
echo "2. Select your app"
echo "3. Go to 'Release' → 'Production' or 'Internal testing'"
echo "4. Look for 'App signing' or 'Signing' in the release section"
echo ""

print_status "Method 3: Through App Settings"
echo "1. Go to Google Play Console: https://play.google.com/console"
echo "2. Select your app"
echo "3. Go to 'Store presence' → 'App content'"
echo "4. Look for 'App signing' or 'Signing' options"
echo ""

print_status "Method 4: Search Function"
echo "1. Go to Google Play Console: https://play.google.com/console"
echo "2. Use the search bar at the top"
echo "3. Search for 'app signing' or 'signing'"
echo "4. Click on the relevant result"
echo ""

print_status "Method 5: Alternative Paths"
echo "Try these navigation paths:"
echo "- App → Setup → App signing"
echo "- App → Settings → App signing"
echo "- App → Release → App signing"
echo "- App → Store presence → App signing"
echo "- App → Configuration → App signing"
echo ""

print_warning "If you still can't find App Signing:"
echo ""
echo "1. Check if you have the correct permissions:"
echo "   - You need 'Admin' or 'Owner' access to the app"
echo "   - Contact your Play Console admin if you don't have access"
echo ""
echo "2. Try different browsers or clear cache:"
echo "   - Use Chrome, Firefox, or Safari"
echo "   - Clear browser cache and cookies"
echo "   - Try incognito/private mode"
echo ""
echo "3. Contact Google Play Support:"
echo "   - Go to: https://support.google.com/googleplay/android-developer"
echo "   - Select 'App signing & keys' category"
echo "   - Ask for help finding the App Signing section"
echo ""

print_status "What to look for once you find App Signing:"
echo ""
echo "You should see one of these options:"
echo "- 'App Signing by Google Play' (with Enable/Disable toggle)"
echo "- 'Upload key certificate' (shows your current upload key)"
echo "- 'App signing certificate' (shows Google's signing certificate)"
echo "- 'Key management' or 'Certificate management'"
echo ""

print_warning "IMPORTANT:"
echo "- If App Signing by Google Play is enabled, you can use any keystore"
echo "- If it's NOT enabled, you need the original keystore or contact Google"
echo "- Don't disable App Signing by Google Play if it's already enabled"
echo "" 