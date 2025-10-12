import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../models/calendar_event.dart';
import '../providers/deck_provider.dart';
import '../providers/calendar_provider.dart';
import '../widgets/common/themed_background_wrapper.dart';
import 'flashcard_detail_screen.dart';

/// Screen displaying all flashcard decks in a list format
/// Shows decks sorted by most recently reviewed first with edit buttons
class FlashcardsListScreen extends StatefulWidget {
  const FlashcardsListScreen({super.key});

  @override
  State<FlashcardsListScreen> createState() => _FlashcardsListScreenState();
}

class _FlashcardsListScreenState extends State<FlashcardsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load decks when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeckProvider>(context, listen: false).loadDecks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Flash Cards'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showDeckFormDialog(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Color(0xFFD9D9D9)),
                decoration: InputDecoration(
                  hintText: 'Search flashcard decks...',
                  hintStyle: const TextStyle(color: Color(0xFF888888)),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF6FB8E9)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear, color: Color(0xFF888888)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6FB8E9),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF242628),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Deck list
            Expanded(
              child: Consumer<DeckProvider>(
                builder: (context, deckProvider, child) {
                  final allDecks = deckProvider.decks;

                  // Filter decks based on search query
                  final filteredDecks = _searchQuery.isEmpty
                      ? allDecks
                      : allDecks.where((deck) {
                          return deck.title
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              deck.tags.any((tag) => tag
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()));
                        }).toList();

                  // Sort by most recently reviewed (updatedAt) first
                  filteredDecks
                      .sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                  if (filteredDecks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.style_outlined,
                            size: 80,
                            color: Color(0xFF888888),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No flash cards yet'
                                : 'No decks found',
                            style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Create your first deck to get started'
                                : 'Try adjusting your search terms',
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredDecks.length,
                    itemBuilder: (context, index) {
                      final deck = filteredDecks[index];
                      return _buildDeckCard(deck);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckCard(Deck deck) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF242628),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlashcardDetailScreen(deck: deck),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Deck icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.style,
                  color: Color(0xFF6FB8E9),
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              // Deck info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.title,
                      style: const TextStyle(
                        color: Color(0xFFD9D9D9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${deck.cards.length} cards',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                    if (deck.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: deck.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6FB8E9)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF6FB8E9)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Color(0xFF6FB8E9),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Last reviewed: ${_formatLastReviewed(deck.updatedAt)}',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Quiz grade circular chart (always show - 0% if no quiz taken)
              _buildGradeCircularChart(deck.lastQuizGrade ?? 0.0),
              const SizedBox(width: 12),

              // More options menu button (three dots)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEditOptions(deck);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242628),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeCircularChart(double grade) {
    final gradeColor =
        grade > 0 ? _getGradeColor(grade) : const Color(0xFF888888);
    final percentage = (grade * 100).round();
    final displayText = grade > 0 ? '$percentage%' : '—';

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF242628),
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: grade,
              strokeWidth: 4,
              backgroundColor: const Color(0xFF242628),
              valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
            ),
          ),
          // Percentage text or dash if no quiz taken
          Text(
            displayText,
            style: TextStyle(
              color: gradeColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastReviewed(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        } else {
          return '${difference.inMinutes}m ago';
        }
      } else {
        return '${difference.inHours}h ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  Color _getGradeColor(double grade) {
    // Return color based on grade percentage (0.0 to 1.0)
    if (grade >= 0.9) {
      return const Color(0xFF4CAF50); // Excellent - Green
    } else if (grade >= 0.8) {
      return const Color(0xFF6FB8E9); // Great - Blue
    } else if (grade >= 0.7) {
      return const Color(0xFFFFB74D); // Good - Amber
    } else if (grade >= 0.6) {
      return const Color(0xFFFF9800); // Fair - Orange
    } else {
      return const Color(0xFFEF5350); // Needs Improvement - Red
    }
  }

  void _showEditOptions(Deck deck) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Options for "${deck.title}"',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Deck'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeckFormDialog(existingDeck: deck);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Add Cards'),
                subtitle: const Text('Add flashcards to this deck'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddCardsDialog(deck);
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('Add to Calendar'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToCalendarDialog(deck);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Deck',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(deck);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAddToCalendarDialog(Deck deck) {
    // Default to tomorrow at 10 AM
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    selectedDate = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 10, 0);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    int selectedDuration = 30; // Default 30 minutes

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Schedule Flashcard Study'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule study time for "${deck.title}"',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(
                        '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedDate.hour,
                              selectedDate.minute,
                            );
                          });
                        }
                      },
                    ),

                    // Time Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(selectedTime.format(context)),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),

                    // Duration Selector
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer),
                      title: const Text('Duration'),
                      subtitle: DropdownButton<int>(
                        value: selectedDuration,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 15, child: Text('15 minutes')),
                          DropdownMenuItem(
                              value: 30, child: Text('30 minutes')),
                          DropdownMenuItem(
                              value: 45, child: Text('45 minutes')),
                          DropdownMenuItem(value: 60, child: Text('1 hour')),
                          DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                          DropdownMenuItem(value: 120, child: Text('2 hours')),
                        ],
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDuration = newValue;
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${deck.cards.length} card${deck.cards.length == 1 ? '' : 's'} to review',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addToCalendar(deck, selectedDate, selectedDuration);
                    Navigator.pop(context);
                  },
                  child: const Text('Add to Calendar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addToCalendar(
      Deck deck, DateTime scheduledTime, int durationMinutes) async {
    try {
      // Create the calendar event from the deck
      final event = CalendarEvent.fromDeck(
        deck: deck,
        scheduledTime: scheduledTime,
        durationMinutes: durationMinutes,
      );

      // Add to calendar provider
      final calendarProvider =
          Provider.of<CalendarProvider>(context, listen: false);
      final addedEvent = await calendarProvider.addFlashcardStudyEvent(event);

      if (addedEvent != null) {
        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Added "${deck.title}" to calendar for ${scheduledTime.month}/${scheduledTime.day} at ${TimeOfDay.fromDateTime(scheduledTime).format(context)}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to planner screen
                Navigator.pushNamed(context, '/planner');
              },
            ),
          ),
        );
      } else {
        // Show error from provider
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to calendar'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to calendar: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Deck deck) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Deck'),
          content: Text(
              'Are you sure you want to delete "${deck.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteDeck(deck);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDeck(Deck deck) async {
    final deckProvider = Provider.of<DeckProvider>(context, listen: false);

    // Delete the deck
    final success = await deckProvider.deleteDeck(deck.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${deck.title}"'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete "${deck.title}"'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Shows dialog for creating new deck or editing existing deck
  void _showDeckFormDialog({Deck? existingDeck}) {
    final isEditMode = existingDeck != null;
    final titleController =
        TextEditingController(text: existingDeck?.title ?? '');
    final tagsController = TextEditingController(
      text: existingDeck?.tags.join(', ') ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditMode ? 'Edit Deck' : 'Create New Deck'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Deck Title *',
                      hintText: 'e.g., Biology Chapter 5',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                    autofocus: !isEditMode,
                  ),
                  const SizedBox(height: 16),

                  // Tags Field
                  TextFormField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (optional)',
                      hintText: 'e.g., biology, science, exam',
                      helperText: 'Separate multiple tags with commas',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    isEditMode
                        ? 'Deck has ${existingDeck.cards.length} cards'
                        : 'You can add cards after creating the deck',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                titleController.dispose();
                tagsController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                // Parse tags
                final tagsList = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                // Capture context-dependent objects before async operations
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final deckProvider =
                    Provider.of<DeckProvider>(context, listen: false);

                if (isEditMode) {
                  // Update existing deck
                  final updatedDeck = existingDeck.copyWith(
                    title: titleController.text.trim(),
                    tags: tagsList,
                    updatedAt: DateTime.now(),
                  );
                  deckProvider.updateDeck(updatedDeck);
                } else {
                  // Create new deck
                  final newDeck = Deck(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    tags: tagsList,
                    cards: [],
                  );
                  await deckProvider.addDeck(newDeck);
                }

                titleController.dispose();
                tagsController.dispose();

                if (!mounted) return;
                navigator.pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditMode
                          ? 'Deck updated successfully'
                          : 'Deck created successfully',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(isEditMode ? 'Update' : 'Create'),
            ),
          ],
        );
      },
    );
  }

  /// Shows dialog for adding cards to a deck
  void _showAddCardsDialog(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => _AddCardsDialog(deck: deck),
    );
  }
}

