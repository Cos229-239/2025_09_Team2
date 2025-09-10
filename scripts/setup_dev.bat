@echo off
REM Development setup script for StudyPals
REM Installs dependencies and sets up the development environment

cd /d "%~dp0\.."
echo Setting up StudyPals development environment...
echo.

echo Step 1: Getting Flutter dependencies...
flutter pub get
echo.

echo Step 2: Running code analysis...
flutter analyze
echo.

echo Step 3: Running tests...
flutter test
echo.

echo Development environment setup complete!
echo You can now run the app using scripts\run_app.bat
pause
