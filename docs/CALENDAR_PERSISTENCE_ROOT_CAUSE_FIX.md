# Calendar Events Not Persisting - Root Cause Analysis & Fix

## Problem
Calendar events (flashcards, notes, etc.) were **disappearing on app restart** even though they were being saved to Firestore successfully.

## Root Cause Investigation

### Evidence from Logs
**Before restart - Events ARE being saved:**
```
💾 Saving flashcard study event to Firestore: Study: AI Generated: Biology
✅ Created calendar event: 7NkXBEWZpkN8mWtgdenF
✅ Flashcard study event saved to Firestore with ID: 7NkXBEWZpkN8mWtgdenF

💾 Saving calendar event to Firestore: Review: Database Design Principles
✅ Created calendar event: tn5zzhl0TE8LvZTfO3PI
✅ Event saved to Firestore with ID: tn5zzhl0TE8LvZTfO3PI
```

**After restart - No loading messages:**
```
✅ Firebase initialized successfully
✅ Firestore configured with offline support
Google AI automatically configured on dashboard load
✅ Loaded 3 decks from Firestore
✅ Retrieved 0 reviews for user: CE0CRVDFulY3q7EPYLnvUn1RhGT2
❌ NO "📅 Loading calendar events from Firestore" message!
```

### Root Cause
The `CalendarProvider.initialize()` method was **NEVER being called** during app startup!

**The issue:**
1. `CalendarProvider` was created in `main.dart` with `ChangeNotifierProvider(create: (_) => CalendarProvider())`
2. But unlike other providers (TaskProvider, DeckProvider, etc.), its `initialize()` method was never invoked
3. Without calling `initialize()`, the `refreshAllEvents()` method that loads calendar events from Firestore was never triggered
4. So events were saved to Firestore ✅ but never loaded back ❌

## The Fix

### Step 1: Import CalendarProvider in Dashboard
**File:** `lib/screens/dashboard_screen.dart`

```dart
import 'package:studypals/providers/calendar_provider.dart'; // Calendar provider state
```

### Step 2: Initialize CalendarProvider in _loadData()
**File:** `lib/screens/dashboard_screen.dart`

```dart
Future<void> _loadData() async {
  // Get provider instances
  final taskProvider = Provider.of<TaskProvider>(context, listen: false);
  final deckProvider = Provider.of<DeckProvider>(context, listen: false);
  final petProvider = Provider.of<PetProvider>(context, listen: false);
  final srsProvider = Provider.of<SRSProvider>(context, listen: false);
  final questProvider = Provider.of<DailyQuestProvider>(context, listen: false);
  final aiProvider = Provider.of<StudyPalsAIProvider>(context, listen: false);
  final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
  
  // ✅ NEW: Get calendar provider instance
  final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);

  // ✅ NEW: Initialize calendar provider with references to other providers
  calendarProvider.initialize(
    taskProvider: taskProvider,
    questProvider: questProvider,
    petProvider: petProvider,
  );
  
  // ... rest of the loading code
}
```

### Step 3: Enhanced Logging in CalendarProvider
**File:** `lib/providers/calendar_provider.dart`

Added debug logging to track event saving and loading:

```dart
Future<void> _refreshCalendarEvents() async {
  // Clear old calendar events first
  _removeEventsByType(CalendarEventType.studySession);
  _removeEventsByType(CalendarEventType.flashcardStudy);
  _removeEventsByType(CalendarEventType.custom);
  // ... etc
  
  final eventMaps = await _firestoreService.getUserCalendarEvents(user.uid);
  
  print('📅 Loading ${eventMaps.length} calendar events from Firestore'); // NEW
  
  for (final eventMap in eventMaps) {
    final event = _convertFirestoreToCalendarEvent(eventMap);
    _addEventToMap(event);
    print('  ✅ Loaded event: ${event.title} (${event.type})'); // NEW
  }
  
  print('📅 Finished loading calendar events'); // NEW
}
```

## Expected Behavior After Fix

### On App Startup (After Login):
```
✅ Firebase initialized successfully
✅ Firestore configured with offline support
📅 Loading 4 calendar events from Firestore         ← NEW!
  ✅ Loaded event: Study: AI Generated: Biology (flashcardStudy)
  ✅ Loaded event: Review: React Hooks Study Guide (studySession)
  ✅ Loaded event: Complete JavaScript Assignment (task)
  ✅ Loaded event: Test (task)
📅 Finished loading calendar events                 ← NEW!
```

### When Creating New Events:
```
💾 Saving flashcard study event to Firestore: Study: Biology
✅ Created calendar event: xyz123
✅ Flashcard study event saved to Firestore with ID: xyz123
```

### On Restart/Logout-Login:
- All previously saved calendar events will reappear
- Events persist across sessions
- No data loss

## Why This Happened

The CalendarProvider had the infrastructure for persistence (Firestore save/load methods) but was missing the **initialization hook** that other providers had. This is a classic case of:

1. ✅ **Write path working:** Events being saved to Firestore
2. ❌ **Read path broken:** Events never loaded back from Firestore
3. 🔧 **Fix:** Connect the read path by calling `initialize()` on app startup

## Testing Checklist

✅ **Create Events:**
- [ ] Add flashcard study session → Check Firestore → Event saved with ID

✅ **Restart App:**
- [ ] Close browser tab
- [ ] Reopen app
- [ ] Check console for "📅 Loading X calendar events from Firestore"
- [ ] Verify events reappear on calendars

✅ **Logout/Login:**
- [ ] Create events
- [ ] Logout
- [ ] Login again
- [ ] Events should still be there

✅ **Cross-Device (if applicable):**
- [ ] Create events on Device A
- [ ] Login on Device B
- [ ] Events should sync via Firestore

## Files Modified

1. **lib/screens/dashboard_screen.dart**
   - Added `import 'package:studypals/providers/calendar_provider.dart'`
   - Added `calendarProvider` instance in `_loadData()`
   - Called `calendarProvider.initialize()` with other provider references

2. **lib/providers/calendar_provider.dart** (previously)
   - Added Firebase imports
   - Updated `createEvent()` to save to Firestore
   - Updated `addFlashcardStudyEvent()` to save to Firestore
   - Added `_refreshCalendarEvents()` to load from Firestore
   - Updated `updateEvent()` and `deleteEvent()` to persist changes
   - Added debug logging for troubleshooting

## Key Takeaway

**Always ensure provider initialization methods are called during app startup!**

Other providers (TaskProvider, DeckProvider, etc.) had their `loadX()` methods called in `_loadData()`. CalendarProvider needed the same treatment with its `initialize()` method.
