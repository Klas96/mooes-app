#!/bin/bash

# Contact Google Play Support Guide
# Guide för att kontakta Google Play Support för nyckelåterställning

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
    echo -e "${BLUE}=== Kontakta Google Play Support för Nyckelåterställning ===${NC}"
}

print_header

echo "Problemet är att Google Play Console fortfarande förväntar sig den ursprungliga"
echo "uppladdningsnyckeln, även om App-signering av Google Play är aktiverat."
echo ""
echo "Du behöver kontakta Google Play Support för en nyckelåterställning."
echo ""

print_status "Steg för att kontakta Google Play Support:"
echo ""

echo "1. Gå till Google Play Support:"
echo "   https://support.google.com/googleplay/android-developer"
echo ""

echo "2. Klicka på 'Kontakta oss' eller 'Contact us'"
echo ""

echo "3. Välj kategori: 'App signing & keys' eller 'App-signering och nycklar'"
echo ""

echo "4. Välj underkategori: 'Lost upload key' eller 'Förlorad uppladdningsnyckel'"
echo ""

echo "5. Fyll i formuläret med följande information:"
echo ""

print_warning "Information att inkludera i support-förfrågan:"
echo ""
echo "- App-namn: Mooves"
echo "- Package name: com.mooves.app"
echo "- Problem: Lost upload key / Förlorad uppladdningsnyckel"
echo "- Expected SHA1: 36:2E:91:FC:73:02:34:31:BC:E9:15:35:5B:14:34:9B:B0:65:1F:FB"
echo "- Current SHA1: D9:A1:1F:8E:1B:3E:63:01:FD:69:8B:8A:9A:C8:47:CE:36:A2:1F:EC"
echo "- App Signing by Google Play: ENABLED"
echo "- Request: Key reset for upload key"
echo ""

print_status "Bevis på ägandeskap att inkludera:"
echo ""
echo "1. Screenshots av Google Play Console"
echo "2. Tidigare APK/AAB-filer om du har dem"
echo "3. Dokumentation av din app"
echo "4. Bevis på att du är app-ägaren"
echo ""

print_warning "Alternativt: Kontakta Google Play Support via e-post"
echo ""
echo "Om webbsupport inte fungerar, prova att skicka e-post till:"
echo "play-developer-support@google.com"
echo ""
echo "Ämne: 'Key reset request for com.mooves.app'"
echo ""

print_status "Vad som händer efter support-förfrågan:"
echo ""
echo "1. Google kommer att granska din förfrågan"
echo "2. De kan be om ytterligare bevis på ägandeskap"
echo "3. Om godkänd, kommer de att återställa din uppladdningsnyckel"
echo "4. Du kommer att få instruktioner för att ladda upp en ny nyckel"
echo ""

print_warning "Under tiden:"
echo ""
echo "- Ladda INTE upp fler AAB-filer med fel nyckel"
echo "- Vänta på svar från Google Play Support"
echo "- Förbered bevis på ägandeskap"
echo ""

print_status "När du får nyckelåterställning:"
echo ""
echo "1. Skapa en ny keystore med instruktionerna från Google"
echo "2. Uppdatera android/key.properties"
echo "3. Bygg ny AAB: flutter build appbundle --release"
echo "4. Ladda upp till Play Console"
echo ""

print_warning "VIKTIGT:"
echo "- Var tålmodig, detta kan ta några dagar"
echo "- Inkludera all nödvändig information i support-förfrågan"
echo "- Behåll bevis på ägandeskap redo"
echo "- Ladda inte upp fler AAB-filer tills problemet är löst"
echo "" 