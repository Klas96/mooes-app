#!/bin/bash

# Script to copy Flutter web build to mooves-website directory
# This integrates the Flutter web app into the website

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Copy Flutter Web to mooves-website  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FRONTEND_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$FRONTEND_DIR")"
WEBSITE_DIR="$PROJECT_ROOT/mooves-website"

echo -e "${BLUE}📂 Frontend directory: $FRONTEND_DIR${NC}"
echo -e "${BLUE}📂 Website directory: $WEBSITE_DIR${NC}"
echo ""

# Check if build exists
BUILD_DIR="$FRONTEND_DIR/build/web"
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}❌ Build directory not found: $BUILD_DIR${NC}"
    echo -e "${YELLOW}💡 Building Flutter web app first...${NC}"
    cd "$FRONTEND_DIR"
    # Build with /mooves-website/ base href since site is at https://klas96.github.io/mooves-website/
    flutter build web --release --base-href /mooves-website/
    echo ""
fi

# Rebuild with correct base href if needed
echo -e "${YELLOW}🔧 Ensuring correct base href for website deployment...${NC}"
cd "$FRONTEND_DIR"
flutter build web --release --base-href /mooves-website/
echo ""

if [ ! -f "$BUILD_DIR/index.html" ]; then
    echo -e "${RED}❌ Flutter web build not found. Please build first:${NC}"
    echo -e "${YELLOW}   cd mooves-frontend && flutter build web --release${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter web build found${NC}"
echo ""

# Check if website directory exists
if [ ! -d "$WEBSITE_DIR" ]; then
    echo -e "${RED}❌ Website directory not found: $WEBSITE_DIR${NC}"
    exit 1
fi

# Backup important files
echo -e "${YELLOW}📦 Backing up important files...${NC}"
BACKUP_DIR="$WEBSITE_DIR/.backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Files to preserve
KEEP_FILES=(
    "index.html"
    "app.html"
    "company-portal.html"
    "policy.html"
    "privacy-policy.html"
    "terms.html"
    "reset-password.html"
    "child-safety-standards.html"
    "mooves-icon.png"
    "deploy-to-server.sh"
    "*.md"
)

for pattern in "${KEEP_FILES[@]}"; do
    if [ -f "$WEBSITE_DIR/$pattern" ] || [ -d "$WEBSITE_DIR/$pattern" ]; then
        cp -r "$WEBSITE_DIR/$pattern" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# Also backup all .md files
find "$WEBSITE_DIR" -maxdepth 1 -name "*.md" -exec cp {} "$BACKUP_DIR/" \; 2>/dev/null || true

echo -e "${GREEN}✅ Backup created: $BACKUP_DIR${NC}"
echo ""

# Copy Flutter web build to website
echo -e "${YELLOW}📋 Copying Flutter web build to mooves-website...${NC}"
cd "$WEBSITE_DIR"

# Preserve existing index.html (landing page) and app.html (Flutter app)
PRESERVE_INDEX=false
PRESERVE_APP=false
if [ -f "$WEBSITE_DIR/index.html" ] && grep -q "website-nav" "$WEBSITE_DIR/index.html" 2>/dev/null; then
    echo "Preserving existing index.html (landing page)..."
    cp "$WEBSITE_DIR/index.html" "$WEBSITE_DIR/index.html.backup"
    PRESERVE_INDEX=true
fi
if [ -f "$WEBSITE_DIR/app.html" ] && grep -q "flutter_bootstrap" "$WEBSITE_DIR/app.html" 2>/dev/null; then
    echo "Preserving existing app.html (Flutter app)..."
    cp "$WEBSITE_DIR/app.html" "$WEBSITE_DIR/app.html.backup"
    PRESERVE_APP=true
fi

# Remove old Flutter files (but keep important ones)
echo "Cleaning old Flutter files..."
find . -maxdepth 1 -type f \
    ! -name "index.html" \
    ! -name "app.html" \
    ! -name "company-portal.html" \
    ! -name "policy.html" \
    ! -name "privacy-policy.html" \
    ! -name "terms.html" \
    ! -name "reset-password.html" \
    ! -name "child-safety-standards.html" \
    ! -name "mooves-icon.png" \
    ! -name "deploy-to-server.sh" \
    ! -name "*.md" \
    ! -name "*.apk" \
    ! -name "index.html.with-nav" \
    -delete 2>/dev/null || true

# Remove old Flutter directories (but keep .git if it exists)
find . -maxdepth 1 -type d \
    ! -name "." \
    ! -name ".." \
    ! -name ".git" \
    ! -name ".backup-*" \
    -exec rm -rf {} \; 2>/dev/null || true

# Copy new Flutter build files (but not index.html yet)
echo "Copying new Flutter build files..."
cd "$BUILD_DIR"
find . -type f ! -name "index.html" -exec cp --parents {} "$WEBSITE_DIR/" \;
find . -type d ! -name "." ! -name ".." -exec mkdir -p "$WEBSITE_DIR/{}" \;

# Now handle index.html - integrate Flutter app with navigation
cd "$WEBSITE_DIR"
if [ "$PRESERVE_INDEX" = true ] && [ -f "index.html.with-nav" ]; then
    echo "Integrating Flutter app into existing index.html with navigation..."
    # Extract Flutter app script from new build
    FLUTTER_SCRIPT=$(grep -o '<script src="[^"]*flutter[^"]*"' "$BUILD_DIR/index.html" | head -1)
    # Replace Flutter script in preserved index.html if needed
    if [ -n "$FLUTTER_SCRIPT" ]; then
        # The preserved index.html already has the script, just ensure it's correct
        sed -i "s|<script src=\"[^\"]*flutter[^\"]*\"|$FLUTTER_SCRIPT|g" index.html.with-nav 2>/dev/null || true
    fi
    mv index.html.with-nav index.html
    echo "✅ Flutter app integrated with navigation"
else
    echo "Creating new index.html with navigation..."
    # Use the template we created (it's already in mooves-website/index.html)
    # Just ensure Flutter script is correct
    if [ -f "$BUILD_DIR/index.html" ]; then
        FLUTTER_SCRIPT=$(grep -o '<script src="[^"]*flutter[^"]*"' "$BUILD_DIR/index.html" | head -1)
        if [ -n "$FLUTTER_SCRIPT" ] && [ -f "index.html" ]; then
            sed -i "s|<script src=\"[^\"]*flutter[^\"]*\"|$FLUTTER_SCRIPT|g" index.html 2>/dev/null || true
        fi
    fi
fi

echo -e "${GREEN}✅ Flutter web build copied${NC}"
echo ""

# Show what was copied
echo -e "${BLUE}📊 Files in mooves-website:${NC}"
ls -lah "$WEBSITE_DIR" | head -20
echo ""

# Summary
echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Copy Complete! 🎉            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📝 Summary:${NC}"
echo "   ✅ Flutter web build copied to mooves-website"
echo "   ✅ Important files preserved"
echo "   ✅ Backup created: $BACKUP_DIR"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "   1. Review the files in mooves-website/"
echo "   2. Commit and push to deploy"
echo "   3. Or run the GitHub Actions workflow"
echo ""

