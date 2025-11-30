#!/bin/bash

# Find App Signing in Swedish Google Play Console
# Denna guide hjälper dig hitta App Signing på svenska

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
    echo -e "${BLUE}=== Hitta App Signing på Svenska Google Play Console ===${NC}"
}

print_header

echo "På svenska Google Play Console kan App Signing finnas under olika namn."
echo "Här är de vanligaste platserna:"
echo ""

print_status "Metod 1: Under 'Testa och lansera'"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Klicka på 'Testa och lansera' i vänster sidopanel"
echo "4. Leta efter 'App-signering' eller 'Signering'"
echo ""

print_status "Metod 2: Under 'Övervaka och förbättra'"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Klicka på 'Övervaka och förbättra'"
echo "4. Leta efter 'App-signering' eller 'Signering'"
echo ""

print_status "Metod 3: Sökfunktion"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Använd sökfältet högst upp"
echo "3. Sök efter 'app-signering' eller 'signering'"
echo "4. Klicka på relevant resultat"
echo ""

print_status "Metod 4: Under 'Inställningar' eller 'Konfiguration'"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Leta efter 'Inställningar' eller 'Konfiguration' i sidopanelen"
echo "4. Klicka på 'App-signering' eller 'Signering'"
echo ""

print_status "Metod 5: Under 'Produktion' eller 'Intern testning'"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Gå till 'Testa och lansera' → 'Produktion' eller 'Intern testning'"
echo "4. Leta efter 'App-signering' eller 'Signering' i release-sektionen"
echo ""

print_status "Svenska termer att leta efter:"
echo "- 'App-signering'"
echo "- 'Signering'"
echo "- 'Nyckelhantering'"
echo "- 'Certifikathantering'"
echo "- 'Uppladdningsnyckel'"
echo "- 'App-signering av Google Play'"
echo ""

print_warning "Om du fortfarande inte hittar App Signing:"
echo ""
echo "1. Kontrollera dina behörigheter:"
echo "   - Du behöver 'Admin' eller 'Ägare'-åtkomst till appen"
echo "   - Kontakta din Play Console-admin om du inte har åtkomst"
echo ""
echo "2. Prova olika webbläsare eller rensa cache:"
echo "   - Använd Chrome, Firefox eller Safari"
echo "   - Rensa webbläsarens cache och cookies"
echo "   - Prova inkognito/privat läge"
echo ""
echo "3. Kontakta Google Play Support:"
echo "   - Gå till: https://support.google.com/googleplay/android-developer"
echo "   - Välj 'App signing & keys'-kategori"
echo "   - Be om hjälp att hitta App Signing-sektionen"
echo ""

print_status "Vad du ska leta efter när du hittar App Signing:"
echo ""
echo "Du bör se en av dessa alternativ:"
echo "- 'App-signering av Google Play' (med Aktivera/Inaktivera-växel)"
echo "- 'Uppladdningsnyckel-certifikat' (visar din nuvarande uppladdningsnyckel)"
echo "- 'App-signeringscertifikat' (visar Googles signeringscertifikat)"
echo "- 'Nyckelhantering' eller 'Certifikathantering'"
echo ""

print_warning "VIKTIGT:"
echo "- Om App-signering av Google Play är aktiverat kan du använda vilken keystore som helst"
echo "- Om det INTE är aktiverat behöver du den ursprungliga keystore eller kontakta Google"
echo "- Inaktivera INTE App-signering av Google Play om det redan är aktiverat"
echo "" 