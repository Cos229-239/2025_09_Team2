// lib/config/env_config.dart
// Environment configuration loader
// This file reads API keys from environment variables

/// Environment configuration class
/// 
/// SETUP INSTRUCTIONS:
/// 1. Copy .env.example to .env
/// 2. Fill in your API keys in .env
/// 3. Install flutter_dotenv package:
///    flutter pub add flutter_dotenv
/// 4. Load in main.dart before runApp():
///    await dotenv.load(fileName: ".env");
/// 5. Add .env to .gitignore (CRITICAL!)
/// 
/// FALLBACK FOR DEVELOPMENT:
/// If .env is not set up, it will use compile-time constants
/// defined below (which you should remove before committing)

class EnvConfig {
  /// Get Gemini API key from environment or fallback
  static String get geminiApiKey {
    // Try to get from environment variable first
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    
    if (apiKey.isNotEmpty) {
      return apiKey;
    }
    
    // TEMPORARY FALLBACK FOR DEVELOPMENT
    // TODO: Remove this before production deployment!
    // For now, using the key directly for ease of development
    return 'AIzaSyAssbGQp-J912A5UVSHEJ6zNwISHjle_cs';
  }
  
  /// Check if API key is properly configured
  static bool get isConfigured {
    return geminiApiKey.isNotEmpty && 
           geminiApiKey != 'your_gemini_api_key_here' &&
           geminiApiKey.startsWith('AIza');
  }
  
  /// Get display-safe version of API key (for debugging)
  static String get apiKeyPreview {
    if (!isConfigured) return '[NOT CONFIGURED]';
    final key = geminiApiKey;
    if (key.length < 12) return '[INVALID]';
    return '${key.substring(0, 8)}...${key.substring(key.length - 4)}';
  }
}
