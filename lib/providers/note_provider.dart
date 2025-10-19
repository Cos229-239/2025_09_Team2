// Import Flutter's foundation for ChangeNotifier (state management pattern)
import 'package:flutter/foundation.dart';
// Import developer tools for logging and debugging
import 'dart:developer' as developer;
// Import Firebase Auth for user authentication
import 'package:firebase_auth/firebase_auth.dart';
// Import Note model to manage study note data and operations
import 'package:studypals/models/note.dart';
// Import Firestore service for persistence
import 'package:studypals/services/firestore_service.dart';

/// Provider for managing study notes collection and note operations
/// Handles note CRUD operations, search functionality, and loading states
/// Uses ChangeNotifier to notify UI widgets when note data changes
class NoteProvider extends ChangeNotifier {
  // List of all study notes loaded from database (mutable for direct operations)
  final List<Note> _notes = [];

  // Loading state flag to show/hide loading indicators in UI
  bool _isLoading = false;

  // Firebase services for persistence
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Getter for accessing the list of all notes (read-only)
  /// @return List of Note objects containing all study notes
  List<Note> get notes => _notes;

  /// Getter for accessing the current loading state (read-only)
  /// @return Boolean indicating if note data is currently being loaded
  bool get isLoading => _isLoading;

  /// Loads all study notes from persistent storage (database)
  /// Sets loading state and handles errors gracefully with logging
  /// @param forceRefresh If true, always reload. If false, only load if notes list is empty
  Future<void> loadNotes({bool forceRefresh = false}) async {
    // Skip loading if we already have notes and not forcing refresh
    if (!forceRefresh && _notes.isNotEmpty) {
      debugPrint('⏭️ Skipping loadNotes - already have ${_notes.length} notes (use forceRefresh: true to reload)');
      return;
    }

    _isLoading = true; // Set loading state to true
    notifyListeners(); // Notify UI to show loading indicators

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user logged in, cannot load notes');
        _notes.clear();
        return;
      }

      // Load notes from Firestore
      final notesData = await _firestoreService.getUserNotes(currentUser.uid);
      
      if (forceRefresh) {
        // Full refresh - replace everything
        _notes.clear();
        _notes.addAll(notesData.map((data) => _convertFirestoreToNote(data)));
        debugPrint('🔄 Force refreshed - loaded ${_notes.length} notes from Firestore');
      } else {
        // Smart merge - preserve local notes, add any new ones from Firestore
        final firestoreNotes = notesData.map((data) => _convertFirestoreToNote(data)).toList();
        final existingIds = _notes.map((n) => n.id).toSet();
        
        // Add notes from Firestore that aren't already local
        for (final note in firestoreNotes) {
          if (!existingIds.contains(note.id)) {
            _notes.add(note);
          }
        }
        
        debugPrint('✅ Smart merge - now have ${_notes.length} total notes (${firestoreNotes.length} from Firestore)');
      }

      // Sample notes removed - users start with a clean slate
    } catch (e) {
      // Log any errors that occur during note loading for debugging
      developer.log('Error loading notes: $e', name: 'NoteProvider');
      if (forceRefresh) {
        _notes.clear(); // Only clear on error if doing full refresh
      }
    } finally {
      _isLoading = false; // Always clear loading state
      notifyListeners(); // Notify UI that loading is complete
    }
  }

  /// Convert Firestore document data to Note object
  Note _convertFirestoreToNote(Map<String, dynamic> data) {
    return Note(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Untitled Note',
      contentMd: data['contentMd'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Adds a new note to the collection and notifies listeners
  /// @param note - The Note object to add to the collection
  Future<void> addNote(Note note) async {
    _notes.add(note); // Add note to the list locally first
    notifyListeners(); // Notify UI of the addition immediately

    // Save to Firestore in the background
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final noteId = await _firestoreService.createNote(
          uid: currentUser.uid,
          title: note.title,
          contentMd: note.contentMd,
          tags: note.tags,
        );

        if (noteId != null) {
          debugPrint('✅ Saved note to Firestore with ID: $noteId');

          // Update the local note with the Firestore ID
          final noteIndex = _notes.indexWhere((n) => n.id == note.id);
          if (noteIndex != -1) {
            _notes[noteIndex] = note.copyWith(id: noteId);
            notifyListeners();
          }
        } else {
          debugPrint('❌ Failed to save note to Firestore');
        }
      } catch (e) {
        debugPrint('❌ Error saving note to Firestore: $e');
      }
    }
  }

  /// Updates an existing note in the collection by ID
  /// Finds note by ID and replaces it with updated version
  /// @param note - The updated Note object with same ID
  Future<void> updateNote(Note note) async {
    // Find the index of the note to update by matching ID
    final index = _notes.indexWhere((n) => n.id == note.id);

    if (index != -1) {
      // If note found
      _notes[index] = note; // Replace with updated note locally
      notifyListeners(); // Notify UI of the change immediately

      // Update in Firestore in the background
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        try {
          final success = await _firestoreService.updateNote(
            noteId: note.id,
            uid: currentUser.uid,
            title: note.title,
            contentMd: note.contentMd,
            tags: note.tags,
          );

          if (success) {
            debugPrint('✅ Updated note in Firestore: ${note.id}');
          } else {
            debugPrint('❌ Failed to update note in Firestore');
          }
        } catch (e) {
          debugPrint('❌ Error updating note in Firestore: $e');
        }
      }
    }
  }

  /// Removes a note from the collection by ID
  /// @param noteId - The ID of the note to remove
  Future<void> deleteNote(String noteId) async {
    try {
      // Delete from Firestore first
      final user = _auth.currentUser;
      if (user != null) {
        await _firestoreService.deleteNote(noteId);
      }

      // Remove from local list
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners(); // Notify UI of the removal
    } catch (e) {
      debugPrint('Error deleting note: $e');
      // Re-throw to let UI handle the error
      rethrow;
    }
  }

  /// Searches notes by title, content, or tags using case-insensitive matching
  /// Returns all notes if query is empty, filtered notes otherwise
  /// @param query - Search string to match against note data
  /// @return List of Note objects matching the search criteria
  List<Note> searchNotes(String query) {
    // Return all notes if no search query provided
    if (query.isEmpty) return _notes;

    // Filter notes based on title, content, or tag matches
    return _notes.where((note) {
      // Convert query to lowercase for case-insensitive search
      final lowerQuery = query.toLowerCase();

      // Check if title contains the search query
      final titleMatch = note.title.toLowerCase().contains(lowerQuery);

      // Check if content contains the search query
      final contentMatch = note.contentMd.toLowerCase().contains(lowerQuery);

      // Check if any tag contains the search query
      final tagMatch =
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));

      // Return true if any field matches the search query
      return titleMatch || contentMatch || tagMatch;
    }).toList();
  }
}
