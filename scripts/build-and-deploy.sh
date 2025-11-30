#!/bin/bash

# Unified Build and Deploy Script for Mooves
# Supports Android (APK/AAB) and iOS (IPA) builds
# Uploads to Google Cloud Storage and/or Google Drive
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
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
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

print_config() {
    echo -e "${CYAN}[CONFIG]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --platform PLATFORM    Build platform (android, ios, or both)"
    echo "  -t, --target TARGET        Build target (apk, aab, ipa, or all)"
    echo "  -u, --upload DESTINATION   Upload destination (gcs, gdrive, or both)"
    echo "  -c, --clean                Clean build before building"
    echo "  -v, --version VERSION      Override version from pubspec.yaml"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --platform android --target apk --upload gdrive"
    echo "  $0 --platform ios --target ipa --upload both"
    echo "  $0 --platform both --target all --upload both"
    echo "  $0 -p android -t aab -u gcs"
    echo ""
    echo "Defaults:"
    echo "  Platform: android"
    echo "  Target: apk"
    echo "  Upload: gdrive"
}

# Parse command line arguments
PLATFORM="android"
TARGET="apk"
UPLOAD="gdrive"
CLEAN_BUILD=false
OVERRIDE_VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -u|--upload)
            UPLOAD="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -v|--version)
            OVERRIDE_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ ! "$PLATFORM" =~ ^(android|ios|both)$ ]]; then
    print_error "Invalid platform: $PLATFORM. Use: android, ios, or both"
    exit 1
fi

if [[ ! "$TARGET" =~ ^(apk|aab|ipa|all)$ ]]; then
    print_error "Invalid target: $TARGET. Use: apk, aab, ipa, or all"
    exit 1
fi

if [[ ! "$UPLOAD" =~ ^(gcs|gdrive|both)$ ]]; then
    print_error "Invalid upload destination: $UPLOAD. Use: gcs, gdrive, or both"
    exit 1
fi

# Configuration
PROJECT_ID="fresh-oath-337920"
APP_NAME="mooves-dating-app"
REGION="us-central1"

print_header "🚀 Mooves Unified Build and Deploy Script"
print_config "Platform: $PLATFORM"
print_config "Target: $TARGET"
print_config "Upload: $UPLOAD"
print_config "Clean Build: $CLEAN_BUILD"

# Navigate to the Flutter app directory
cd "$(dirname "$0")/.."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found! Please run this script from the Flutter project root."
    exit 1
fi

# Get version from pubspec.yaml (unless overridden)
if [ -n "$OVERRIDE_VERSION" ]; then
    VERSION="$OVERRIDE_VERSION"
    print_config "Using override version: $VERSION"
else
    VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
    if [ -z "$VERSION" ]; then
        print_error "Could not extract version from pubspec.yaml"
        exit 1
    fi
    print_config "Version from pubspec.yaml: $VERSION"
fi

# Get current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
print_config "Timestamp: $TIMESTAMP"

# Check Flutter installation
if ! command_exists flutter; then
    print_error "Flutter is not installed or not in PATH!"
    print_error "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

print_status "🔍 Checking Flutter installation..."
flutter --version
print_status "🏥 Running Flutter doctor..."
flutter doctor

# Clean if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_status "🧹 Cleaning previous builds..."
    flutter clean
fi

# Get dependencies
print_status "📦 Getting dependencies..."
flutter pub get

# Function to build Android targets
build_android() {
    local target="$1"
    
    if [ "$target" = "apk" ] || [ "$target" = "all" ]; then
        print_status "🔨 Building Android APK..."
        flutter build apk --release
        
        if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
            print_error "APK build failed!"
            return 1
        fi
        
        APK_NAME="mooves_v${VERSION}_${TIMESTAMP}.apk"
        cp "build/app/outputs/flutter-apk/app-release.apk" "build/app/outputs/flutter-apk/$APK_NAME"
        APK_SIZE=$(du -h "build/app/outputs/flutter-apk/$APK_NAME" | cut -f1)
        print_success "APK built successfully: $APK_NAME ($APK_SIZE)"
    fi
    
    if [ "$target" = "aab" ] || [ "$target" = "all" ]; then
        print_status "🔨 Building Android AAB..."
        flutter build appbundle --release
        
        if [ ! -f "build/app/outputs/bundle/release/app-release.aab" ]; then
            print_error "AAB build failed!"
            return 1
        fi
        
        AAB_NAME="mooves_v${VERSION}_${TIMESTAMP}.aab"
        cp "build/app/outputs/bundle/release/app-release.aab" "build/app/outputs/bundle/release/$AAB_NAME"
        AAB_SIZE=$(du -h "build/app/outputs/bundle/release/$AAB_NAME" | cut -f1)
        print_success "AAB built successfully: $AAB_NAME ($AAB_SIZE)"
    fi
}

