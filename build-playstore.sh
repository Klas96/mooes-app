#!/bin/bash

# Build script for Google Play Store release
# Version: 134.10.2 (Build 219)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Mooves Play Store Build v219      ║${NC}"
echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Not in Flutter project root${NC}"
    echo "Please run this script from the mooves-frontend directory"
    exit 1
fi

# Get current version
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
echo -e "${GREEN}📦 Building version: $VERSION${NC}"
echo ""

# Step 1: Clean previous builds
echo -e "${YELLOW}🧹 Step 1/6: Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Step 2: Get dependencies
echo -e "${YELLOW}📥 Step 2/6: Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies fetched${NC}"
echo ""

# Step 3: Analyze code
echo -e "${YELLOW}🔍 Step 3/6: Analyzing code...${NC}"
flutter analyze
if [ $? -ne 0 ]; then
    echo -e "${RED}⚠️  Warning: Analysis found issues. Continue? (y/n)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo -e "${GREEN}✅ Analysis complete${NC}"
echo ""

# Step 4: Check keystore
echo -e "${YELLOW}🔑 Step 4/6: Checking keystore...${NC}"
if [ ! -f "android/app/upload-keystore.jks" ] && [ ! -f "android/new-upload-keystore.jks" ]; then
    echo -e "${RED}❌ Error: Keystore file not found${NC}"
    echo "Expected: android/app/upload-keystore.jks or android/new-upload-keystore.jks"
    exit 1
fi
echo -e "${GREEN}✅ Keystore found${NC}"
echo ""

# Step 5: Build App Bundle (AAB)
echo -e "${YELLOW}🏗️  Step 5/6: Building App Bundle (AAB)...${NC}"
echo -e "${BLUE}This may take several minutes...${NC}"
flutter build appbundle --release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ App Bundle built successfully!${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi
echo ""

# Step 6: Build APK (for testing)
echo -e "${YELLOW}🏗️  Step 6/6: Building APK (for testing)...${NC}"
flutter build apk --release --split-per-abi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ APK built successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  APK build failed, but AAB succeeded${NC}"
fi
echo ""

# Show build artifacts
echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Build Complete! 🎉            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📦 Build Artifacts:${NC}"
echo ""

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo -e "${GREEN}✅ App Bundle (AAB):${NC}"
    echo "   📁 Path: $AAB_PATH"
    echo "   📊 Size: $AAB_SIZE"
    echo "   🎯 Use this for Play Store upload"
    echo ""
fi

echo -e "${GREEN}✅ APKs (for testing):${NC}"
for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
    if [ -f "$apk" ]; then
        APK_SIZE=$(du -h "$apk" | cut -f1)
        APK_NAME=$(basename "$apk")
        echo "   📱 $APK_NAME ($APK_SIZE)"
    fi
done
echo ""

# Release notes
echo -e "${BLUE}📝 Release Notes:${NC}"
echo "   Version: $VERSION"
echo "   Release: Event-Focused Transformation"
echo "   Changes:"
echo "   - Event-only Explore tab"
echo "   - Daily event digest notifications"
echo "   - AI event recommendations"
echo "   - Automatic event cleanup"
echo ""

# Next steps
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo ""
echo "1. Test the APK on a device:"
echo "   ${BLUE}adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk${NC}"
echo ""
echo "2. Upload AAB to Play Console:"
echo "   ${BLUE}https://play.google.com/console${NC}"
echo "   File: $AAB_PATH"
echo ""
echo "3. Update release notes in Play Console:"
echo "   See: RELEASE_v219.md for content"
echo ""
echo "4. Submit for review"
echo ""

# Optional: Copy to easy location
echo -e "${YELLOW}💾 Save artifacts? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    RELEASE_DIR="releases/v219"
    mkdir -p "$RELEASE_DIR"
    cp "$AAB_PATH" "$RELEASE_DIR/mooves-v219.aab"
    cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$RELEASE_DIR/mooves-v219-arm64.apk" 2>/dev/null || true
    cp RELEASE_v219.md "$RELEASE_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✅ Artifacts saved to $RELEASE_DIR/${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Build process complete!${NC}"
echo -e "${BLUE}Ready for Play Store upload 🚀${NC}"

