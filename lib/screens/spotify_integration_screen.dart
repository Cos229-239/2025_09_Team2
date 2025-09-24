/// StudyPals Spotify Integration - Main Screen
///
/// This screen provides a complete Spotify integration interface allowing users to:
/// - Connect their Spotify account
/// - View and manage playlists
/// - Search and play tracks
/// - Create new playlists
/// - Manage their Spotify connection
///
/// Architecture:
/// - Uses Provider pattern for state management
/// - Implements responsive layout for different screen sizes
/// - Handles authentication flow through SpotifyProvider
/// - Manages user interface states (connecting, connected, error)
///
/// Key Components:
/// - Connection management UI
/// - Playlist browser
/// - Track listing
/// - Search interface
/// - User profile display
///
/// State Management:
/// - Tracks authentication state
/// - Manages playlist selection
/// - Handles search results
/// - Maintains UI loading states
///
/// @author StudyPals Team
/// @version 1.0.0
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/spotify_provider.dart';
import '../models/spotify_models.dart';
import '../config/spotify_config.dart';

class SpotifyIntegrationScreen extends StatefulWidget {
  const SpotifyIntegrationScreen({super.key});

  @override
  State<SpotifyIntegrationScreen> createState() =>
      _SpotifyIntegrationScreenState();
}

/// State management class for the Spotify integration screen.
/// Handles user interactions, UI state, and communication with SpotifyProvider.
class _SpotifyIntegrationScreenState extends State<SpotifyIntegrationScreen> {
  /// Controller for the search input field
  /// Used to manage text input for track searching
  final TextEditingController _searchController = TextEditingController();

  /// Controller for playlist name input when creating new playlists
  final TextEditingController _playlistNameController = TextEditingController();

  /// Controller for playlist description input when creating new playlists
  final TextEditingController _playlistDescriptionController =
      TextEditingController();

