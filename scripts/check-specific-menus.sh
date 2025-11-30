#!/bin/bash

# Check Specific Menus for App Signing
# Guide för att kolla specifika menyer för App Signing

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
    echo -e "${BLUE}=== Kolla Specifika Menyer för App Signing ===${NC}"
}

print_header

echo "Bra! Nu vet vi vilka menyer du har. Låt oss kolla var App Signing kan finnas:"
echo ""

print_status "Under 'Övervaka och förbättra' → 'Policy'"
echo "1. Klicka på 'Policy' under 'Övervaka och förbättra'"
echo "2. Leta efter:"
echo "   - 'App-signering'"
echo "   - 'Signering'"
echo "   - 'Nyckelhantering'"
echo "   - 'Certifikathantering'"
echo "   - 'Säkerhet'"
echo ""

print_status "Under 'Övervaka och förbättra' → 'Program'"
echo "1. Klicka på 'Program' under 'Övervaka och förbättra'"
echo "2. Leta efter:"
echo "   - 'App-signering'"
echo "   - 'Signering'"
echo "   - 'Nyckelhantering'"
echo "   - 'Certifikathantering'"
echo ""

print_status "Under 'Övervaka och förbättra' → 'Android-diagnos'"
echo "1. Klicka på 'Android-diagnos' under 'Övervaka och förbättra'"
echo "2. Leta efter:"
echo "   - 'App-signering'"
echo "   - 'Signering'"
echo "   - 'Nyckelhantering'"
echo ""

print_status "Under 'Testa och lansera' → 'Produktion'"
echo "1. Gå tillbaka till huvudmenyn"
echo "2. Klicka på 'Testa och lansera'"
echo "3. Klicka på 'Produktion'"
echo "4. Leta efter 'App-signering' eller 'Signering' i release-sektionen"
echo ""

print_status "Under 'Testa och lansera' → 'Intern testning'"
echo "1. Gå tillbaka till huvudmenyn"
echo "2. Klicka på 'Testa och lansera'"
echo "3. Klicka på 'Intern testning'"
echo "4. Leta efter 'App-signering' eller 'Signering'"
echo ""

print_warning "Om du inte hittar App Signing under någon av dessa:"
echo ""
echo "1. Kontrollera dina behörigheter:"
echo "   - Du behöver 'Admin' eller 'Ägare'-åtkomst till appen"
echo "   - Kontakta din Play Console-admin om du inte har åtkomst"
echo ""
echo "2. Kontakta Google Play Support:"
echo "   - Gå till: https://support.google.com/googleplay/android-developer"
echo "   - Välj 'App signing & keys'-kategori"
echo "   - Förklara att du behöver hjälp med keystore-problemet"
echo ""

print_status "Alternativt: Kontakta Google Play Support direkt"
echo ""
echo "Om du inte kan hitta App Signing, kontakta Google Play Support:"
echo "1. Gå till: https://support.google.com/googleplay/android-developer"
echo "2. Välj 'App signing & keys'-kategori"
echo "3. Förklara att du behöver hjälp med keystore-problemet"
echo "4. Be om en nyckelåterställning för din app"
echo ""

print_warning "VIKTIGT:"
echo "- Om App-signering av Google Play är aktiverat kan du använda vilken keystore som helst"
echo "- Om det INTE är aktiverat behöver du den ursprungliga keystore eller kontakta Google"
echo "- Inaktivera INTE App-signering av Google Play om det redan är aktiverat"
echo "" 