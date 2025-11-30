#!/bin/bash
# Complete restart of Flutter app to ensure fresh code

echo "🔄 Cleaning and restarting Flutter app..."
echo ""

cd /home/klas/Kod/mooves-project/mooves-frontend

# Clean build
flutter clean

# Get dependencies  
flutter pub get

echo ""
echo "✅ Ready to run!"
echo ""
echo "Now run your app:"
echo "  flutter run"
echo ""
echo "Or for Android release build:"
echo "  flutter run --release"
echo ""

