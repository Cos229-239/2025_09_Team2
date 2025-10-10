# Study Analytics - Manual Testing Guide

## 🧪 Overview
This guide provides step-by-step instructions for manually testing all the newly implemented analytics features in StudyPals. Follow these tests to verify that all TODO implementations are working correctly.

---

## 🚀 Quick Start Testing

### Option 1: Run Automated Tests (Recommended)
The fastest way to verify everything works:

```bash
# Run the comprehensive test suite
flutter test test/models/study_analytics_test.dart

# Expected output: 17/17 tests passing ✅
```

**✅ If all tests pass, the core logic is working correctly!**

---

## 📱 Manual App Testing

### Prerequisites
1. Start the app: `flutter run`
2. Create a test user account or login
3. Have at least 2-3 decks with flashcards ready
4. Be prepared to study for a few minutes

---

## Test Plan: Complete Walkthrough

### 🎯 Test 1: Study Session Tracking

**Objective:** Verify that study sessions are tracked and activities are recorded correctly.

**Steps:**
1. **Start a Study Session**
   - Navigate to a deck
   - Start studying flashcards
   - Expected: Study session begins automatically

2. **Perform Various Activities**
   - View at least 5 cards (flip them, read them)
   - Answer at least 3 cards (mark correct/incorrect)
   - Use a hint on 1 card (if available)
   - Skip 1 card

3. **Check Session Recording**
   - Open DevTools console or check logs
   - Look for: `SessionActivity` entries being created
   - Expected: Each action creates an activity record

4. **End Study Session**
   - Exit the deck or complete the session
   - Expected: Session end time is recorded

**Verification Points:**
- ✅ Session has start and end times
- ✅ All activities are recorded with timestamps
- ✅ Response times are captured for answers

---

### 🎯 Test 2: Quiz Session Analytics

**Objective:** Test quiz session tracking and score calculation.

**Steps:**
1. **Take a Quiz**
   - Select a deck
   - Start a quiz (if quiz mode available)
   - Answer all questions
   - Complete the quiz

2. **Check Quiz Results**
   - View your quiz score
   - Check the results screen

3. **Verify Data Capture**
   - Quiz should save:
     - Final score (percentage)
     - Individual answers
     - Deck/subject association
     - Completion time

**Verification Points:**
- ✅ Quiz score is calculated correctly
- ✅ Quiz appears in subject performance
- ✅ Recent scores list is populated

---

### 🎯 Test 3: Subject Performance Analysis

**Objective:** Verify subject-specific analytics are calculated correctly.

**Steps:**
1. **Study Multiple Subjects**
   - Study cards from at least 2 different subjects
   - Complete at least 1 quiz in each subject
   - Answer some correctly and some incorrectly

2. **Check Subject Analytics** (via Debug Console or Analytics Screen)
   ```dart
   // Add temporary debug code to your analytics screen:
   print('Subject Performance:');
   for (var entry in analytics.subjectPerformance.entries) {
     print('Subject: ${entry.key}');
     print('  Accuracy: ${(entry.value.accuracy * 100).toStringAsFixed(1)}%');
     print('  Total Cards: ${entry.value.totalCards}');
     print('  Total Quizzes: ${entry.value.totalQuizzes}');
     print('  Recent Scores: ${entry.value.recentScores}');
     print('  Avg Response Time: ${entry.value.averageResponseTime.toStringAsFixed(2)}s');
     print('  Difficulty Breakdown: ${entry.value.difficultyBreakdown}');
   }
   ```

**Expected Results:**
- ✅ Each subject shows separate statistics
- ✅ Accuracy reflects your performance
- ✅ Quiz count matches quizzes taken
- ✅ Recent scores list shows last quiz scores
- ✅ Response times are in reasonable ranges (1-30 seconds)
- ✅ Difficulty breakdown shows easy/moderate/hard counts

---

### 🎯 Test 4: Learning Patterns Detection

**Objective:** Test learning style and pattern analysis.

