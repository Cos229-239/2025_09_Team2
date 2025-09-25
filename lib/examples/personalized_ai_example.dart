// Enhanced Personalized AI System Documentation
// Demonstrates the comprehensive AI personalization features implemented in StudyPals

import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../models/card.dart';
import '../models/user.dart';
import '../models/study_analytics.dart';

/// This example demonstrates the enhanced AI system capabilities
/// 
/// KEY FEATURES IMPLEMENTED:
/// 1. User-Adaptive Personalization - Learning style integration
/// 2. Performance Integration - Adaptive difficulty based on analytics
/// 3. Educational Context - Adapts to major, school, academic level
/// 4. Multi-Modal Generation - Different question types per learning style
/// 5. Comprehensive Error Handling - Fallbacks and robust operation
class PersonalizedAIDemo extends StatefulWidget {
  const PersonalizedAIDemo({super.key});

  @override
  State<PersonalizedAIDemo> createState() => _PersonalizedAIDemoState();
}

class _PersonalizedAIDemoState extends State<PersonalizedAIDemo> {
  final AIService _aiService = AIService();
  List<FlashCard> _generatedCards = [];
  bool _isGenerating = false;
  String _subject = 'Computer Science';
  String _content = 'Object-oriented programming concepts: classes, objects, inheritance, polymorphism, and encapsulation.';

  // Sample user for demonstration
  User get _sampleUser => User(
    id: 'demo_user',
    email: 'demo@studypals.com',
    name: 'Alex Johnson',
    school: 'University of Technology',
    major: 'Computer Science',
    graduationYear: 2025,
    preferences: UserPreferences(
      learningStyle: 'visual',
      difficultyPreference: 'adaptive',
      showHints: true,
      studyStartHour: 9,
      studyEndHour: 17,
      maxCardsPerDay: 25,
    ),
  );

