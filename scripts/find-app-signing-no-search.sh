#!/bin/bash

# Find App Signing without Search Function
# Guide för att hitta App Signing utan sökfält

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
    echo -e "${BLUE}=== Hitta App Signing utan Sökfält ===${NC}"
}

print_header

echo "Eftersom det inte finns något sökfält, här är andra sätt att hitta App Signing:"
echo ""

print_status "Metod 1: Systematisk genomgång av alla menyer"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Klicka på VARJE meny i vänster sidopanel och leta efter:"
echo "   - 'App-signering'"
echo "   - 'Signering'"
echo "   - 'Nyckelhantering'"
echo "   - 'Certifikathantering'"
echo ""

print_status "Metod 2: Under 'Testa och lansera' → 'Produktion'"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Klicka på 'Testa och lansera'"
echo "4. Klicka på 'Produktion'"
echo "5. Leta efter 'App-signering' eller 'Signering' i release-sektionen"
echo ""

print_status "Metod 3: Under 'Testa och lansera' → 'Intern testning'"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Klicka på 'Testa och lansera'"
echo "4. Klicka på 'Intern testning'"
echo "5. Leta efter 'App-signering' eller 'Signering'"
echo ""

print_status "Metod 4: Under 'Övervaka och förbättra'"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Klicka på 'Övervaka och förbättra'"
echo "4. Leta efter undermenyer som:"
echo "   - 'Inställningar'"
echo "   - 'Konfiguration'"
echo "   - 'App-signering'"
echo ""

print_status "Metod 5: Under 'Butikspresens' eller 'App-innehåll'"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Leta efter 'Butikspresens' eller 'App-innehåll'"
echo "4. Leta efter 'App-signering' eller 'Signering'"
echo ""

print_status "Metod 6: Under 'Inställningar' eller 'Konfiguration'"
echo "1. Gå till Google Play Console: https://play.google.com/console"
echo "2. Välj din app"
echo "3. Leta efter 'Inställningar' eller 'Konfiguration' i sidopanelen"
echo "4. Klicka på det och leta efter 'App-signering'"
echo ""

print_warning "Om du fortfarande inte hittar App Signing:"
echo ""
echo "1. Kontrollera dina behörigheter:"
echo "   - Du behöver 'Admin' eller 'Ägare'-åtkomst till appen"
echo "   - Kontakta din Play Console-admin om du inte har åtkomst"
echo ""
echo "2. Prova olika webbläsare:"
echo "   - Använd Chrome, Firefox eller Safari"
echo "   - Rensa webbläsarens cache och cookies"
echo "   - Prova inkognito/privat läge"
echo ""
echo "3. Kontakta Google Play Support:"
echo "   - Gå till: https://support.google.com/googleplay/android-developer"
echo "   - Välj 'App signing & keys'-kategori"
echo "   - Be om hjälp att hitta App Signing-sektionen"
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