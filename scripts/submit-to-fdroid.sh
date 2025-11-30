#!/bin/bash

# F-Droid Distribution Script for Mooves
# Supports both public and private repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_NAME="mooves"
APP_NAME="Mooves"
PACKAGE_NAME="com.mooves.app"
VERSION="1.0.2"
VERSION_CODE="106"

echo -e "${BLUE}=== Mooves F-Droid Distribution Script ===${NC}"
echo

# Check if repository is public
check_repo_visibility() {
    echo -e "${YELLOW}Checking repository visibility...${NC}"
    
    # Try to access the repository
    if curl -s -o /dev/null -w "%{http_code}" "https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/')" | grep -q "200"; then
        echo -e "${GREEN}✓ Repository is public${NC}"
        return 0
    else
        echo -e "${RED}✗ Repository is private${NC}"
        return 1
    fi
}

# Function to create custom F-Droid repository
create_custom_repo() {
    echo -e "${BLUE}Creating custom F-Droid repository...${NC}"
    
    # Check if fdroidserver is installed
    if ! command -v fdroid &> /dev/null; then
        echo -e "${YELLOW}Installing fdroidserver...${NC}"
        pip install fdroidserver
    fi
    
    # Create F-Droid repository directory
    FDROID_DIR="fdroid-repo"
    if [ -d "$FDROID_DIR" ]; then
        echo -e "${YELLOW}Removing existing F-Droid directory...${NC}"
        rm -rf "$FDROID_DIR"
    fi
    
    mkdir "$FDROID_DIR"
    cd "$FDROID_DIR"
    
    # Initialize F-Droid repository
    echo -e "${YELLOW}Initializing F-Droid repository...${NC}"
    fdroid init
    
    # Configure for private repository access
    echo -e "${YELLOW}Configuring for private repository access...${NC}"
    cat > config.yml << EOF
---
accepted_formats:
  - apk
  - aab
archive_older: 0
build_server_https: true
checkupdates_auto: true
checkupdates_name: Mooves
checkupdates_url: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/')
git_credentials:
  - host: github.com
    username: $(git config --get user.name)
    password: YOUR_GITHUB_TOKEN_HERE
make_current_version_link: true
mirrors:
  - https://YOUR_USERNAME.github.io/$REPO_NAME/fdroid/repo
repo_url: https://YOUR_USERNAME.github.io/$REPO_NAME/fdroid/repo
serverwebroot: /var/www/fdroid
sdk_path: ~/Android/Sdk
update_stats: true
EOF
    
    echo -e "${YELLOW}Please edit config.yml and add your GitHub token:${NC}"
    echo -e "${BLUE}1. Go to GitHub Settings → Developer settings → Personal access tokens${NC}"
    echo -e "${BLUE}2. Generate a new token with 'repo' scope${NC}"
    echo -e "${BLUE}3. Replace 'YOUR_GITHUB_TOKEN_HERE' in config.yml${NC}"
    echo -e "${BLUE}4. Update the mirrors URL with your actual GitHub username${NC}"
    echo
    
    read -p "Press Enter when you've updated config.yml..."
    
    # Copy metadata
    echo -e "${YELLOW}Adding app metadata...${NC}"
    cp ../fdroid-metadata.yml "metadata/$PACKAGE_NAME.yml"
    
    # Build the app
    echo -e "${YELLOW}Building app for F-Droid...${NC}"
    fdroid build "$PACKAGE_NAME"
    
    # Update repository
    echo -e "${YELLOW}Updating repository...${NC}"
    fdroid update --create-metadata
    
    echo -e "${GREEN}✓ Custom F-Droid repository created!${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Deploy the 'repo' directory to your web server"
    echo -e "2. Share the repository URL with users"
    echo -e "3. Users can add: https://YOUR_USERNAME.github.io/$REPO_NAME/fdroid/repo"
    
    cd ..
}

