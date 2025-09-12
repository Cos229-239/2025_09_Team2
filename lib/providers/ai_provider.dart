import 'package:flutter/foundation.dart';
import 'package:studypals/services/ai_service.dart';
import 'package:studypals/models/card.dart';
import 'package:studypals/models/user.dart';

/// StudyPals AI Provider for managing intelligent study features
class StudyPalsAIProvider with ChangeNotifier {
  final AIService _aiService = AIService();

  // Configuration state
  AIProvider _currentProvider = AIProvider.openai;

  // State variables
  bool _isAIEnabled = false;
  bool _isGeneratingContent = false;
  String _lastRecommendation = '';
  String _lastPetMessage = '';
  String? _lastError;
  final List<FlashCard> _aiGeneratedCards = [];
  // Getters
  bool get isAIEnabled => _isAIEnabled && _aiService.isConfigured;
  bool get isGeneratingContent => _isGeneratingContent;
  String get lastRecommendation => _lastRecommendation;
  String get lastPetMessage => _lastPetMessage;
  String? get lastError => _lastError;
  List<FlashCard> get aiGeneratedCards => _aiGeneratedCards;
  AIProvider get currentProvider => _currentProvider;
  AIService get aiService => _aiService; // Added getter for AI service

  /// Configure AI service
  Future<void> configureAI({
    required AIProvider provider,
    required String apiKey,
    String? customBaseUrl,
  }) async {
    try {
      _currentProvider = provider;

      _aiService.configure(
        provider: provider,
        apiKey: apiKey,
        customBaseUrl: customBaseUrl,
      );

      _isAIEnabled = true;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = 'Configuration failed: $e';
      _isAIEnabled = false;
      notifyListeners();
    }
  }

  /// Test AI connection
  Future<bool> testConnection() async {
    try {
      final result = await _aiService.testConnection();
      _isAIEnabled = result;
      if (!result) {
        _lastError = 'Connection test failed';
      } else {
        _lastError = null;
      }
      notifyListeners();
      return result;
    } catch (e) {
      _lastError = 'Connection error: $e';
      _isAIEnabled = false;
      notifyListeners();
      return false;
    }
  }

  /// Initialize AI features
  Future<void> initializeAI() async {
    _isAIEnabled = await _aiService.testConnection();
    notifyListeners();
  }

  /// Generate flashcards from text input
  Future<List<FlashCard>> generateFlashcards(
      String content, String subject) async {
    if (!isAIEnabled) return [];

    _isGeneratingContent = true;
    notifyListeners();

    try {
      final cards =
          await _aiService.generateFlashcardsFromText(content, subject);
      _aiGeneratedCards.addAll(cards);
      return cards;
    } finally {
      _isGeneratingContent = false;
      notifyListeners();
    }
  }

  /// Generate flashcards from text with additional options
  Future<List<FlashCard>> generateFlashcardsFromText(
    String content, {
    int count = 5,
    String subject = 'General',
  }) async {
    if (!isAIEnabled) return [];

    _isGeneratingContent = true;
    notifyListeners();

    try {
      final cards = await _aiService
          .generateFlashcardsFromText(content, subject, count: count);
      _aiGeneratedCards.addAll(cards);
      return cards;
    } finally {
      _isGeneratingContent = false;
      notifyListeners();
    }
  }

  /// Get personalized study recommendation
  Future<String> getStudyRecommendation(
      User user, Map<String, dynamic> stats) async {
    if (!isAIEnabled) {
      return "Keep up the great work! Consistency is key to success.";
    }

    try {
      _lastRecommendation = await _aiService.getStudyRecommendation(stats);
      notifyListeners();
      return _lastRecommendation;
    } catch (e) {
      return "Stay focused and keep studying! You're doing great!";
    }
  }

  /// Get AI-powered pet message
  Future<String> getPetMessage(
      String petName, Map<String, dynamic> stats) async {
    if (!isAIEnabled) {
      return "Great job studying today! Keep it up! 🐾";
    }

    try {
      _lastPetMessage = await _aiService.getPetMessage(petName, stats);
      notifyListeners();
      return _lastPetMessage;
    } catch (e) {
      return "You're amazing! I'm proud of your hard work! 🐾";
    }
  }

  /// Enhance an existing flashcard with AI
  Future<FlashCard?> enhanceFlashcard(FlashCard card) async {
    if (!isAIEnabled) return null;

    try {
      return await _aiService.enhanceFlashcard(card);
    } catch (e) {
      debugPrint('Failed to enhance flashcard: $e');
      return null;
    }
  }

  /// Clear AI-generated content
  void clearAIContent() {
    _aiGeneratedCards.clear();
    _lastRecommendation = '';
    _lastPetMessage = '';
    notifyListeners();
  }

  /// Toggle AI features (for settings)
  void toggleAI(bool enabled) {
    _isAIEnabled = enabled;
    notifyListeners();
  }
}
