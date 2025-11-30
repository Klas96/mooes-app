#!/bin/bash

echo "🚀 Activating Internal Testing Release..."

# Deploy with completed status instead of draft
fastlane supply \
  --json_key ~/Downloads/fresh-oath-337920-ddb4351c237a.json \
  --package_name com.mooves.app \
  --aab build/app/outputs/bundle/release/app-release.aab \
  --track internal \
  --release_status completed

echo "✅ Internal testing activated!"
echo "📱 You can now install the app from the testing link"
echo "🔗 Check Google Play Console for the testing URL" 