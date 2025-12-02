#!/bin/bash

# Check Root Keystore Script
# Systematically check the mooves-release-key.jks file

set -e

KEYSTORE_PATH="/home/klas/Kod/mooves-project/mooves-release-key.jks"
EXPECTED_SHA1="36:2E:91:FC:73:02:34:31:BC:E9:15:35:5B:14:34:9B:B0:65:1F:FB"

echo "Checking keystore: $KEYSTORE_PATH"
echo "Expected SHA1: $EXPECTED_SHA1"
echo "=================================="

# Extended password list
PASSWORDS=(
    "mooves123" "Feuille3000" "password" "123456" "android" "keypass" "storepass" "mooves"
    "playstore" "release" "upload" "signing" "keystore" "app" "key" "secret"
    "mooves2023" "mooves2024" "mooves2025" "dating" "match" "love" "heart"
    "google" "play" "store" "console" "developer" "publish" "release"
    "admin" "root" "user" "test" "demo" "sample" "example"
    "private" "secret" "uploadkey" "signingkey" "releasekey"
    "klas" "linux" "ubuntu" "debian" "fedora" "arch"
    "development" "production" "staging" "beta" "alpha"
    "mobile" "app" "android" "ios" "flutter" "dart"
    "moovesapp" "moovesapp123" "moovesapp2023" "moovesapp2024"
    "releasekey" "releasekey123" "releasekey2023" "releasekey2024"
    "uploadkey" "uploadkey123" "uploadkey2023" "uploadkey2024"
    "signingkey" "signingkey123" "signingkey2023" "signingkey2024" "mooves2025!"
)

FOUND_PASSWORD=""
FOUND_SHA1=""

for password in "${PASSWORDS[@]}"; do
    echo "Trying password: $password"
    
    # Try to get SHA1 fingerprint
    sha1=$(keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$password" 2>/dev/null | grep "SHA1:" | awk '{print $2}')
    
    if [ ! -z "$sha1" ]; then
        echo "  ✅ Found valid password: $password"
        echo "  SHA1: $sha1"
        FOUND_PASSWORD="$password"
        FOUND_SHA1="$sha1"
        
        if [ "$sha1" = "$EXPECTED_SHA1" ]; then
            echo ""
            echo "🎉 FOUND THE ORIGINAL KEYSTORE!"
            echo "   Password: $password"
            echo "   SHA1: $sha1"
            echo ""
            echo "Next steps:"
            echo "1. Copy this keystore to: android/app/play-store-keystore.jks"
            echo "2. Update android/key.properties with password: $password"
            echo "3. Build AAB with: flutter build appbundle --release"
            exit 0
        fi
        break
    fi
done

if [ ! -z "$FOUND_PASSWORD" ]; then
    echo ""
    echo "Found keystore with password: $FOUND_PASSWORD"
    echo "SHA1: $FOUND_SHA1"
    echo ""
    echo "This is NOT the original keystore (SHA1 doesn't match)"
    echo "Expected: $EXPECTED_SHA1"
    echo "Found:    $FOUND_SHA1"
else
    echo ""
    echo "Could not find valid password for this keystore"
    echo "The original keystore is still missing"
fi 