# AI Tutor Enhancement - Integration & Rollout Plan

## Overview
This document describes how to integrate the new AI tutor validation middleware into the existing StudyPals system and roll it out safely to production.

## Architecture Summary

### New Components Added
1. **Models**
   - `user_profile_data.dart` - User profile with learning preferences and opt-in flags
   
2. **Services**
   - `user_profile_store.dart` - Persistent profile storage (Firestore)
   - `session_context.dart` - Ephemeral conversation tracking
   - `learning_style_detector.dart` - Automatic learning style detection
   - `math_engine.dart` - Math expression validator
   - `memory_claim_validator.dart` - False memory claim detector
   - `ai_tutor_middleware.dart` - Main pre/post processing coordinator

3. **Tests**
   - `ai_tutor_regression_test.dart` - Automated QA test runner

### How It Works
```
User Message
    ↓
[PRE-PROCESSING]
    ├─ Load session context (last 50 messages)
    ├─ Load user profile (if opted in)
    ├─ Detect learning style from patterns
    └─ Build enhanced system prompt
    ↓
LLM Call (existing)
    ↓
[POST-PROCESSING]
    ├─ Validate memory claims
    ├─ Validate math calculations
    ├─ Apply corrections if needed
    └─ Add fallback if multiple failures
    ↓
Final Response to User
```

---

## Phase 1: Integration (Non-Breaking)

### Step 1: Add Middleware to Enhanced AI Tutor Provider

**File**: `lib/providers/enhanced_ai_tutor_provider.dart`

**Location**: In the `sendMessage` method, wrap the existing LLM call

**Before**:
```dart
Future<void> sendMessage(String content) async {
  // ... existing code ...
  
  // Direct LLM call
  final response = await _tutorService.generateResponse(...);
  
  // ... rest of code ...
}
```

**After**:
```dart
// Add import at top
import '../services/ai_tutor_middleware.dart';

// Add field to class
final AITutorMiddleware _middleware = AITutorMiddleware();

Future<void> sendMessage(String content) async {
  // ... existing code ...
  
  // PRE-PROCESS
  final preContext = await _middleware.preProcessMessage(
    userId: _currentSession?.userId ?? 'anonymous',
    message: content,
  );
  
  // LLM call with enhanced prompt
  final response = await _tutorService.generateResponse(
    systemPrompt: preContext.systemPrompt,  // Use enhanced prompt
    userMessage: content,
    // ... other params ...
  );
  
  // POST-PROCESS
  final postResult = await _middleware.postProcessResponse(
    userId: _currentSession?.userId ?? 'anonymous',
    message: content,
    llmResponse: response,
    context: preContext,
  );
  
  // Use corrected response
  final finalResponse = postResult.response;
  
  // ... rest of code uses finalResponse ...
}
```

### Step 2: Update Firestore Rules

**File**: `firestore.rules`

Add rules for user_profiles collection:

```
match /user_profiles/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

### Step 3: Feature Flags Setup

Create a feature flags service to control rollout:

**File**: `lib/config/feature_flags.dart`

```dart
class FeatureFlags {
  static bool memoryValidation = false;
  static bool mathValidation = false;
  static bool styleAdaptation = false;
  static bool profileStorage = false;
  
  // Enable for specific user IDs (for testing)
  static Set<String> betaUsers = {};
  
  static bool isEnabled(String feature, String userId) {
    if (betaUsers.contains(userId)) return true;
    
    switch (feature) {
      case 'memoryValidation':
        return memoryValidation;
      case 'mathValidation':
        return mathValidation;
      case 'styleAdaptation':
        return styleAdaptation;
      case 'profileStorage':
        return profileStorage;
      default:
        return false;
    }
  }
}
```

Update middleware to respect flags:

```dart
// In ai_tutor_middleware.dart postProcessResponse method

// Only validate memory if flag enabled
if (FeatureFlags.isEnabled('memoryValidation', userId)) {
  final memoryValidation = MemoryClaimValidator.validate(...);
  // ... validation logic ...
}

