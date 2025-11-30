#!/bin/bash

# Build Play Store AAB Script
# This script builds an AAB file specifically for Google Play Store

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
    echo -e "${PURPLE}=== Play Store AAB Builder ===${NC}"
}

print_header

# Navigate to the Flutter app directory
cd "$(dirname "$0")/.."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found! Please run this script from the Flutter project root."
    exit 1
fi

# Get version from pubspec.yaml
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

print_status "Version: $VERSION"
print_status "Timestamp: $TIMESTAMP"

# Check Flutter installation
print_status "Checking Flutter installation..."
flutter --version
flutter doctor

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Check keystore configuration
KEYSTORE_FILE="android/play-store-keystore.jks"
KEY_PROPERTIES_FILE="android/key.properties"

if [ ! -f "$KEYSTORE_FILE" ]; then
    print_warning "Play Store keystore not found!"
    print_status "Creating new keystore..."
    ./scripts/create-play-store-keystore.sh
fi

# Verify keystore fingerprint
print_status "Verifying keystore fingerprint..."
if [ -f "$KEYSTORE_FILE" ]; then
    keytool -list -v -keystore "$KEYSTORE_FILE" -alias play-store-key -storepass mooves123 -keypass mooves123 | grep "SHA1:"
else
    print_error "Keystore file not found!"
    exit 1
fi

# Build AAB
print_status "Building AAB for Play Store..."
flutter build appbundle --release

# Check if build was successful
if [ ! -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    print_error "AAB build failed!"
    exit 1
fi

# Create versioned AAB
AAB_NAME="mooves_v${VERSION}_${TIMESTAMP}.aab"
cp "build/app/outputs/bundle/release/app-release.aab" "build/app/outputs/bundle/release/$AAB_NAME"

# Get file size
AAB_SIZE=$(du -h "build/app/outputs/bundle/release/$AAB_NAME" | cut -f1)

print_success "AAB built successfully!"
print_success "File: $AAB_NAME"
print_success "Size: $AAB_SIZE"
print_success "Location: build/app/outputs/bundle/release/$AAB_NAME"

# Generate build summary
SUMMARY_FILE="play_store_build_${TIMESTAMP}.txt"
cat > "$SUMMARY_FILE" << EOF
Play Store AAB Build Summary
============================
Build Date: $(date)
Version: $VERSION
File: $AAB_NAME
Size: $AAB_SIZE
Location: build/app/outputs/bundle/release/$AAB_NAME

Next Steps:
1. Upload $AAB_NAME to Google Play Console
2. Test the AAB on internal testing track
3. Submit for review when ready

IMPORTANT: Make sure you're using the correct keystore that matches
the fingerprint expected by Google Play Console.
EOF

print_success "Build summary saved to: $SUMMARY_FILE"
print_success "🎉 Play Store AAB build completed successfully!"
print_warning "Remember to upload the AAB to Google Play Console!" 