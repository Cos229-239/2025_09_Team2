import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:studypals/models/card.dart';

/// AI Provider types
enum AIProvider { openai, google, anthropic, localModel, ollama }

/// AI Service for intelligent study features
class AIService {
  AIProvider _provider = AIProvider.google;
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
        _baseUrl = customBaseUrl ?? 'http://localhost:8000';
        break;
    }
  }
  
  /// Check if AI service is properly configured
  bool get isConfigured => _apiKey.isNotEmpty && _baseUrl.isNotEmpty;
  
  /// Generate flashcards from study text
  Future<List<FlashCard>> generateFlashcardsFromText(String content, String subject, {int count = 5}) async {
    debugPrint('=== AI Flashcard Generation Debug ===');
    debugPrint('Provider: $_provider');
    debugPrint('API Key configured: ${_apiKey.isNotEmpty}');
    debugPrint('Base URL: $_baseUrl');
    debugPrint('Is configured: $isConfigured');
    debugPrint('Content: $content');
    debugPrint('Subject: $subject');
    debugPrint('Count: $count');
    
    if (!isConfigured) {
      debugPrint('ERROR: AI service not configured!');
      return _createFallbackFlashcards(subject, content);
    }
    
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
      
      debugPrint('Sending prompt to AI...');
      final response = await _callAI(prompt);
<<<<<<< HEAD
=======
      debugPrint('Raw AI response: $response');
>>>>>>> backend-features
      
      // Clean the response to extract JSON
      String cleanResponse = response.trim();
      
      // Find JSON array in the response
      int startIndex = cleanResponse.indexOf('[');
      int endIndex = cleanResponse.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
      }
      
<<<<<<< HEAD
      // Parse JSON
      final cardsData = json.decode(cleanResponse) as List;
=======
      debugPrint('Cleaned response: $cleanResponse');
      
      // Parse JSON
      final cardsData = json.decode(cleanResponse) as List;
      debugPrint('Parsed ${cardsData.length} cards from AI response');
>>>>>>> backend-features
      
      return cardsData.map((cardJson) => FlashCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deckId: 'ai_generated',
        type: CardType.basic,
        front: cardJson['question'] ?? 'Question',
        back: cardJson['answer'] ?? 'Answer',
      )).toList();
      
    } catch (e) {
      debugPrint('AI flashcard generation error: $e');
<<<<<<< HEAD
      debugPrint('Raw response might not be valid JSON');
      return [];
=======
      return _createFallbackFlashcards(subject, content);
>>>>>>> backend-features
    }
  }
  
  /// Create fallback flashcards when AI is unavailable
  List<FlashCard> _createFallbackFlashcards(String subject, String content) {
    debugPrint('Creating fallback flashcards for $subject');
    
    return [
      FlashCard(
        id: '1',
        deckId: 'ai_generated',
        type: CardType.basic,
        front: 'What is the main topic of $subject?',
        back: content.length > 100 ? content.substring(0, 100) + '...' : content,
      ),
      FlashCard(
        id: '2',
        deckId: 'ai_generated',
        type: CardType.basic,
        front: 'Define key concepts in $subject',
        back: 'Key concepts include the fundamental principles and ideas covered in this subject area.',
      ),
      FlashCard(
        id: '3',
        deckId: 'ai_generated',
        type: CardType.basic,
        front: 'Why is $subject important?',
        back: 'Understanding $subject helps develop critical thinking and knowledge in this field.',
      ),
      FlashCard(
        id: '4',
        deckId: 'ai_generated',
        type: CardType.basic,
        front: 'How can you apply $subject knowledge?',
        back: 'Apply this knowledge through practice, real-world examples, and further study.',
      ),
      FlashCard(
        id: '5',
        deckId: 'ai_generated',
        type: CardType.basic,
        front: 'What are the next steps for learning $subject?',
        back: 'Continue studying, practice regularly, and seek additional resources to deepen understanding.',
      ),
    ];
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
  
  /// Get study recommendation based on user stats
  Future<String> getStudyRecommendation(Map<String, dynamic> stats) async {
    try {
      final prompt = '''
      Based on study stats:
      - Cards studied: ${stats['cardsStudied']}
      - Success rate: ${stats['successRate']}%
      - Study streak: ${stats['studyStreak']} days
      
      Provide a brief study recommendation (max 50 words):
      ''';
      
      return await _callAI(prompt);
    } catch (e) {
      return "Keep up the great work! Try to study a little each day to maintain your momentum.";
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
      default:
        throw Exception('Unsupported AI provider: $_provider');
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
        'model': 'gpt-4o-mini',
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
  
  /// Google AI (Gemini) API call with retry logic
  Future<String> _callGoogleAI(String prompt) async {
<<<<<<< HEAD
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
=======
    return await _callGoogleAIWithRetry(prompt, 0);
  }
  
  Future<String> _callGoogleAIWithRetry(String prompt, int retryCount) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 2);
    
    debugPrint('=== Google AI API Call (Attempt ${retryCount + 1}) ===');
    debugPrint('URL: $_baseUrl/models/gemini-1.5-flash:generateContent?key=${_apiKey.substring(0, 8)}...');
    debugPrint('Prompt length: ${prompt.length}');
    
    try {
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
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      // Handle 503 Service Unavailable (model overloaded)
      if (response.statusCode == 503 && retryCount < maxRetries) {
        final delay = baseDelay * (retryCount + 1);
        debugPrint('API overloaded (503), retrying in ${delay.inSeconds} seconds... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(delay);
        return await _callGoogleAIWithRetry(prompt, retryCount + 1);
      }
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final result = data['candidates'][0]['content']['parts'][0]['text'].trim();
          debugPrint('Extracted result: $result');
          return result;
        } else {
          debugPrint('No candidates in response: $data');
          throw Exception('No response from Google AI');
        }
      } else {
        debugPrint('API call failed with status ${response.statusCode}');
        throw Exception('Google AI API call failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('503') && retryCount < maxRetries) {
        final delay = baseDelay * (retryCount + 1);
        debugPrint('Exception indicates 503 error, retrying in ${delay.inSeconds} seconds... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(delay);
        return await _callGoogleAIWithRetry(prompt, retryCount + 1);
      }
      debugPrint('Exception in Google AI call: $e');
      rethrow;
>>>>>>> backend-features
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
        'model': 'llama2',
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
  
  /// Local model API call
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
  
<<<<<<< HEAD
  /// Get AI service status
=======
>>>>>>> backend-features
  /// Test AI connection
  Future<bool> testConnection() async {
    if (!isConfigured) return false;
    
    try {
<<<<<<< HEAD
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
=======
      await _callAI('Test message');
      return true;
    } catch (e) {
      debugPrint('AI connection test failed: $e');
      return false;
    }
  }
  
  /// Debug method for testing flashcard generation
  Future<String> debugFlashcardGeneration(String content, String subject) async {
    try {
      final prompt = '''
Create exactly 5 flashcards about $subject. Topic: $content
>>>>>>> backend-features

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
