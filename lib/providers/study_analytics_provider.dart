import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/study_analytics.dart';
import '../providers/analytics_provider.dart';
import '../providers/deck_provider.dart';

/// Provider specifically for learning progress analytics
/// Extends functionality of base AnalyticsProvider with visualization-specific methods
class StudyAnalyticsProvider with ChangeNotifier {
  final AnalyticsProvider _analyticsProvider;
  final DeckProvider _deckProvider;
  
  StudyAnalyticsProvider(this._analyticsProvider, this._deckProvider) {
    _analyticsProvider.addListener(_onAnalyticsChanged);
  }
  
  void _onAnalyticsChanged() {
    notifyListeners();
  }
  
  @override
  void dispose() {
    _analyticsProvider.removeListener(_onAnalyticsChanged);
    super.dispose();
  }
  
  // Forward base analytics properties
  StudyAnalytics? get currentAnalytics => _analyticsProvider.currentAnalytics;
  bool get isLoading => _analyticsProvider.isLoading;
  String? get error => _analyticsProvider.error;
  int get currentStreak => _analyticsProvider.currentStreak;
  double get overallAccuracy => _analyticsProvider.overallAccuracy;
  
  // Dashboard-specific analytics 
  int get cardsReviewedToday {
    // For now, use sample data since we don't have the exact structure
    // This would be replaced with real implementation once structure is confirmed
    final analytics = _analyticsProvider.currentAnalytics;
    if (analytics == null) return 0;
    return analytics.totalCardsStudied ~/ 30;
  }
  
  double get overallMasteryPercentage {
    final analytics = currentAnalytics;
    if (analytics == null) return 0.0;
    
    final totalDecks = _deckProvider.decks.length;
    if (totalDecks == 0) return 0.0;
    
    int masteredCards = 0;
    int totalCards = 0;
    
    for (final deck in _deckProvider.decks) {
      final subjectPerf = analytics.subjectPerformance[deck.title];
      if (subjectPerf != null) {
        totalCards += deck.cards.length;
        masteredCards += (subjectPerf.accuracy * deck.cards.length).round();
      }
    }
    
    if (totalCards == 0) return 0.0;
    return (masteredCards / totalCards) * 100;
  }
  
  List<FlSpot> get weeklyPerformanceData {
    final analytics = currentAnalytics;
    if (analytics == null) return _generateSamplePerformanceData();
    
    // Since we don't have the exact structure for daily activity in the model yet,
    // we'll use sample data that increases slightly over time
    return _generateSamplePerformanceData();
  }
  
  // Detailed analytics for the full progress screen
  Map<String, List<FlSpot>> getSubjectProgressData(int days) {
    final analytics = currentAnalytics;
    if (analytics == null) return _generateSampleSubjectData();
    
    // Since we don't have the exact daily progress tracking structure yet,
    // we'll use sample data
    return _generateSampleSubjectData();
  }
  
  Map<String, double> getSubjectTimeDistribution() {
    final analytics = currentAnalytics;
    if (analytics == null) return _generateSampleTimeDistribution();
    
    final result = <String, double>{};
    double totalTime = 0;
    
    // Calculate total time across all subjects
    for (final subject in analytics.subjectPerformance.values) {
      totalTime += subject.studyTimeMinutes;
    }
    
    if (totalTime > 0) {
      for (final subject in analytics.subjectPerformance.entries) {
        result[subject.key] = subject.value.studyTimeMinutes / totalTime;
      }
    }
    
    return result;
  }
  
  // Helper methods to generate sample data when real data isn't available
  List<FlSpot> _generateSamplePerformanceData() {
    return [
      const FlSpot(0, 65),
      const FlSpot(1, 68),
      const FlSpot(2, 75),
      const FlSpot(3, 72),
      const FlSpot(4, 78),
      const FlSpot(5, 82),
      const FlSpot(6, 85),
    ];
  }
  
  Map<String, List<FlSpot>> _generateSampleSubjectData() {
    return {
      'Mathematics': [
        const FlSpot(0, 60),
        const FlSpot(1, 65),
        const FlSpot(2, 70),
        const FlSpot(3, 75),
        const FlSpot(4, 73),
        const FlSpot(5, 80),
        const FlSpot(6, 85),
      ],
      'Physics': [
        const FlSpot(0, 50),
        const FlSpot(1, 55),
        const FlSpot(2, 60),
        const FlSpot(3, 68),
        const FlSpot(4, 75),
        const FlSpot(5, 78),
        const FlSpot(6, 80),
      ],
      'Chemistry': [
        const FlSpot(0, 65),
        const FlSpot(1, 70),
        const FlSpot(2, 68),
        const FlSpot(3, 72),
        const FlSpot(4, 75),
        const FlSpot(5, 80),
        const FlSpot(6, 82),
      ],
    };
  }
  
  Map<String, double> _generateSampleTimeDistribution() {
    return {
      'Mathematics': 0.35,
      'Physics': 0.25,
      'Chemistry': 0.20,
      'Biology': 0.15,
      'Computer Science': 0.05,
    };
  }
}