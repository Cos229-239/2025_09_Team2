# StudyPals Automatic Setup Script for Teammates
# This script will force your local environment to match the working version EXACTLY

Write-Host "🚀 StudyPals - Automatic Setup Script" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if a command exists
function Test-Command($command) {
    try {
        if (Get-Command $command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
}

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow
if (-not (Test-Command "flutter")) {
    Write-Host "❌ Flutter is not installed or not in PATH!" -ForegroundColor Red
    Write-Host "Please install Flutter first: https://flutter.dev/docs/get-started/install" -ForegroundColor Red
    exit 1
}

if (-not (Test-Command "git")) {
    Write-Host "❌ Git is not installed or not in PATH!" -ForegroundColor Red
    Write-Host "Please install Git first: https://git-scm.com/download/win" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites check passed" -ForegroundColor Green
Write-Host ""

# Check Flutter version
Write-Host "🔍 Checking Flutter version..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
Write-Host "Current version: $flutterVersion" -ForegroundColor White

$expectedVersion = "3.35.3"
if ($flutterVersion -notmatch $expectedVersion) {
    Write-Host "⚠️  WARNING: Your Flutter version may not match!" -ForegroundColor Yellow
    Write-Host "Expected: Flutter $expectedVersion" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        Write-Host "Setup cancelled. Please update Flutter to version $expectedVersion" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Confirm before proceeding
Write-Host "⚠️  WARNING: This will DELETE all local changes!" -ForegroundColor Red
Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Delete all uncommitted changes" -ForegroundColor Yellow
Write-Host "  2. Reset to the exact working branch" -ForegroundColor Yellow
Write-Host "  3. Clean all build artifacts" -ForegroundColor Yellow
Write-Host "  4. Reinstall dependencies" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Are you sure you want to continue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Setup cancelled." -ForegroundColor Red
    exit 0
}
Write-Host ""

# Step 1: Reset Git
Write-Host "📦 Step 1/6: Resetting Git repository..." -ForegroundColor Cyan
try {
    git reset --hard 2>&1 | Out-Null
    git clean -fdx 2>&1 | Out-Null
    Write-Host "✅ Git reset complete" -ForegroundColor Green
} catch {
    Write-Host "❌ Git reset failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Fetch and checkout correct branch
Write-Host "🌿 Step 2/6: Fetching and checking out correct branch..." -ForegroundColor Cyan
try {
    git fetch --all --prune 2>&1 | Out-Null
    git checkout -B personal/NolensBranch origin/personal/NolensBranch 2>&1 | Out-Null
    git reset --hard origin/personal/NolensBranch 2>&1 | Out-Null
    
    $currentCommit = git rev-parse --short HEAD
    $currentBranch = git branch --show-current
    
    Write-Host "✅ Branch: $currentBranch" -ForegroundColor Green
    Write-Host "✅ Commit: $currentCommit" -ForegroundColor Green
    
    if ($currentCommit -ne "4eb9ce1") {
        Write-Host "⚠️  WARNING: Commit hash doesn't match expected!" -ForegroundColor Yellow
        Write-Host "Expected: 4eb9ce1, Got: $currentCommit" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Git checkout failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Clean Flutter
Write-Host "🧹 Step 3/6: Cleaning Flutter build artifacts..." -ForegroundColor Cyan
try {
    flutter clean 2>&1 | Out-Null
    Write-Host "✅ Flutter clean complete" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter clean failed: $_" -ForegroundColor Red
}
Write-Host ""

# Step 4: Delete build directories
Write-Host "🗑️  Step 4/6: Removing build directories..." -ForegroundColor Cyan
try {
    $dirsToRemove = @(".dart_tool", "build", ".flutter-plugins", ".flutter-plugins-dependencies")
    foreach ($dir in $dirsToRemove) {
        if (Test-Path $dir) {
            Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
            Write-Host "  Removed: $dir" -ForegroundColor Gray
        }
    }
    Write-Host "✅ Build directories removed" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Warning: Some directories could not be removed: $_" -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Get dependencies
Write-Host "📥 Step 5/6: Installing dependencies..." -ForegroundColor Cyan
Write-Host "  This may take a few minutes..." -ForegroundColor Gray
try {
    flutter pub get
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Dependency installation failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 6: Analyze code
Write-Host "🔍 Step 6/6: Analyzing code..." -ForegroundColor Cyan
try {
    $analyzeOutput = flutter analyze 2>&1
    Write-Host $analyzeOutput
    
    if ($analyzeOutput -match "No issues found") {
        Write-Host ""
        Write-Host "✅ SUCCESS! Setup complete with no errors!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "⚠️  Setup complete but there may be issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Code analysis failed: $_" -ForegroundColor Red
}
Write-Host ""

# Final summary
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now run the app with:" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor Cyan
Write-Host ""
Write-Host "To verify your setup matches:" -ForegroundColor White
Write-Host "  - Branch: $(git branch --show-current)" -ForegroundColor Cyan
Write-Host "  - Commit: $(git rev-parse --short HEAD)" -ForegroundColor Cyan
Write-Host "  - Errors: Should be 0" -ForegroundColor Cyan
Write-Host "  - Warnings: Should be 0" -ForegroundColor Cyan
Write-Host "  - Info: Should be 102" -ForegroundColor Cyan
Write-Host ""

# Pause at the end
Read-Host "Press Enter to exit"