  /// Initializes the screen state and Spotify connection.
  ///
  /// Uses WidgetsBinding.instance.addPostFrameCallback to ensure the context
  /// is fully built before attempting to initialize the SpotifyProvider.
  /// This prevents potential null context errors during initialization.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotifyProvider>().initialize();
    });
  }

  /// Cleans up resources when the screen is disposed.
  ///
  /// Properly disposes of all TextEditingControllers to prevent memory leaks
  /// and ensure proper cleanup of resources. This is especially important
  /// when dealing with text input fields and controllers.
  @override
  void dispose() {
    _searchController.dispose();
    _playlistNameController.dispose();
    _playlistDescriptionController.dispose();
    super.dispose();
  }

  /// Builds the main screen UI structure.
  ///
  /// The screen layout consists of:
  /// - AppBar with title and connection status
  /// - Main body that changes based on connection state
  /// - Conditional loading indicators
  ///
  /// Uses Consumer(SpotifyProvider) to react to state changes in:
  /// - Connection status
  /// - Authentication state
  /// - Loading state
  ///
  /// The UI updates automatically when the provider state changes,
  /// showing appropriate screens for each state.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(SpotifyConfig.theme.backgroundColor),
      appBar: AppBar(
        title: Row(
          children: [
            // Spotify icon with themed color
            Icon(Icons.music_note,
                color: Color(SpotifyConfig.theme.primaryColor)),
            const SizedBox(width: 8),
            const Text('StudyPals - Spotify Integration'),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Consumer<SpotifyProvider>(
            builder: (context, provider, child) {
              if (provider.isAuthenticated) {
                return TextButton.icon(
                  onPressed: () => _showDisconnectDialog(context, provider),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Disconnect',
                      style: TextStyle(color: Colors.red)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<SpotifyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                      color: Color(SpotifyConfig.theme.primaryColor)),
                  const SizedBox(height: 16),
                  const Text('Loading...'),
                ],
              ),
            );
          }

          switch (provider.connectionState) {
            case SpotifyConnectionState.disconnected:
              return _buildConnectionScreen(context, provider);
            case SpotifyConnectionState.connecting:
              return _buildConnectingScreen(context, provider);
            case SpotifyConnectionState.connected:
              return _buildDashboardScreen(context, provider);
            case SpotifyConnectionState.error:
              return _buildErrorScreen(context, provider);
          }
        },
      ),
    );
  }

  /// Builds the initial connection screen shown when not connected to Spotify.
  ///
  /// This screen provides:
  /// - Visual explanation of Spotify integration benefits
  /// - Connect button to initiate OAuth flow
  /// - Error message display if connection failed
  ///
  /// Layout:
  /// - Scrollable container for responsive design
  /// - Centered content with consistent padding
  /// - Conditional error message display
  ///
  /// @param context The build context for theme and navigation
  /// @param provider The SpotifyProvider instance for state management
  /// @returns Widget containing the connection screen UI
  Widget _buildConnectionScreen(
      BuildContext context, SpotifyProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          _buildSpotifyCard(context),
          const SizedBox(height: 24),
          // Conditionally show error message if present
          if (provider.errorMessage != null) ...[
            _buildErrorMessage(provider.errorMessage!),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  /// Builds the loading screen shown during Spotify connection process.
  ///
  /// Features:
  /// - Centered loading indicator with Spotify brand color
  /// - Loading message for user feedback
  /// - Simple, clean layout focusing on the connection process
  ///
  /// @param context Build context for theme access
  /// @param provider SpotifyProvider instance managing connection state
  /// @returns Widget displaying connection progress UI
  Widget _buildConnectingScreen(
      BuildContext context, SpotifyProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
              color: Color(SpotifyConfig.theme.primaryColor)),
          const SizedBox(height: 16),
          const Text('Connecting to Spotify...'),
        ],
      ),
    );
  }

  /// Builds the main dashboard screen shown when successfully connected to Spotify.
  ///
  /// Layout Structure:
  /// - Scrollable container for responsive design
  /// - User information at the top
  /// - Search functionality section
  /// - Two-column layout for playlists and tracks
  ///
  /// Components:
  /// 1. User Info Card:
  ///    - Profile information
  ///    - Account status
  /// 2. Search Section:
  ///    - Search input
  ///    - Results display
  /// 3. Content Grid:
  ///    - Playlists column (1/3 width)
  ///    - Tracks column (2/3 width)
  ///
  /// Spacing:
  /// - Consistent 16px padding
  /// - 16px gaps between major sections
  ///
  /// @param context Build context for theming
  /// @param provider SpotifyProvider for data and actions
  /// @returns Widget containing the complete dashboard interface
  Widget _buildDashboardScreen(BuildContext context, SpotifyProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          _buildUserInfoCard(context, provider),
          const SizedBox(height: 16),

          // Search Section
          _buildSearchSection(context, provider),
          const SizedBox(height: 16),

          // Main Content Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Playlists Column (1/3 width)
              Expanded(
                flex: 1,
                child: _buildPlaylistsColumn(context, provider),
              ),
              const SizedBox(width: 16),

              // Tracks Column (2/3 width)
              Expanded(
                flex: 2,
                child: _buildTracksColumn(context, provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the error screen shown when Spotify connection fails.
  ///
  /// Features:
  /// - Clear error icon and message display
  /// - Error details from provider
  /// - Retry button to attempt reconnection
  ///
  /// Visual Design:
  /// - Centered layout with proper spacing
  /// - Red error icon for clear status indication
  /// - Themed text styles for hierarchy
  ///
  /// User Actions:
  /// - Retry button triggers provider.initialize()
  /// - Properly handles both known and unknown errors
  ///
  /// @param context Build context for theme access
  /// @param provider SpotifyProvider instance containing error details
  /// @returns Widget displaying error state and retry option
  Widget _buildErrorScreen(BuildContext context, SpotifyProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.initialize(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotifyCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(SpotifyConfig.theme.primaryColor),
            Color(SpotifyConfig.theme.secondaryColor),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Color(SpotifyConfig.theme.primaryColor).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.music_note, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            '🎵 Connect to Spotify',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect your Spotify account to access your playlists, search music, and manage your library.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<SpotifyProvider>().connect(),
            icon: const Icon(Icons.music_note),
            label: const Text('Connect Spotify Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(SpotifyConfig.theme.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a card displaying the connected Spotify user's information.
  ///
  /// Features:
  /// - User profile image (with fallback icon)
  /// - Display name and email
  /// - Quick action to create new playlist
  ///
  /// Visual Elements:
  /// - Circular avatar (30px radius)
  /// - Themed text styles for name and email
  /// - Add playlist button with tooltip
  ///
  /// Null Safety:
  /// - Handles null user case with empty widget
  /// - Safely handles missing images and email
  ///
  /// @param context Build context for theming
  /// @param provider SpotifyProvider containing user data
  /// @returns Widget showing user info or empty widget if no user
  Widget _buildUserInfoCard(BuildContext context, SpotifyProvider provider) {
    final user = provider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar with fallback
            CircleAvatar(
              radius: 30,
              backgroundImage: user.images?.isNotEmpty == true
                  ? CachedNetworkImageProvider(user.images!.first.url!)
                  : null,
              child: user.images?.isEmpty != false
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            // User information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${user.displayName ?? 'User'}!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (user.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Create playlist action button
            IconButton(
              onPressed: () => _showCreatePlaylistDialog(context, provider),
              icon: const Icon(Icons.add),
              tooltip: 'Create Playlist',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the search section of the dashboard allowing users to find tracks.
  ///
  /// Features:
  /// - Search input field with hint text
  /// - Search button with icon
  /// - Dynamic search results display
  ///
  /// User Interactions:
  /// - Text input with onSubmitted support
  /// - Button click to trigger search
  /// - Results update automatically through provider
  ///
  /// Layout:
  /// - Card container with padding
  /// - Row layout for input and button
  /// - Conditional results display
  ///
  /// @param context Build context for theme and styling
  /// @param provider SpotifyProvider for search functionality
  /// @returns Widget containing search interface and results
  Widget _buildSearchSection(BuildContext context, SpotifyProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Music',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for songs, artists, or albums...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (query) => provider.searchTracks(query),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () =>
                      provider.searchTracks(_searchController.text),
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ],
            ),
            if (provider.searchResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSearchResults(context, provider),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the column displaying user's Spotify playlists.
  ///
  /// Features:
  /// - Scrollable list of playlists
  /// - Empty state handling
  /// - Fixed height container
  ///
  /// Visual Design:
  /// - Card container with padding
  /// - Themed title text
  /// - Grey icon for empty state
  ///
  /// Component Structure:
  /// - Title section
  /// - 400px height scrollable area
  /// - Playlist items or empty state message
  ///
  /// States:
  /// - Loading: Handled by parent
  /// - Empty: Shows centered message
  /// - Populated: Scrollable list of items
  ///
  /// @param context Build context for theming
  /// @param provider SpotifyProvider with playlist data
  /// @returns Widget containing playlist list or empty state
  Widget _buildPlaylistsColumn(BuildContext context, SpotifyProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Playlists',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 400,
              child: provider.playlists.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_play,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No playlists found'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = provider.playlists[index];
                        return _buildPlaylistItem(context, provider, playlist);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the column displaying tracks from the selected playlist.
  ///
  /// Features:
  /// - Dynamic title based on selected playlist
  /// - Scrollable track list
  /// - Empty state handling
  ///
  /// Visual Design:
  /// - Card container with padding
  /// - Themed title text
  /// - Grey icon for empty state
  /// - 400px fixed height for content
  ///
  /// States:
  /// - No playlist selected: Shows selection prompt
  /// - Empty playlist: Shows empty message
  /// - Populated: Shows scrollable track list
  ///
  /// @param context Build context for theming
  /// @param provider SpotifyProvider with track data
  /// @returns Widget containing track list or appropriate message
  Widget _buildTracksColumn(BuildContext context, SpotifyProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic title based on selection
            Text(
              provider.selectedPlaylist?.name ?? 'Select a playlist',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 400,
              child: provider.currentTracks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.music_note,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            provider.selectedPlaylist == null
                                ? 'Select a playlist to view tracks'
                                : 'No tracks in this playlist',
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.currentTracks.length,
                      itemBuilder: (context, index) {
                        final track = provider.currentTracks[index];
                        return _buildTrackItem(context, provider, track);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a selectable item representing a Spotify playlist.
  ///
  /// Visual Features:
  /// - Playlist cover image (48x48px)
  /// - Playlist name and track count
  /// - Selection state indication
  /// - Hover feedback via InkWell
  ///
  /// Styling:
  /// - Light green background when selected
  /// - Green border when selected
  /// - Rounded corners (8px)
  /// - Consistent padding (12px)
  ///
  /// Image Handling:
  /// - Uses CachedNetworkImage for efficient loading
  /// - Placeholder and error states with music icon
  /// - Rounded corners on image (4px)
  ///
  /// Text Layout:
  /// - Bold playlist name with ellipsis overflow
  /// - Grey secondary text for track count
  /// - Left-aligned text content
  ///
  /// Interaction:
  /// - Tapping selects the playlist via provider
  /// - Visual feedback on hover
  ///
  /// @param context Build context for theming
  /// @param provider SpotifyProvider for selection handling
  /// @param playlist The playlist to display
  /// @returns Widget displaying playlist information
  Widget _buildPlaylistItem(BuildContext context, SpotifyProvider provider,
      SpotifyPlaylist playlist) {
    final isSelected = provider.selectedPlaylist?.id == playlist.id;

    return InkWell(
      onTap: () => provider.selectPlaylist(playlist),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : null,
          border: isSelected ? Border.all(color: Colors.green[200]!) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Playlist cover image
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: playlist.images?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: playlist.images!.first.url!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note),
                    ),
            ),
            const SizedBox(width: 12),
            // Playlist information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${playlist.tracks.total} tracks',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a list item displaying a Spotify track with playback controls.
  ///
  /// Visual Features:
  /// - Album artwork (48x48px)
  /// - Track title and artists
  /// - Duration display
  /// - Play button
  ///
  /// Layout:
  /// - Horizontal row layout
  /// - Left-aligned album art
  /// - Expanded track info section
  /// - Right-aligned duration and controls
  ///
  /// Styling:
  /// - Rounded corners (8px container, 4px image)
  /// - Consistent padding (12px)
  /// - Typography hierarchy for title and artists
  /// - Grey secondary text for duration
  ///
  /// Image Handling:
  /// - Uses CachedNetworkImage for album art
  /// - Placeholder and error states with music icon
  ///
  /// Interaction:
  /// - Click anywhere to play the track
  /// - Explicit play button with tooltip
  /// - Hover feedback via InkWell
  ///
  /// Text Overflow:
  /// - Single line with ellipsis for title
  /// - Single line with ellipsis for artists
  ///
  /// @param context Build context for theming
  /// @param provider SpotifyProvider for playback control
  /// @param track The track to display
  /// @returns Widget displaying track information and controls
  Widget _buildTrackItem(
      BuildContext context, SpotifyProvider provider, SpotifyTrack track) {
    return InkWell(
      onTap: () => provider.playTrack(track),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Album artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: track.album.images?.isNotEmpty == true
                  ? CachedNetworkImage(
                      imageUrl: track.album.images!.first.url!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note),
                    ),
            ),
            const SizedBox(width: 12),
            // Track information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artistNames,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Track duration
            Text(
              track.durationFormatted,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            // Play button
            IconButton(
              onPressed: () => provider.playTrack(track),
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Play',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the search results section showing matching tracks.
  ///
  /// Features:
  /// - Section title
  /// - List of track items
  /// - Consistent spacing
  ///
  /// Layout:
  /// - Vertical column layout
  /// - Left-aligned content
  /// - Themed title text
  /// - Track items with consistent styling
  ///
  /// @param context Build context for theming
  /// @param provider SpotifyProvider containing search results
  /// @returns Widget displaying search results
  Widget _buildSearchResults(BuildContext context, SpotifyProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...provider.searchResults
            .map((track) => _buildTrackItem(context, provider, track)),
      ],
    );
  }

  /// Builds a styled error message container.
  ///
  /// Visual Design:
  /// - Light red background (50% shade)
  /// - Darker red border (200% shade)
  /// - Dark red text (800% shade)
  /// - Rounded corners (8px radius)
  /// - Consistent padding (12px)
  ///
  /// @param message The error message to display
  /// @returns Widget containing styled error message
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.red[800]),
      ),
    );
  }

  /// Shows a confirmation dialog before disconnecting from Spotify.
  ///
  /// Dialog Features:
  /// - Clear title indicating action
  /// - Confirmation message
  /// - Cancel button (neutral)
  /// - Disconnect button (red, destructive action)
  ///
  /// User Flow:
  /// - Cancel: Dismisses dialog
  /// - Disconnect: Closes dialog and calls provider.disconnect()
  ///
  /// @param context Build context for dialog display
  /// @param provider SpotifyProvider for disconnect action
  void _showDisconnectDialog(BuildContext context, SpotifyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect from Spotify'),
        content:
            const Text('Are you sure you want to disconnect from Spotify?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.disconnect();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog for creating a new Spotify playlist.
  ///
  /// Dialog Features:
  /// - Name input field (required)
  /// - Description input field (optional)
  /// - Cancel and Create actions
  ///
  /// Form Handling:
  /// - Clears input fields on open
  /// - Validates name is not empty
  /// - Trims whitespace from inputs
  /// - Handles optional description
  ///
  /// User Flow:
  /// 1. Clear previous input
  /// 2. Show dialog with form
  /// 3. Validate input on submit
  /// 4. Create playlist through provider
  ///
  /// @param context Build context for dialog display
  /// @param provider SpotifyProvider for playlist creation
  void _showCreatePlaylistDialog(
      BuildContext context, SpotifyProvider provider) {
    // Clear previous input
    _playlistNameController.clear();
    _playlistDescriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name input field
            TextField(
              controller: _playlistNameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Optional description field
            TextField(
              controller: _playlistDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_playlistNameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                provider.createPlaylist(
                  _playlistNameController.text.trim(),
                  description:
                      _playlistDescriptionController.text.trim().isEmpty
                          ? null
                          : _playlistDescriptionController.text.trim(),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
