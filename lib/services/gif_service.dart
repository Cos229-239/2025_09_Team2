import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for fetching GIFs - Uses Giphy API (works immediately, no approval needed)
class GifService {
  // Giphy Public Beta API Key (no approval needed, works instantly)
  static const String _giphyApiKey =
      'sXpGFDGZs0Dv1mmNFvYaGUvYwKX0PWIh'; // Public beta key
  static const String _giphyBaseUrl = 'https://api.giphy.com/v1/gifs';

  /// Search for GIFs using Giphy
  Future<List<GifResult>> searchGifs(String query, {int limit = 20}) async {
    try {
      debugPrint('🔍 Searching GIFs: $query');

      final url = Uri.parse(
        '$_giphyBaseUrl/search?api_key=$_giphyApiKey&q=$query&limit=$limit&rating=g',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['data'] as List)
            .map((item) => GifResult.fromGiphyJson(item))
            .toList();

        debugPrint('✅ Found ${results.length} GIFs from Giphy');
        return results;
      } else {
        debugPrint('❌ Giphy API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error searching GIFs: $e');
      return [];
    }
  }

  /// Get trending GIFs using Giphy
  Future<List<GifResult>> getTrendingGifs({int limit = 20}) async {
    try {
      debugPrint('🔥 Fetching trending GIFs from Giphy');

      final url = Uri.parse(
        '$_giphyBaseUrl/trending?api_key=$_giphyApiKey&limit=$limit&rating=g',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['data'] as List)
            .map((item) => GifResult.fromGiphyJson(item))
            .toList();

        debugPrint('✅ Found ${results.length} trending GIFs from Giphy');
        return results;
      } else {
        debugPrint('❌ Giphy API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching trending GIFs: $e');
      return [];
    }
  }

  /// Get GIF categories
  Future<List<String>> getCategories() async {
    // Giphy doesn't have a categories endpoint, so return popular search terms
    return _defaultCategories;
  }

  static const List<String> _defaultCategories = [
    'Happy',
    'Sad',
    'Love',
    'Angry',
    'Excited',
    'Funny',
    'Dance',
    'Applause',
    'Thumbs Up',
    'Facepalm',
    'Yay',
    'Oops',
  ];
}

/// GIF result from Giphy API
class GifResult {
  final String id;
  final String title;
  final String previewUrl; // Small preview for grid
  final String fullUrl; // Full GIF for sending
  final int width;
  final int height;

  GifResult({
    required this.id,
    required this.title,
    required this.previewUrl,
    required this.fullUrl,
    required this.width,
    required this.height,
  });

  /// Parse Giphy API response
  factory GifResult.fromGiphyJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>;

    // Use fixed_width for better quality preview (not small)
    // This gives us good quality while still being optimized for grid display
    final preview = images['fixed_width'] as Map<String, dynamic>?;
    final previewUrl = preview?['url'] as String? ?? '';

    // Get full quality GIF (original or downsized)
    final original = images['original'] as Map<String, dynamic>?;
    final fullUrl = original?['url'] as String? ?? previewUrl;
    final width = int.tryParse(original?['width']?.toString() ?? '200') ?? 200;
    final height =
        int.tryParse(original?['height']?.toString() ?? '200') ?? 200;

    return GifResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'GIF',
      previewUrl: previewUrl,
      fullUrl: fullUrl,
      width: width,
      height: height,
    );
  }
}