/// Dialog for adding multiple cards to a deck
class _AddCardsDialog extends StatefulWidget {
  final Deck deck;

  const _AddCardsDialog({required this.deck});

  @override
  State<_AddCardsDialog> createState() => _AddCardsDialogState();
}

class _AddCardsDialogState extends State<_AddCardsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();

  CardType _selectedType = CardType.basic;
  int _difficulty = 3;
  int _correctAnswerIndex = 0;
  int _cardsAdded = 0;

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Cards to "${widget.deck.title}"'),
          const SizedBox(height: 4),
          Text(
            'Cards added: $_cardsAdded',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Type Selector
              DropdownButtonFormField<CardType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Card Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: CardType.basic,
                    child: Row(
                      children: [
                        const Icon(Icons.article, size: 20),
                        const SizedBox(width: 8),
                        const Text('Basic (Front/Back)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: CardType.multipleChoice,
                    child: Row(
                      children: [
                        const Icon(Icons.quiz, size: 20),
                        const SizedBox(width: 8),
                        const Text('Multiple Choice'),
                      ],
                    ),
                  ),
                ],
                onChanged: (CardType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Front/Question
              TextFormField(
                controller: _frontController,
                decoration: InputDecoration(
                  labelText: _selectedType == CardType.multipleChoice
                      ? 'Question *'
                      : 'Front (Question) *',
                  hintText: 'Enter the question or prompt',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the front content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_selectedType == CardType.basic) ...[
                // Back/Answer for basic cards
                TextFormField(
                  controller: _backController,
                  decoration: const InputDecoration(
                    labelText: 'Back (Answer) *',
                    hintText: 'Enter the answer',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the back content';
                    }
                    return null;
                  },
                ),
              ] else if (_selectedType == CardType.multipleChoice) ...[
                // Multiple choice options
                Text(
                  'Answer Options',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),

                _buildOptionField(_option1Controller, 'Option 1 *', 0),
                const SizedBox(height: 8),
                _buildOptionField(_option2Controller, 'Option 2 *', 1),
                const SizedBox(height: 8),
                _buildOptionField(_option3Controller, 'Option 3 *', 2),
                const SizedBox(height: 8),
                _buildOptionField(_option4Controller, 'Option 4 *', 3),
                const SizedBox(height: 16),

                // Correct answer selector
                Text(
                  'Correct Answer: Option ${_correctAnswerIndex + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
              ],
              const SizedBox(height: 16),

              // Difficulty Selector
              Text(
                'Difficulty',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final difficulty = index + 1;
                  final isSelected = _difficulty == difficulty;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < 4 ? 4 : 0,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _difficulty = difficulty;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$difficulty',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_cardsAdded > 0 ? 'Done' : 'Cancel'),
        ),
        if (_cardsAdded > 0)
          TextButton(
            onPressed: _addAnotherCard,
            child: const Text('Add Another'),
          ),
        ElevatedButton(
          onPressed: _saveCard,
          child: Text(_cardsAdded > 0 ? 'Add & Continue' : 'Add Card'),
        ),
      ],
    );
  }

  Widget _buildOptionField(
      TextEditingController controller, String label, int index) {
    final isCorrect = _correctAnswerIndex == index;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isCorrect ? Colors.green : Colors.grey,
                  width: isCorrect ? 2 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isCorrect ? Colors.green : Colors.grey,
                  width: isCorrect ? 2 : 1,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCorrect ? Colors.green : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _correctAnswerIndex = index;
            });
          },
          tooltip: 'Mark as correct answer',
        ),
      ],
    );
  }

  void _saveCard() {
    if (!_formKey.currentState!.validate()) return;

    final deckProvider = Provider.of<DeckProvider>(context, listen: false);

    // Create the new card
    final newCard = FlashCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deckId: widget.deck.id,
      type: _selectedType,
      front: _frontController.text.trim(),
      back: _selectedType == CardType.basic
          ? _backController.text.trim()
          : _option1Controller.text.trim(), // Use first option as back for MC
      multipleChoiceOptions: _selectedType == CardType.multipleChoice
          ? [
              _option1Controller.text.trim(),
              _option2Controller.text.trim(),
              _option3Controller.text.trim(),
              _option4Controller.text.trim(),
            ]
          : [],
      correctAnswerIndex:
          _selectedType == CardType.multipleChoice ? _correctAnswerIndex : 0,
      difficulty: _difficulty,
    );

    // Add card to deck
    deckProvider.addCardToDeck(widget.deck.id, newCard);

    setState(() {
      _cardsAdded++;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Card added! Total: $_cardsAdded'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );

    // Clear form for next card
    _clearForm();
  }

  void _addAnotherCard() {
    _clearForm();
  }

  void _clearForm() {
    _frontController.clear();
    _backController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    setState(() {
      _difficulty = 3;
      _correctAnswerIndex = 0;
    });
  }
}
