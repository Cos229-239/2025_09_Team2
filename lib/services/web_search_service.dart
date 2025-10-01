// web_search_service.dart
// Service for performing web searches using Google Gemini AI

import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';
import 'dart:developer' as developer;

/// Result from a web search query
class SearchResult {
  final String answer;
  final DateTime timestamp;
  final String query;
  final bool fromCache;
  final String? error;
  
  SearchResult({
    required this.answer,
    required this.timestamp,
    required this.query,
    this.fromCache = false,
    this.error,
  });
  
  bool get hasError => error != null;
  
  Map<String, dynamic> toJson() => {
    'answer': answer,
    'timestamp': timestamp.toIso8601String(),
    'query': query,
    'fromCache': fromCache,
    'error': error,
  };
}

/// Service for web-grounded AI search using Google Gemini
class WebSearchService {
  GenerativeModel? _model;
  final Map<String, DateTime> _rateLimiter = {};
  final Map<String, SearchResult> _cache = {};
  
  /// Initialize the Gemini model
  void initialize() {
    print('🌐 DEBUG: WebSearchService.initialize() called');
    print('🌐 DEBUG: enableWebSearch=${GeminiConfig.enableWebSearch}');
    print('🌐 DEBUG: apiKey length=${GeminiConfig.apiKey.length}');
    
    if (!GeminiConfig.enableWebSearch) {
      developer.log('Web search is disabled in config', name: 'WebSearchService');
      print('🌐 DEBUG: Web search DISABLED in config');
      return;
    }
    
    if (GeminiConfig.apiKey == 'YOUR_GEMINI_API_KEY_HERE' || 
        GeminiConfig.apiKey.isEmpty || 
        GeminiConfig.apiKey.length < 20) {
      developer.log(
        'WARNING: Gemini API key not configured. Web search will not work.',
        name: 'WebSearchService',
      );
      print('🌐 DEBUG: API key INVALID');
      return;
    }
    
    print('🌐 DEBUG: Attempting to create GenerativeModel...');
    try {
      _model = GenerativeModel(
        model: GeminiConfig.model,
        apiKey: GeminiConfig.apiKey,
        generationConfig: GenerationConfig(
          temperature: GeminiConfig.temperature,
          maxOutputTokens: GeminiConfig.maxTokens,
        ),
        safetySettings: [
          SafetySetting(
            HarmCategory.harassment,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.hateSpeech,
            HarmBlockThreshold.medium,
          ),
        ],
      );
      
      print('🌐 DEBUG: GenerativeModel created! _model != null? ${_model != null}');
      developer.log('✅ Gemini model initialized successfully! Model is ${_model != null ? "available" : "NULL"}', name: 'WebSearchService');
    } catch (e) {
      print('🌐 DEBUG: EXCEPTION during model creation: $e');
      developer.log('❌ Failed to initialize Gemini: $e', name: 'WebSearchService');
    }
  }
  
  /// Check if web search is available
  bool get isAvailable => _model != null && GeminiConfig.enableWebSearch;
  
