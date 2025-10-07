import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../widgets/common/themed_background_wrapper.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  final bool startInEditMode;

  const NoteDetailScreen({
    super.key,
    required this.note,
    this.startInEditMode = false,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Note _currentNote = Note(id: '', title: '', contentMd: '');
  bool _isEditMode = false;
  bool _showPreview = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _isEditMode = widget.startInEditMode;
    _titleController.text = _currentNote.title;
    _contentController.text = _currentNote.contentMd;
    _tagsController.text = _currentNote.tags.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _titleController.text = _currentNote.title;
        _contentController.text = _currentNote.contentMd;
        _tagsController.text = _currentNote.tags.join(', ');
      }
    });
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedNote = Note(
        id: _currentNote.id,
        title: _titleController.text.trim(),
        contentMd: _contentController.text.trim(),
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        createdAt: _currentNote.createdAt,
        updatedAt: DateTime.now(),
      );

      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      await noteProvider.updateNote(updatedNote);

      setState(() {
        _currentNote = updatedNote;
        _isEditMode = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating note: $e')),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A3050),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF6FB8E9),
              width: 2,
            ),
          ),
          title: const Text(
            'Delete Note',
            style: TextStyle(
              color: Color(0xFFD9D9D9),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this note? This action cannot be undone.',
            style: TextStyle(
              color: Color(0xFFD9D9D9),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFD9D9D9),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteNote();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      await noteProvider.deleteNote(_currentNote.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A3050),
          foregroundColor: const Color(0xFFD9D9D9),
          title: Text(
            _isEditMode ? 'Edit Note' : _currentNote.title,
            style: const TextStyle(
              color: Color(0xFFD9D9D9),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (_isEditMode) ...[
              TextButton(
                onPressed: _isLoading ? null : _saveNote,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6FB8E9),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: Color(0xFF6FB8E9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ] else ...[
              IconButton(
                onPressed: _toggleEditMode,
                icon: const Icon(
                  Icons.edit,
                  color: Color(0xFF6FB8E9),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFFD9D9D9),
                ),
              ),
            ],
          ],
        ),
        body: _isEditMode ? _buildEditMode() : _buildViewMode(),
      ),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note header card
          Card(
            color: const Color(0xFF2A3050),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0xFF6FB8E9),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6FB8E9),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.note,
                          color: Color(0xFF6FB8E9),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentNote.title,
                              style: const TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Created ${_formatTimeAgo(_currentNote.createdAt)}',
                              style: const TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_currentNote.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentNote.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6FB8E9),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Color(0xFF6FB8E9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Note content card
          Card(
            color: const Color(0xFF2A3050),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0xFF6FB8E9),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Content',
                    style: TextStyle(
                      color: Color(0xFFD9D9D9),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: _currentNote.contentMd.isEmpty
                        ? const Text(
                            'No content available',
                            style: TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _currentNote.contentMd,
                              style: const TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Title field
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Color(0xFFD9D9D9)),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: const TextStyle(color: Color(0xFF6FB8E9)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFF2A3050),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tags field
          TextField(
            controller: _tagsController,
            style: const TextStyle(color: Color(0xFFD9D9D9)),
            decoration: InputDecoration(
              labelText: 'Tags (comma separated)',
              labelStyle: const TextStyle(color: Color(0xFF6FB8E9)),
              hintText: 'e.g., physics, chapter1, formulas',
              hintStyle: const TextStyle(color: Color(0xFFD9D9D9)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFF2A3050),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content field with rich text editor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Content',
                      style: TextStyle(
                        color: const Color(0xFF6FB8E9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showPreview = false;
                            });
                          },
                          icon: Icon(
                            Icons.edit,
                            size: 16,
                            color: !_showPreview ? const Color(0xFF6FB8E9) : const Color(0xFFD9D9D9),
                          ),
                          label: Text(
                            'Edit',
                            style: TextStyle(
                              color: !_showPreview ? const Color(0xFF6FB8E9) : const Color(0xFFD9D9D9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showPreview = true;
                            });
                          },
                          icon: Icon(
                            Icons.visibility,
                            size: 16,
                            color: _showPreview ? const Color(0xFF6FB8E9) : const Color(0xFFD9D9D9),
                          ),
                          label: Text(
                            'Preview',
                            style: TextStyle(
                              color: _showPreview ? const Color(0xFF6FB8E9) : const Color(0xFFD9D9D9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                if (!_showPreview) ...[
                  // Text input field
                  Expanded(
                    child: TextFormField(
                      controller: _contentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Write your note content here...',
                        hintStyle: const TextStyle(color: Color(0xFF888888)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF444444)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF444444)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (value) {
                        setState(() {}); // Trigger rebuild for preview
                      },
                    ),
                  ),
                ] else ...[
                  // Preview mode
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3050),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6FB8E9)),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _contentController.text.isEmpty 
                              ? 'Preview will appear here...' 
                              : _contentController.text,
                            style: TextStyle(
                              color: _contentController.text.isEmpty 
                                ? const Color(0xFF888888) 
                                : const Color(0xFFD9D9D9),
                              fontSize: 14,
                              fontStyle: _contentController.text.isEmpty 
                                ? FontStyle.italic 
                                : FontStyle.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}