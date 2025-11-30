#!/bin/bash

# Upload APK to Google Drive releases/android/ folder
set -e  # Exit on any error

echo "🚀 Starting APK upload to Google Drive releases/android/..."

# Navigate to the Flutter app directory
cd "$(dirname "$0")/.."

# Check if APK file is provided as argument
if [ $# -eq 0 ]; then
    echo "❌ No APK file specified!"
    echo "Usage: $0 <path-to-apk-file>"
    echo "Example: $0 build/app/outputs/flutter-apk/app-release.apk"
    exit 1
fi

APK_PATH="$1"

# Check if the APK file exists
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK file not found: $APK_PATH"
    exit 1
fi

# Get APK filename
APK_FILENAME=$(basename "$APK_PATH")

# Get current timestamp for backup naming
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')

# Create backup filename with version and timestamp
BACKUP_FILENAME="mooves_v${VERSION}_${TIMESTAMP}.apk"

echo "📱 Uploading APK: $APK_FILENAME"
echo "📋 Backup filename: $BACKUP_FILENAME"

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "❌ rclone is not installed!"
    echo "Please install rclone first: https://rclone.org/install/"
    exit 1
fi

# Check if gdrive remote is configured
if ! rclone listremotes | grep -q "gdrive:"; then
    echo "❌ Google Drive remote 'gdrive' is not configured!"
    echo "Please configure rclone with: rclone config"
    exit 1
fi

# Create releases/android/ directory structure if it doesn't exist
echo "📁 Ensuring Mooves/releases/android/ directory exists..."
rclone mkdir gdrive:Mooves/releases/android/ 2>/dev/null || true

# Upload APK to Mooves/releases/android/ with original filename
echo "☁️ Uploading to Google Drive Mooves/releases/android/..."
rclone copy "$APK_PATH" "gdrive:Mooves/releases/android/"

# Also create a backup with timestamp in Mooves/releases/android/backups/
echo "📁 Creating backup in Mooves/releases/android/backups/..."
rclone mkdir gdrive:Mooves/releases/android/backups/ 2>/dev/null || true
rclone copy "$APK_PATH" "gdrive:Mooves/releases/android/backups/$BACKUP_FILENAME"

echo "✅ APK successfully uploaded!"
echo "📱 Original APK: Mooves/releases/android/$APK_FILENAME"
echo "📋 Backup APK: Mooves/releases/android/backups/$BACKUP_FILENAME"
echo "🔗 You can find it in your Google Drive 'Mooves/releases/android/' folder"

# Show file size
FILE_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo "📊 File size: $FILE_SIZE"

# List files in the Mooves/releases/android/ directory
echo "📂 Files in Mooves/releases/android/:"
rclone ls gdrive:Mooves/releases/android/ --human-readable

echo "🎉 Upload complete!" 