  /// Perform a web search with the given query
  Future<SearchResult> search(
    String query, {
    String? conversationContext,
    String? userId,
  }) async {
    print('🌐 DEBUG: search() method called. query="$query"');
    final startTime = DateTime.now();
    
    // Check if web search is available
    if (!isAvailable) {
      print('🌐 DEBUG: search() - NOT AVAILABLE! _model=${_model != null}, enableWebSearch=${GeminiConfig.enableWebSearch}');
      return SearchResult(
        answer: 'Web search is not available. Please check your API configuration.',
        timestamp: startTime,
        query: query,
        error: 'Service not initialized',
      );
    }
    
    print('🌐 DEBUG: search() - Service is available, proceeding...');
    try {
      // Rate limiting
      if (userId != null) {
        await _waitForRateLimit(userId);
      }
      
      // Check cache (5-minute expiration)
      final cacheKey = _getCacheKey(query);
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        final age = startTime.difference(cached.timestamp);
        if (age.inMinutes < 5) {
          print('🌐 DEBUG: Returning CACHED result');
          developer.log('Returning cached result for: $query', name: 'WebSearchService');
          return SearchResult(
            answer: cached.answer,
            timestamp: cached.timestamp,
            query: query,
            fromCache: true,
          );
        }
      }
      
      // Build search prompt
      final prompt = _buildSearchPrompt(query, conversationContext);
      
      print('🌐 DEBUG: Calling Gemini API with prompt length=${prompt.length}');
      developer.log('Performing web search for: $query', name: 'WebSearchService');
      
      // Perform search with timeout
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(GeminiConfig.searchTimeout);
      
      print('🌐 DEBUG: Gemini API responded!');
      final answer = response.text ?? 'No results found.';
      print('🌐 DEBUG: Answer length=${answer.length}');
      
      final result = SearchResult(
        answer: answer,
        timestamp: DateTime.now(),
        query: query,
      );
      
      // Cache the result
      _cache[cacheKey] = result;
      
      // Clean old cache entries (keep last 20)
      if (_cache.length > 20) {
        final oldestKey = _cache.keys.first;
        _cache.remove(oldestKey);
      }
      
      final duration = DateTime.now().difference(startTime);
      developer.log(
        'Web search completed in ${duration.inMilliseconds}ms',
        name: 'WebSearchService',
      );
      
      return result;
      
    } catch (e) {
      print('🌐 DEBUG: EXCEPTION in search(): $e');
      print('🌐 DEBUG: Exception type: ${e.runtimeType}');
      developer.log('Web search error: $e', name: 'WebSearchService');
      
      return SearchResult(
        answer: 'I apologize, but I encountered an error while searching for that information. '
               'Please try rephrasing your question or try again later.',
        timestamp: DateTime.now(),
        query: query,
        error: e.toString(),
      );
    }
  }
  
  /// Build optimized prompt for web search
  String _buildSearchPrompt(String query, String? context) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are an expert research assistant with access to current web information.');
    buffer.writeln('Your role is to provide accurate, well-researched answers to student questions.');
    buffer.writeln();
    
    if (context != null && context.isNotEmpty) {
      buffer.writeln('CONVERSATION CONTEXT:');
      buffer.writeln(context);
      buffer.writeln();
    }
    
    buffer.writeln('STUDENT QUESTION: $query');
    buffer.writeln();
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln('1. Search for current, accurate information about this query');
    buffer.writeln('2. Provide a clear, concise answer suitable for a student');
    buffer.writeln('3. If you find specific facts (names, dates, numbers), include them');
    buffer.writeln('4. If information might be outdated or uncertain, mention when it was last verified');
    buffer.writeln('5. Focus on educational value and accuracy');
    buffer.writeln('6. Keep the response under 300 words unless more detail is specifically needed');
    buffer.writeln();
    buffer.writeln('Please provide your answer:');
    
    return buffer.toString();
  }
  
  /// Generate cache key for a query
  String _getCacheKey(String query) {
    return query.toLowerCase().trim();
  }
  
  /// Wait if rate limit would be exceeded
  Future<void> _waitForRateLimit(String userId) async {
    if (_rateLimiter.containsKey(userId)) {
      final lastRequest = _rateLimiter[userId]!;
      final elapsed = DateTime.now().difference(lastRequest);
      
      if (elapsed < GeminiConfig.minRequestInterval) {
        final waitTime = GeminiConfig.minRequestInterval - elapsed;
        developer.log(
          'Rate limiting: waiting ${waitTime.inMilliseconds}ms',
          name: 'WebSearchService',
        );
        await Future.delayed(waitTime);
      }
    }
    
    _rateLimiter[userId] = DateTime.now();
    
    // Clean old entries (keep last 100 users)
    if (_rateLimiter.length > 100) {
      final oldestUser = _rateLimiter.keys.first;
      _rateLimiter.remove(oldestUser);
    }
  }
  
  /// Clear the search cache
  void clearCache() {
    _cache.clear();
    developer.log('Search cache cleared', name: 'WebSearchService');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'rateLimiterSize': _rateLimiter.length,
      'isAvailable': isAvailable,
    };
  }
}
