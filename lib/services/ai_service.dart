import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/card.dart';

/// AI Provider types
enum AIProvider { openai, google, anthropic, localModel, ollama }

/// AI Service for intelligent study features
class AIService {
  AIProvider _provider = AIProvider.openai;
  String _apiKey = '';
  String _baseUrl = '';
  
  /// Configure the AI service with provider and API key
  void configure({
    required AIProvider provider,
    required String apiKey,
    String? customBaseUrl,
  }) {
    _provider = provider;
    _apiKey = apiKey;
    
    switch (provider) {
      case AIProvider.openai:
        _baseUrl = 'https://api.openai.com/v1';
        break;
      case AIProvider.google:
        _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
        break;
      case AIProvider.anthropic:
        _baseUrl = 'https://api.anthropic.com/v1';
        break;
      case AIProvider.ollama:
        _baseUrl = customBaseUrl ?? 'http://localhost:11434/api';
        break;
      case AIProvider.localModel:
        _baseUrl = customBaseUrl ?? 'http://localhost:8080/v1';
        break;
    }
  }
  
  /// Check if AI service is properly configured
  bool get isConfigured => _apiKey.isNotEmpty && _baseUrl.isNotEmpty;
  
  /// Generate flashcards from study text
  Future<List<FlashCard>> generateFlashcardsFromText(String content, String subject, {int count = 5}) async {
    try {
      final prompt = '''
Create exactly $count flashcards about $subject. Topic: $content

You MUST respond with ONLY a valid JSON array. No explanation, no extra text.

Format:
[
  {"question": "What is...", "answer": "The answer is..."},
  {"question": "Define...", "answer": "It means..."}
]

Make questions clear and answers concise. Focus on key concepts.
      ''';
      
      final response = await _callAI(prompt);
      
      // Clean the response to extract JSON
      String cleanResponse = response.trim();
      
      // Find JSON array in the response
      int startIndex = cleanResponse.indexOf('[');
      int endIndex = cleanResponse.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
      }
      
      // Parse JSON
      final cardsData = json.decode(cleanResponse) as List;
      
      return cardsData.map((cardJson) => FlashCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deckId: 'ai_generated',
        type: CardType.basic,
        front: cardJson['question'] ?? 'Question',
        back: cardJson['answer'] ?? 'Answer',
      )).toList();
      
    } catch (e) {
      debugPrint('AI flashcard generation error: $e');
      debugPrint('Raw response might not be valid JSON');
      return [];
    }
  }
  
  /// Get personalized study recommendations
  Future<String> getStudyRecommendation(Map<String, dynamic> userStats) async {
    try {
      final prompt = '''
      Based on this student's performance data:
      - Cards studied today: ${userStats['cardsToday']}
      - Success rate: ${userStats['successRate']}%
      - Study streak: ${userStats['streak']} days
      - Weak subjects: ${userStats['weakSubjects']}
      
      Provide 1 specific, encouraging study tip (max 50 words):
      ''';
      
      return await _callAI(prompt);
    } catch (e) {
      return "Keep up the great work! Consistency is key to mastering any subject.";
    }
  }
  
  /// Generate motivational pet message
  Future<String> getPetMessage(String petName, Map<String, dynamic> userStats) async {
    try {
      final prompt = '''
      You are $petName, a friendly study companion pet. Based on:
      - User studied ${userStats['cardsToday']} cards today
      - Success rate: ${userStats['successRate']}%
      
      Generate a short, encouraging message (max 30 words) in a cute, supportive tone:
      ''';
      
      return await _callAI(prompt);
    } catch (e) {
      return "Great job studying today! I'm proud of your hard work! 🐾";
    }
  }
  
  /// Improve an existing flashcard
  Future<FlashCard> enhanceFlashcard(FlashCard originalCard) async {
    try {
      final prompt = '''
      Improve this flashcard:
      Question: ${originalCard.front}
      Answer: ${originalCard.back}
      
      Suggest a better question, clearer answer, and helpful hint.
      Return as JSON: {"question": "...", "answer": "...", "hint": "..."}
      ''';
      
      final response = await _callAI(prompt);
      final improved = json.decode(response);
      
      return FlashCard(
        id: originalCard.id,
        deckId: originalCard.deckId,
        type: originalCard.type,
        front: improved['question'] ?? originalCard.front,
        back: improved['answer'] ?? originalCard.back,
        clozeMask: originalCard.clozeMask,
      );
      
    } catch (e) {
      debugPrint('Card enhancement error: $e');
      return originalCard;
    }
  }
  
  /// Private method to call AI API - supports multiple providers
  Future<String> _callAI(String prompt) async {
    if (!isConfigured) {
      throw Exception('AI service not configured');
    }
    
    switch (_provider) {
      case AIProvider.openai:
        return await _callOpenAI(prompt);
      case AIProvider.google:
        return await _callGoogleAI(prompt);
      case AIProvider.anthropic:
        return await _callAnthropic(prompt);
      case AIProvider.ollama:
        return await _callOllama(prompt);
      case AIProvider.localModel:
        return await _callLocalModel(prompt);
    }
  }
  
  /// OpenAI API call
  Future<String> _callOpenAI(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'gpt-4o-mini', // Use latest efficient model
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('OpenAI API call failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Google AI (Gemini) API call
  Future<String> _callGoogleAI(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/models/gemini-1.5-flash:generateContent?key=$_apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 300,
        }
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        return data['candidates'][0]['content']['parts'][0]['text'].trim();
      } else {
        throw Exception('No response from Google AI');
      }
    } else {
      throw Exception('Google AI API call failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Anthropic Claude API call
  Future<String> _callAnthropic(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: {
        'x-api-key': _apiKey,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
      },
      body: json.encode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 300,
        'messages': [
          {'role': 'user', 'content': prompt}
        ]
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['content'][0]['text'].trim();
    } else {
      throw Exception('Anthropic API call failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Ollama (Local open source models) API call
  Future<String> _callOllama(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'model': 'llama3.1', // Popular open source model
        'prompt': prompt,
        'stream': false,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['response'].trim();
    } else {
      throw Exception('Ollama API call failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Local model API call (OpenAI-compatible endpoint)
  Future<String> _callLocalModel(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'local-model',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Local model API call failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Get AI service status
  /// Test AI connection
  Future<bool> testConnection() async {
    if (!isConfigured) return false;
    
    try {
      await _callAI('Hello, this is a test. Please respond with "Connection successful".');
      return true;
    } catch (e) {
      debugPrint('AI Connection test failed: $e');
      return false;
    }
  }

  /// Debug method to see raw AI responses
  Future<String> debugFlashcardGeneration(String content, String subject) async {
    try {
      final prompt = '''
Create exactly 2 flashcards about $subject. Topic: $content

You MUST respond with ONLY a valid JSON array. No explanation, no extra text.

Format:
[
  {"question": "What is...", "answer": "The answer is..."},
  {"question": "Define...", "answer": "It means..."}
]

Make questions clear and answers concise. Focus on key concepts.
      ''';
      
      final response = await _callAI(prompt);
      debugPrint('Raw AI Response for debugging: $response');
      return response;
      
    } catch (e) {
      debugPrint('Debug generation error: $e');
      return 'Error: $e';
    }
  }
}
