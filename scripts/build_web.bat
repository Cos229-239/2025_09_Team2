@echo off
REM Build script for StudyPals app
REM Builds the app for web deployment

cd /d "%~dp0\.."
echo Building StudyPals for web deployment...
flutter build web
echo Build complete! Files are in build\web\ directory
pause