# Function to create public release repository
create_public_release() {
    echo -e "${BLUE}Creating public release repository...${NC}"
    
    RELEASE_REPO="mooves-releases"
    
    if [ -d "$RELEASE_REPO" ]; then
        echo -e "${YELLOW}Removing existing release repository...${NC}"
        rm -rf "$RELEASE_REPO"
    fi
    
    mkdir "$RELEASE_REPO"
    cd "$RELEASE_REPO"
    
    # Initialize git
    git init
    
    # Copy only the app code
    echo -e "${YELLOW}Copying app code...${NC}"
    cp -r ../dating_app .
    cp ../fdroid-metadata.yml .
    cp ../README_FDROID.md .
    
    # Create README
    cat > README.md << EOF
# Mooves - Match Making App

This is the public release repository for Mooves match making app.

## About

Mooves is a match making app focused on connections through intelligent matching and detailed profiles.

## Features

- Create detailed profiles with multiple photos
- Intelligent matching algorithm
- Real-time messaging
- Location-based matching
- Premium features for enhanced experience

## Installation

### F-Droid
1. Add this repository to F-Droid
2. Search for "Mooves" and install

### Direct Download
Download the latest APK from the releases page.

## License

MIT License

## Support

For support and issues, please visit the main repository.
EOF
    
    # Add and commit
    git add .
    git commit -m "Initial release v$VERSION"
    
    echo -e "${GREEN}✓ Public release repository created!${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Create a new public repository on GitHub named '$RELEASE_REPO'"
    echo -e "2. Push this repository: git remote add origin https://github.com/YOUR_USERNAME/$RELEASE_REPO.git"
    echo -e "3. Push: git push -u origin main"
    echo -e "4. Follow the official F-Droid submission process with this repository"
    
    cd ..
}

# Function to submit to official F-Droid
submit_to_official() {
    echo -e "${BLUE}Preparing for official F-Droid submission...${NC}"
    
    # Check if we're in the right directory
    if [ ! -f "fdroid-metadata.yml" ]; then
        echo -e "${RED}Error: fdroid-metadata.yml not found. Run this script from the dating_app directory.${NC}"
        exit 1
    fi
    
    # Create release tag
    echo -e "${YELLOW}Creating release tag...${NC}"
    git tag "v$VERSION"
    git push origin "v$VERSION"
    
    echo -e "${GREEN}✓ Release tag created!${NC}"
    echo
    echo -e "${BLUE}Next steps for official F-Droid submission:${NC}"
    echo -e "1. Fork https://gitlab.com/fdroid/fdroiddata"
    echo -e "2. Clone your fork"
    echo -e "3. Copy fdroid-metadata.yml to metadata/$PACKAGE_NAME.yml"
    echo -e "4. Update the metadata with your repository details"
    echo -e "5. Commit and create a merge request"
    echo
    echo -e "${YELLOW}See FDROID_SUBMISSION_GUIDE.md for detailed instructions.${NC}"
}

# Main script
main() {
    echo -e "${YELLOW}Repository visibility check:${NC}"
    if check_repo_visibility; then
        echo
        echo -e "${GREEN}Your repository is public! You can submit to official F-Droid.${NC}"
        echo
        echo "Choose an option:"
        echo "1) Submit to official F-Droid repository"
        echo "2) Create custom F-Droid repository (recommended for private repos)"
        echo "3) Create public release repository"
        echo "4) Exit"
        echo
        read -p "Enter your choice (1-4): " choice
        
        case $choice in
            1)
                submit_to_official
                ;;
            2)
                create_custom_repo
                ;;
            3)
                create_public_release
                ;;
            4)
                echo -e "${BLUE}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Exiting...${NC}"
                exit 1
                ;;
        esac
    else
        echo
        echo -e "${RED}Your repository is private. Official F-Droid submission is not possible.${NC}"
        echo
        echo "Choose an option:"
        echo "1) Create custom F-Droid repository (recommended)"
        echo "2) Create public release repository"
        echo "3) Exit"
        echo
        read -p "Enter your choice (1-3): " choice
        
        case $choice in
            1)
                create_custom_repo
                ;;
            2)
                create_public_release
                ;;
            3)
                echo -e "${BLUE}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Exiting...${NC}"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main 