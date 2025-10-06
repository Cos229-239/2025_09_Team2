// Import Flutter's foundation for ChangeNotifier (state management pattern)
import 'package:flutter/foundation.dart';
// Import developer tools for logging and debugging
import 'dart:developer' as developer;
// Import async for stream subscriptions
import 'dart:async';
// Import Firebase Auth for user authentication
import 'package:firebase_auth/firebase_auth.dart';
// Import Cloud Firestore for real-time updates
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Stream subscription for real-time updates
  StreamSubscription<QuerySnapshot>? _notesStreamSubscription;

  /// Getter for accessing the list of all notes (read-only)
  /// @return List of Note objects containing all study notes
  List<Note> get notes => _notes;

  /// Getter for accessing the current loading state (read-only)
  /// @return Boolean indicating if note data is currently being loaded
  bool get isLoading => _isLoading;

  /// Loads all study notes from persistent storage with real-time updates
  /// Sets loading state and handles errors gracefully with logging
  Future<void> loadNotes() async {
    _isLoading = true; // Set loading state to true
    notifyListeners(); // Notify UI to show loading indicators

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user logged in, cannot load notes');
        _notes.clear();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Cancel any existing stream subscription
      await _notesStreamSubscription?.cancel();

      // Set up real-time stream listener with includeMetadataChanges
      // This ensures we see pending writes immediately
      _notesStreamSubscription =
          _firestoreService.getUserNotesStream(currentUser.uid).listen(
        (QuerySnapshot snapshot) {
          _notes.clear();

          debugPrint(
              '📡 Stream update received: ${snapshot.docs.length} documents');

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;

            // Log each document for debugging
            debugPrint(
                '  📝 Note: ${doc.id} - ${data['title']} (hasPendingWrites: ${doc.metadata.hasPendingWrites})');

            _notes.add(_convertFirestoreToNote(data));
          }

          debugPrint('✅ Loaded ${_notes.length} notes from Firestore stream');
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          developer.log('❌ Error in notes stream: $error',
              name: 'NoteProvider');
          _notes.clear();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      // Log any errors that occur during note loading for debugging
      developer.log('Error loading notes: $e', name: 'NoteProvider');
      _notes.clear();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notesStreamSubscription?.cancel();
    super.dispose();
  }

  /// Convert Firestore document data to Note object
  Note _convertFirestoreToNote(Map<String, dynamic> data) {
    // Handle Firestore Timestamp objects
    DateTime? createdAt;
    DateTime? updatedAt;

    try {
      if (data['createdAt'] != null) {
        final createdAtValue = data['createdAt'];
        if (createdAtValue is Timestamp) {
          createdAt = createdAtValue.toDate();
        }
      }

      if (data['updatedAt'] != null) {
        final updatedAtValue = data['updatedAt'];
        if (updatedAtValue is Timestamp) {
          updatedAt = updatedAtValue.toDate();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing timestamps: $e');
    }

    return Note(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Untitled Note',
      contentMd: data['contentMd'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Adds a new note to the collection and notifies listeners
  /// @param note - The Note object to add to the collection
  /// Note: The real-time stream will automatically update the UI with the new note
  Future<void> addNote(Note note) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No user logged in, cannot create note');
      return;
    }

    try {
      // Save to Firestore and wait for the document ID
      final noteId = await _firestoreService.createNote(
        uid: currentUser.uid,
        title: note.title,
        contentMd: note.contentMd,
        tags: note.tags,
      );

      if (noteId != null) {
        debugPrint('✅ Created note in Firestore with ID: $noteId');
        // The real-time stream listener will automatically update _notes
      } else {
        debugPrint('❌ Failed to create note in Firestore');
        throw Exception('Failed to create note in Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error creating note in Firestore: $e');
      rethrow;
    }
  }

  /// Updates an existing note in the collection by ID
  /// @param note - The updated Note object with same ID
  /// Note: The real-time stream will automatically update the UI with changes
  Future<void> updateNote(Note note) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No user logged in, cannot update note');
      return;
    }

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
        // The real-time stream listener will automatically update _notes
      } else {
        debugPrint('❌ Failed to update note in Firestore');
        throw Exception('Failed to update note in Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error updating note in Firestore: $e');
      rethrow;
    }
  }

  /// Removes a note from the collection by ID
  /// @param noteId - The ID of the note to remove
  /// Note: The real-time stream will automatically update the UI after deletion
  Future<void> deleteNote(String noteId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No user logged in, cannot delete note');
      return;
    }

    try {
      // Delete from Firestore (soft delete by archiving)
      final success = await _firestoreService.deleteNote(noteId);

      if (success) {
        debugPrint('✅ Deleted note from Firestore: $noteId');
        // The real-time stream listener will automatically update _notes
      } else {
        debugPrint('❌ Failed to delete note from Firestore');
        throw Exception('Failed to delete note from Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error deleting note from Firestore: $e');
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
