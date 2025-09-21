/**
 * StudyPals Spotify Integration - Provider
 * 
 * This provider manages the state for Spotify integration functionality.
 * It coordinates between the UI and the Spotify service.
 * 
 * @author StudyPals Team
 * @version 1.0.0
 */

import 'package:flutter/foundation.dart';
import '../models/spotify_models.dart';
import '../services/spotify_service.dart';

enum SpotifyConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class SpotifyProvider with ChangeNotifier {
  final SpotifyService _spotifyService = SpotifyService();

  SpotifyConnectionState _connectionState = SpotifyConnectionState.disconnected;
  SpotifyUser? _currentUser;
  List<SpotifyPlaylist> _playlists = [];
  List<SpotifyTrack> _currentTracks = [];
  List<SpotifyTrack> _searchResults = [];
  SpotifyPlaylist? _selectedPlaylist;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  SpotifyConnectionState get connectionState => _connectionState;
  SpotifyUser? get currentUser => _currentUser;
  List<SpotifyPlaylist> get playlists => _playlists;
  List<SpotifyTrack> get currentTracks => _currentTracks;
  List<SpotifyTrack> get searchResults => _searchResults;
  SpotifyPlaylist? get selectedPlaylist => _selectedPlaylist;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _spotifyService.isAuthenticated;

  /// Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _spotifyService.initialize();

      if (_spotifyService.isAuthenticated) {
        _connectionState = SpotifyConnectionState.connected;
        await _loadUserData();
      } else {
        _connectionState = SpotifyConnectionState.disconnected;
      }
    } catch (e) {
      _setError('Failed to initialize Spotify: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Connect to Spotify
  Future<void> connect() async {
    _setLoading(true);
    _connectionState = SpotifyConnectionState.connecting;
    _clearError();
    notifyListeners();

    try {
      await _spotifyService.launchAuthFlow();
      // Note: The actual token exchange will happen when the user returns from OAuth
      // This is typically handled by a callback or deep link
    } catch (e) {
      _setError('Failed to connect to Spotify: $e');
      _connectionState = SpotifyConnectionState.error;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle OAuth callback with authorization code
  Future<void> handleAuthCallback(String code) async {
    _setLoading(true);
    _connectionState = SpotifyConnectionState.connecting;
    _clearError();
    notifyListeners();

    try {
      await _spotifyService.exchangeCodeForTokens(code);
      _connectionState = SpotifyConnectionState.connected;
      await _loadUserData();
    } catch (e) {
      _setError('Failed to complete authentication: $e');
      _connectionState = SpotifyConnectionState.error;
    } finally {
      _setLoading(false);
    }
  }

  /// Load user data and playlists
  Future<void> _loadUserData() async {
    try {
      _currentUser = await _spotifyService.getCurrentUser();
      await _loadPlaylists();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user data: $e');
    }
  }

  /// Load user's playlists
  Future<void> _loadPlaylists() async {
    try {
      _playlists = await _spotifyService.getUserPlaylists();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load playlists: $e');
    }
  }

  /// Select a playlist and load its tracks
  Future<void> selectPlaylist(SpotifyPlaylist playlist) async {
    _selectedPlaylist = playlist;
    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      _currentTracks = await _spotifyService.getPlaylistTracks(playlist.id);
    } catch (e) {
      _setError('Failed to load playlist tracks: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Search for tracks
  Future<void> searchTracks(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      _searchResults = await _spotifyService.searchTracks(query);
    } catch (e) {
      _setError('Search failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new playlist
  Future<void> createPlaylist(String name,
      {String? description, bool isPublic = false}) async {
    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      final newPlaylist = await _spotifyService.createPlaylist(
        name,
        description: description,
        isPublic: isPublic,
      );

      _playlists.add(newPlaylist);
      notifyListeners();
    } catch (e) {
      _setError('Failed to create playlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add tracks to a playlist
  Future<void> addTracksToPlaylist(
      String playlistId, List<SpotifyTrack> tracks) async {
    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      final trackUris =
          tracks.map((track) => 'spotify:track:${track.id}').toList();
      await _spotifyService.addTracksToPlaylist(playlistId, trackUris);

      // Refresh playlists to update track counts
      await _loadPlaylists();
    } catch (e) {
      _setError('Failed to add tracks to playlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Play a track (placeholder for future implementation)
  Future<void> playTrack(SpotifyTrack track) async {
    // This would integrate with Spotify's Web Playback SDK
    // For now, just show a message or handle the preview URL
    if (track.previewUrl != null) {
      // Handle preview playback
      debugPrint('Playing preview: ${track.name} by ${track.artistNames}');
    } else {
      _setError('Preview not available for this track');
    }
  }

  /// Disconnect from Spotify
  Future<void> disconnect() async {
    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      await _spotifyService.disconnect();

      _connectionState = SpotifyConnectionState.disconnected;
      _currentUser = null;
      _playlists = [];
      _currentTracks = [];
      _searchResults = [];
      _selectedPlaylist = null;
    } catch (e) {
      _setError('Failed to disconnect: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// Refresh data
  Future<void> refresh() async {
    if (isAuthenticated) {
      await _loadUserData();
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _connectionState = SpotifyConnectionState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    if (_connectionState == SpotifyConnectionState.error) {
      _connectionState = SpotifyConnectionState.disconnected;
    }
  }
}
