// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing task state management
import 'package:provider/provider.dart';
// Import intl package for date formatting functionality
import 'package:intl/intl.dart';
// Import TaskProvider for adding new tasks to the system
import 'package:studypals/providers/task_provider.dart';
// Import Task model to create new task instances
import 'package:studypals/models/task.dart';

// TODO: Add Task Sheet - Missing Advanced Features
// - No task template system for recurring task types
// - Missing task categorization beyond tags
// - No collaboration features (assign to study partner)
// - Missing subtask creation capability
// - No time tracking integration during task creation
// - Missing calendar integration for automatic scheduling
// - No attachment support (files, images, links)
// - Missing location-based reminders
// - No task dependency management
// - Missing productivity analytics integration
// - No AI suggestions for task optimization
// - No voice input for hands-free task creation

/// Modal bottom sheet widget for creating new tasks
/// Provides form interface for task title, duration, due date, priority, and tags
/// Used throughout the app wherever users need to quickly add tasks
class AddTaskSheet extends StatefulWidget {
  // Constructor with optional key for widget identification
  const AddTaskSheet({super.key});

  /// Creates the mutable state object for this widget
  /// @return State object managing form data and user interactions
  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

/// Private state class managing form input and validation for task creation
/// Handles user input collection, validation, and task submission
class _AddTaskSheetState extends State<AddTaskSheet> {
  // Form key for validation and form state management
  final _formKey = GlobalKey<FormState>();

  // Text controllers for form input fields
  final _titleController = TextEditingController(); // Task title input
  final _minutesController =
      TextEditingController(text: '30'); // Estimated duration (default 30 min)

  // Task properties managed by state
  DateTime? _selectedDate; // Optional due date
  int _priority = 1; // Priority level (1=low, 2=medium, 3=high)
  final List<String> _tags = []; // List of tags for organization
  final _tagController = TextEditingController(); // Tag input field

  /// Builds the add task sheet with form fields and controls
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing the task creation form
  @override
  Widget build(BuildContext context) {
    return Padding(
      // Adjust padding to account for keyboard when it appears
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20), // Internal spacing for form content
        child: Form(
          key: _formKey, // Form key for validation
          child: SingleChildScrollView(
            // Allow scrolling if content overflows
            child: Column(
              mainAxisSize: MainAxisSize.min, // Take minimum required space
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align content to left
              children: [
                // Header row with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sheet title
                    Text(
                      'Add Task',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    // Close button to dismiss the sheet
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context), // Close modal
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Spacing between header and form

                // Task title input field
                TextFormField(
                  controller: _titleController, // Controller for title input
                  decoration: const InputDecoration(
                    labelText: 'Task Title', // Field label
                    border: OutlineInputBorder(), // Material design border
                  ),
                  validator: (value) {
                    // Input validation
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title'; // Error message for empty title
                    }
                    return null; // Valid input
                  },
                ),
                const SizedBox(height: 16), // Spacing between fields

                // Row with duration input and date picker
                Row(
                  children: [
                    // Estimated minutes input field
                    Expanded(
                      child: TextFormField(
                        controller:
                            _minutesController, // Controller for duration input
                        keyboardType: TextInputType.number, // Numeric keyboard
                        decoration: const InputDecoration(
                          labelText: 'Estimated Minutes',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          // Input validation for duration
                          if (value == null || value.isEmpty) {
                            return 'Required'; // Error message for empty field
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid number'; // Error message for non-numeric input
                          }
                          return null; // Valid input
                        },
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing between fields

                    // Due date picker field
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate, // Open date picker on tap
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Display selected date or placeholder
                              Text(
                                _selectedDate != null
                                    ? DateFormat('MMM d').format(
                                        _selectedDate!) // Format date (e.g., "Jan 5")
                                    : 'Select', // Placeholder text
                              ),
                              // Calendar icon for visual cue
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Spacing between sections

                // Priority selection section
                const Text('Priority', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8), // Spacing between label and buttons
                // Segmented button for priority selection
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                        value: 1, label: Text('Low')), // Low priority option
                    ButtonSegment(
                        value: 2,
                        label: Text('Medium')), // Medium priority option
                    ButtonSegment(
                        value: 3, label: Text('High')), // High priority option
                  ],
                  selected: {_priority}, // Currently selected priority
                  onSelectionChanged: (Set<int> selected) {
                    setState(() {
                      _priority = selected
                          .first; // Update priority when selection changes
                    });
                  },
                ),
                const SizedBox(height: 16), // Spacing between sections

                // Tag input section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController, // Controller for tag input
                        decoration: InputDecoration(
                          labelText: 'Add Tag',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addTag, // Add tag when button pressed
                          ),
                        ),
                        onSubmitted: (_) =>
                            _addTag(), // Add tag when Enter pressed
                      ),
                    ),
                  ],
                ),

                // Display added tags (only shown if tags exist)
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8), // Spacing before tag display
                  // Wrap widget for tag chips with automatic line wrapping
                  Wrap(
                    spacing: 8, // Horizontal spacing between chips
                    children: _tags
                        .map((tag) => Chip(
                              label: Text(tag), // Tag text
                              onDeleted: () {
                                // Delete callback for tag removal
                                setState(() {
                                  _tags.remove(tag); // Remove tag from list
                                });
                              },
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24), // Spacing before submit button

                // Submit button
                SizedBox(
                  width: double.infinity, // Full width button
                  child: ElevatedButton(
                    onPressed: _saveTask, // Save task when pressed
                    child: const Text('Add Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens date picker dialog for due date selection
  /// Allows user to select any date from today up to one year in the future
  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now(), // Default to selected date or today
      firstDate: DateTime.now(), // Can't select past dates
      lastDate: DateTime.now()
          .add(const Duration(days: 365)), // Up to 1 year in future
    );

    // Update selected date if user made a selection
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Adds a new tag to the task if input is not empty
  /// Clears the tag input field after adding
  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text); // Add tag to list
        _tagController.clear(); // Clear input field
      });
    }
  }

  /// Validates form input and creates new task if valid
  /// Adds task to provider and closes the modal with success message
  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      // Validate all form fields
      // Create new task with form data
      final task = Task(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(), // Generate unique ID
        title: _titleController.text, // Task title from input
        estMinutes: int.parse(_minutesController.text), // Estimated duration
        dueAt: _selectedDate, // Optional due date
        priority: _priority, // Selected priority level
        tags: _tags, // List of added tags
        status: TaskStatus.pending, // Default to pending status
      );

      // Add task to provider (updates app state and UI)
      Provider.of<TaskProvider>(context, listen: false).addTask(task);

      // Close the modal
      Navigator.pop(context);

      // Show success message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully')),
      );
    }
  }

  /// Dispose of text controllers to prevent memory leaks
  /// Called when widget is removed from widget tree
  @override
  void dispose() {
    _titleController.dispose(); // Clean up title controller
    _minutesController.dispose(); // Clean up minutes controller
    _tagController.dispose(); // Clean up tag controller
    super.dispose(); // Call parent dispose
  }
}
