@echo off
REM Clean script for StudyPals app
REM Cleans build artifacts and regenerates dependencies

cd /d "%~dp0\.."
echo Cleaning StudyPals project...
echo.

echo Step 1: Flutter clean...
flutter clean
echo.

echo Step 2: Reinstalling dependencies...
flutter pub get
echo.

echo Clean complete! Project is ready for fresh build.
pause
