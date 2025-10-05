import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for fetching GIFs from Tenor API (Discord's GIF provider)
class GifService {
  // Tenor API key from Google Cloud Console
  static const String _apiKey = 'AIzaSyCmtkUPudyPMjUMkRjmjSnAHRKV4NpByyo';
  static const String _clientKey = 'studypals_app'; // Client identifier for Tenor API v2
  static const String _baseUrl = 'https://tenor.googleapis.com/v2';
  
  /// Search for GIFs
  Future<List<GifResult>> searchGifs(String query, {int limit = 20}) async {
    try {
      debugPrint('🔍 Searching GIFs: $query');
      
      final url = Uri.parse(
        '$_baseUrl/search?q=$query&key=$_apiKey&client_key=$_clientKey&limit=$limit&media_filter=gif,tinygif',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List)
            .map((item) => GifResult.fromJson(item))
            .toList();
        
        debugPrint('✅ Found ${results.length} GIFs');
        return results;
      } else {
        debugPrint('❌ Tenor API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error searching GIFs: $e');
      return [];
    }
  }
  
  /// Get trending/featured GIFs
  Future<List<GifResult>> getTrendingGifs({int limit = 20}) async {
    try {
      debugPrint('🔥 Fetching trending GIFs');
      
      // Try search endpoint first (works immediately after API enable)
      final url = Uri.parse(
        '$_baseUrl/search?q=trending&key=$_apiKey&client_key=$_clientKey&limit=$limit&media_filter=gif,tinygif',
      );
      
      debugPrint('📡 Calling: ${url.toString().replaceAll(_apiKey, 'API_KEY_HIDDEN')}');
      
      final response = await http.get(url);
      
      debugPrint('📬 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = (data['results'] as List)
            .map((item) => GifResult.fromJson(item))
            .toList();
        
        debugPrint('✅ Found ${results.length} trending GIFs');
        return results;
      } else if (response.statusCode == 403) {
        debugPrint('⏳ Tenor API permissions still propagating (usually takes 5-10 minutes after enabling)');
        debugPrint('Response: ${response.body}');
        return [];
      } else {
        debugPrint('❌ Tenor API error: ${response.statusCode}');
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
    try {
      final url = Uri.parse(
        '$_baseUrl/categories?key=$_apiKey&client_key=$_clientKey',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tags = (data['tags'] as List)
            .map((tag) => tag['searchterm'] as String)
            .toList();
        
        debugPrint('✅ Found ${tags.length} categories');
        return tags;
      } else {
        return _defaultCategories;
      }
    } catch (e) {
      debugPrint('❌ Error fetching categories: $e');
      return _defaultCategories;
    }
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

/// GIF result from Tenor API
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
  
  factory GifResult.fromJson(Map<String, dynamic> json) {
    final mediaFormats = json['media_formats'] as Map<String, dynamic>;
    
    // Get tinygif for preview (smaller, faster loading)
    final preview = mediaFormats['tinygif'] as Map<String, dynamic>?;
    final previewUrl = preview?['url'] as String? ?? '';
    
    // Get gif for full quality
    final gif = mediaFormats['gif'] as Map<String, dynamic>?;
    final fullUrl = gif?['url'] as String? ?? previewUrl;
    final width = (gif?['dims'] as List?)?.first as int? ?? 200;
    final height = (gif?['dims'] as List?)?.last as int? ?? 200;
    
    return GifResult(
      id: json['id'] as String? ?? '',
      title: json['content_description'] as String? ?? 'GIF',
      previewUrl: previewUrl,
      fullUrl: fullUrl,
      width: width,
      height: height,
    );
  }
}
