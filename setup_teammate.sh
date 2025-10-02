#!/bin/bash
# StudyPals Automatic Setup Script for Teammates
# This script will force your local environment to match the working version EXACTLY

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 StudyPals - Automatic Setup Script${NC}"
echo -e "${CYAN}=======================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH!${NC}"
    echo -e "${RED}Please install Flutter first: https://flutter.dev/docs/get-started/install${NC}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed or not in PATH!${NC}"
    echo -e "${RED}Please install Git first: https://git-scm.com/download${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Check Flutter version
echo -e "${YELLOW}🔍 Checking Flutter version...${NC}"
FLUTTER_VERSION=$(flutter --version 2>&1 | head -n 1)
echo -e "Current version: ${FLUTTER_VERSION}"

EXPECTED_VERSION="3.35.3"
if [[ ! "$FLUTTER_VERSION" =~ "$EXPECTED_VERSION" ]]; then
    echo -e "${YELLOW}⚠️  WARNING: Your Flutter version may not match!${NC}"
    echo -e "${YELLOW}Expected: Flutter $EXPECTED_VERSION${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Setup cancelled. Please update Flutter to version $EXPECTED_VERSION${NC}"
        exit 1
    fi
fi
echo ""

# Confirm before proceeding
echo -e "${RED}⚠️  WARNING: This will DELETE all local changes!${NC}"
echo -e "${YELLOW}This script will:${NC}"
echo -e "${YELLOW}  1. Delete all uncommitted changes${NC}"
echo -e "${YELLOW}  2. Reset to the exact working branch${NC}"
echo -e "${YELLOW}  3. Clean all build artifacts${NC}"
echo -e "${YELLOW}  4. Reinstall dependencies${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo -e "${RED}Setup cancelled.${NC}"
    exit 0
fi
echo ""

# Step 1: Reset Git
echo -e "${CYAN}📦 Step 1/6: Resetting Git repository...${NC}"
git reset --hard > /dev/null 2>&1
git clean -fdx > /dev/null 2>&1
echo -e "${GREEN}✅ Git reset complete${NC}"
echo ""

# Step 2: Fetch and checkout correct branch
echo -e "${CYAN}🌿 Step 2/6: Fetching and checking out correct branch...${NC}"
git fetch --all --prune > /dev/null 2>&1
git checkout -B personal/NolensBranch origin/personal/NolensBranch > /dev/null 2>&1
git reset --hard origin/personal/NolensBranch > /dev/null 2>&1

CURRENT_COMMIT=$(git rev-parse --short HEAD)
CURRENT_BRANCH=$(git branch --show-current)

echo -e "${GREEN}✅ Branch: $CURRENT_BRANCH${NC}"
echo -e "${GREEN}✅ Commit: $CURRENT_COMMIT${NC}"

if [[ "$CURRENT_COMMIT" != "4eb9ce1" ]]; then
    echo -e "${YELLOW}⚠️  WARNING: Commit hash doesn't match expected!${NC}"
    echo -e "${YELLOW}Expected: 4eb9ce1, Got: $CURRENT_COMMIT${NC}"
fi
echo ""

# Step 3: Clean Flutter
echo -e "${CYAN}🧹 Step 3/6: Cleaning Flutter build artifacts...${NC}"
flutter clean > /dev/null 2>&1
echo -e "${GREEN}✅ Flutter clean complete${NC}"
echo ""

# Step 4: Delete build directories
echo -e "${CYAN}🗑️  Step 4/6: Removing build directories...${NC}"
rm -rf .dart_tool build .flutter-plugins .flutter-plugins-dependencies 2>/dev/null || true
echo -e "${GREEN}✅ Build directories removed${NC}"
echo ""

# Step 5: Get dependencies
echo -e "${CYAN}📥 Step 5/6: Installing dependencies...${NC}"
echo -e "  ${NC}This may take a few minutes...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 6: Analyze code
echo -e "${CYAN}🔍 Step 6/6: Analyzing code...${NC}"
ANALYZE_OUTPUT=$(flutter analyze 2>&1)
echo "$ANALYZE_OUTPUT"

if [[ "$ANALYZE_OUTPUT" =~ "No issues found" ]]; then
    echo ""
    echo -e "${GREEN}✅ SUCCESS! Setup complete with no errors!${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️  Setup complete but there may be issues${NC}"
fi
echo ""

# Final summary
echo -e "${CYAN}=======================================${NC}"
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo -e "${CYAN}=======================================${NC}"
echo ""
echo -e "${NC}You can now run the app with:${NC}"
echo -e "${CYAN}  flutter run${NC}"
echo ""
echo -e "${NC}To verify your setup matches:${NC}"
echo -e "${CYAN}  - Branch: $(git branch --show-current)${NC}"
echo -e "${CYAN}  - Commit: $(git rev-parse --short HEAD)${NC}"
echo -e "${CYAN}  - Errors: Should be 0${NC}"
echo -e "${CYAN}  - Warnings: Should be 0${NC}"
echo -e "${CYAN}  - Info: Should be 102${NC}"
echo ""
