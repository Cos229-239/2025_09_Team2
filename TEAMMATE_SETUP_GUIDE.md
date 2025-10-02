# 🚀 StudyPals - EXACT SETUP GUIDE FOR TEAMMATES

## ⚠️ CRITICAL: Follow these steps EXACTLY in order

This guide ensures you get the EXACT same working version with:
- ✅ 0 Errors
- ✅ 0 Warnings  
- ✅ 102 Info messages

---

## 📋 Prerequisites

### Required Versions (MUST MATCH):
- **Flutter**: 3.35.3 (channel stable)
- **Dart**: 3.9.2
- **DevTools**: 2.48.0

### Check Your Versions:
```bash
flutter --version
```

**If your versions don't match**, install the correct Flutter version:
```bash
flutter channel stable
flutter upgrade --force
```

---

## 🔧 Step-by-Step Setup

### Step 1: Clean Start (Delete Everything)
```bash
# Navigate to your StudyPals folder
cd path/to/StudyPals

# Delete ALL local changes and branches
git reset --hard
git clean -fdx

# This removes:
# - All uncommitted changes
# - All untracked files
# - All build artifacts
# - All generated files
```

### Step 2: Fetch Latest from Remote
```bash
# Get all remote branches
git fetch --all --prune

# Force checkout the exact working branch
git checkout -B personal/NolensBranch origin/personal/NolensBranch

# Verify you're on the correct commit
git log --oneline -1
# Should show: 4eb9ce1 HUGE UPDATE ; ]
```

### Step 3: Nuclear Clean
```bash
# Delete build artifacts
flutter clean

# Remove pub cache for this project
rm -rf .dart_tool/
rm -rf build/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies

# For Windows PowerShell, use:
Remove-Item -Recurse -Force .dart_tool/
Remove-Item -Recurse -Force build/
Remove-Item -Force .flutter-plugins
Remove-Item -Force .flutter-plugins-dependencies
```

### Step 4: Fresh Dependencies
```bash
# Get dependencies (DO NOT UPGRADE)
flutter pub get

# Verify packages are correct
flutter pub deps
```

### Step 5: Verify Setup
```bash
# Analyze for errors
flutter analyze

# Should show:
# - 0 errors
# - 0 warnings
# - 102 info messages
```

### Step 6: Run the App
```bash
flutter run
```

---

## 🔍 Verification Checklist

After setup, verify these files exist:

### Critical Files:
- [x] `lib/main.dart`
- [x] `lib/firebase_options.dart`
- [x] `lib/utils/responsive_spacing.dart`
- [x] `lib/widgets/dashboard/calendar_display_widget.dart`
- [x] `lib/widgets/dashboard/pet_display_widget.dart`
- [x] `lib/widgets/dashboard/progress_graph_widget.dart`
- [x] `pubspec.yaml`
- [x] `pubspec.lock`

### Verify Git Status:
```bash
git status
# Should show: "nothing to commit, working tree clean"

git log --oneline -1
# Should show: 4eb9ce1 HUGE UPDATE ; ]

git branch --show-current
# Should show: personal/NolensBranch
```

---

## 🐛 Troubleshooting

### Problem: Still Getting Errors

**Solution 1: Force Reset**
```bash
# Delete the entire project folder
cd ..
rm -rf StudyPals

# Clone fresh from GitHub
git clone https://github.com/NOYA-COSC/StudyPals.git
cd StudyPals

# Checkout the working branch
git checkout personal/NolensBranch

# Follow steps 3-6 above
flutter clean
flutter pub get
flutter run
```

**Solution 2: Check Flutter Doctor**
```bash
flutter doctor -v

# Fix any issues shown
# All checks should be green ✓
```

**Solution 3: Clear Flutter Cache**
```bash
# Clear global Flutter cache
flutter pub cache clean

# Then re-run from Step 3
```

### Problem: Firebase Configuration Issues

```bash
# Regenerate Firebase configuration
flutter pub add firebase_core
flutterfire configure --project=studypals-6c4ad
```

### Problem: Android Build Issues

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

For Windows:
```bash
cd android
gradlew.bat clean
cd ..
flutter clean
flutter pub get
```

### Problem: Version Mismatch

If your Flutter version doesn't match, force install the exact version:

```bash
# Install Flutter Version Manager (FVM)
dart pub global activate fvm

# Install the exact Flutter version
fvm install 3.35.3

# Use it for this project
fvm use 3.35.3

# Now use fvm flutter instead of flutter
fvm flutter pub get
fvm flutter run
```

---

## 📝 Quick Reference

### Correct Branch Information:
- **Branch**: `personal/NolensBranch`
- **Commit**: `4eb9ce1` (HUGE UPDATE ; ])
- **Flutter**: 3.35.3
- **Dart**: 3.9.2

### One-Line Setup (PowerShell):
```powershell
git fetch --all --prune; git checkout -B personal/NolensBranch origin/personal/NolensBranch; git reset --hard origin/personal/NolensBranch; flutter clean; Remove-Item -Recurse -Force .dart_tool/,build/ -ErrorAction SilentlyContinue; flutter pub get; flutter analyze
```

### One-Line Setup (Bash/Terminal):
```bash
git fetch --all --prune && git checkout -B personal/NolensBranch origin/personal/NolensBranch && git reset --hard origin/personal/NolensBranch && flutter clean && rm -rf .dart_tool/ build/ && flutter pub get && flutter analyze
```

---

## ✅ Success Criteria

You should see:
```
Analyzing StudyPals...
No issues found!
```

With exactly:
- **0 errors**
- **0 warnings**
- **102 info messages**

---

## 🆘 Still Having Issues?

If you followed ALL steps and still have errors:

1. **Share your output from:**
   ```bash
   flutter --version
   git log --oneline -1
   git branch --show-current
   flutter analyze
   ```

2. **Check if you have local modifications:**
   ```bash
   git status
   git diff
   ```

3. **Verify remote is correct:**
   ```bash
   git remote -v
   # Should show: https://github.com/NOYA-COSC/StudyPals.git
   ```

---

## 📞 Contact

If all else fails, share:
- Your `flutter doctor -v` output
- Your `git status` output
- Screenshot of the errors

**Branch**: personal/NolensBranch  
**Commit**: 4eb9ce1  
**Date**: October 1, 2025
