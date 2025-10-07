import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:studypals/models/note.dart';
import '../../features/notes/widgets/notes_formatting_toolbar.dart';

class CreateNoteForm extends StatefulWidget {
  final Function(Note) onSaveNote;

  const CreateNoteForm({
    super.key,
    required this.onSaveNote,
  });

  @override
  State<CreateNoteForm> createState() => _CreateNoteFormState();
}

class _CreateNoteFormState extends State<CreateNoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late QuillController _contentController;
  final FocusNode _focusNode = FocusNode();

  String _selectedSubject = 'General';
  final List<String> _subjects = [
    'General',
    'Math',
    'Science',
    'History',
    'Literature',
    'Computer Science',
    'Art',
    'Music',
    'Languages',
    'Other',
  ];

  // Rich text formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isHighlighted = false;
  String _currentAlignment = 'left';

  @override
  void initState() {
    super.initState();
    _contentController = QuillController.basic();
    _setupListeners();
  }

  void _setupListeners() {
    _contentController.addListener(_updateToolbarState);
  }

  void _updateToolbarState() {
    final selection = _contentController.selection;
    if (!selection.isValid) return;

    setState(() {
      _isBold = _selectionHas(Attribute.bold);
      _isItalic = _selectionHas(Attribute.italic);
      _isUnderline = _selectionHas(Attribute.underline);
      _isHighlighted = _selectionHasBackground(const Color(0xFFFFFF00));
      _currentAlignment = _getCurrentAlignment();
    });
  }

  bool _selectionHas(Attribute attribute) {
    return _contentController
        .getAllSelectionStyles()
        .any((style) => style.attributes.containsKey(attribute.key));
  }

  bool _selectionHasBackground(Color color) {
    final styles = _contentController.getAllSelectionStyles();
    final colorHex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    for (final style in styles) {
      final bgAttr = style.attributes[Attribute.background.key];
      if (bgAttr != null && bgAttr.value == colorHex) {
        return true;
      }
    }
    return false;
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

  void _toggleInline(Attribute attribute) {
    final isActive = _selectionHas(attribute);
    _contentController.formatSelection(isActive ? Attribute.clone(attribute, null) : attribute);
  }

  void _toggleHighlight() {
    const yellowBackground = Color(0xFFFFFF00);
    final isHighlighted = _selectionHasBackground(yellowBackground);
    
    if (isHighlighted) {
      _contentController.formatSelection(Attribute.clone(Attribute.background, null));
    } else {
      _contentController.formatSelection(BackgroundAttribute('#FFFF00'));
    }
  }

  void _setAlignment(Attribute alignmentAttribute) {
    _contentController.formatSelection(Attribute.clone(Attribute.leftAlignment, null));
    _contentController.formatSelection(Attribute.clone(Attribute.centerAlignment, null));
    _contentController.formatSelection(Attribute.clone(Attribute.rightAlignment, null));
    
    if (alignmentAttribute != Attribute.leftAlignment) {
      _contentController.formatSelection(alignmentAttribute);
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_updateToolbarState);
    _titleController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_formKey.currentState?.validate() ?? false) {
      // Get plain text from QuillController
      final contentText = _contentController.document.toPlainText();
      
      // Validate content manually since it's not in a TextFormField
      if (contentText.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter some content for your note.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        contentMd: contentText.trim(),
        tags: _selectedSubject != 'General' ? [_selectedSubject.toLowerCase()] : [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      widget.onSaveNote(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title field
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Note Title',
              labelStyle: const TextStyle(color: Color(0xFF6FB8E9)),
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
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Subject dropdown
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Subject',
              labelStyle: const TextStyle(color: Color(0xFF6FB8E9)),
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
            ),
            dropdownColor: const Color(0xFF2A2A2A),
            items: _subjects.map((String subject) {
              return DropdownMenuItem<String>(
                value: subject,
                child: Text(subject, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedSubject = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Rich Text Formatting Toolbar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF444444)),
            ),
            child: NotesFormattingToolbar(
              controller: _contentController,
              isBold: _isBold,
              isItalic: _isItalic,
              isUnderline: _isUnderline,
              isHighlighted: _isHighlighted,
              currentAlignment: _currentAlignment,
              onToggleBold: () => _toggleInline(Attribute.bold),
              onToggleItalic: () => _toggleInline(Attribute.italic),
              onToggleUnderline: () => _toggleInline(Attribute.underline),
              onToggleHighlight: _toggleHighlight,
              onSetAlignment: _setAlignment,
            ),
          ),
          const SizedBox(height: 8),

          // Rich Text Content Editor
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF444444)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.all(16),
                  child: QuillEditor.basic(
                    controller: _contentController,
                    focusNode: _focusNode,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6FB8E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save Note'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}