**Steps:**
1. **Study at Different Times**
   - Study in morning (before 12pm)
   - Study in afternoon (12pm-5pm)
   - Study in evening (after 5pm)

2. **Check Preferred Study Hours**
   ```dart
   print('Preferred Study Hours: ${analytics.learningPatterns.preferredStudyHours}');
   print('Preferred Time: ${analytics.learningPatterns.preferredStudyTime}');
   ```

3. **Check Learning Style Effectiveness**
   ```dart
   print('Learning Styles: ${analytics.learningPatterns.learningStyleEffectiveness}');
   print('Most Effective: ${analytics.learningPatterns.mostEffectiveLearningStyle}');
   ```

4. **Check Topic Interest**
   ```dart
   print('Topic Interest Scores: ${analytics.learningPatterns.topicInterest}');
   ```

**Expected Results:**
- ✅ Study hours map shows when you studied
- ✅ Preferred time matches your most frequent study hour
- ✅ Learning styles show effectiveness scores (0-1)
- ✅ Topic interest scores reflect engagement (0-1)
- ✅ Topics you studied more have higher interest scores

---

### 🎯 Test 5: Mistake Pattern Analysis

**Objective:** Verify common mistake detection works.

**Steps:**
1. **Create Mistake Patterns**
   - Answer the same card incorrectly multiple times
   - Make several mistakes in a row
   - Take longer to answer some questions

2. **Check Mistake Patterns**
   ```dart
   print('Common Mistakes: ${analytics.learningPatterns.commonMistakePatterns}');
   ```

**Expected Patterns:**
- ✅ "Repeated errors on X cards" (if you got same cards wrong)
- ✅ "High error rate in recent sessions" (if accuracy is low recently)
- ✅ "Slower response times on incorrect answers" (if slow + wrong)

---

### 🎯 Test 6: Performance Trend Tracking

**Objective:** Test weekly trend analysis and direction detection.

**Steps:**
1. **Study Over Multiple Days** (Best Results)
   - Study today
   - Study yesterday (or wait and study tomorrow)
   - Study 2-3 days ago (or simulate with test data)

2. **Check Weekly Statistics**
   ```dart
   print('Weeks Analyzed: ${analytics.recentTrend.weeksAnalyzed}');
   print('Trend Direction: ${analytics.recentTrend.direction}');
   print('Change Rate: ${analytics.recentTrend.changeRate.toStringAsFixed(2)}%');
   
   for (var week in analytics.recentTrend.weeklyData) {
     print('Week ${week.weekStart}: Accuracy ${(week.averageAccuracy * 100).toStringAsFixed(1)}%');
   }
   ```

**Expected Results:**
- ✅ 4 weeks of data (some may be empty)
- ✅ Current week shows your recent activity
- ✅ Direction is 'improving', 'declining', or 'stable'
- ✅ Change rate shows percentage per week
- ✅ Weekly data shows accuracy, time, cards, quizzes

---

### 🎯 Test 7: Streak Calculation

**Objective:** Verify streak tracking works correctly.

**Steps:**
1. **Build a Streak**
   - Study today
   - Study yesterday (or check if you did)
   - Continue for consecutive days

2. **Check Streak Values**
   ```dart
   print('Current Streak: ${analytics.currentStreak} days');
   print('Longest Streak: ${analytics.longestStreak} days');
   ```

