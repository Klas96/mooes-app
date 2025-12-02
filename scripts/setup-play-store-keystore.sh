#!/bin/bash

# Setup Play Store Keystore Script
# This script helps set up the correct keystore for Play Store signing

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
    echo -e "${BLUE}=== Setup Play Store Keystore ===${NC}"
}

print_header

# Navigate to the Flutter app directory
cd "$(dirname "$0")/.."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found! Please run this script from the Flutter project root."
    exit 1
fi

print_status "This script will help you set up the correct keystore for Play Store signing."
echo ""

# Check if keystore file exists
if [ -f "android/play-store-keystore.jks" ]; then
    print_warning "Keystore file already exists: android/play-store-keystore.jks"
    echo "Do you want to replace it? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Keeping existing keystore."
        exit 0
    fi
fi

print_status "Please provide the following information:"
echo ""

# Get keystore file path
echo "Enter the path to your keystore file:"
read -r keystore_path

if [ ! -f "$keystore_path" ]; then
    print_error "Keystore file not found: $keystore_path"
    exit 1
fi

# Get keystore alias
echo "Enter the keystore alias:"
read -r keystore_alias

# Get keystore password
echo "Enter the keystore password:"
read -s keystore_password
echo ""

# Get key password (usually same as keystore password)
echo "Enter the key password (press Enter if same as keystore password):"
read -s key_password
echo ""

if [ -z "$key_password" ]; then
    key_password="$keystore_password"
fi

# Verify the keystore
print_status "Verifying keystore..."
keytool -list -v -keystore "$keystore_path" -alias "$keystore_alias" -storepass "$keystore_password" -keypass "$key_password" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    print_error "Failed to verify keystore. Please check your credentials."
    exit 1
fi

# Get SHA1 fingerprint
sha1_fingerprint=$(keytool -list -v -keystore "$keystore_path" -alias "$keystore_alias" -storepass "$keystore_password" -keypass "$key_password" | grep "SHA1:" | awk '{print $2}')

print_success "Keystore verified successfully!"
print_status "SHA1 fingerprint: $sha1_fingerprint"

# Copy keystore to android directory
print_status "Copying keystore to android directory..."
cp "$keystore_path" "android/play-store-keystore.jks"

# Update key.properties
print_status "Updating key.properties file..."
cat > "android/key.properties" << EOF
storePassword=$keystore_password
keyPassword=$key_password
keyAlias=$keystore_alias
storeFile=play-store-keystore.jks
EOF

print_success "Keystore setup completed!"
echo ""
print_status "Next steps:"
echo "1. Build AAB: flutter build appbundle --release"
echo "2. Upload AAB to Google Play Console"
echo "3. Test on internal testing track"
echo ""
print_warning "IMPORTANT: Keep your keystore file and passwords secure!" 