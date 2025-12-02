#!/bin/bash

# Deep Keystore Search Script
# Comprehensive search for the private moovesing the upload certificate

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
    echo -e "${BLUE}=== Deep Keystore Search for Private Key ===${NC}"
}

print_header

echo "Searching for the private key that matches SHA1: $EXPECTED_SHA1"
echo "=================================================="

# Extended list of passwords to try
PASSWORDS=(
    "mooves123" "Feuille3000" "password" "123456" "android" "keypass" "storepass" "mooves"
    "playstore" "release" "upload" "signing" "keystore" "app" "key" "secret"
    "mooves2023" "mooves2024" "mooves2025" "dating" "match" "love" "heart"
    "google" "play" "store" "console" "developer" "publish" "release"
    "admin" "root" "user" "test" "demo" "sample" "example"
    "private" "secret" "uploadkey" "signingkey" "releasekey"
)

# Search in specific project directories first
PROJECT_PATHS=(
    "/home/klas/Kod/mooves-project"
    "/home/klas/Kod/mooves-project/mooves"
    "/home/klas/Kod/mooves-project/mooves/dating_app"
    "/home/klas/Kod/mooves-project/mooves/nodejs-backend"
    "/home/klas/Kod/mooves-project/mooves-fdroid"
)

FOUND_KEYSTORE=""
TOTAL_CHECKED=0
TOTAL_FOUND=0

for search_path in "${PROJECT_PATHS[@]}"; do
    if [ -d "$search_path" ]; then
        print_status "Searching in: $search_path"
        
        # Find all keystore files
        keystore_files=$(find "$search_path" -name "*.jks" -o -name "*.keystore" -o -name "*.p12" -o -name "*.pfx" 2>/dev/null)
        
        if [ -z "$keystore_files" ]; then
            echo "  No keystore files found"
            continue
        fi
        
        while IFS= read -r keystore; do
            TOTAL_CHECKED=$((TOTAL_CHECKED + 1))
            echo "  Checking [$TOTAL_CHECKED]: $keystore"
            
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
                        TOTAL_FOUND=$((TOTAL_FOUND + 1))
                        
                        if [ "$sha1" = "$EXPECTED_SHA1" ]; then
                            echo ""
                            print_success "✅ FOUND MATCHING KEYSTORE!"
                            echo "    Keystore: $keystore"
                            echo "    Alias: $alias"
                            echo "    Password: $password"
                            echo "    SHA1: $sha1"
                            echo ""
                            
                            # Save the found keystore info
                            echo "$keystore|$alias|$password" > /tmp/found_keystore.txt
                            break 2
                        fi
                        break
                    fi
                done
            done
        done <<< "$keystore_files"
    fi
done

# Also search for private key files
print_status "Searching for private key files..."
PRIVATE_KEY_FILES=$(find /home/klas -name "*.key" -o -name "private*.pem" -o -name "*private*" 2>/dev/null | grep -v node_modules | head -20)

if [ ! -z "$PRIVATE_KEY_FILES" ]; then
    echo "Found potential private key files:"
    echo "$PRIVATE_KEY_FILES"
    echo ""
    print_status "You may need to manually check these files for the matching private key."
fi

echo ""
print_status "Search Summary:"
echo "  Total keystores checked: $TOTAL_CHECKED"
echo "  Total keystores with valid passwords: $TOTAL_FOUND"
echo ""

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
    print_warning "Original keystore not found after deep search!"
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
    echo "   - Previous computers/devices"
    echo ""
    print_error "IMPORTANT: Do not create a new app unless absolutely necessary!"
fi 