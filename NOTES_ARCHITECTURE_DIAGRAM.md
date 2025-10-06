# Notes Feature Architecture - Real-Time Firebase Integration

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          USER INTERFACE LAYER                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │
│  │  NotesScreen    │  │ CreateNoteScreen│  │ Dashboard       │         │
│  │  (List View)    │  │ (Form)          │  │ (Overview)      │         │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘         │
│           │                    │                     │                   │
│           └────────────────────┼─────────────────────┘                   │
│                                │                                         │
└────────────────────────────────┼─────────────────────────────────────────┘
                                 │
                    Consumer<NoteProvider>
                                 │
┌────────────────────────────────▼─────────────────────────────────────────┐
│                      STATE MANAGEMENT LAYER                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                         NoteProvider                              │   │
│  │                    (ChangeNotifier)                               │   │
│  ├──────────────────────────────────────────────────────────────────┤   │
│  │                                                                   │   │
│  │  State:                        Stream:                           │   │
│  │  • List<Note> _notes           • _notesStreamSubscription        │   │
│  │  • bool _isLoading             • Real-time listener              │   │
│  │                                                                   │   │
│  │  Methods:                      Lifecycle:                        │   │
│  │  • loadNotes()                 • dispose()                       │   │
│  │  • addNote(note)                                                 │   │
│  │  • updateNote(note)                                              │   │
│  │  • deleteNote(noteId)                                            │   │
│  │  • searchNotes(query)                                            │   │
│  │                                                                   │   │
│  └───────────────┬──────────────────────────────────┬───────────────┘   │
│                  │                                  │                    │
│                  │ CRUD Operations                  │ Stream Events     │
│                  ▼                                  ▲                    │
└──────────────────┼──────────────────────────────────┼────────────────────┘
                   │                                  │
┌──────────────────▼──────────────────────────────────┼────────────────────┐
│                      SERVICE LAYER                  │                    │
├─────────────────────────────────────────────────────┼────────────────────┤
│                                                     │                    │
│  ┌─────────────────────────────────────────────────┼─────────────────┐  │
│  │               FirestoreService                  │                 │  │
│  ├─────────────────────────────────────────────────┼─────────────────┤  │
│  │                                                 │                 │  │
│  │  Write Operations:                  Read Operations:              │  │
│  │  • createNote()                     • getUserNotes()              │  │
│  │  • updateNote()                     • getUserNotesStream() ◄──────┤  │
│  │  • deleteNote()                                                   │  │
│  │                                                                   │  │
│  └───────────────┬─────────────────────────────────┬─────────────────┘  │
│                  │                                 │                    │
└──────────────────┼─────────────────────────────────┼────────────────────┘
                   │                                 │
                   │ Firestore API                   │ snapshots()
                   ▼                                 ▲
┌──────────────────────────────────────────────────────────────────────────┐
│                      FIREBASE CLOUD LAYER                                │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    Cloud Firestore Database                       │   │
│  ├──────────────────────────────────────────────────────────────────┤   │
│  │                                                                   │   │
│  │  Collection: notes                                                │   │
│  │  ┌────────────────────────────────────────────────────────────┐  │   │
│  │  │  Document: {noteId}                                        │  │   │
│  │  │  ┌──────────────────────────────────────────────────────┐ │  │   │
│  │  │  │  • uid: string                                       │ │  │   │
│  │  │  │  • title: string                                     │ │  │   │
│  │  │  │  • contentMd: string                                 │ │  │   │
│  │  │  │  • tags: array<string>                               │ │  │   │
│  │  │  │  • createdAt: timestamp                              │ │  │   │
│  │  │  │  • updatedAt: timestamp                              │ │  │   │
│  │  │  │  • wordCount: number                                 │ │  │   │
│  │  │  │  • isArchived: boolean                               │ │  │   │
│  │  │  └──────────────────────────────────────────────────────┘ │  │   │
│  │  └────────────────────────────────────────────────────────────┘  │   │
│  │                                                                   │   │
│  │  Indexes:                                                         │   │
│  │  • uid + isArchived + updatedAt (DESC)                            │   │
│  │                                                                   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Sequences

### 1. Initial Load (Real-Time Stream Subscription)

```
User Opens NotesScreen
        │
        ▼
  NotesScreen.initState()
        │
        ▼
  noteProvider.loadNotes()
        │
        ├──► Set _isLoading = true
        │
        ├──► notifyListeners() ────────► UI shows loading spinner
        │
        ├──► Check Firebase Auth
        │
        ├──► Cancel existing stream
        │
        ▼
  firestoreService.getUserNotesStream(uid)
        │
        ▼
  Firestore.snapshots()
        │
        ▼
  ┌──────────────────────────────────────┐
  │  REAL-TIME STREAM ESTABLISHED        │
  │  (Stays open until disposed)         │
  └──────────────────────────────────────┘
        │
        ▼ (Initial snapshot)
  Stream Listener Callback
        │
        ├──► _notes.clear()
        ├──► Convert docs to Note objects
        ├──► Add to _notes list
        ├──► Set _isLoading = false
        │
        ▼
  notifyListeners() ────────► UI rebuilds with notes
```

### 2. Create Note

```
User Fills Form & Clicks "Save"
        │
        ▼
  CreateNoteScreen._saveNote()
        │
        ├──► Validate form
        ├──► Create Note object (id: '')
        │
        ▼
  await noteProvider.addNote(note)
        │
        ├──► Check Firebase Auth
        │
        ▼
  await firestoreService.createNote()
        │
        ├──► Prepare note data
        ├──► Add server timestamps
        ├──► Calculate word count
        │
        ▼
  Firestore.collection('notes').add()
        │
        ▼
  ┌──────────────────────────────────────┐
  │  NEW DOCUMENT CREATED IN FIREBASE    │
  │  (Returns document ID)               │
  └──────────────────────────────────────┘
        │
        ▼
  Stream Listener Detects Change ◄───────┘
        │
        ├──► Receives updated snapshot
        ├──► New note included in snapshot
        ├──► _notes updated automatically
        │
        ▼
  notifyListeners() ────────► UI shows new note instantly
        │
        ▼
  ShowSnackBar("Note created!")
        │
        ▼
  Navigator.pop() ───────────► Return to NotesScreen
```

