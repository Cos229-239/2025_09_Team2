/// StudyPals Spotify Integration - Configuration
///
/// This file contains all the configuration settings for the Spotify integration.
/// It replaces the JavaScript spotify-config.js file with Dart equivalents.
///
/// @author StudyPals Team
/// @version 1.0.0
library;

/// Central configuration class for Spotify integration.
/// Contains all the necessary settings and constants for the Spotify API.
///
/// Configuration Categories:
/// 1. OAuth Settings - Client credentials and redirect URIs
/// 2. API Permissions - Scopes for user authorization
/// 3. API Endpoints - Base URLs for various Spotify services
/// 4. Application Settings - Default values and limits
/// 5. UI Configuration - Theme colors and styling
///
/// SECURITY NOTE: In a production environment, sensitive values like
/// clientId and clientSecret should be stored securely and not
/// committed to version control.
///
/// Usage:
/// ```dart
/// // Access OAuth settings
/// final clientId = SpotifyConfig.clientId;
///
/// // Get API endpoints
/// final apiUrl = SpotifyConfig.apiBaseUrl;
///
/// // Access theme colors
/// final primaryColor = SpotifyConfig.theme.primaryColor;
/// ```
///
/// Integration Setup:
/// 1. Register app in Spotify Developer Dashboard
/// 2. Configure redirect URI in Spotify app settings
/// 3. Set up required permissions (scopes)
/// 4. Update clientId and clientSecret
/// 5. Test authentication flow
class SpotifyConfig {
  /// OAuth client ID from Spotify Developer Dashboard
  /// Used to identify this application to Spotify's OAuth service
  /// Must match the client ID registered in Spotify Developer Portal
  static const String clientId = '6840c4bc3c11466a81c2822ca3cd1f2e';

  /// OAuth client secret from Spotify Developer Dashboard
  /// Used for server-side authentication
  /// IMPORTANT: Keep this value secure and never expose it in client-side code
  static const String clientSecret = '2cd3e20bd4e340428050c00d903aef25';

  /// OAuth redirect URI for handling authentication callback
  /// IMPORTANT: This exact URI must be registered in your Spotify app settings
  /// The URI receives the authentication code after user approval
  static const String redirectUri =
      'http://127.0.0.1:3000/auth/spotify/callback';

  // OAuth Scopes - what permissions your app requests from users
  static const List<String> scopes = [
    'user-read-private', // Access user's subscription details
    'user-read-email', // Access user's email address
    'playlist-read-private', // Read user's private playlists
    'playlist-read-collaborative', // Read collaborative playlists
    'playlist-modify-public', // Create/modify public playlists
    'playlist-modify-private', // Create/modify private playlists
    'user-library-read', // Read user's saved tracks/albums
    'user-library-modify' // Add/remove tracks from user's library
  ];

  // API Base URLs
  static const String authUrl = 'https://accounts.spotify.com/authorize';
  static const String tokenUrl = 'https://accounts.spotify.com/api/token';
  static const String apiBaseUrl = 'https://api.spotify.com/v1';

  // Application Settings
  static const String appName = 'StudyPals Spotify Integration';
  static const String appVersion = '1.0.0';
  static const int defaultSearchLimit = 10;
  static const int defaultPlaylistLimit = 50;

  // UI Settings
  static const SpotifyTheme theme = SpotifyTheme(
    primaryColor: 0xFF1DB954, // Spotify green
    secondaryColor: 0xFF1ed760, // Spotify light green
    backgroundColor: 0xFFf9fafb, // Light gray
    textColor: 0xFF1f2937, // Dark gray
  );
}

/// Theme configuration class for Spotify integration UI.
/// Defines the color scheme and visual styling used throughout
/// the Spotify integration interface.
///
/// Colors are stored as 32-bit integers (0xAARRGGBB format)
/// where:
/// - AA: Alpha channel (opacity)
/// - RR: Red channel
/// - GG: Green channel
/// - BB: Blue channel
///
/// Default Theme:
/// - Primary: Spotify Green (#1DB954)
/// - Secondary: Light Green (#1ED760)
/// - Background: Light Gray (#F9FAFB)
/// - Text: Dark Gray (#1F2937)
///
/// Usage:
/// ```dart
/// final theme = SpotifyConfig.theme;
/// Color primaryColor = Color(theme.primaryColor);
/// ```
class SpotifyTheme {
  /// Primary brand color (Spotify Green)
  /// Used for main buttons and important UI elements
  final int primaryColor;

  /// Secondary brand color (Light Green)
  /// Used for hover states and accents
  final int secondaryColor;

  /// Background color (Light Gray)
  /// Used for main content areas
  final int backgroundColor;

  /// Text color (Dark Gray)
  /// Used for primary content text
  final int textColor;

  /// Creates a new SpotifyTheme instance
  /// All colors must be provided as 32-bit integers
  const SpotifyTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
  });
}

// Quick Setup Instructions
const String setupInstructions = '''
🎵 StudyPals Spotify Integration - Quick Setup

1. 📋 Prerequisites:
   - Flutter SDK installed
   - Spotify Developer Account (https://developer.spotify.com/)

2. 🔑 Get Spotify Credentials:
   - Go to https://developer.spotify.com/dashboard/applications
   - Click "Create App"
   - Fill in app details
   - Copy Client ID and Client Secret
   - Add Redirect URI: ${SpotifyConfig.redirectUri}

3. 📁 File Setup:
   - spotify_integration_screen.dart (main UI)
   - spotify_service.dart (API service)
   - spotify_config.dart (configuration)

4. 🚀 Run the Application:
   - flutter pub get
   - flutter run

5. ✅ Test Connection:
   - Tap "Connect Spotify Account"
   - Authorize the app
   - View your playlists and search music

📞 Support:
   - Check console for errors
   - Verify Spotify app settings
   - Ensure redirect URI matches exactly
''';
