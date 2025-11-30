#!/bin/bash

# Script to automatically bump version code
echo "🔄 Bumping version code..."

# Get current version code from build.gradle
CURRENT_VERSION=$(grep "versionCode = " android/app/build.gradle | awk '{print $3}' | tr -d '\r')
echo "Current version code: $CURRENT_VERSION"

# Increment version code
NEW_VERSION=$((CURRENT_VERSION + 1))
echo "New version code: $NEW_VERSION"

# Update build.gradle
sed -i "s/versionCode = $CURRENT_VERSION/versionCode = $NEW_VERSION/" android/app/build.gradle

# Update pubspec.yaml
sed -i "s/version: 1.0.1+$CURRENT_VERSION/version: 1.0.1+$NEW_VERSION/" pubspec.yaml

echo "✅ Version bumped to $NEW_VERSION"
echo "📦 Building new AAB..."
flutter build appbundle --release

echo "🚀 Ready to upload with version code $NEW_VERSION" 