  // Sample analytics for demonstration
  StudyAnalytics get _sampleAnalytics => StudyAnalytics(
    userId: 'demo_user',
    lastUpdated: DateTime.now(),
    overallAccuracy: 0.78,
    totalStudyTime: 1250,
    totalCardsStudied: 340,
    totalQuizzesTaken: 15,
    currentStreak: 7,
    longestStreak: 12,
    subjectPerformance: {
      'Computer Science': SubjectPerformance(
        subject: 'Computer Science',
        accuracy: 0.82,
        totalCards: 120,
        totalQuizzes: 8,
        studyTimeMinutes: 480,
        lastStudied: DateTime.now().subtract(Duration(days: 1)),
        recentScores: [0.85, 0.80, 0.88, 0.75, 0.90],
        difficultyBreakdown: {'easy': 30, 'moderate': 60, 'challenging': 30},
        averageResponseTime: 12.5,
      ),
    },
    learningPatterns: LearningPatterns(
      preferredStudyHours: {'9': 5, '14': 8, '19': 3},
      learningStyleEffectiveness: {'visual': 0.85, 'auditory': 0.72},
      averageSessionLength: 35.0,
      preferredCardsPerSession: 15,
      topicInterest: {'programming': 0.92, 'algorithms': 0.88},
      commonMistakePatterns: ['syntax errors', 'logic flow'],
    ),
    recentTrend: PerformanceTrend(
      direction: 'improving',
      changeRate: 5.2,
      weeksAnalyzed: 4,
      weeklyData: [],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced Personalized AI System'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPersonalizationDemo(),
            SizedBox(height: 20),
            _buildInputSection(),
            SizedBox(height: 20),
            _buildGenerateButton(),
            SizedBox(height: 20),
            _buildGeneratedCards(),
            SizedBox(height: 20),
            PersonalizationFeaturesWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizationDemo() {
    final user = _sampleUser;
    final analytics = _sampleAnalytics;
    
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎯 AI Personalization Demo for ${user.name}', 
                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 12),
            
            // User Profile Context
            Text('👤 User Profile:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('  • Learning Style: ${user.preferences.learningStyle.toUpperCase()}'),
            Text('  • Difficulty: ${user.preferences.difficultyPreference}'),
            Text('  • Major: ${user.major} at ${user.school}'),
            Text('  • Study Time: ${user.preferences.studyStartHour}:00-${user.preferences.studyEndHour}:00'),
            SizedBox(height: 8),
            
            // Performance Analytics
            Text('📊 Performance Analytics:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('  • Overall Level: ${analytics.performanceLevel}'),
            Text('  • Accuracy: ${(analytics.overallAccuracy * 100).round()}%'),
            Text('  • Current Streak: ${analytics.currentStreak} days'),
            Text('  • CS Performance: ${(analytics.subjectPerformance['Computer Science']!.accuracy * 100).round()}%'),
            Text('  • Trend: ${analytics.recentTrend.direction} (+${analytics.recentTrend.changeRate}%/week)'),
            SizedBox(height: 8),
            
            // AI Adaptations
            Text('🤖 AI Adaptations Applied:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('  • Visual learner optimization (diagrams, spatial concepts)'),
            Text('  • CS major context (programming examples, technical terms)'),
            Text('  • Adaptive difficulty (currently: ${analytics.getRecommendedDifficulty('Computer Science')})'),
            Text('  • Performance-based adjustments (82% accuracy = moderate challenge)'),
            Text('  • Hints enabled (detailed explanations included)'),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📝 Input Configuration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        Text('Subject:', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter subject (e.g., Computer Science, Biology)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _subject = value,
          controller: TextEditingController(text: _subject),
        ),
        SizedBox(height: 16),
        Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter content to generate flashcards from',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) => _content = value,
          controller: TextEditingController(text: _content),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isGenerating ? null : () => _generatePersonalizedCards(_sampleUser, _sampleAnalytics),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: _isGenerating
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 8),
                  Text('Generating Personalized Cards...', style: TextStyle(color: Colors.white)),
                ],
              )
            : Text('🤖 Generate Personalized AI Flashcards', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _buildGeneratedCards() {
    if (_generatedCards.isEmpty) {
      return Text('No cards generated yet. Click the button above to create personalized flashcards!');
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generated Cards:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _generatedCards.length,
              itemBuilder: (context, index) {
                final card = _generatedCards[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text('Card ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Question:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(card.front),
                            SizedBox(height: 12),
                            Text('Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(card.back),
                            SizedBox(height: 12),
                            Text('Multiple Choice Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...card.multipleChoiceOptions.asMap().entries.map((entry) {
                              final index = entry.key;
                              final option = entry.value;
                              final isCorrect = index == card.correctAnswerIndex;
                              return Padding(
                                padding: EdgeInsets.only(left: 16, top: 4),
                                child: Text(
                                  '${String.fromCharCode(65 + index)}) $option',
                                  style: TextStyle(
                                    color: isCorrect ? Colors.green : Colors.black,
                                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  label: Text('Difficulty: ${card.difficulty}/5'),
                                  backgroundColor: _getDifficultyColor(card.difficulty),
                                ),
                                SizedBox(width: 8),
                                Chip(
                                  label: Text('Correct: ${String.fromCharCode(65 + card.correctAnswerIndex)}'),
                                  backgroundColor: Colors.green[100],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
      case 2:
        return Colors.green[100]!;
      case 3:
        return Colors.orange[100]!;
      case 4:
      case 5:
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Future<void> _generatePersonalizedCards(User user, StudyAnalytics analytics) async {
    if (_content.trim().isEmpty || _subject.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both subject and content')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedCards.clear();
    });

    try {
      // Generate flashcards with full personalization
      final cards = await _aiService.generateFlashcardsFromText(
        _content,
        _subject,
        user,
        count: 5,
        analytics: analytics,
      );

      setState(() {
        _generatedCards = cards;
      });

      // Show success message with personalization details
      String personalizationInfo = 'Generated for ${user.preferences.learningStyle} learner (${analytics.performanceLevel} level)';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Personalized cards generated! $personalizationInfo'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Show demo cards if AI service fails
      setState(() {
        _generatedCards = _createDemoCards();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📝 Demo cards generated (AI service not configured)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  /// Create demo cards showing personalization features
  List<FlashCard> _createDemoCards() {
    return [
      FlashCard(
        id: 'demo_1',
        deckId: 'demo_deck',
        type: CardType.basic,
        front: 'In object-oriented programming, what is the concept that allows a class to inherit properties and methods from another class?',
        back: 'Inheritance\n\n💡 Think of it like a family tree - child classes inherit traits from their parent class, just like you inherit traits from your parents!',
        multipleChoiceOptions: ['Encapsulation', 'Polymorphism', 'Inheritance', 'Abstraction'],
        correctAnswerIndex: 2,
        difficulty: 3,
      ),
      FlashCard(
        id: 'demo_2',
        deckId: 'demo_deck',
        type: CardType.basic,
        front: 'Which principle of OOP involves bundling data and methods that operate on that data within a single unit?',
        back: 'Encapsulation\n\n💡 Picture a capsule that contains medicine - encapsulation "capsules" or wraps data and methods together to protect them!',
        multipleChoiceOptions: ['Inheritance', 'Encapsulation', 'Polymorphism', 'Composition'],
        correctAnswerIndex: 1,
        difficulty: 2,
      ),
      FlashCard(
        id: 'demo_3',
        deckId: 'demo_deck',
        type: CardType.basic,
        front: 'What OOP concept allows objects of different classes to be treated as objects of a common base class?',
        back: 'Polymorphism\n\n💡 "Poly" means many, "morph" means forms - one interface, many implementations! Like how different animals all "move" but in different ways.',
        multipleChoiceOptions: ['Abstraction', 'Polymorphism', 'Inheritance', 'Encapsulation'],
        correctAnswerIndex: 1,
        difficulty: 4,
      ),
    ];
  }
}

/// Widget showing AI personalization features summary
class PersonalizationFeaturesWidget extends StatelessWidget {
  const PersonalizationFeaturesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🤖 AI Personalization Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildFeature('🎯', 'Learning Style Adaptation', 
                'Optimizes questions for Visual, Auditory, Kinesthetic, or Reading/Writing learners'),
            _buildFeature('📊', 'Performance Integration', 
                'Adjusts difficulty based on your subject-specific performance history'),
            _buildFeature('🎓', 'Educational Context', 
                'Adapts content to your school, major, and academic level'),
            _buildFeature('⚡', 'Adaptive Difficulty', 
                'Automatically adjusts challenge level based on your progress'),
            _buildFeature('📈', 'Learning Patterns', 
                'Uses your study habits and preferred times for optimal content'),
            _buildFeature('🎨', 'Multi-Modal Questions', 
                'Varies question types based on what works best for you'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}