### 3. Update Note

```
User Edits Note & Clicks "Update"
        │
        ▼
  _editNote() Dialog
        │
        ├──► Create updated Note object
        │
        ▼
  noteProvider.updateNote(note)
        │
        ├──► Check Firebase Auth
        │
        ▼
  await firestoreService.updateNote()
        │
        ├──► Prepare update data
        ├──► Set server timestamp
        ├──► Recalculate word count
        │
        ▼
  Firestore.doc(noteId).update()
        │
        ▼
  ┌──────────────────────────────────────┐
  │  DOCUMENT UPDATED IN FIREBASE        │
  └──────────────────────────────────────┘
        │
        ▼
  Stream Listener Detects Change ◄───────┘
        │
        ├──► Receives updated snapshot
        ├──► Updated note in snapshot
        ├──► _notes updated automatically
        │
        ▼
  notifyListeners() ────────► UI reflects changes instantly
        │
        ▼
  ShowSnackBar("Note updated")
        │
        ▼
  Navigator.pop() ───────────► Close dialog
```

### 4. Delete Note

```
User Clicks "Delete" Button
        │
        ▼
  Confirm Dialog
        │
        ▼
  noteProvider.deleteNote(noteId)
        │
        ├──► Check Firebase Auth
        │
        ▼
  await firestoreService.deleteNote(noteId)
        │
        ├──► Soft delete (set isArchived: true)
        ├──► Set archivedAt timestamp
        ├──► Update updatedAt timestamp
        │
        ▼
  Firestore.doc(noteId).update()
        │
        ▼
  ┌──────────────────────────────────────┐
  │  DOCUMENT ARCHIVED IN FIREBASE       │
  │  (Filtered out by query)             │
  └──────────────────────────────────────┘
        │
        ▼
  Stream Listener Detects Change ◄───────┘
        │
        ├──► Receives updated snapshot
        ├──► Archived note excluded
        ├──► _notes updated automatically
        │
        ▼
  notifyListeners() ────────► UI removes note instantly
        │
        ▼
  ShowSnackBar("Note deleted")
```

### 5. Real-Time Sync (Multi-Device)

```
Device A                          Firebase                     Device B
   │                                 │                             │
   │  User edits note                │                             │
   ├────────────────────────────────►│                             │
   │  updateNote()                   │                             │
   │                                 │                             │
   │                                 ├─────────────────────────────►
   │                                 │  Stream snapshot update     │
   │                                 │                             │
   │  ◄─────────────────────────────┤                             ├──►
   │  Stream snapshot update         │                             │  notifyListeners()
   │                                 │                             │
   ├──►                              │                             ├──►
   │  notifyListeners()              │                             │  UI updates
   │                                 │                             │
   ├──►                              │                             │
   │  UI updates                     │                             │
   │                                 │                             │
   └─────────── BOTH DEVICES IN SYNC ───────────────────────────────┘
```

## Security Rules (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /notes/{noteId} {
      // Allow read if user owns the note
      allow read: if request.auth != null 
                  && resource.data.uid == request.auth.uid;
      
      // Allow create if authenticated and sets uid to self
      allow create: if request.auth != null 
                    && request.resource.data.uid == request.auth.uid;
      
      // Allow update/delete if user owns the note
      allow update, delete: if request.auth != null 
                            && resource.data.uid == request.auth.uid;
    }
  }
}
```

## Performance Considerations

### Stream Optimization
- **Query Filter**: Only fetches non-archived notes (`isArchived: false`)
- **User Filter**: Only fetches current user's notes (`uid: currentUserUid`)
- **Ordering**: Results sorted by `updatedAt DESC` for most recent first
- **Single Subscription**: Only one stream active per provider instance

### Memory Management
- **Disposal**: Stream cancelled in `dispose()` to prevent leaks
- **Resubscription**: Old stream cancelled before creating new one
- **List Clearing**: `_notes.clear()` before repopulating ensures clean state

### Error Handling
- **Authentication Check**: Validates user before all operations
- **Try-Catch Blocks**: All async operations wrapped in error handling
- **Stream Error Handler**: `onError` callback for stream failures
- **Loading States**: Clear loading flags in all code paths (success, error, finally)

### Offline Support (Future)
- Enable Firestore persistence: `FirebaseFirestore.instance.settings.persistenceEnabled`
- Cached data served while offline
- Operations queued and synced when online
- No code changes needed in provider

## Testing Strategy

### Unit Tests
```dart
test('NoteProvider loads notes from stream', () async {
  // Mock FirestoreService with stream controller
  // Emit test data
  // Verify _notes list updated
  // Verify notifyListeners called
});
```

### Widget Tests
```dart
testWidgets('NotesScreen displays notes from provider', (tester) async {
  // Create mock NoteProvider with test data
  // Pump NotesScreen
  // Verify note tiles displayed
  // Verify search works
});
```

### Integration Tests
```dart
testWidgets('Create note end-to-end', (tester) async {
  // Setup Firebase emulator
  // Navigate to CreateNoteScreen
  // Fill form and submit
  // Verify note appears in NotesScreen
  // Verify note exists in Firestore
});
```

---
**Architecture Version**: 2.0 (Real-Time Firebase)
**Last Updated**: October 5, 2025
**Status**: ✅ Production Ready
