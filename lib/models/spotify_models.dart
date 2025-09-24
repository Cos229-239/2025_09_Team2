/// StudyPals Spotify Integration - Data Models
///
/// This file contains all the data models for Spotify API responses.
/// These models replace the JavaScript objects used in the HTML file.
///
/// Key Components:
/// - SpotifyUser: Represents a Spotify user profile with their details
/// - SpotifyPlaylist: Represents a playlist with its metadata and tracks
/// - SpotifyTrack: Represents a single track with its details and metadata
/// - SpotifyArtist: Represents an artist with basic information
/// - SpotifyAlbum: Represents an album with its metadata
/// - SpotifyTokens: Manages authentication tokens and their expiration
///
/// Each model class includes:
/// - Constructor for object creation
/// - fromJson factory for deserialization from API responses
/// - toJson method for serialization when needed
/// - Getter methods for computed properties
///
/// Usage:
/// These models are used throughout the application to maintain type safety
/// and provide a consistent interface for Spotify data.
///
/// @author StudyPals Team
/// @version 1.0.0
library;

/// Represents a Spotify user profile containing their basic information and preferences.
///
/// Properties:
/// - id: Unique identifier for the user
/// - displayName: User's display name (can be null)
/// - email: User's email address (can be null if not granted permission)
/// - images: List of profile images in different sizes
/// - country: User's country code
/// - product: User's Spotify subscription level (premium, free, etc.)
class SpotifyUser {
  final String id;
  final String? displayName;
  final String? email;
  final List<SpotifyImage>? images;
  final String? country;
  final String? product;

  SpotifyUser({
    required this.id,
    this.displayName,
    this.email,
    this.images,
    this.country,
    this.product,
  });

  factory SpotifyUser.fromJson(Map<String, dynamic> json) {
    return SpotifyUser(
      id: json['id'] ?? '',
      displayName: json['display_name'],
      email: json['email'],
      images: json['images'] != null
          ? (json['images'] as List)
              .map((i) => SpotifyImage.fromJson(i))
              .toList()
          : null,
      country: json['country'],
      product: json['product'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'images': images?.map((i) => i.toJson()).toList(),
      'country': country,
      'product': product,
    };
  }
}

/// Represents an image resource from Spotify's API.
/// Images can be album covers, artist photos, or user profile pictures.
class SpotifyImage {
  /// Direct URL to the image resource
  /// Can be null if image is not available
  final String? url;

  /// Height of the image in pixels
  /// Spotify usually provides multiple sizes
  final int? height;

  /// Width of the image in pixels
  /// Spotify usually provides multiple sizes
  final int? width;

  /// Creates a new SpotifyImage instance
  /// All parameters are optional as some images might not have complete metadata
  SpotifyImage({
    this.url,
    this.height,
    this.width,
  });

  factory SpotifyImage.fromJson(Map<String, dynamic> json) {
    return SpotifyImage(
      url: json['url'],
      height: json['height'],
      width: json['width'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'height': height,
      'width': width,
    };
  }
}

/// Represents a Spotify playlist with its metadata and tracks information.
/// Playlists can be user-created or Spotify-curated collections of tracks.
class SpotifyPlaylist {
  /// Unique identifier for the playlist
  final String id;

  /// Display name of the playlist
  final String name;

  /// Optional description of the playlist's content or purpose
  final String? description;

  /// List of images associated with the playlist (usually cover art)
  /// Multiple sizes may be available for different display contexts
  final List<SpotifyImage>? images;

  /// Track collection information including total count
  final SpotifyPlaylistTracks tracks;

  /// External URL to open this playlist in Spotify
  final String? externalUrl;

  /// Indicates if the playlist is public or private
  /// null means the visibility is not known
  final bool? isPublic;

  /// ID of the user who created/owns this playlist
  /// Used for permission checks and attribution
  final String? ownerId;

  SpotifyPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.images,
    required this.tracks,
    this.externalUrl,
    this.isPublic,
    this.ownerId,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    return SpotifyPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      images: json['images'] != null
          ? (json['images'] as List)
              .map((i) => SpotifyImage.fromJson(i))
              .toList()
          : null,
      tracks: SpotifyPlaylistTracks.fromJson(json['tracks'] ?? {}),
      externalUrl: json['external_urls']?['spotify'],
      isPublic: json['public'],
      ownerId: json['owner']?['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'images': images?.map((i) => i.toJson()).toList(),
      'tracks': tracks.toJson(),
      'external_urls': externalUrl != null ? {'spotify': externalUrl} : null,
      'public': isPublic,
      'owner': ownerId != null ? {'id': ownerId} : null,
    };
  }
}

class SpotifyPlaylistTracks {
  final int total;

  SpotifyPlaylistTracks({
    required this.total,
  });

  factory SpotifyPlaylistTracks.fromJson(Map<String, dynamic> json) {
    return SpotifyPlaylistTracks(
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
    };
  }
}

/// Represents a single track (song) in Spotify's catalog.
/// Contains all metadata and playback information for a track.
class SpotifyTrack {
  /// Unique identifier for the track
  final String id;

  /// Title/name of the track
  final String name;

  /// List of artists who performed the track
  /// A track can have multiple artists (collaborations)
  final List<SpotifyArtist> artists;

  /// Album that contains this track
  /// Includes album metadata like cover art
  final SpotifyAlbum album;

  /// Duration of the track in milliseconds
  /// Used for display and playback timing
  final int durationMs;

  /// URL for a 30-second preview of the track
  /// Can be null if preview is not available
  final String? previewUrl;

  /// External URL to open this track in Spotify
  final String? externalUrl;

  /// Indicates if the track can be played in the user's region/market
  /// Used for availability checks before attempting playback
  final bool isPlayable;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artists,
    required this.album,
    required this.durationMs,
    this.previewUrl,
    this.externalUrl,
    required this.isPlayable,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      artists: json['artists'] != null
          ? (json['artists'] as List)
              .map((a) => SpotifyArtist.fromJson(a))
              .toList()
          : [],
      album: SpotifyAlbum.fromJson(json['album'] ?? {}),
      durationMs: json['duration_ms'] ?? 0,
      previewUrl: json['preview_url'],
      externalUrl: json['external_urls']?['spotify'],
      isPlayable: json['is_playable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artists': artists.map((a) => a.toJson()).toList(),
      'album': album.toJson(),
      'duration_ms': durationMs,
      'preview_url': previewUrl,
      'external_urls': externalUrl != null ? {'spotify': externalUrl} : null,
      'is_playable': isPlayable,
    };
  }

  String get durationFormatted {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get artistNames => artists.map((a) => a.name).join(', ');
}

/// Represents a Spotify artist with basic identification and linking information.
/// This model contains essential artist details used in track and album references.
class SpotifyArtist {
  /// Unique identifier for the artist in Spotify's system
  final String id;

  /// Display name of the artist
  /// This is the official artist name shown to users
  final String name;

  /// URL to the artist's page on Spotify
  /// Can be used to link to the full artist profile
  final String? externalUrl;

  /// Creates a new SpotifyArtist instance
  /// [id] and [name] are required for basic artist identification
  /// [externalUrl] is optional but useful for linking to artist's profile
  SpotifyArtist({
    required this.id,
    required this.name,
    this.externalUrl,
  });

  factory SpotifyArtist.fromJson(Map<String, dynamic> json) {
    return SpotifyArtist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      externalUrl: json['external_urls']?['spotify'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'external_urls': externalUrl != null ? {'spotify': externalUrl} : null,
    };
  }
}

/// Represents a Spotify album containing tracks.
/// Provides album metadata including cover art and external links.
/// Albums are the primary grouping mechanism for tracks in Spotify.
class SpotifyAlbum {
  /// Unique identifier for the album
  final String id;

  /// Title/name of the album
  final String name;

  /// Collection of album artwork in various sizes
  /// Can be null if artwork is not available
  /// Usually contains multiple resolutions for different display contexts
  final List<SpotifyImage>? images;

  /// URL to view the album on Spotify
  /// Can be used to direct users to the full album page
  final String? externalUrl;

