#!/bin/bash

# Create New Play Store Keystore Script
# This script creates a new keystore for Play Store signing

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
    echo -e "${BLUE}=== Create New Play Store Keystore ===${NC}"
}

print_header

# Navigate to the Flutter app directory
cd "$(dirname "$0")/.."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found! Please run this script from the Flutter project root."
    exit 1
fi

print_status "This script will create a new keystore for Play Store signing."
echo ""

# Check if App Signing by Google Play is enabled
print_status "Before creating a new keystore, please check:"
echo "1. Go to Google Play Console"
echo "2. Navigate to Setup → App signing"
echo "3. Check if 'App Signing by Google Play' is enabled"
echo ""
echo "If App Signing by Google Play is enabled, you can use any keystore."
echo "If it's NOT enabled, you'll need to contact Google Play Support."
echo ""

read -p "Is App Signing by Google Play enabled? (y/N): " app_signing_enabled

if [[ ! "$app_signing_enabled" =~ ^[Yy]$ ]]; then
    print_warning "App Signing by Google Play is NOT enabled!"
    echo ""
    print_status "You have two options:"
    echo ""
    echo "Option 1: Enable App Signing by Google Play"
    echo "1. Go to Google Play Console → Setup → App signing"
    echo "2. Enable 'App Signing by Google Play'"
    echo "3. Run this script again"
    echo ""
    echo "Option 2: Contact Google Play Support"
    echo "1. Go to: https://support.google.com/googleplay/android-developer"
    echo "2. Select 'App signing & keys' category"
    echo "3. Request a key reset for your app"
    echo ""
    print_error "Cannot proceed without App Signing by Google Play or key reset!"
    exit 1
fi

print_success "App Signing by Google Play is enabled!"
echo ""

# Generate random passwords
STORE_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
KEY_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
KEY_ALIAS="play-store-key"
KEYSTORE_FILE="android/play-store-keystore.jks"

print_status "Generating new keystore with secure passwords..."
echo "Store password: $STORE_PASSWORD"
echo "Key password: $KEY_PASSWORD"
echo "Key alias: $KEY_ALIAS"
echo ""

# Create the keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Mooves App, OU=Development, O=Mooves, L=City, ST=State, C=US"

if [ $? -eq 0 ]; then
    print_success "Keystore created successfully!"
    
    # Display the fingerprint
    print_status "Keystore fingerprint:"
    keytool -list -v -keystore "$KEYSTORE_FILE" -alias "$KEY_ALIAS" -storepass "$STORE_PASSWORD" -keypass "$KEY_PASSWORD" | grep "SHA1:"
    
    # Create key.properties file
    print_status "Creating key.properties file..."
    cat > "android/key.properties" << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=play-store-keystore.jks
EOF
    
    print_success "key.properties file created!"
    
    # Save credentials to a secure file
    CREDENTIALS_FILE="keystore-credentials.txt"
    cat > "$CREDENTIALS_FILE" << EOF
Play Store Keystore Credentials
===============================
Generated: $(date)
Keystore file: $KEYSTORE_FILE
Key alias: $KEY_ALIAS
Store password: $STORE_PASSWORD
Key password: $KEY_PASSWORD

IMPORTANT: Keep this file secure and backup your keystore!
EOF
    
    print_success "Credentials saved to: $CREDENTIALS_FILE"
    print_warning "IMPORTANT: Please save this keystore file and passwords securely!"
    print_warning "You will need this keystore to sign future updates for the Play Store."
    
    echo ""
    print_status "Next steps:"
    echo "1. Build AAB: flutter build appbundle --release"
    echo "2. Upload AAB to Google Play Console"
    echo "3. Test on internal testing track"
    echo ""
    print_warning "Keep the keystore file and credentials secure!"
    
else
    print_error "Failed to create keystore!"
    exit 1
fi 