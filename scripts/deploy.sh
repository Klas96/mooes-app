#!/bin/bash

# Simple deployment script
echo "🚀 Starting deployment..."

# Bump version and build
./scripts/bump-version.sh

# Upload to Google Play
echo "📤 Uploading to Google Play Internal Testing..."
fastlane supply \
  --json_key ~/Downloads/fresh-oath-337920-ddb4351c237a.json \
  --package_name com.mooves.app \
  --aab build/app/outputs/bundle/release/app-release.aab \
  --track internal \
  --release_status draft

echo "✅ Deployment complete!" 