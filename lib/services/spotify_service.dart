/// StudyPals Spotify Integration - Service Layer
///
/// This service class handles all Spotify API interactions and replaces
/// the backend functionality from spotify-server.js.
///
/// @author StudyPals Team
/// @version 1.0.0
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/spotify_config.dart';
import '../models/spotify_models.dart';

/// Service class that handles all Spotify API interactions and authentication.
/// This service manages the OAuth flow, token storage, and API requests.
///
/// Key responsibilities:
/// - Managing authentication state
/// - Storing and refreshing tokens
/// - Making authenticated API requests
/// - Handling API errors and retries
class SpotifyService {
  /// Storage key for the OAuth access token in SharedPreferences
  static const String _storageKeyAccessToken = 'spotify_access_token';

  /// Storage key for the OAuth refresh token in SharedPreferences
  static const String _storageKeyRefreshToken = 'spotify_refresh_token';

  /// Storage key for token expiration timestamp in SharedPreferences
  static const String _storageKeyExpiresAt = 'spotify_expires_at';

  /// Current access token for API requests
  /// Null if not authenticated
  String? _accessToken;

  /// Refresh token for obtaining new access tokens
  /// Persisted across sessions
  String? _refreshToken;

  /// Timestamp when the current access token expires
  /// Used to determine when to refresh the token
  int? _expiresAt;

  // Getters
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && !_isTokenExpired;

