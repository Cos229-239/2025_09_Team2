// gemini_config.dart
// Configuration for Google Gemini AI integration

import 'env_config.dart';

/// Configuration class for Gemini AI web search capabilities
class GeminiConfig {
  /// Gemini API key
  ///
  /// TO GET YOUR FREE API KEY:
  /// 1. Go to https://makersuite.google.com/app/apikey
  /// 2. Click "Create API Key"
  /// 3. Update EnvConfig.geminiApiKey in lib/config/env_config.dart
  ///
  /// FREE TIER: 60 requests/minute, 1,500 requests/day
  static String get apiKey => EnvConfig.geminiApiKey;

  /// Model to use for web-grounded searches
  ///
  /// Available models:
  /// - 'gemini-1.5-flash': Fast and efficient (RECOMMENDED)
  /// - 'gemini-1.5-pro': More accurate but slower
  /// - 'gemini-2.0-flash-exp': Latest experimental model
  static const String model = 'gemini-2.0-flash';

  /// Maximum tokens for responses
  static const int maxTokens = 2048;

  /// Temperature for response generation (0.0 = deterministic, 1.0 = creative)
  static const double temperature = 0.7;

  /// Safety settings
  static const String safetyLevel = 'BLOCK_MEDIUM_AND_ABOVE';

  /// Rate limiting
  static const int maxRequestsPerMinute = 55; // Stay under 60 limit
  static const Duration minRequestInterval = Duration(seconds: 1);

  /// Timeout for web search requests
  static const Duration searchTimeout = Duration(seconds: 30);

  /// Enable/disable web search feature
  /// Set to false to disable web search globally
  static const bool enableWebSearch = true;

  /// Enable debug logging
  static const bool debugMode = true;
}
