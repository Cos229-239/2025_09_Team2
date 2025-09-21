/**
 * StudyPals Spotify Integration - Configuration File
 * 
 * This file contains all the configuration settings for the Spotify integration.
 * It includes environment variables, API settings, and easy-to-modify credentials.
 * 
 * To use this configuration:
 * 1. Copy this file to your project
 * 2. Update the credentials below with your Spotify app credentials
 * 3. Modify any other settings as needed
 * 
 * @author StudyPals Team
 * @version 1.0.0
 */

// Spotify API Configuration
const SPOTIFY_CONFIG = {
  // Your Spotify App Credentials
  // Get these from: https://developer.spotify.com/dashboard/applications
  CLIENT_ID: '6840c4bc3c11466a81c2822ca3cd1f2e',
  CLIENT_SECRET: '2cd3e20bd4e340428050c00d903aef25',
  
  // Redirect URI - must match what you set in your Spotify app settings
  // Note: Spotify requires 127.0.0.1 instead of localhost for security compliance
  REDIRECT_URI: 'http://127.0.0.1:3000/auth/spotify/callback',
  
  // OAuth Scopes - what permissions your app requests from users
  SCOPES: [
    'user-read-private',        // Access user's subscription details
    'user-read-email',          // Access user's email address
    'playlist-read-private',    // Read user's private playlists
    'playlist-read-collaborative', // Read collaborative playlists
    'playlist-modify-public',   // Create/modify public playlists
    'playlist-modify-private',  // Create/modify private playlists
    'user-library-read',        // Read user's saved tracks/albums
    'user-library-modify'       // Add/remove tracks from user's library
  ],
  
  // API Base URLs
  AUTH_URL: 'https://accounts.spotify.com/authorize',
  TOKEN_URL: 'https://accounts.spotify.com/api/token',
  API_BASE_URL: 'https://api.spotify.com/v1'
};

// Server Configuration
const SERVER_CONFIG = {
  // Port for the backend server
  PORT: 5000,
  
  // Frontend URL (where your HTML file is served from)
  FRONTEND_URL: 'http://127.0.0.1:3000',
  
  // CORS settings
  CORS_ORIGIN: 'http://127.0.0.1:3000'
};

// Application Settings
const APP_CONFIG = {
  // App name and version
  NAME: 'StudyPals Spotify Integration',
  VERSION: '1.0.0',
  
  // Default settings
  DEFAULT_SEARCH_LIMIT: 10,
  DEFAULT_PLAYLIST_LIMIT: 50,
  
  // UI Settings
  THEME: {
    PRIMARY_COLOR: '#1DB954',    // Spotify green
    SECONDARY_COLOR: '#1ed760',  // Spotify light green
    BACKGROUND_COLOR: '#f9fafb', // Light gray
    TEXT_COLOR: '#1f2937'        // Dark gray
  }
};

// Environment Variables (for .env file)
const ENV_TEMPLATE = `
# Spotify API Credentials
SPOTIFY_CLIENT_ID=${SPOTIFY_CONFIG.CLIENT_ID}
SPOTIFY_CLIENT_SECRET=${SPOTIFY_CONFIG.CLIENT_SECRET}
SPOTIFY_REDIRECT_URI=${SPOTIFY_CONFIG.REDIRECT_URI}

# Server Configuration
PORT=${SERVER_CONFIG.PORT}
FRONTEND_URL=${SERVER_CONFIG.FRONTEND_URL}
`;

// Export configurations for use in other files
if (typeof module !== 'undefined' && module.exports) {
  // Node.js environment
  module.exports = {
    SPOTIFY_CONFIG,
    SERVER_CONFIG,
    APP_CONFIG,
    ENV_TEMPLATE
  };
} else {
  // Browser environment
  window.SPOTIFY_CONFIG = SPOTIFY_CONFIG;
  window.SERVER_CONFIG = SERVER_CONFIG;
  window.APP_CONFIG = APP_CONFIG;
}

// Quick Setup Instructions
const SETUP_INSTRUCTIONS = `
🎵 StudyPals Spotify Integration - Quick Setup

1. 📋 Prerequisites:
   - Node.js installed (https://nodejs.org/)
   - Spotify Developer Account (https://developer.spotify.com/)

2. 🔑 Get Spotify Credentials:
   - Go to https://developer.spotify.com/dashboard/applications
   - Click "Create App"
   - Fill in app details
   - Copy Client ID and Client Secret
   - Add Redirect URI: ${SPOTIFY_CONFIG.REDIRECT_URI}

3. 📁 File Setup:
   - spotify-integration.html (frontend)
   - spotify-server.js (backend)
   - spotify-config.js (configuration)

4. 🚀 Run the Application:
   - Install dependencies: npm install express cors axios dotenv
   - Start server: node spotify-server.js
   - Open browser: http://localhost:5000

5. ✅ Test Connection:
   - Click "Connect Spotify Account"
   - Authorize the app
   - View your playlists and search music

📞 Support:
   - Check console for errors
   - Verify Spotify app settings
   - Ensure redirect URI matches exactly
`;

// Log setup instructions if running in Node.js
if (typeof console !== 'undefined' && typeof process !== 'undefined') {
  console.log(SETUP_INSTRUCTIONS);
}
