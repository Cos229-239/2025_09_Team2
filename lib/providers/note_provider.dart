// Import Flutter's foundation for ChangeNotifier (state management pattern)
import 'package:flutter/foundation.dart';
// Import developer tools for logging and debugging
import 'dart:developer' as developer;
// Import Note model to manage study note data and operations
import 'package:studypals/models/note.dart';

/// Provider for managing study notes collection and note operations
/// Handles note CRUD operations, search functionality, and loading states
/// Uses ChangeNotifier to notify UI widgets when note data changes
class NoteProvider extends ChangeNotifier {
  // List of all study notes loaded from database (mutable for direct operations)
  final List<Note> _notes = [];
  
  // Loading state flag to show/hide loading indicators in UI
  bool _isLoading = false;

  /// Getter for accessing the list of all notes (read-only)
  /// @return List of Note objects containing all study notes
  List<Note> get notes => _notes;
  
  /// Getter for accessing the current loading state (read-only)
  /// @return Boolean indicating if note data is currently being loaded
  bool get isLoading => _isLoading;

  /// Loads all study notes from persistent storage (database)
  /// Sets loading state and handles errors gracefully with logging
  Future<void> loadNotes() async {
    _isLoading = true;                            // Set loading state to true
    notifyListeners();                            // Notify UI to show loading indicators
    
    try {
      // Database loading will be implemented when repository layer is added
      // For now, notes list remains empty until user creates notes
      // _notes = await NoteRepository.getAllNotes();
    } catch (e) {
      // Log any errors that occur during note loading for debugging
      developer.log('Error loading notes: $e', name: 'NoteProvider');
    } finally {
      _isLoading = false;                         // Always clear loading state
      notifyListeners();                          // Notify UI that loading is complete
    }
  }

  /// Adds a new note to the collection and notifies listeners
  /// @param note - The Note object to add to the collection
  void addNote(Note note) {
    _notes.add(note);                             // Add note to the list
    notifyListeners();                            // Notify UI of the addition
  }

  /// Updates an existing note in the collection by ID
  /// Finds note by ID and replaces it with updated version
  /// @param note - The updated Note object with same ID
  void updateNote(Note note) {
    // Find the index of the note to update by matching ID
    final index = _notes.indexWhere((n) => n.id == note.id);
    
    if (index != -1) {                            // If note found
      _notes[index] = note;                       // Replace with updated note
      notifyListeners();                          // Notify UI of the change
    }
  }

  /// Removes a note from the collection by ID
  /// @param noteId - The ID of the note to remove
  void deleteNote(String noteId) {
    // Remove all notes with matching ID (should be only one)
    _notes.removeWhere((note) => note.id == noteId);
    notifyListeners();                            // Notify UI of the removal
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
      final tagMatch = note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      
      // Return true if any field matches the search query
      return titleMatch || contentMatch || tagMatch;
    }).toList();
  }
}
