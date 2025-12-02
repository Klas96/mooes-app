#!/bin/bash

# Script to verify if a keystore has the correct fingerprint for Google Play Console
EXPECTED_SHA1="36:2E:91:FC:73:02:34:31:BC:E9:15:35:5B:14:34:9B:B0:65:1F:FB"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <keystore_file> [alias] [password]"
    echo ""
    echo "This script verifies if a keystore has the correct SHA1 fingerprint for Google Play Console."
    echo "Expected SHA1: $EXPECTED_SHA1"
    echo ""
    echo "Examples:"
    echo "  $0 correct-keystore.jks"
    echo "  $0 correct-keystore.jks my-alias my-password"
    exit 1
fi

KEYSTORE_FILE="$1"
ALIAS="${2:-mooves}"
PASSWORD="${3:-mooves123}"

if [ ! -f "$KEYSTORE_FILE" ]; then
    echo "Error: Keystore file '$KEYSTORE_FILE' not found!"
    exit 1
fi

echo "Verifying keystore: $KEYSTORE_FILE"
echo "Alias: $ALIAS"
echo "Expected SHA1: $EXPECTED_SHA1"
echo "=================================================="

# Try to get the SHA1 fingerprint
SHA1=$(keytool -list -v -keystore "$KEYSTORE_FILE" -alias "$ALIAS" -storepass "$PASSWORD" 2>/dev/null | grep "SHA1:" | awk '{print $2}')

if [ -z "$SHA1" ]; then
    echo "❌ Could not read keystore with provided credentials"
    echo "   Try different alias or password"
    echo ""
    echo "Available aliases:"
    keytool -list -keystore "$KEYSTORE_FILE" 2>/dev/null | grep "Alias name:" | awk '{print $3}' || echo "   Could not list aliases"
    exit 1
fi

echo "Found SHA1: $SHA1"
echo ""

if [ "$SHA1" = "$EXPECTED_SHA1" ]; then
    echo "✅ SUCCESS! This keystore has the correct fingerprint!"
    echo ""
    echo "To use this keystore:"
    echo "1. Copy it to: android/correct-keystore.jks"
    echo "2. Update key.properties:"
    echo "   storeFile=correct-keystore.jks"
    echo "   keyAlias=$ALIAS"
    echo "   storePassword=$PASSWORD"
    echo "   keyPassword=$PASSWORD"
    echo ""
    echo "3. Build your AAB:"
    echo "   flutter build appbundle"
else
    echo "❌ WRONG FINGERPRINT!"
    echo "   Expected: $EXPECTED_SHA1"
    echo "   Found:    $SHA1"
    echo ""
    echo "This keystore cannot be used for Google Play Console uploads."
    echo "You need to find the keystore with the correct fingerprint."
fi 