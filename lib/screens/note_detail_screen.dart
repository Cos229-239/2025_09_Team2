import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../widgets/common/themed_background_wrapper.dart';
import '../features/notes/widgets/notes_formatting_toolbar.dart';
import '../widgets/ai/ai_flashcard_generator.dart';

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
  final TextEditingController _titleController = TextEditingController();
  late QuillController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  final TextEditingController _tagsController = TextEditingController();
  bool _isLoading = false;

  // Rich text formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isHighlighted = false;
  String _currentAlignment = 'left';
  int _currentFontSize = 16;
  bool _isBulletList = false;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _isEditMode = widget.startInEditMode;
    _titleController.text = _currentNote.title;
    _tagsController.text = _currentNote.tags.join(', ');
    
    // Initialize QuillController with the note's content
    _initializeQuillController();
  }

  void _initializeQuillController() {
    try {
      // Try to parse the content as Quill JSON delta
      final contentData = jsonDecode(_currentNote.contentMd) as List;
      final doc = Document.fromJson(contentData);
      _contentController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // If parsing fails (old plain text notes), create document with plain text
      _contentController = QuillController.basic();
      // Set the plain text if available
      if (_currentNote.contentMd.isNotEmpty) {
        final doc = Document()..insert(0, _currentNote.contentMd);
        _contentController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
    _contentController.addListener(_updateToolbarState);
  }

  void _updateToolbarState() {
    final selection = _contentController.selection;
    
    setState(() {
      if (selection.isValid && !selection.isCollapsed) {
        _isBold = _selectionHas(Attribute.bold);
        _isItalic = _selectionHas(Attribute.italic);
        _isUnderline = _selectionHas(Attribute.underline);
        _isHighlighted = _selectionHas(Attribute.background);
        _isBulletList = _selectionHas(Attribute.list);
      }
      
      _currentAlignment = _getCurrentAlignment();
      _currentFontSize = _getCurrentFontSize();
    });
  }

  bool _selectionHas(Attribute attribute) {
    return _contentController
        .getAllSelectionStyles()
        .any((style) => style.attributes.containsKey(attribute.key));
  }

  String _getCurrentAlignment() {
    final styles = _contentController.getAllSelectionStyles();
    for (final style in styles) {
      if (style.attributes.containsKey(Attribute.centerAlignment.key)) {
        return 'center';
      } else if (style.attributes.containsKey(Attribute.rightAlignment.key)) {
        return 'right';
      }
    }
    return 'left';
  }

  int _getCurrentFontSize() {
    final styles = _contentController.getAllSelectionStyles();
    for (final style in styles) {
      final sizeAttr = style.attributes[Attribute.size.key];
      if (sizeAttr != null && sizeAttr.value != null) {
        final sizeValue = sizeAttr.value.toString();
        final parsedSize = int.tryParse(sizeValue.replaceAll('px', ''));
        if (parsedSize != null && parsedSize >= 12 && parsedSize <= 48) {
          return parsedSize;
        }
      }
    }
    return 16;
  }

  @override
  void dispose() {
    _contentController.removeListener(_updateToolbarState);
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _toggleInline(Attribute attribute) {
    final isActive = _selectionHas(attribute);
    _contentController.formatSelection(isActive ? Attribute.clone(attribute, null) : attribute);
    
    setState(() {
      if (attribute == Attribute.bold) _isBold = !isActive;
      if (attribute == Attribute.italic) _isItalic = !isActive;
      if (attribute == Attribute.underline) _isUnderline = !isActive;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarState();
    });
  }

  void _toggleHighlight() {
    final isActive = _selectionHas(Attribute.background);
    _contentController.formatSelection(isActive ? Attribute.clone(Attribute.background, null) : const BackgroundAttribute('#FFFF00'));
    
    setState(() {
      _isHighlighted = !isActive;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarState();
    });
  }

  void _setAlignment(Attribute alignmentAttribute) {
    _contentController.formatSelection(Attribute.clone(Attribute.leftAlignment, null));
    _contentController.formatSelection(Attribute.clone(Attribute.centerAlignment, null));
    _contentController.formatSelection(Attribute.clone(Attribute.rightAlignment, null));
    
    if (alignmentAttribute != Attribute.leftAlignment) {
      _contentController.formatSelection(alignmentAttribute);
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarState();
    });
  }

  void _setFontSize(int fontSize) {
    _contentController.formatSelection(SizeAttribute(fontSize.toString()));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarState();
    });
  }

  void _toggleBulletList() {
    final isActive = _selectionHas(Attribute.list);
    _contentController.formatSelection(isActive ? Attribute.clone(Attribute.list, null) : const ListAttribute('bullet'));
    
    setState(() {
      _isBulletList = !isActive;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarState();
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _titleController.text = _currentNote.title;
        _tagsController.text = _currentNote.tags.join(', ');
        // Reinitialize the controller with current note content
        _initializeQuillController();
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
      // Convert Quill document to JSON format
      final delta = _contentController.document.toDelta();
      final contentJson = jsonEncode(delta.toJson());
      
      final updatedNote = Note(
        id: _currentNote.id,
        title: _titleController.text.trim(),
        contentMd: contentJson,
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
          backgroundColor: const Color(0xFF242628),
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

  void _generateFlashcards() {
    // Extract plain text from the Quill document
    final plainText = _contentController.document.toPlainText();
    
    // Navigate to AI flashcard generator with pre-filled text
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Generate Flashcards'),
            backgroundColor: const Color(0xFF242628),
            foregroundColor: const Color(0xFFD9D9D9),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AIFlashcardGenerator(
                initialTopic: _currentNote.title,
                initialText: plainText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemedBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF242628),
          foregroundColor: const Color(0xFFD9D9D9),
          elevation: 0,
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
                  } else if (value == 'generate_flashcards') {
                    _generateFlashcards();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'generate_flashcards',
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 18, color: Color(0xFF6FB8E9)),
                        SizedBox(width: 12),
                        Text('Generate Flashcards', style: TextStyle(color: Color(0xFFD9D9D9))),
                      ],
                    ),
                  ),
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
            elevation: 1,
            color: const Color(0xFF242628),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
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
                                color: Color(0xFF888888),
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
                          color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
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
            elevation: 1,
            color: const Color(0xFF242628),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
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
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: _currentNote.contentMd.isEmpty
                        ? const Text(
                            'No content available',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : IgnorePointer(
                            child: QuillEditor.basic(
                              controller: _contentController,
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
                borderSide: BorderSide(color: const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFF242628),
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
              hintStyle: const TextStyle(color: Color(0xFF888888)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFF242628),
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
                    const Text(
                      'Content',
                      style: TextStyle(
                        color: Color(0xFFD9D9D9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Rich Text Formatting Toolbar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242628),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
                  ),
                  child: NotesFormattingToolbar(
                    controller: _contentController,
                    isBold: _isBold,
                    isItalic: _isItalic,
                    isUnderline: _isUnderline,
                    isHighlighted: _isHighlighted,
                    currentAlignment: _currentAlignment,
                    currentFontSize: _currentFontSize,
                    isBulletList: _isBulletList,
                    onToggleBold: () => _toggleInline(Attribute.bold),
                    onToggleItalic: () => _toggleInline(Attribute.italic),
                    onToggleUnderline: () => _toggleInline(Attribute.underline),
                    onToggleHighlight: _toggleHighlight,
                    onSetAlignment: _setAlignment,
                    onSetFontSize: _setFontSize,
                    onToggleBulletList: _toggleBulletList,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Rich Text Content Editor
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: const Color(0xFF242628),
                        padding: const EdgeInsets.all(16),
                        child: QuillEditor.basic(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                        ),
                      ),
                    ),
                  ),
                ),
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