// Only validate math if flag enabled  
if (FeatureFlags.isEnabled('mathValidation', userId)) {
  final mathValidation = await MathEngine.validateAndAnnotate(...);
  // ... validation logic ...
}
```

---

## Phase 2: Testing

### Automated Tests

Run regression tests:

```bash
flutter test test/ai_tutor_regression_test.dart
```

### Manual Testing Checklist

1. **Memory Claims**
   - [ ] Ask "Do you remember what we discussed?" with no prior conversation
   - [ ] Verify response doesn't assert false memory
   - [ ] Verify response offers to explain or asks for clarification

2. **Math Validation**
   - [ ] Ask "What is 2 + 2?"
   - [ ] Provide intentionally wrong answer in system
   - [ ] Verify correction appears in response

3. **Learning Style Detection**
   - [ ] Have conversation asking for "visual examples"
   - [ ] Check that subsequent responses adapt to visual style
   - [ ] Verify style detection in session stats

4. **Profile Opt-In**
   - [ ] Create UI for profile opt-in (or use test code)
   - [ ] Verify data only stored after opt-in
   - [ ] Test profile deletion

### Test with QA File

Create test script to process AI TUTOR QUESTIONS.txt:

```dart
void main() async {
  final runner = AITutorTestRunner();
  final results = await runner.runAllTests(
    'path/to/AI TUTOR QUESTIONS.txt'
  );
  
  print(results.getSummary());
  
  // Fail CI if pass rate < 80%
  if (results.passRate < 0.8) {
    exit(1);
  }
}
```

---

## Phase 3: Gradual Rollout

### Week 1: Internal Testing
- Enable all features for dev team user IDs
- Monitor telemetry dashboard
- Fix any critical issues

```dart
FeatureFlags.betaUsers = {'dev_user_1', 'dev_user_2', ...};
```

### Week 2: Beta Cohort (10% of users)
- Enable memory validation for 10% of users
- Monitor error rates and user feedback

```dart
FeatureFlags.memoryValidation = true;
// In middleware, add random sampling:
if (Random().nextDouble() < 0.1 || betaUsers.contains(userId)) {
  // Enable feature
}
```

### Week 3: Expand to 50%
- If metrics look good, expand to 50%
- Add math validation to beta

```dart
FeatureFlags.mathValidation = true;
```

### Week 4: Full Rollout
- Enable for 100% if no issues
- Enable learning style adaptation

```dart
FeatureFlags.memoryValidation = true;
FeatureFlags.mathValidation = true;
FeatureFlags.styleAdaptation = true;
```

---

## Monitoring & Telemetry

### Metrics to Track

Create dashboard to monitor:

1. **Memory Validation**
   - Total claims detected per day
   - Invalid claims caught per day
   - Correction rate
   - User satisfaction after corrections

2. **Math Validation**
   - Math expressions found per day
   - Errors detected per day
   - Correction rate

3. **Learning Style**
   - Distribution of detected styles
   - Adaptation confidence scores
   - User engagement metrics

4. **Performance**
   - Pre-processing latency (target: <100ms)
   - Post-processing latency (target: <200ms)
   - Total overhead (target: <300ms)

### Logging Setup

Add to `ai_tutor_middleware.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

// In postProcessResponse
FirebaseAnalytics.instance.logEvent(
  name: 'ai_tutor_validation',
  parameters: {
    'memory_valid': memoryValid,
    'math_valid': mathValid,
    'corrections_count': corrections.length,
    'used_fallback': telemetry['usedFallback'] ?? false,
  },
);
```

---

## Rollback Plan

If issues arise:

1. **Immediate**: Disable feature flags
   ```dart
   FeatureFlags.memoryValidation = false;
   FeatureFlags.mathValidation = false;
   ```

2. **Partial**: Reduce beta percentage
   ```dart
   // Roll back to 10%
   if (Random().nextDouble() < 0.1) { ... }
   ```

3. **Complete**: Remove middleware wrapper
   - Comment out pre/post processing calls
   - System reverts to original behavior

---

## Migration Script

For existing users, migrate to new schema:

**File**: `lib/scripts/migrate_user_data.dart`

```dart
Future<void> migrateUserData() async {
  final firestore = FirebaseFirestore.instance;
  
  // Get all existing users
  final usersSnapshot = await firestore.collection('users').get();
  
  for (final doc in usersSnapshot.docs) {
    final userId = doc.id;
    
    // Create default profile (opt-out by default)
    final profile = UserProfileData(
      userId: userId,
      displayName: doc.data()['displayName'],
      optInFlags: OptInFlags(), // All false by default
    );
    
    // Store in new collection
    await firestore
        .collection('user_profiles')
        .doc(userId)
        .set(profile.toJson());
  }
  
  print('Migrated ${usersSnapshot.docs.length} users');
}
```

---

## Success Criteria

Consider rollout successful when:

- ✅ Regression test pass rate > 90%
- ✅ No increase in error rates
- ✅ False memory claims reduced by >80%
- ✅ Math error corrections working in >95% of cases
- ✅ User feedback positive (>4.0/5.0 rating)
- ✅ Performance overhead < 300ms
- ✅ No privacy incidents
- ✅ Beta users report improved experience

---

## Next Steps After Rollout

1. **Semantic Memory** - Add vector embeddings for better topic matching
2. **Advanced Math** - Integrate symbolic math library for algebra/calculus
3. **Multi-turn Scaffolding** - Implement Socratic questioning chains
4. **Personalization Dashboard** - UI for users to view/edit their learning profile
5. **A/B Testing** - Compare personalized vs non-personalized responses

---

## Support & Documentation

- **Code Documentation**: All services have inline comments
- **API Docs**: See each service file for public API methods
- **Test Coverage**: Run `flutter test --coverage`
- **Issues**: Track in GitHub Issues with label `ai-enhancement`

---

## Contact

For questions about this integration:
- Review inline code comments
- Check test files for usage examples
- See `ai_tutor_middleware.dart` for main integration point
