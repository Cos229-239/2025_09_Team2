#!/bin/bash
# Cross-platform script to run StudyPals app in Chrome
# Works on macOS, Linux, and Windows (with Git Bash)

cd "$(dirname "$0")/.."
flutter run -d chrome --web-port 8080