3. **Test Streak Breaking**
   - Skip a day (don't study)
   - Study again the next day
   - Check that streak reset to 1

**Expected Results:**
- ✅ Current streak matches consecutive study days
- ✅ Longest streak is >= current streak
- ✅ Streak resets to 0 if you miss a day
- ✅ Streak starts at 1 when you study after missing days

---

### 🎯 Test 8: Incremental Updates

**Objective:** Test that analytics update efficiently without full recalculation.

**Steps:**
1. **Load Initial Analytics**
   ```dart
   final initial = await analyticsService.getUserAnalytics(userId);
   print('Initial Total Cards: ${initial.totalCardsStudied}');
   print('Initial Study Time: ${initial.totalStudyTime}');
   ```

2. **Study a Few Cards**
   - Study 5 new cards
   - Answer 3 correctly, 2 incorrectly

3. **Refresh Analytics**
   ```dart
   final updated = await analyticsService.getUserAnalytics(userId);
   print('Updated Total Cards: ${updated.totalCardsStudied}');
   print('Updated Study Time: ${updated.totalStudyTime}');
   ```

**Expected Results:**
- ✅ Total cards increased by 5
- ✅ Study time increased
- ✅ Accuracy updated correctly
- ✅ Subject performance updated
- ✅ Update happens quickly (< 1 second)

---

### 🎯 Test 9: Overall Analytics Summary

**Objective:** Verify all summary metrics are calculated correctly.

**Steps:**
1. **View Analytics Dashboard** (if available in your app)
   - Navigate to profile or analytics screen

2. **Check Overall Metrics**
   ```dart
   print('=== Overall Analytics ===');
   print('User: ${analytics.userId}');
   print('Performance Level: ${analytics.performanceLevel}');
   print('Overall Accuracy: ${(analytics.overallAccuracy * 100).toStringAsFixed(1)}%');
   print('Total Study Time: ${analytics.totalStudyTime} minutes');
   print('Total Cards Studied: ${analytics.totalCardsStudied}');
   print('Total Quizzes: ${analytics.totalQuizzesTaken}');
   print('Current Streak: ${analytics.currentStreak} days');
   print('Longest Streak: ${analytics.longestStreak} days');
   print('Struggling Subjects: ${analytics.strugglingSubjects}');
   print('Strong Subjects: ${analytics.strongSubjects}');
   ```

**Expected Results:**
- ✅ All values are reasonable and match your activity
- ✅ Performance level is one of: Expert, Advanced, Intermediate, Developing, Beginner
- ✅ Struggling subjects have accuracy < 70%
- ✅ Strong subjects have accuracy >= 85%

---

## 🔍 Debugging Tips

### Enable Debug Logging

Add this to your app's main initialization:
```dart
// In main.dart or analytics service
void main() {
  debugPrint('Analytics Debug Mode Enabled');
  runApp(MyApp());
}
```

### Add Debug Print Statements

Temporarily add to `analytics_service.dart`:
```dart
Future<StudyAnalytics> calculateAndUpdateAnalytics(String userId) async {
  final sessions = await _getSessions(userId);
  final quizzes = await _getQuizSessions(userId);
  
  debugPrint('📊 Calculating analytics...');
  debugPrint('  Sessions: ${sessions.length}');
  debugPrint('  Quizzes: ${quizzes.length}');
  
  final analytics = AnalyticsCalculator.calculateUserAnalytics(
    userId: userId,
    sessions: sessions,
    quizSessions: quizzes,
    reviews: [],
  );
  
  debugPrint('  ✅ Analytics calculated successfully');
  debugPrint('  Accuracy: ${(analytics.overallAccuracy * 100).toStringAsFixed(1)}%');
  
  return analytics;
}
```

### Check Firebase/Database Directly

If using Firebase:
```dart
// In Firebase Console
- Go to Firestore
- Check 'study_sessions' collection
- Check 'quiz_sessions' collection
- Verify data structure matches models
```

---

## ✅ Validation Checklist

After completing all tests, verify:

### Data Integrity
- [ ] All study sessions have start/end times
- [ ] Activities have correct timestamps
- [ ] Quiz sessions have finalScore values
- [ ] Subject names are consistent

### Calculation Accuracy
- [ ] Overall accuracy matches manual calculation
- [ ] Subject totals add up correctly
- [ ] Streaks match consecutive days
- [ ] Weekly data covers 4 weeks

### Performance
- [ ] Analytics load in < 2 seconds
- [ ] Updates complete quickly
- [ ] No memory leaks or crashes
- [ ] Smooth UI during calculations

### Edge Cases
- [ ] Empty sessions handled gracefully
- [ ] Zero quiz sessions don't crash
- [ ] Missing subject names handled
- [ ] Future dates handled correctly

---

## 🐛 Common Issues & Solutions

### Issue: Analytics show 0 for everything
**Solution:** 
- Check if study sessions are being saved
- Verify user ID is correct
- Check database permissions
- Run automated tests to verify logic

### Issue: Streak is always 0
**Solution:**
- Check if sessions have correct dates
- Verify date comparison logic
- Study on consecutive days to test

### Issue: Subject performance not appearing
**Solution:**
- Ensure sessions have subject field set
- Check subject name consistency (case-sensitive)
- Verify quiz sessions link to correct decks

### Issue: Response times seem wrong
**Solution:**
- Check if responseTimeMs is being recorded
- Verify milliseconds are converted to seconds
- Ensure timer starts/stops correctly

---

## 📊 Expected Results After Testing

After completing manual testing, you should see:

1. **Study Sessions Tab:**
   - List of all your study sessions
   - Correct duration and card count
   - Subject associations

2. **Performance Tab:**
   - Overall accuracy percentage
   - Subject breakdown
   - Performance level badge
   - Streak counter

3. **Trends Tab:**
   - Weekly performance chart
   - Trend direction indicator
   - Change rate percentage

4. **Insights Tab:**
   - Preferred study times
   - Topic interest scores
   - Common mistake patterns
   - Learning style effectiveness

---

## 🎓 Advanced Testing

### Test with Different Scenarios

1. **High Performer:**
   - Answer most questions correctly (>90%)
   - Expected: "Expert" or "Advanced" level

2. **Struggling Student:**
   - Answer many incorrectly (<60%)
   - Expected: "Beginner" or "Developing" level

3. **Streak Master:**
   - Study 7+ consecutive days
   - Expected: High streak values

4. **Multi-Subject Learner:**
   - Study 5+ different subjects
   - Expected: Each subject tracked separately

---

## 📝 Testing Log Template

Use this to track your testing:

```
Date: ___________
Tester: ___________

Test Results:
[ ] Test 1: Study Session Tracking - PASS/FAIL
    Notes: ________________________________

[ ] Test 2: Quiz Session Analytics - PASS/FAIL
    Notes: ________________________________

[ ] Test 3: Subject Performance - PASS/FAIL
    Notes: ________________________________

[ ] Test 4: Learning Patterns - PASS/FAIL
    Notes: ________________________________

[ ] Test 5: Mistake Patterns - PASS/FAIL
    Notes: ________________________________

[ ] Test 6: Performance Trends - PASS/FAIL
    Notes: ________________________________

[ ] Test 7: Streak Calculation - PASS/FAIL
    Notes: ________________________________

[ ] Test 8: Incremental Updates - PASS/FAIL
    Notes: ________________________________

[ ] Test 9: Overall Analytics - PASS/FAIL
    Notes: ________________________________

Overall Status: PASS / FAIL / PARTIAL
Issues Found: ________________________________
```

---

## 🚀 Quick Smoke Test (5 Minutes)

If you're short on time, do this minimal test:

1. **Run automated tests**: `flutter test test/models/study_analytics_test.dart`
2. **Study 5 cards** in the app
3. **Take 1 quiz**
4. **Check analytics screen** for any crashes
5. **Verify numbers** look reasonable

**If all 5 steps complete without errors, core functionality is working! ✅**

---

## 📞 Support

If you encounter issues during testing:
1. Check the automated test results first
2. Review error logs in console
3. Verify data is being saved to database
4. Check this guide's troubleshooting section
5. Review implementation documentation

---

## ✅ Success Criteria

Testing is successful when:
- ✅ All automated tests pass (17/17)
- ✅ Manual tests show correct values
- ✅ No crashes or errors occur
- ✅ Performance is acceptable
- ✅ Edge cases are handled gracefully

**Happy Testing! 🎉**
