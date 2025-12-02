#!/bin/bash

# Find Original Keystore Script
# This script searches for the original keystore with the correct SHA1 fingerprint

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

EXPECTED_SHA1="36:2E:91:FC:73:02:34:31:BC:E9:15:35:5B:14:34:9B:B0:65:1F:FB"

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
    echo -e "${BLUE}=== Find Original Keystore ===${NC}"
}

print_header

echo "Looking for keystore with SHA1 fingerprint: $EXPECTED_SHA1"
echo "=================================================="

# Common passwords to try
PASSWORDS=("mooves123" "Feuille3000" "password" "123456" "android" "keypass" "storepass" "mooves" "playstore" "release")

# Search in common locations
SEARCH_PATHS=(
    "/home/klas"
    "/home/klas/Downloads"
    "/home/klas/Documents"
    "/home/klas/Desktop"
    "/home/klas/.android"
    "/home/klas/.keystore"
)

FOUND_KEYSTORE=""

for search_path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$search_path" ]; then
        print_status "Searching in: $search_path"
        
        # Find all keystore files
        find "$search_path" -name "*.jks" -o -name "*.keystore" 2>/dev/null | while read keystore; do
            echo "  Checking: $keystore"
            
            # Try to list aliases without password first
            aliases=$(keytool -list -keystore "$keystore" 2>/dev/null | grep "Alias name:" | awk '{print $3}')
            
            if [ -z "$aliases" ]; then
                echo "    Could not read keystore (password protected or invalid)"
                continue
            fi
            
            for alias in $aliases; do
                echo "    Checking alias: $alias"
                
                # Try common passwords
                for password in "${PASSWORDS[@]}"; do
                    sha1=$(keytool -list -v -keystore "$keystore" -alias "$alias" -storepass "$password" 2>/dev/null | grep "SHA1:" | awk '{print $2}')
                    
                    if [ ! -z "$sha1" ]; then
                        echo "      Password: $password - SHA1: $sha1"
                        
                        if [ "$sha1" = "$EXPECTED_SHA1" ]; then
                            echo ""
                            print_success "✅ FOUND MATCHING KEYSTORE!"
                            echo "    Keystore: $keystore"
                            echo "    Alias: $alias"
                            echo "    Password: $password"
                            echo ""
                            
                            # Save the found keystore info
                            echo "$keystore|$alias|$password" > /tmp/found_keystore.txt
                            break 2
                        fi
                        break
                    fi
                done
            done
        done
    fi
done

# Check if we found the keystore
if [ -f /tmp/found_keystore.txt ]; then
    FOUND_KEYSTORE=$(cat /tmp/found_keystore.txt)
    rm /tmp/found_keystore.txt
    
    print_success "Original keystore found!"
    print_status "Next steps:"
    echo "1. Copy the keystore to: android/play-store-keystore.jks"
    echo "2. Update android/key.properties with the correct details"
    echo "3. Build the AAB with: flutter build appbundle --release"
    
else
    print_warning "Original keystore not found!"
    echo ""
    print_status "You have the following options:"
    echo ""
    echo "1. Contact Google Play Support:"
    echo "   - Go to: https://support.google.com/googleplay/android-developer"
    echo "   - Select 'App signing & keys' category"
    echo "   - Request a key reset for your app"
    echo ""
    echo "2. Check these locations manually:"
    echo "   - Google Drive"
    echo "   - Dropbox"
    echo "   - OneDrive"
    echo "   - Email attachments"
    echo "   - USB drives"
    echo "   - Local backups"
    echo ""
    echo "3. Enable App Signing by Google Play:"
    echo "   - Go to Google Play Console"
    echo "   - Navigate to Setup > App signing"
    echo "   - Enable App Signing by Google Play"
    echo ""
    print_error "IMPORTANT: Do not create a new app unless absolutely necessary!"
fi 