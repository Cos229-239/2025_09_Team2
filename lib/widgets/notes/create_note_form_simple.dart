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
  int _currentFontSize = 16; // Default font size
  bool _isBulletList = false;

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
    
    setState(() {
      // If there's a valid selection, check the formatting of the selected text
      if (selection.isValid && !selection.isCollapsed) {
        _isBold = _selectionHas(Attribute.bold);
        _isItalic = _selectionHas(Attribute.italic);
        _isUnderline = _selectionHas(Attribute.underline);
        _isHighlighted = _selectionHas(Attribute.background);
        _isBulletList = _selectionHas(Attribute.list);
      }
      // For cursor position (no selection), keep current formatting states
      // This ensures buttons stay visually active for future typing
      
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
        // Parse the size value (it might be a string like "16px" or just "16")
        final sizeValue = sizeAttr.value.toString();
        final parsedSize = int.tryParse(sizeValue.replaceAll('px', ''));
        if (parsedSize != null && parsedSize >= 12 && parsedSize <= 48) {
          return parsedSize;
        }
      }
    }
    return 16; // Default font size
  }

  void _setFontSize(int fontSize) {
    _contentController.formatSelection(SizeAttribute(fontSize.toString()));
    
    // Immediately update toolbar state after formatting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarState();
    });
  }

  void _toggleBulletList() {
    final isActive = _selectionHas(Attribute.list);
    _contentController.formatSelection(isActive ? Attribute.clone(Attribute.list, null) : const ListAttribute('bullet'));
    
    // Immediately update state for visual feedback
    setState(() {
      _isBulletList = !isActive;
    });
    
    // Also update other states after formatting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarState();
    });
  }

  void _toggleInline(Attribute attribute) {
    final isActive = _selectionHas(attribute);
    _contentController.formatSelection(isActive ? Attribute.clone(attribute, null) : attribute);
    
    // Immediately update state for visual feedback
    setState(() {
      if (attribute == Attribute.bold) _isBold = !isActive;
      if (attribute == Attribute.italic) _isItalic = !isActive;
      if (attribute == Attribute.underline) _isUnderline = !isActive;
    });
    
    // Also update other states after formatting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarState();
    });
  }

  void _toggleHighlight() {
    final isActive = _selectionHas(Attribute.background);
    _contentController.formatSelection(isActive ? Attribute.clone(Attribute.background, null) : const BackgroundAttribute('#FFFF00'));
    
    // Immediately update state for visual feedback
    setState(() {
      _isHighlighted = !isActive;
    });
    
    // Also update other states after formatting
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
    
    // Immediately update toolbar state after formatting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateToolbarState();
    });
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