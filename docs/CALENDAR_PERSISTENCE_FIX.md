# Calendar Events Persistence Fix

## Problem
Calendar events (flashcard study sessions, note reviews, etc.) were **not persisting when users logged out**. All events were stored only in memory and lost on logout or app restart.

## Root Cause
The `CalendarProvider` was only storing events in an in-memory `Map<DateTime, List<CalendarEvent>> _events` without any Firebase Firestore persistence. While the `FirestoreService` already had calendar event methods implemented, the `CalendarProvider` wasn't using them.

## Solution
Added complete Firebase Firestore integration to `CalendarProvider`:

### 1. Added Firebase Dependencies
```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class CalendarProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ...
}
```

### 2. Updated `createEvent()` Method
**Before:** Only added events to in-memory map
```dart
// Add to internal events map
_addEventToMap(event);
```

**After:** Saves to Firestore and gets generated ID
```dart
// Convert to JSON for Firestore
final eventData = event.toJson();
eventData.remove('id'); // Firestore will generate the ID

// Save to Firestore
final docId = await _firestoreService.createCalendarEvent(user.uid, eventData);
if (docId == null) {
  _setError('Failed to save event to database');
  return null;
}

// Create event with Firestore-generated ID
final savedEvent = event.copyWith(id: docId);

// Add to internal events map
_addEventToMap(savedEvent);
```

### 3. Updated `addFlashcardStudyEvent()` Method
Similar changes - now saves flashcard study events to Firestore with proper user association.

### 4. Added `_refreshCalendarEvents()` Method
New method to load persisted events from Firestore on app start:
```dart
Future<void> _refreshCalendarEvents() async {
  final user = _auth.currentUser;
  if (user == null) return;

  final eventMaps = await _firestoreService.getUserCalendarEvents(user.uid);
  
  for (final eventMap in eventMaps) {
    try {
      final event = _convertFirestoreToCalendarEvent(eventMap);
      _addEventToMap(event);
    } catch (e) {
      print('Error converting calendar event: $e');
    }
  }
}
```

### 5. Updated `refreshAllEvents()` Method
Added call to `_refreshCalendarEvents()` alongside other refresh methods:
```dart
Future<void> refreshAllEvents() async {
  await Future.wait([
    _refreshCalendarEvents(), // ← NEW: Load from Firestore
    _refreshTaskEvents(),
    _refreshQuestEvents(),
    _refreshSocialEvents(),
    _refreshPetCareEvents(),
  ]);
}
```

### 6. Updated `updateEvent()` Method
Now persists updates to Firestore:
```dart
// Update in Firestore
final eventData = event.toJson();
eventData.remove('id');
final success = await _firestoreService.updateCalendarEvent(event.id, eventData);

if (!success) {
  _setError('Failed to update event in database');
  return null;
}
```

### 7. Updated `deleteEvent()` Method
Now archives events in Firestore (soft delete):
```dart
// Delete from Firestore (archives it)
final success = await _firestoreService.deleteCalendarEvent(event.id);

if (!success) {
  _setError('Failed to delete event from database');
  return false;
}
```

## Testing Instructions

### Test Calendar Event Persistence
1. **Login** to your StudyPals account
2. **Create calendar events** using any method:
   - Go to Learning → Flash Cards → Click ⋮ on a deck → "Add to Calendar"
   - Go to Learning → Notes → Click ⋮ on a note → "Add to Calendar"
   - Go to Planner → Click "Create Event" button
3. **Verify events appear** on both calendars:
   - Weekly dashboard calendar (small calendar on dashboard)
   - Monthly planner calendar (Planner screen)
4. **Logout** of your account
5. **Login again** with the same account
6. **Check calendars** - events should still be there! ✅

### Test Event Operations
- **Create:** Add new events → Logout/Login → Events persist ✅
- **Update:** Edit event details → Logout/Login → Changes saved ✅
- **Delete:** Delete events → Logout/Login → Events stay deleted ✅
- **Complete:** Mark task events complete → Logout/Login → Status persists ✅

## Firestore Structure
Events are stored in the `calendarEvents` collection with this structure:
```
calendarEvents/
  {eventId}/
    uid: "user123"              // User who owns the event
    title: "Review Biology Notes"
    description: "..."
    type: "studySession"
    startTime: Timestamp(...)
    endTime: Timestamp(...)
    priority: 2
    tags: ["notes", "biology"]
    reminders: [...]
    createdAt: Timestamp(...)
    updatedAt: Timestamp(...)
    isArchived: false
```

## Files Modified
- **lib/providers/calendar_provider.dart**
  - Added Firebase imports and service instances
  - Updated `createEvent()` to save to Firestore
  - Updated `addFlashcardStudyEvent()` to save to Firestore
  - Added `_refreshCalendarEvents()` to load from Firestore
  - Added `_convertFirestoreToCalendarEvent()` helper
  - Updated `refreshAllEvents()` to call refresh method
  - Updated `updateEvent()` to persist updates
  - Updated `deleteEvent()` to archive in Firestore

## Benefits
✅ **Persistence:** Calendar events survive logout/login cycles
✅ **Cross-Device:** Events sync across devices via Firestore
✅ **User Isolation:** Events are user-specific (filtered by `uid`)
✅ **Soft Delete:** Deleted events are archived, not permanently removed
✅ **Audit Trail:** `createdAt`/`updatedAt` timestamps tracked automatically
✅ **Backwards Compatible:** Existing event creation code works unchanged

## Notes
- The `FirestoreService` calendar methods were already implemented - we just needed to use them!
- Events are now properly associated with user accounts via the `uid` field
- The in-memory event map is still used for fast UI updates, but Firestore is the source of truth
- All event types (tasks, quests, flashcards, notes, social sessions) now persist correctly
