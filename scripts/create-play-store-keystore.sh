#!/bin/bash

# Create Play Store Keystore Script
# This script creates a new keystore for Google Play Store signing

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
    echo -e "${BLUE}=== Play Store Keystore Creation ===${NC}"
}

print_header

# Navigate to the Flutter app directory
cd "$(dirname "$0")/.."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found! Please run this script from the Flutter project root."
    exit 1
fi

# Keystore configuration
KEYSTORE_FILE="android/play-store-keystore.jks"
KEY_ALIAS="play-store-key"
STORE_PASSWORD="mooves123"
KEY_PASSWORD="mooves123"

print_status "Creating Play Store keystore..."

# Create the keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Mooves, OU=Development, O=Mooves, L=City, ST=State, C=US"

if [ $? -eq 0 ]; then
    print_success "Keystore created successfully!"
    
    # Display the fingerprint
    print_status "Keystore fingerprint:"
    keytool -list -v -keystore "$KEYSTORE_FILE" -alias "$KEY_ALIAS" -storepass "$STORE_PASSWORD" -keypass "$KEY_PASSWORD"
    
    # Create key.properties file
    print_status "Creating key.properties file..."
    cat > "android/key.properties" << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=play-store-keystore.jks
EOF
    
    print_success "key.properties file created!"
    print_warning "IMPORTANT: Please save this keystore file and password securely!"
    print_warning "You will need this keystore to sign future updates for the Play Store."
    
else
    print_error "Failed to create keystore!"
    exit 1
fi

print_success "Play Store keystore setup completed!" 