# Function to build iOS targets
build_ios() {
    local target="$1"
    
    if [ "$target" = "ipa" ] || [ "$target" = "all" ]; then
        print_status "🔨 Building iOS IPA..."
        
        # Check iOS toolchain
        if ! flutter doctor | grep -q "iOS toolchain - develop for iOS devices"; then
            print_error "iOS toolchain is not properly configured!"
            return 1
        fi
        
        if ! command_exists xcodebuild; then
            print_error "Xcode is not installed or not in PATH!"
            return 1
        fi
        
        flutter build ipa --release
        
        if ! ls build/ios/ipa/*.ipa 1> /dev/null 2>&1; then
            print_error "IPA build failed!"
            return 1
        fi
        
        IPA_NAME="mooves_v${VERSION}_${TIMESTAMP}.ipa"
        for IPA in build/ios/ipa/*.ipa; do
            cp "$IPA" "build/ios/ipa/$IPA_NAME"
            break
        done
        IPA_SIZE=$(du -h "build/ios/ipa/$IPA_NAME" | cut -f1)
        print_success "IPA built successfully: $IPA_NAME ($IPA_SIZE)"
    fi
}

# Function to upload to Google Cloud Storage
upload_to_gcs() {
    local platform="$1"
    
    print_status "☁️ Uploading to Google Cloud Storage..."
    
    # Create bucket if it doesn't exist
    local bucket_name="${PROJECT_ID}-app-releases"
    gsutil ls -b "gs://$bucket_name" > /dev/null 2>&1 || {
        print_status "📦 Creating Google Cloud Storage bucket..."
        gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION "gs://$bucket_name"
    }
    
    if [ "$platform" = "android" ]; then
        if [ -n "$APK_NAME" ]; then
            print_status "📤 Uploading APK to GCS..."
            gsutil cp "build/app/outputs/flutter-apk/$APK_NAME" "gs://$bucket_name/apks/"
            gsutil acl ch -u AllUsers:R "gs://$bucket_name/apks/$APK_NAME"
            APK_GCS_URL="https://storage.googleapis.com/$bucket_name/apks/$APK_NAME"
            print_success "APK uploaded: $APK_GCS_URL"
        fi
        
        if [ -n "$AAB_NAME" ]; then
            print_status "📤 Uploading AAB to GCS..."
            gsutil cp "build/app/outputs/bundle/release/$AAB_NAME" "gs://$bucket_name/aabs/"
            gsutil acl ch -u AllUsers:R "gs://$bucket_name/aabs/$AAB_NAME"
            AAB_GCS_URL="https://storage.googleapis.com/$bucket_name/aabs/$AAB_NAME"
            print_success "AAB uploaded: $AAB_GCS_URL"
        fi
    fi
    
    if [ "$platform" = "ios" ] && [ -n "$IPA_NAME" ]; then
        print_status "📤 Uploading IPA to GCS..."
        gsutil cp "build/ios/ipa/$IPA_NAME" "gs://$bucket_name/ipas/"
        gsutil acl ch -u AllUsers:R "gs://$bucket_name/ipas/$IPA_NAME"
        IPA_GCS_URL="https://storage.googleapis.com/$bucket_name/ipas/$IPA_NAME"
        print_success "IPA uploaded: $IPA_GCS_URL"
    fi
}

# Function to upload to Google Drive
upload_to_gdrive() {
    local platform="$1"
    
    print_status "☁️ Uploading to Google Drive..."
    
    # Check rclone
    if ! command_exists rclone; then
        print_error "rclone is not installed!"
        return 1
    fi
    
    if ! rclone listremotes | grep -q "gdrive:"; then
        print_error "Google Drive remote 'gdrive' is not configured!"
        return 1
    fi
    
    if [ "$platform" = "android" ]; then
        # Create directory structure
        rclone mkdir gdrive:Mooves/releases/android/ 2>/dev/null || true
        rclone mkdir gdrive:Mooves/releases/android/backups/ 2>/dev/null || true
        
        if [ -n "$APK_NAME" ]; then
            print_status "📤 Uploading APK to Google Drive..."
            rclone copy "build/app/outputs/flutter-apk/$APK_NAME" "gdrive:Mooves/releases/android/"
            rclone copy "build/app/outputs/flutter-apk/$APK_NAME" "gdrive:Mooves/releases/android/backups/"
            print_success "APK uploaded to Google Drive"
        fi
        
        if [ -n "$AAB_NAME" ]; then
            print_status "📤 Uploading AAB to Google Drive..."
            rclone copy "build/app/outputs/bundle/release/$AAB_NAME" "gdrive:Mooves/releases/android/"
            rclone copy "build/app/outputs/bundle/release/$AAB_NAME" "gdrive:Mooves/releases/android/backups/"
            print_success "AAB uploaded to Google Drive"
        fi
    fi
    
    if [ "$platform" = "ios" ] && [ -n "$IPA_NAME" ]; then
        # Create directory structure
        rclone mkdir gdrive:Mooves/releases/ios/ 2>/dev/null || true
        rclone mkdir gdrive:Mooves/releases/ios/backups/ 2>/dev/null || true
        
        print_status "📤 Uploading IPA to Google Drive..."
        rclone copy "build/ios/ipa/$IPA_NAME" "gdrive:Mooves/releases/ios/"
        rclone copy "build/ios/ipa/$IPA_NAME" "gdrive:Mooves/releases/ios/backups/"
        print_success "IPA uploaded to Google Drive"
    fi
}

# Main build process
print_header "🔨 Starting build process..."

if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "both" ]; then
    print_status "📱 Building Android targets..."
    build_android "$TARGET"
fi

if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "both" ]; then
    print_status "🍎 Building iOS targets..."
    build_ios "$TARGET"
fi

# Upload process
print_header "📤 Starting upload process..."

if [ "$UPLOAD" = "gcs" ] || [ "$UPLOAD" = "both" ]; then
    if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "both" ]; then
        upload_to_gcs "android"
    fi
    if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "both" ]; then
        upload_to_gcs "ios"
    fi
fi

if [ "$UPLOAD" = "gdrive" ] || [ "$UPLOAD" = "both" ]; then
    if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "both" ]; then
        upload_to_gdrive "android"
    fi
    if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "both" ]; then
        upload_to_gdrive "ios"
    fi
fi

# Generate summary
print_header "📊 Build Summary"
echo "Version: $VERSION"
echo "Timestamp: $TIMESTAMP"
echo "Platform: $PLATFORM"
echo "Target: $TARGET"
echo "Upload: $UPLOAD"

if [ -n "$APK_NAME" ]; then
    echo "APK: $APK_NAME ($APK_SIZE)"
fi
if [ -n "$AAB_NAME" ]; then
    echo "AAB: $AAB_NAME ($AAB_SIZE)"
fi
if [ -n "$IPA_NAME" ]; then
    echo "IPA: $IPA_NAME ($IPA_SIZE)"
fi

if [ "$UPLOAD" = "gcs" ] || [ "$UPLOAD" = "both" ]; then
    echo ""
    echo "Google Cloud Storage URLs:"
    if [ -n "$APK_GCS_URL" ]; then
        echo "APK: $APK_GCS_URL"
    fi
    if [ -n "$AAB_GCS_URL" ]; then
        echo "AAB: $AAB_GCS_URL"
    fi
    if [ -n "$IPA_GCS_URL" ]; then
        echo "IPA: $IPA_GCS_URL"
    fi
fi

# Save build info
SUMMARY_FILE="build_info_${TIMESTAMP}.txt"
cat > "$SUMMARY_FILE" << EOF
Mooves Build Summary
======================
Build Date: $(date)
Version: $VERSION
Platform: $PLATFORM
Target: $TARGET
Upload: $UPLOAD
Flutter Version: $(flutter --version | head -1)

Files Created:
EOF

if [ -n "$APK_NAME" ]; then
    echo "APK: $APK_NAME ($APK_SIZE)" >> "$SUMMARY_FILE"
fi
if [ -n "$AAB_NAME" ]; then
    echo "AAB: $AAB_NAME ($AAB_SIZE)" >> "$SUMMARY_FILE"
fi
if [ -n "$IPA_NAME" ]; then
    echo "IPA: $IPA_NAME ($IPA_SIZE)" >> "$SUMMARY_FILE"
fi

echo "" >> "$SUMMARY_FILE"
echo "Upload Locations:" >> "$SUMMARY_FILE"
if [ "$UPLOAD" = "gcs" ] || [ "$UPLOAD" = "both" ]; then
    echo "- Google Cloud Storage: gs://${PROJECT_ID}-app-releases/" >> "$SUMMARY_FILE"
fi
if [ "$UPLOAD" = "gdrive" ] || [ "$UPLOAD" = "both" ]; then
    echo "- Google Drive: Mooves/releases/" >> "$SUMMARY_FILE"
fi

print_success "📄 Build summary saved to: $SUMMARY_FILE"
print_success "🎉 Build and deploy process completed successfully!" 