  /// Creates a new SpotifyAlbum instance
  /// [id] and [name] are required for basic album identification
  /// [images] and [externalUrl] are optional but enhance the user experience
  SpotifyAlbum({
    required this.id,
    required this.name,
    this.images,
    this.externalUrl,
  });

  factory SpotifyAlbum.fromJson(Map<String, dynamic> json) {
    return SpotifyAlbum(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      images: json['images'] != null
          ? (json['images'] as List)
              .map((i) => SpotifyImage.fromJson(i))
              .toList()
          : null,
      externalUrl: json['external_urls']?['spotify'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'images': images?.map((i) => i.toJson()).toList(),
      'external_urls': externalUrl != null ? {'spotify': externalUrl} : null,
    };
  }
}

/// Represents a track within a Spotify playlist context.
/// This wrapper class allows for future expansion to include playlist-specific
/// metadata like date added, added by user, etc.
class SpotifyPlaylistTrack {
  /// The actual track object containing all track metadata
  /// This is the core track information as it appears in the playlist
  final SpotifyTrack track;

  /// Creates a new SpotifyPlaylistTrack instance
  /// [track] is required as it contains the essential track information
  SpotifyPlaylistTrack({
    required this.track,
  });

  factory SpotifyPlaylistTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyPlaylistTrack(
      track: SpotifyTrack.fromJson(json['track'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'track': track.toJson(),
    };
  }
}

/// Container class for Spotify search results.
/// Currently only handles track results, but can be expanded to include
/// other types like artists, albums, and playlists.
class SpotifySearchResults {
  /// Collection of tracks matching the search query
  /// Includes pagination information and the tracks themselves
  final SpotifySearchTracks tracks;

  /// Creates a new SpotifySearchResults instance
  /// [tracks] is required and contains all track-related search results
  SpotifySearchResults({
    required this.tracks,
  });

  factory SpotifySearchResults.fromJson(Map<String, dynamic> json) {
    return SpotifySearchResults(
      tracks: SpotifySearchTracks.fromJson(json['tracks'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tracks': tracks.toJson(),
    };
  }
}

/// Container for track-specific search results from Spotify.
/// Includes both the matching tracks and pagination information.
class SpotifySearchTracks {
  /// List of tracks matching the search query
  /// Contains the actual track objects with full metadata
  final List<SpotifyTrack> items;

  /// Total number of tracks matching the search query
  /// Used for pagination and displaying result counts
  final int total;

  /// Creates a new SpotifySearchTracks instance
  /// [items] contains the actual track results
  /// [total] indicates the total number of matches (may be more than returned)
  SpotifySearchTracks({
    required this.items,
    required this.total,
  });

  factory SpotifySearchTracks.fromJson(Map<String, dynamic> json) {
    return SpotifySearchTracks(
      items: json['items'] != null
          ? (json['items'] as List)
              .map((t) => SpotifyTrack.fromJson(t))
              .toList()
          : [],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((t) => t.toJson()).toList(),
      'total': total,
    };
  }
}

/// Manages authentication tokens for Spotify API access.
/// Handles both the access token for immediate use and refresh token for
/// obtaining new access tokens when needed.
class SpotifyTokens {
  /// Short-lived token used for API requests
  /// Usually valid for about 1 hour
  final String accessToken;

  /// Long-lived token used to obtain new access tokens
  /// Should be stored securely and persisted across sessions
  final String refreshToken;

  /// Unix timestamp (milliseconds) when the access token expires
  /// Used to determine when to refresh the token
  final int expiresAt;

  /// Creates a new SpotifyTokens instance
  /// All parameters are required for proper authentication management
  /// [accessToken] is used for immediate API access
  /// [refreshToken] is used to obtain new access tokens
  /// [expiresAt] determines when the access token needs to be refreshed
  SpotifyTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory SpotifyTokens.fromJson(Map<String, dynamic> json) {
    return SpotifyTokens(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresAt: json['expires_at'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt,
    };
  }

  bool get isExpired => DateTime.now().millisecondsSinceEpoch >= expiresAt;
}
