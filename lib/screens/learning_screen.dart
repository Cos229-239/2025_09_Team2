import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypals/providers/task_provider.dart';
import 'package:studypals/providers/note_provider.dart';
import 'package:studypals/providers/deck_provider.dart';
import 'package:studypals/screens/task_list_screen.dart';
import 'package:studypals/screens/create_note_screen.dart';
import 'package:studypals/screens/flashcard_study_screen.dart';
import 'package:studypals/models/task.dart';

/// Learning hub screen that provides access to all learning-related features
/// Includes tasks (daily/weekly), flashcards (with search, quiz, study modes), and notes
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final TextEditingController _flashcardSearchController = TextEditingController();
  final TextEditingController _noteSearchController = TextEditingController();
  String _flashcardSearchQuery = '';
  String _noteSearchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load all necessary data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
      Provider.of<NoteProvider>(context, listen: false).loadNotes();
      Provider.of<DeckProvider>(context, listen: false).loadDecks();
    });
  }

  @override
  void dispose() {
    _flashcardSearchController.dispose();
    _noteSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Learning tasks section
            _buildSectionHeader(context, 'Learning tasks'),
            const SizedBox(height: 12),
            _buildTasksSection(),
            const SizedBox(height: 24),

            // Flash cards section
            _buildSectionHeader(context, 'Flash cards'),
            const SizedBox(height: 12),
            _buildFlashcardsSection(),
            const SizedBox(height: 24),

            // Notes section
            _buildSectionHeader(context, 'Notes'),
            const SizedBox(height: 12),
            _buildNotesSection(),
          ],
        ),
      ),
    );
  }

  /// Build section header with bold text
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
    );
  }

  /// Build the learning tasks section with daily and weekly tasks
  Widget _buildTasksSection() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.tasks
            .where((task) => task.status != TaskStatus.completed)
            .toList();

        // Filter tasks for today (daily tasks)
        final today = DateTime.now();
        final dailyTasks = allTasks.where((task) {
          if (task.dueAt == null) return false;
          return task.dueAt!.year == today.year &&
              task.dueAt!.month == today.month &&
              task.dueAt!.day == today.day;
        }).toList();

        // Filter tasks for this week (weekly tasks)
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final weeklyTasks = allTasks.where((task) {
          if (task.dueAt == null) return false;
          return task.dueAt!.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              task.dueAt!.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();

        return Column(
          children: [
            // Daily tasks
            _buildTaskCard(
              context,
              title: 'daily tasks',
              count: dailyTasks.length,
              icon: Icons.today,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Weekly tasks
            _buildTaskCard(
              context,
              title: 'Weekly tasks',
              count: weeklyTasks.length,
              icon: Icons.calendar_today,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskListScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Build a task card with icon and count
  Widget _buildTaskCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'task' : 'tasks'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the flashcards section with search, quiz mode, and study mode
  Widget _buildFlashcardsSection() {
    return Consumer<DeckProvider>(
      builder: (context, deckProvider, child) {
        final decks = deckProvider.decks;
        final filteredDecks = _flashcardSearchQuery.isEmpty
            ? decks
            : decks.where((deck) {
                return deck.title
                        .toLowerCase()
                        .contains(_flashcardSearchQuery.toLowerCase()) ||
                    deck.tags.any((tag) => tag
                        .toLowerCase()
                        .contains(_flashcardSearchQuery.toLowerCase()));
              }).toList();

        return Column(
          children: [
            // Flash cards with search bar option
            Card(
              elevation: 2,
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.style, color: Colors.blue, size: 24),
                ),
                title: const Text(
                  'flash cards with search bar option',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${decks.length} ${decks.length == 1 ? 'deck' : 'decks'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: _flashcardSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search flashcard decks...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _flashcardSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _flashcardSearchController.clear();
                                      setState(() {
                                        _flashcardSearchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _flashcardSearchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Deck list
                        if (filteredDecks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _flashcardSearchQuery.isEmpty
                                  ? 'No decks available'
                                  : 'No decks found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredDecks.length,
                            itemBuilder: (context, index) {
                              final deck = filteredDecks[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.style, size: 20),
                                title: Text(
                                  deck.title,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${deck.cards.length} cards',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 14),
                                onTap: () {
                                  if (deck.cards.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FlashcardStudyScreen(deck: deck),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Deck "${deck.title}" has no cards'),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quiz mode
            _buildFlashcardModeCard(
              context,
              title: 'quiz mode',
              icon: Icons.quiz,
              color: Colors.green,
              onTap: () {
                _showDeckSelectionDialog(context, isQuizMode: true);
              },
            ),
            const SizedBox(height: 12),

            // Study mode
            _buildFlashcardModeCard(
              context,
              title: 'Study mode',
              icon: Icons.school,
              color: Colors.indigo,
              onTap: () {
                _showDeckSelectionDialog(context, isQuizMode: false);
              },
            ),
          ],
        );
      },
    );
  }

  /// Build a flashcard mode card (quiz or study)
  Widget _buildFlashcardModeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog to select a deck for quiz or study mode
  void _showDeckSelectionDialog(BuildContext context,
      {required bool isQuizMode}) {
    final deckProvider = Provider.of<DeckProvider>(context, listen: false);
    final decks = deckProvider.decks;

    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No decks available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Deck for ${isQuizMode ? 'Quiz' : 'Study'} Mode'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return ListTile(
                leading: const Icon(Icons.style),
                title: Text(deck.title),
                subtitle: Text('${deck.cards.length} cards'),
                onTap: () {
                  Navigator.pop(context);
                  if (deck.cards.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlashcardStudyScreen(
                          deck: deck,
                          startInQuizMode: isQuizMode,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deck "${deck.title}" has no cards'),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Build the notes section with search bar and create functionality
  Widget _buildNotesSection() {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final notes = noteProvider.notes;
        final filteredNotes = _noteSearchQuery.isEmpty
            ? notes
            : notes.where((note) {
                return note.title
                        .toLowerCase()
                        .contains(_noteSearchQuery.toLowerCase()) ||
                    note.contentMd
                        .toLowerCase()
                        .contains(_noteSearchQuery.toLowerCase());
              }).toList();

        return Column(
          children: [
            // Notes still with search bar
            Card(
              elevation: 2,
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.note, color: Colors.amber, size: 24),
                ),
                title: const Text(
                  'Notes still with search bar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: _noteSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search notes...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _noteSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _noteSearchController.clear();
                                      setState(() {
                                        _noteSearchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _noteSearchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Notes list
                        if (filteredNotes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _noteSearchQuery.isEmpty
                                  ? 'No notes available'
                                  : 'No notes found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              final note = filteredNotes[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.note, size: 20),
                                title: Text(
                                  note.title,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  note.contentMd,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 14),
                                onTap: () {
                                  // Navigate to note details (can be enhanced later)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Viewing: ${note.title}'),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Create note button
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateNoteScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.teal, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
