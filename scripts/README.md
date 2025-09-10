# Scripts Directory

This directory contains utility scripts and batch files for the StudyPals project.

## Available Scripts

### `run_app.bat` / `run_app.sh`
- **Purpose**: Quickly launch the StudyPals app in Chrome browser
- **Usage**: Double-click the file or run from command line
- **Port**: Runs on port 8080
- **Platform**: Windows batch script (.bat) / Cross-platform shell script (.sh)

### `build_web.bat`
- **Purpose**: Build the app for web deployment
- **Usage**: Creates production-ready web build in `build/web/` directory
- **Platform**: Windows batch script

### `setup_dev.bat`
- **Purpose**: Complete development environment setup
- **Usage**: Installs dependencies, runs analysis, and tests
- **Platform**: Windows batch script

### `clean.bat`
- **Purpose**: Clean build artifacts and refresh dependencies
- **Usage**: Removes build files and reinstalls packages
- **Platform**: Windows batch script

## Usage Instructions

### Windows Users
1. Navigate to the `scripts` folder
2. Double-click any `.bat` file to run:
   - `run_app.bat` - Start the app
   - `build_web.bat` - Build for production
   - `setup_dev.bat` - Set up development environment
   - `clean.bat` - Clean and refresh project
3. The appropriate action will execute automatically

### macOS/Linux Users
1. Make the shell script executable: `chmod +x scripts/run_app.sh`
2. Run the script: `./scripts/run_app.sh`

### Command Line Usage
```bash
# From project root directory (Windows)
scripts\run_app.bat          # Start the app
scripts\build_web.bat        # Build for production
scripts\setup_dev.bat        # Setup development environment
scripts\clean.bat            # Clean project

# From project root directory (macOS/Linux)
./scripts/run_app.sh         # Start the app
```

## Adding New Scripts

When adding new utility scripts:
1. Place them in this `scripts/` directory
2. Update this README with script descriptions
3. Include platform compatibility notes
4. Document any required dependencies

## Notes
- All scripts assume Flutter is properly installed and configured
- Scripts are designed to run from the project root directory
- Ensure proper execution permissions are set for your platform
