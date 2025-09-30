// AI SYSTEM LIVE TESTING SCREEN
// This screen allows manual validation of AI features in the running app

import 'package:flutter/material.dart';
import '../utils/ai_system_validator.dart';

class AISystemTestScreen extends StatefulWidget {
  const AISystemTestScreen({super.key});
  
  @override
  AISystemTestScreenState createState() => AISystemTestScreenState();
}

class AISystemTestScreenState extends State<AISystemTestScreen> {
  Map<String, bool>? validationResults;
  bool isRunning = false;
  String testOutput = '';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🚀 AI System Validation', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo[700]!, Colors.indigo[900]!],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 24),
              _buildValidationButton(),
              SizedBox(height: 24),
              _buildTestOutput(),
              SizedBox(height: 16),
              if (validationResults != null) _buildResultsDisplay(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Card(
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.indigo[700], size: 32),
                SizedBox(width: 12),
                Text(
                  'Comprehensive AI System Validation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'This tool validates that ALL AI features from the enhancement requirements are implemented correctly and working as intended.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border(left: BorderSide(width: 4, color: Colors.orange)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '⚡ CRITICAL VALIDATION: "The world depends on this update, YOU CANNOT FAIL, IT HAS TO BE PERFECT!"',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildValidationButton() {
    return Center(
      child: isRunning
          ? Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Running comprehensive validation...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            )
          : ElevatedButton.icon(
              onPressed: _runValidation,
              icon: Icon(Icons.play_arrow, size: 24),
              label: Text('🚀 RUN COMPLETE AI VALIDATION', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
            ),
    );
  }
  
  Widget _buildTestOutput() {
    if (testOutput.isEmpty) return SizedBox();
    
    return Expanded(
      child: Card(
        color: Colors.black87,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.terminal, color: Colors.green[400]),
                  SizedBox(width: 8),
                  Text(
                    'Validation Output',
                    style: TextStyle(
                      color: Colors.green[400],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    testOutput,
                    style: TextStyle(
                      color: Colors.green[300],
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultsDisplay() {
    if (validationResults == null) return SizedBox();
    
    final passed = validationResults!.values.where((result) => result).length;
    final total = validationResults!.length;
    final percentage = ((passed / total) * 100).round();
    
    Color resultColor = percentage >= 90 ? Colors.green : 
                       percentage >= 75 ? Colors.orange : Colors.red;
    
    return Card(
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  percentage >= 90 ? Icons.check_circle : 
                  percentage >= 75 ? Icons.warning : Icons.error,
                  color: resultColor,
                  size: 32,
                ),
                SizedBox(width: 12),
                Text(
                  'Validation Results',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Overall Score
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: resultColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '$passed/$total tests passed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$percentage% Success Rate',
                    style: TextStyle(
                      fontSize: 18,
                      color: resultColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: passed / total,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(resultColor),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Status Message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                percentage >= 90 ? '🎉 EXCELLENT! AI System is fully implemented and working correctly!' :
                percentage >= 75 ? '✅ GOOD! AI System is mostly implemented with minor issues.' :
                percentage >= 50 ? '⚠️ PARTIAL! AI System has significant gaps that need attention.' :
                '❌ CRITICAL! AI System has major implementation issues.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: resultColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _runValidation() async {
    setState(() {
      isRunning = true;
      testOutput = '';
      validationResults = null;
    });
    
    try {
      // Create validator and initialize
      final validator = AISystemValidator();
      validator.initialize();
      
      // Capture console output
      String output = '';
      
      // Add header to output
      output += '🚀 STARTING COMPREHENSIVE AI SYSTEM VALIDATION\n';
      output += '═══════════════════════════════════════════════\n';
      output += 'Testing all 6 major AI enhancement tasks...\n\n';
      
      // Run validation and capture results
      final results = await validator.validateAllFeatures();
      
      // Add results summary to output
      final passed = results.values.where((result) => result).length;
      final total = results.length;
      final percentage = ((passed / total) * 100).round();
      
      output += '\n🎯 VALIDATION RESULTS SUMMARY\n';
      output += '═══════════════════════════════════════════════\n';
      output += 'Overall Score: $passed/$total ($percentage%)\n\n';
      
      // Group results by task
      final tasks = {
        'Task 1 - AI Service Integration': ['16LayerPersonalization', 'MultiModalInstructions', 'ContextualInstructions', 'TimeBasedInstructions'],
        'Task 2 - Multi-Modal Generation': ['LearningStyleAdaptation', 'CardTypeVariety'],
        'Task 3 - Question Type Variety': ['18QuestionTypes', 'QuestionInstructions'],
        'Task 4 - Difficulty Adaptation': ['DifficultyAdaptation', 'PerformanceContext'],
        'Task 5 - Analytics Feedback': ['AnalyticsInstructions', 'AdaptiveRecommendations'],
        'Task 6 - Advanced Formats': ['AdvancedFormats', 'FallbackCards'],
        'Integration Testing': ['FullIntegration', 'ErrorHandling'],
      };
      
      for (final task in tasks.entries) {
        final taskResults = task.value.map((key) => results[key] ?? false).toList();
        final taskPassed = taskResults.where((result) => result).length;
        final taskTotal = taskResults.length;
        final taskPercentage = ((taskPassed / taskTotal) * 100).round();
        
        final status = taskPercentage == 100 ? '✅' : taskPercentage >= 75 ? '⚠️' : '❌';
        output += '$status ${task.key}: $taskPassed/$taskTotal ($taskPercentage%)\n';
      }
      
      output += '\n═══════════════════════════════════════════════\n';
      
      if (percentage >= 90) {
        output += '🎉 EXCELLENT! AI System is fully implemented!\n';
      } else if (percentage >= 75) {
        output += '✅ GOOD! AI System is mostly implemented.\n';
      } else if (percentage >= 50) {
        output += '⚠️ PARTIAL! AI System has significant gaps.\n';
      } else {
        output += '❌ CRITICAL! AI System has major issues.\n';
      }
      
      setState(() {
        validationResults = results;
        testOutput = output;
        isRunning = false;
      });
      
    } catch (e) {
      setState(() {
        testOutput = 'ERROR: Failed to run validation - $e';
        isRunning = false;
      });
    }
  }
}