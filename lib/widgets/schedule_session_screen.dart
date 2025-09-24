import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/social_session.dart';
import '../providers/social_session_provider.dart';
import '../providers/deck_provider.dart';

class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({super.key});

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  Duration _selectedDuration = const Duration(minutes: 30);
  SessionType _selectedType = SessionType.quiz;
  int _maxParticipants = 5;
  bool _isPublic = false;

  final Set<String> _selectedDeckIds = {};
  final Set<String> _selectedFriendIds = {};

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: const Text(
          'Schedule Study Session',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSessionBasicsCard(context),
                    const SizedBox(height: 16),
                    _buildSchedulingCard(context),
                    const SizedBox(height: 16),
                    _buildDeckSelectionCard(context),
                    const SizedBox(height: 16),
                    _buildInvitationCard(context),
                    const SizedBox(height: 16),
                    _buildSettingsCard(context),
                    const SizedBox(height: 24),
                    _buildScheduleButton(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSessionBasicsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Session Details',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Session Title',
                hintText: 'e.g., Math Quiz Challenge',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a session title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'What will you be studying?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SessionType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Session Type',
                border: OutlineInputBorder(),
              ),
              items: SessionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (SessionType? value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Schedule',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDateTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date & Time',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy - hh:mm a')
                              .format(_selectedDateTime),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.calendar_today, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Duration>(
              initialValue: _selectedDuration,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
              ),
              items: [
                const Duration(minutes: 15),
                const Duration(minutes: 30),
                const Duration(minutes: 45),
                const Duration(hours: 1),
                const Duration(hours: 2),
              ].map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(_formatDuration(duration)),
                );
              }).toList(),
              onChanged: (Duration? value) {
                if (value != null) {
                  setState(() {
                    _selectedDuration = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckSelectionCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.library_books, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Study Material',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<DeckProvider>(
              builder: (context, deckProvider, child) {
                final decks = deckProvider.decks;

                if (decks.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No decks available. Create some flashcard decks first!',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return Column(
                  children: decks
                      .map((deck) => CheckboxListTile(
                            title: Text(
                              deck.title,
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              '${deck.cards.length} cards',
                              style: TextStyle(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                            value: _selectedDeckIds.contains(deck.id),
                            activeColor: colorScheme.primary,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedDeckIds.add(deck.id);
                                } else {
                                  _selectedDeckIds.remove(deck.id);
                                }
                              });
                            },
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Invite Friends',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<SocialSessionProvider>(
              builder: (context, socialProvider, child) {
                final friends = socialProvider.friends;

                if (friends.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No friends available. Add some friends first!',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return Column(
                  children: friends.entries
                      .map((friend) => CheckboxListTile(
                            title: Text(
                              friend.value,
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                            value: _selectedFriendIds.contains(friend.key),
                            activeColor: colorScheme.primary,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedFriendIds.add(friend.key);
                                } else {
                                  _selectedFriendIds.remove(friend.key);
                                }
                              });
                            },
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Max Participants',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: _maxParticipants.toString(),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed >= 2 && parsed <= 20) {
                        setState(() {
                          _maxParticipants = parsed;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Public Session',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              subtitle: Text(
                'Allow anyone to join',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              value: _isPublic,
              activeThumbColor: colorScheme.primary,
              onChanged: (bool value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _canSchedule() ? _scheduleSession : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available),
            SizedBox(width: 8),
            Text(
              'Schedule Session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSchedule() {
    return _titleController.text.trim().isNotEmpty &&
        _selectedDeckIds.isNotEmpty &&
        !_isLoading;
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Future<void> _scheduleSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final socialProvider =
          Provider.of<SocialSessionProvider>(context, listen: false);

      await socialProvider.scheduleSession(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledTime: _selectedDateTime,
        duration: _selectedDuration,
        deckIds: _selectedDeckIds.toList(),
        type: _selectedType,
        invitedFriendIds: _selectedFriendIds.toList(),
        maxParticipants: _maxParticipants,
        isPublic: _isPublic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
