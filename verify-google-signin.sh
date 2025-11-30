#!/bin/bash

echo "════════════════════════════════════════════════════════"
echo "  Google Sign-In Configuration Verification"
echo "════════════════════════════════════════════════════════"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cd "$(dirname "$0")"

echo "1. Checking google-services.json..."
if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✓${NC} google-services.json exists"
    
    # Check if oauth_client is populated
    oauth_count=$(grep -o "client_type" android/app/google-services.json | wc -l)
    if [ "$oauth_count" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} OAuth clients found: $oauth_count"
        echo ""
        echo "OAuth Client IDs:"
        grep -A 3 "client_id.*apps.googleusercontent.com" android/app/google-services.json | grep "client_id" | sed 's/.*"client_id": "/  - /' | sed 's/".*//'
    else
        echo -e "${RED}✗${NC} No OAuth clients found in google-services.json!"
        echo -e "${YELLOW}⚠${NC}  You need to download a fresh google-services.json from Firebase"
    fi
else
    echo -e "${RED}✗${NC} google-services.json not found!"
fi

echo ""
echo "2. Checking package name..."
package_name=$(grep "package=" android/app/src/main/AndroidManifest.xml | sed 's/.*package="//' | sed 's/".*//')
echo "   Package: $package_name"
if [ "$package_name" = "com.mooves.app" ]; then
    echo -e "${GREEN}✓${NC} Package name is correct"
else
    echo -e "${RED}✗${NC} Package name doesn't match!"
fi

echo ""
echo "3. Checking SHA fingerprints..."
echo "   Debug keystore:"
if [ -f "$HOME/.android/debug.keystore" ]; then
    keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1\|SHA256" | while read line; do
        echo "   $line"
    done
    echo -e "${GREEN}✓${NC} Debug keystore found"
else
    echo -e "${RED}✗${NC} Debug keystore not found"
fi

echo ""
echo "   Release keystore:"
if [ -f "android/play-store-keystore.jks" ]; then
    keytool -list -v -keystore android/play-store-keystore.jks -storepass mooves123 2>/dev/null | grep "SHA1\|SHA256" | while read line; do
        echo "   $line"
    done
    echo -e "${GREEN}✓${NC} Release keystore found"
else
    echo -e "${YELLOW}⚠${NC}  Release keystore not found at android/play-store-keystore.jks"
fi

echo ""
echo "4. Checking Google Sign-In configuration..."
if grep -q "google_sign_in" pubspec.yaml; then
    version=$(grep "google_sign_in:" pubspec.yaml | awk '{print $2}')
    echo -e "${GREEN}✓${NC} google_sign_in dependency found (version: $version)"
else
    echo -e "${RED}✗${NC} google_sign_in not in pubspec.yaml"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Next Steps:"
echo "════════════════════════════════════════════════════════"
echo ""
echo "1. Go to Firebase Console and add these fingerprints:"
echo "   https://console.firebase.google.com/project/mooves-15954/settings/general/android:com.mooves.app"
echo ""
echo "2. Go to OAuth Consent Screen:"
echo "   https://console.cloud.google.com/apis/credentials/consent?project=mooves-15954"
echo "   → Click 'PUBLISH APP' or add your Gmail as test user"
echo ""
echo "3. Download fresh google-services.json and replace:"
echo "   android/app/google-services.json"
echo ""
echo "4. Rebuild the app:"
echo "   flutter clean && flutter build apk --debug"
echo ""
echo "════════════════════════════════════════════════════════"

