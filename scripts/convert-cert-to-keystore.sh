#!/bin/bash

# Convert Upload Certificate to Keystore
# Konvertera uppladdningscertifikat till keystore

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}=== Konvertera Upload Certifikat till Keystore ===${NC}"
}

print_header

# Navigate to the Flutter app directory
cd "$(dirname "$0")/.."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found! Please run this script from the Flutter project root."
    exit 1
fi

print_status "Hittade upload_certificate.pem med rätt SHA1-fingeravtryck!"
echo "SHA1: 36:2E:91:FC:73:02:34:31:BC:E9:15:35:5B:14:34:9B:B0:65:1F:FB"
echo ""

print_status "Detta certifikat behöver konverteras till en keystore för att kunna användas för signering."
echo ""

print_warning "VIKTIGT: Detta certifikat innehåller bara den publika nyckeln, inte den privata nyckeln."
echo "För att kunna signera behöver du den privata nyckeln också."
echo ""

print_status "Alternativ 1: Kontakta Google Play Support"
echo "Eftersom du bara har certifikatet (publik nyckel) men inte den privata nyckeln,"
echo "behöver du kontakta Google Play Support för en nyckelåterställning."
echo ""

print_status "Alternativ 2: Sök efter den privata nyckeln"
echo "Låt oss söka efter den privata nyckeln som matchar detta certifikat:"
echo ""

# Search for private keys that might match
print_status "Söker efter privata nycklar..."
find /home/klas -name "*.key" -o -name "*.pem" -o -name "*.p12" -o -name "*.pfx" 2>/dev/null | grep -v node_modules | head -10

echo ""
print_status "Om du hittar en privat nyckel som matchar, kan vi skapa en keystore."
echo ""

print_status "Alternativ 3: Kontakta Google Play Support för nyckelåterställning"
echo "1. Gå till: https://support.google.com/googleplay/android-developer"
echo "2. Välj 'App signing & keys'"
echo "3. Välj 'Lost upload key'"
echo "4. Inkludera information om att du har certifikatet men inte den privata nyckeln"
echo ""

print_warning "Rekommendation:"
echo "Kontakta Google Play Support eftersom du bara har certifikatet, inte den privata nyckeln."
echo "De kommer att kunna återställa din uppladdningsnyckel."
echo "" 