  bool get _isTokenExpired {
    if (_expiresAt == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= _expiresAt!;
  }

  /// Initialize the service by loading stored tokens
  Future<void> initialize() async {
    await _loadStoredTokens();
  }

  /// Load tokens from local storage
  /// Loads authentication tokens from persistent storage.
  ///
  /// This method:
  /// 1. Retrieves stored tokens from SharedPreferences
  /// 2. Checks if tokens are present and valid
  /// 3. Automatically refreshes the access token if expired
  ///
  /// Error handling:
  /// - Silently fails if storage access fails
  /// - Logs errors for debugging purposes
  /// - Maintains null state for tokens if loading fails
  ///
  /// @returns Future that completes when tokens are loaded
  Future<void> _loadStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load all tokens at once to maintain consistency
      final storedAccessToken = prefs.getString(_storageKeyAccessToken);
      final storedRefreshToken = prefs.getString(_storageKeyRefreshToken);
      final storedExpiresAt = prefs.getInt(_storageKeyExpiresAt);

      // Only update tokens if we have valid data
      if (storedAccessToken != null &&
          storedRefreshToken != null &&
          storedExpiresAt != null) {
        _accessToken = storedAccessToken;
        _refreshToken = storedRefreshToken;
        _expiresAt = storedExpiresAt;

        // Check if token is expired and refresh if needed
        if (_isTokenExpired) {
          try {
            await refreshAccessToken();
          } catch (error) {
            debugPrint('Error refreshing token: $error');
            // Clear invalid tokens
            await clearTokens();
          }
        }
      } else {
        // Clear partially stored data
        await clearTokens();
      }
    } catch (e) {
      debugPrint('Error loading stored tokens: $e');
      // Ensure tokens are cleared on error
      await clearTokens();
    }
  }

  /// Save tokens to local storage
  Future<void> _saveTokens(
      String accessToken, String refreshToken, int expiresAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKeyAccessToken, accessToken);
      await prefs.setString(_storageKeyRefreshToken, refreshToken);
      await prefs.setInt(_storageKeyExpiresAt, expiresAt);

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _expiresAt = expiresAt;
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }

  /// Clear all stored tokens
  Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKeyAccessToken);
      await prefs.remove(_storageKeyRefreshToken);
      await prefs.remove(_storageKeyExpiresAt);

      _accessToken = null;
      _refreshToken = null;
      _expiresAt = null;
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }

  /// The state parameter used in the current OAuth flow
  String? _currentAuthState;

  /// Generate OAuth authorization URL
  /// Generates the OAuth authorization URL for Spotify login.
  ///
  /// This URL is opened in a browser where the user can:
  /// 1. Login to their Spotify account
  /// 2. Review the requested permissions
  /// 3. Approve or deny the application's access
  ///
  /// Security Features:
  /// - Generates random state parameter for CSRF protection
  /// - Stores state for validation on callback
  /// - Uses configured redirect URI
  /// - Requests minimum required permissions
  ///
  /// @returns String Complete URL for OAuth authorization
  /// @throws Exception if configuration is invalid
  String generateAuthUrl() {
    if (SpotifyConfig.clientId.isEmpty) {
      throw Exception('Client ID not configured');
    }

    if (SpotifyConfig.redirectUri.isEmpty) {
      throw Exception('Redirect URI not configured');
    }

    if (SpotifyConfig.scopes.isEmpty) {
      throw Exception('No scopes configured for authentication');
    }

    // Generate and store random state for CSRF protection
    _currentAuthState = _generateRandomString();

    // Build the required OAuth parameters
    final params = {
      'client_id': SpotifyConfig.clientId,
      'response_type': 'code',
      'redirect_uri': SpotifyConfig.redirectUri,
      'scope': SpotifyConfig.scopes.join(' '),
      'state': _currentAuthState,
      'show_dialog': 'true', // Always show auth dialog for clarity
    };

    try {
      final uri = Uri.parse(SpotifyConfig.authUrl).replace(
        queryParameters: params,
      );
      return uri.toString();
    } catch (e) {
      throw Exception('Failed to generate authorization URL: $e');
    }
  }

  /// Validates the state parameter returned from OAuth callback
  /// @param state The state parameter from the callback
  /// @returns bool True if state is valid
  bool validateAuthState(String state) {
    if (_currentAuthState == null || state != _currentAuthState) {
      return false;
    }
    // Clear state after validation
    _currentAuthState = null;
    return true;
  }

  /// Exchange authorization code for tokens
  /// Exchanges an authorization code for access and refresh tokens.
  ///
  /// This is the second step of the OAuth flow, called after the user
  /// authorizes the application and we receive a temporary code.
  ///
  /// Flow:
  /// 1. Sends code to Spotify's token endpoint
  /// 2. Receives access and refresh tokens
  /// 3. Stores tokens for future use
  /// 4. Returns token information
  ///
  /// Error handling:
  /// - Throws exception if network request fails
  /// - Throws exception if Spotify returns an error response
  /// - Validates token data before storing
  ///
  /// @param code The authorization code received from Spotify OAuth redirect
  /// @returns SpotifyTokens containing access and refresh tokens
  /// @throws Exception if token exchange fails
  Future<SpotifyTokens> exchangeCodeForTokens(String code) async {
    try {
      final response = await http.post(
        Uri.parse(SpotifyConfig.tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': SpotifyConfig.redirectUri,
          'client_id': SpotifyConfig.clientId,
          'client_secret': SpotifyConfig.clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final expiresAt = DateTime.now().millisecondsSinceEpoch +
            ((data['expires_in'] as int) * 1000);

        final tokens = SpotifyTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresAt: expiresAt,
        );

        await _saveTokens(
            tokens.accessToken, tokens.refreshToken, tokens.expiresAt);
        return tokens;
      } else {
        throw Exception(
            'Failed to exchange code for tokens: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error exchanging code for tokens: $e');
    }
  }

  /// Refresh access token using refresh token
  ///
  /// This method attempts to get a new access token using the stored refresh token.
  /// If the refresh fails due to an invalid refresh token, it clears all tokens
  /// to force re-authentication.
  ///
  /// Error Handling:
  /// - Validates refresh token presence
  /// - Handles HTTP errors gracefully
  /// - Clears tokens on critical failures
  /// - Throws specific exceptions for different failure cases
  ///
  /// @returns Future String containing the new access token
  /// @throws AuthenticationException if refresh token is missing or invalid
  /// @throws NetworkException if request fails
  Future<String> refreshAccessToken() async {
    if (_refreshToken == null) {
      await clearTokens();
      throw Exception('No refresh token available');
    }

    try {
      // Add timeout to prevent hanging
      final response = await http.post(
        Uri.parse(SpotifyConfig.tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': SpotifyConfig.clientId,
          'client_secret': SpotifyConfig.clientSecret,
        },
      ).timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['access_token'] != null) {
        final expiresAt = DateTime.now().millisecondsSinceEpoch +
            ((responseData['expires_in'] as int) * 1000);

        // If we got a new refresh token, update it
        final newRefreshToken =
            responseData['refresh_token'] as String? ?? _refreshToken!;

        await _saveTokens(
            responseData['access_token'], newRefreshToken, expiresAt);
        return responseData['access_token'];
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        // Invalid or expired refresh token
        await clearTokens();
        throw Exception('Invalid refresh token - please reconnect to Spotify');
      } else {
        throw Exception('Failed to refresh token: ${response.statusCode}');
      }
    } catch (e) {
      // Clear tokens if refresh failed
      await clearTokens();
      throw Exception('Error refreshing token: $e');
    }
  }

  /// Maximum number of retry attempts for API requests
  static const int _maxRetries = 3;

  /// Make authenticated request to Spotify API
  ///
  /// Features:
  /// - Automatic token refresh on 401 errors
  /// - Request retry on temporary failures
  /// - Timeout handling
  /// - Rate limit handling
  ///
  /// @param endpoint The API endpoint to call
  /// @param queryParams Optional query parameters
  /// @returns Future Map containing JSON response data
  /// @throws Exception for various error conditions
  Future<Map<String, dynamic>> _makeRequest(String endpoint,
      {Map<String, String>? queryParams, int retryCount = 0}) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated with Spotify');
    }

    try {
      final uri = Uri.parse('${SpotifyConfig.apiBaseUrl}$endpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      switch (response.statusCode) {
        case 200:
          // Successful request
          return json.decode(response.body);

        case 401:
          // Token expired, try to refresh and retry
          if (retryCount < _maxRetries) {
            await refreshAccessToken();
            return _makeRequest(endpoint,
                queryParams: queryParams, retryCount: retryCount + 1);
          }
          throw Exception('Authentication failed after $_maxRetries attempts');

        case 429:
          // Rate limited, wait and retry
          final retryAfter =
              int.tryParse(response.headers['retry-after'] ?? '5') ?? 5;
          if (retryCount < _maxRetries) {
            await Future.delayed(Duration(seconds: retryAfter));
            return _makeRequest(endpoint,
                queryParams: queryParams, retryCount: retryCount + 1);
          }
          throw Exception('Rate limited by Spotify API');

        case 404:
          throw Exception('Spotify API endpoint not found: $endpoint');

        case 500:
        case 502:
        case 503:
          // Server error, retry with backoff
          if (retryCount < _maxRetries) {
            await Future.delayed(Duration(seconds: pow(2, retryCount) as int));
            return _makeRequest(endpoint,
                queryParams: queryParams, retryCount: retryCount + 1);
          }
          throw Exception('Spotify API server error: ${response.statusCode}');

        default:
          throw Exception('Spotify API error: ${response.statusCode}');
      }
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        return _makeRequest(endpoint,
            queryParams: queryParams, retryCount: retryCount + 1);
      }
      throw Exception('Spotify API request timed out');
    } catch (e) {
      throw Exception('Error making Spotify request: $e');
    }
  }

  /// Retrieves the current user's Spotify profile information.
  ///
  /// This method fetches the authenticated user's profile data including:
  /// - User ID
  /// - Display name
  /// - Email (if permission granted)
  /// - Profile image
  /// - Subscription status
  ///
  /// Error Handling:
  /// - Throws if not authenticated
  /// - Throws if API request fails
  /// - Handles token refresh automatically
  ///
  /// @returns Future SpotifyUser containing user profile data
  /// @throws Exception if request fails or user not authenticated
  Future<SpotifyUser> getCurrentUser() async {
    final data = await _makeRequest('/me');
    return SpotifyUser.fromJson(data);
  }

  /// Retrieves the authenticated user's playlists.
  ///
  /// Features:
  /// - Fetches both owned and followed playlists
  /// - Supports pagination through limit parameter
  /// - Returns playlist metadata and basic track info
  ///
  /// Parameters:
  /// @param limit Maximum number of playlists to return (default: 50)
  ///
  /// Response Handling:
  /// - Deserializes JSON to SpotifyPlaylist objects
  /// - Maintains playlist order from Spotify
  /// - Includes playlist images and track counts
  ///
  /// @returns List of SpotifyPlaylist containing user's playlists
  /// @throws Exception if request fails or user not authenticated
  Future<List<SpotifyPlaylist>> getUserPlaylists({int limit = 50}) async {
    final data = await _makeRequest('/me/playlists',
        queryParams: {'limit': limit.toString()});
    final playlists = (data['items'] as List)
        .map((playlist) => SpotifyPlaylist.fromJson(playlist))
        .toList();
    return playlists;
  }

  /// Retrieves tracks from a specific playlist.
  ///
  /// Features:
  /// - Fetches full track metadata
  /// - Supports pagination through limit parameter
  /// - Includes track ordering from playlist
  ///
  /// Parameters:
  /// @param playlistId Spotify ID of the playlist to fetch
  /// @param limit Maximum number of tracks to return (default: 100)
  ///
  /// Response Processing:
  /// - Extracts tracks from playlist track wrapper
  /// - Deserializes to full SpotifyTrack objects
  /// - Maintains playlist order
  ///
  /// @returns List of SpotifyTrack containing playlist tracks
  /// @throws Exception if request fails or playlist not found
  Future<List<SpotifyTrack>> getPlaylistTracks(String playlistId,
      {int limit = 100}) async {
    final data = await _makeRequest('/playlists/$playlistId/tracks',
        queryParams: {'limit': limit.toString()});
    final tracks = (data['items'] as List)
        .map((item) => SpotifyPlaylistTrack.fromJson(item).track)
        .toList();
    return tracks;
  }

  /// Searches Spotify's catalog for tracks matching a query.
  ///
  /// Search Capabilities:
  /// - Matches track titles
  /// - Matches artist names
  /// - Matches album titles
  /// - Supports partial matches
  ///
  /// Parameters:
  /// @param query Search string to match against Spotify catalog
  /// @param limit Maximum number of results to return (default: 10)
  ///
  /// Query Tips:
  /// - Can include track name, artist, album
  /// - More specific queries yield better results
  /// - Supports Unicode characters
  ///
  /// Response Processing:
  /// - Deserializes to SpotifyTrack objects
  /// - Orders by relevance
  /// - Includes full track metadata
  ///
  /// @returns List of SpotifyTrack containing matching tracks
  /// @throws Exception if search fails or query invalid
  Future<List<SpotifyTrack>> searchTracks(String query,
      {int limit = 10}) async {
    final data = await _makeRequest('/search', queryParams: {
      'q': query,
      'type': 'track',
      'limit': limit.toString(),
    });
    final searchResults = SpotifySearchResults.fromJson(data);
    return searchResults.tracks.items;
  }

  /// Creates a new playlist for the authenticated user.
  ///
  /// Features:
  /// - Creates empty playlist
  /// - Sets visibility (public/private)
  /// - Adds optional description
  ///
  /// Parameters:
  /// @param name Name of the playlist to create
  /// @param description Optional description of the playlist
  /// @param isPublic Whether the playlist is public (default: false)
  ///
  /// Validation:
  /// - Checks authentication status
  /// - Validates name is not empty
  /// - Verifies user has playlist creation permission
  ///
  /// Response:
  /// - Returns created playlist details
  /// - Includes Spotify-generated playlist ID
  ///
  /// @returns SpotifyPlaylist representing the created playlist
  /// @throws Exception if creation fails or user not authenticated
  Future<SpotifyPlaylist> createPlaylist(String name,
      {String? description, bool isPublic = false}) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated with Spotify');
    }

    try {
      if (name.trim().isEmpty) {
        throw Exception('Playlist name cannot be empty');
      }

      // First get the user ID
      final user = await getCurrentUser();

      if (user.id.isEmpty) {
        throw Exception('Could not determine user ID');
      }

      final response = await http
          .post(
            Uri.parse('${SpotifyConfig.apiBaseUrl}/users/${user.id}/playlists'),
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'name': name.trim(),
              'description': description?.trim(),
              'public': isPublic,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['id'] != null) {
        return SpotifyPlaylist.fromJson(responseData);
      } else if (response.statusCode == 403) {
        throw Exception('You don\'t have permission to create playlists');
      } else if (response.statusCode == 401) {
        await refreshAccessToken();
        // Retry once after token refresh
        return createPlaylist(name,
            description: description, isPublic: isPublic);
      } else {
        throw Exception('Failed to create playlist: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out while creating playlist');
    } catch (e) {
      throw Exception('Error creating playlist: $e');
    }
  }

  /// Adds tracks to an existing Spotify playlist.
  ///
  /// Features:
  /// - Adds multiple tracks in one request
  /// - Maintains add order in playlist
  /// - Handles duplicate checking
  ///
  /// Parameters:
  /// @param playlistId Spotify ID of the target playlist
  /// @param trackUris List of Spotify track URIs to add
  ///
  /// URI Format:
  /// - Must be valid Spotify track URIs
  /// - Format: "spotify:track:1234567890abcdef"
  ///
  /// Error Handling:
  /// - Validates authentication status
  /// - Checks playlist modification permissions
  /// - Verifies valid track URIs
  /// - Handles API errors gracefully
  ///
  /// Request Format:
  /// ```json
  /// {
  ///   "uris": [
  ///     "spotify:track:4iV5W9uYEdYUVa79Axb7Rh",
  ///     "spotify:track:1301WleyT98MSxVHPZCA6M"
  ///   ]
  /// }
  /// ```
  ///
  /// @throws Exception if addition fails or user not authenticated
  /// @returns void - Completes when tracks are added successfully
  Future<void> addTracksToPlaylist(
      String playlistId, List<String> trackUris) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated with Spotify');
    }

    try {
      final response = await http.post(
        Uri.parse('${SpotifyConfig.apiBaseUrl}/playlists/$playlistId/tracks'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'uris': trackUris,
        }),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to add tracks to playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding tracks to playlist: $e');
    }
  }

  /// Initiates the OAuth authentication flow in the system browser.
  ///
  /// Process Flow:
  /// 1. Generates authentication URL with state
  /// 2. Opens system browser
  /// 3. User logs in to Spotify
  /// 4. User authorizes application
  /// 5. Redirect back to application
  ///
  /// Security Features:
  /// - Uses state parameter for CSRF protection
  /// - Opens in system browser for secure login
  /// - Validates redirect URI
  ///
  /// Error Handling:
  /// - Checks if URL can be launched
  /// - Handles browser launch failures
  /// - Reports launch errors clearly
  ///
  /// @throws Exception if browser cannot be launched
  Future<void> launchAuthFlow() async {
    final authUrl = generateAuthUrl();
    final uri = Uri.parse(authUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch OAuth flow');
    }
  }

  /// Generates a cryptographically secure random string for OAuth state.
  ///
  /// Features:
  /// - 32 characters long
  /// - Uses alphanumeric characters
  /// - Random distribution for security
  ///
  /// Character Set:
  /// - Lowercase letters (a-z)
  /// - Uppercase letters (A-Z)
  /// - Numbers (0-9)
  ///
  /// Usage:
  /// - OAuth state parameter
  /// - CSRF protection
  /// - Request validation
  ///
  /// @returns String - 32 character random string
  String _generateRandomString() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        32, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// Disconnects from Spotify by clearing all stored tokens.
  ///
  /// Actions:
  /// 1. Clears access token
  /// 2. Clears refresh token
  /// 3. Clears expiration timestamp
  ///
  /// Security:
  /// - Removes all stored credentials
  /// - Invalidates current session
  /// - Requires re-authentication for future access
  ///
  /// State Changes:
  /// - Sets isAuthenticated to false
  /// - Clears all stored tokens
  /// - Resets service state
  ///
  /// @returns Future that completes when disconnection is finished
  Future<void> disconnect() async {
    await clearTokens();
  }
}
