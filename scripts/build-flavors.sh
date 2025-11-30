#!/bin/bash

# Build script for Mooves Android app with different flavors
# Supports dual distribution: Play Store and F-Droid

set -e

echo "🔧 Building Mooves Android app for dual distribution..."
echo "📱 Target: Android 15 (API level 35)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to build for a specific flavor
build_flavor() {
    local flavor=$1
    local build_type=$2
    local output_dir="builds/$flavor"
    
    echo -e "${BLUE}🏗️  Building for $flavor flavor...${NC}"
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Clean previous build
    echo "🧹 Cleaning previous build..."
    flutter clean
    
    # Get dependencies
    echo "📦 Getting dependencies..."
    flutter pub get
    
    # Build APK
    echo "🔨 Building $flavor $build_type APK..."
    flutter build apk \
        --$build_type \
        --flavor $flavor \
        --target-platform android-arm64 \
        --dart-define=FLAVOR=$flavor
    
    # Copy APK to output directory
    local apk_name="mooves-$flavor-$build_type.apk"
    cp "build/app/outputs/flutter-apk/app-$flavor-$build_type.apk" "$output_dir/$apk_name"
    
    echo -e "${GREEN}✅ $flavor $build_type build completed: $output_dir/$apk_name${NC}"
}

# Function to build both flavors
build_all_flavors() {
    echo -e "${YELLOW}🚀 Building all flavors...${NC}"
    
    # Build Play Store flavor
    build_flavor "playstore" "release"
    
    # Build F-Droid flavor
    build_flavor "fdroid" "release"
    
    echo -e "${GREEN}🎉 All builds completed successfully!${NC}"
    echo ""
    echo "📁 Build outputs:"
    echo "  - Play Store: builds/playstore/mooves-playstore-release.apk"
    echo "  - F-Droid: builds/fdroid/mooves-fdroid-release.apk"
}

# Function to build debug versions
build_debug_flavors() {
    echo -e "${YELLOW}🐛 Building debug versions...${NC}"
    
    # Build Play Store debug
    build_flavor "playstore" "debug"
    
    # Build F-Droid debug
    build_flavor "fdroid" "debug"
    
    echo -e "${GREEN}🎉 Debug builds completed successfully!${NC}"
}

# Function to install on connected device
install_flavor() {
    local flavor=$1
    local build_type=${2:-debug}
    
    echo -e "${BLUE}📱 Installing $flavor $build_type on device...${NC}"
    
    # Build and install
    flutter install \
        --flavor $flavor \
        --$build_type
    
    echo -e "${GREEN}✅ $flavor installed successfully!${NC}"
}

# Main script logic
case "${1:-all}" in
    "playstore")
        build_flavor "playstore" "${2:-release}"
        ;;
    "fdroid")
        build_flavor "fdroid" "${2:-release}"
        ;;
    "debug")
        build_debug_flavors
        ;;
    "install-playstore")
        install_flavor "playstore" "${2:-debug}"
        ;;
    "install-fdroid")
        install_flavor "fdroid" "${2:-debug}"
        ;;
    "all"|*)
        build_all_flavors
        ;;
esac

echo ""
echo -e "${BLUE}📋 Usage:${NC}"
echo "  ./scripts/build-flavors.sh all              # Build all flavors (release)"
echo "  ./scripts/build-flavors.sh debug            # Build debug versions"
echo "  ./scripts/build-flavors.sh playstore        # Build Play Store flavor"
echo "  ./scripts/build-flavors.sh fdroid           # Build F-Droid flavor"
echo "  ./scripts/build-flavors.sh install-playstore # Install Play Store on device"
echo "  ./scripts/build-flavors.sh install-fdroid   # Install F-Droid on device" 