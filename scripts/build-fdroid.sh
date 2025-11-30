#!/bin/bash

# F-Droid Build Script for Mooves
# This script builds the app specifically for F-Droid distribution

set -e

echo "🔧 Building Mooves for F-Droid..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Mooves"
VERSION="1.0.3"
BUILD_NUMBER="107"
OUTPUT_DIR="build/fdroid"
APK_NAME="fdroid-v${VERSION}-${BUILD_NUMBER}.apk"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}📱 Building $APP_NAME v$VERSION for F-Droid...${NC}"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean

# Recreate output directory after cleaning
mkdir -p "$OUTPUT_DIR"

# Get dependencies
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

# Build for Android (release mode)
echo -e "${YELLOW}🔨 Building Android APK...${NC}"
flutter build apk --release --target-platform android-arm64

# Copy APK to output directory
echo -e "${YELLOW}📋 Copying APK to output directory...${NC}"
cp "build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/$APK_NAME"

# Verify APK was created
if [ -f "$OUTPUT_DIR/$APK_NAME" ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo -e "${GREEN}📱 APK created: $OUTPUT_DIR/$APK_NAME${NC}"
    
    # Get APK size
    APK_SIZE=$(du -h "$OUTPUT_DIR/$APK_NAME" | cut -f1)
    echo -e "${BLUE}📊 APK size: $APK_SIZE${NC}"
    
    # Show APK info
    echo -e "${BLUE}📋 APK Information:${NC}"
    echo "  - Name: $APK_NAME"
    echo "  - Version: $VERSION"
    echo "  - Build: $BUILD_NUMBER"
    echo "  - Platform: Android (ARM64)"
    echo "  - Distribution: F-Droid"
    echo "  - Payment: Stripe, Bitcoin"
    
    echo -e "${GREEN}🎉 F-Droid build completed successfully!${NC}"
    echo -e "${YELLOW}💡 Next steps:${NC}"
    echo "  1. Submit to F-Droid repository"
    echo "  2. Update fdroid-metadata.yml if needed"
    echo "  3. Test the APK on F-Droid devices"
    
else
    echo -e "${RED}❌ Build failed! APK not found.${NC}"
    exit 1
fi

echo -e "${BLUE}📁 Output directory: $OUTPUT_DIR${NC}"
ls -la "$OUTPUT_DIR" 