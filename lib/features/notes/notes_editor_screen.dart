import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'widgets/notes_formatting_toolbar.dart';

class NotesEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDelta;
  final String? initialText;
  final String title;

  const NotesEditorScreen({
    super.key,
    this.initialDelta,
    this.initialText,
    this.title = 'New Note',
  });

  @override
  State<NotesEditorScreen> createState() => _NotesEditorScreenState();
}

class _NotesEditorScreenState extends State<NotesEditorScreen> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  
  // Toolbar state tracking
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isHighlighted = false;
  String _currentAlignment = 'left';

  @override
  void initState() {
    super.initState();
    _initializeController();
    _setupListeners();
  }

  void _initializeController() {
    if (widget.initialDelta != null) {
      // Initialize with provided delta JSON
      final delta = Delta.fromJson(widget.initialDelta!['ops'] ?? []);
      _controller = QuillController(
        document: Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else if (widget.initialText != null) {
      // Initialize with plain text
      _controller = QuillController.basic();
      _controller.document.insert(0, widget.initialText!);
      _controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
    } else {
      // Initialize with empty document
      _controller = QuillController.basic();
    }
  }

  void _setupListeners() {
    // Listen to selection changes to update toolbar state
    _controller.addListener(_updateToolbarState);
  }

  void _updateToolbarState() {
    final selection = _controller.selection;
    if (!selection.isValid) return;

    setState(() {
      _isBold = _selectionHas(Attribute.bold);
      _isItalic = _selectionHas(Attribute.italic);
      _isUnderline = _selectionHas(Attribute.underline);
      _isHighlighted = _selectionHasBackground(const Color(0xFFFFFF00));
      _currentAlignment = _getCurrentAlignment();
    });
  }

  // Helper methods for formatting detection
  bool _selectionHas(Attribute attribute) {
    return _controller
        .getAllSelectionStyles()
        .any((style) => style.attributes.containsKey(attribute.key));
  }

  bool _selectionHasBackground(Color color) {
    final styles = _controller.getAllSelectionStyles();
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
    final styles = _controller.getAllSelectionStyles();
    for (final style in styles) {
      if (style.attributes.containsKey(Attribute.centerAlignment.key)) {
        return 'center';
      } else if (style.attributes.containsKey(Attribute.rightAlignment.key)) {
        return 'right';
      }
    }
    return 'left';
  }

  // Formatting methods
  void _toggleInline(Attribute attribute) {
    final isActive = _selectionHas(attribute);
    _controller.formatSelection(isActive ? Attribute.clone(attribute, null) : attribute);
  }

  void _toggleHighlight() {
    const yellowBackground = Color(0xFFFFFF00);
    final isHighlighted = _selectionHasBackground(yellowBackground);
    
    if (isHighlighted) {
      // Remove highlight
      _controller.formatSelection(Attribute.clone(Attribute.background, null));
    } else {
      // Add yellow highlight - use hex color string
      _controller.formatSelection(BackgroundAttribute('#FFFF00'));
    }
  }

  void _setAlignment(Attribute alignmentAttribute) {
    // Clear existing alignment attributes
    _controller.formatSelection(Attribute.clone(Attribute.leftAlignment, null));
    _controller.formatSelection(Attribute.clone(Attribute.centerAlignment, null));
    _controller.formatSelection(Attribute.clone(Attribute.rightAlignment, null));
    
    // Apply new alignment (unless it's left, which is default)
    if (alignmentAttribute != Attribute.leftAlignment) {
      _controller.formatSelection(alignmentAttribute);
    }
  }

  // Export methods
  Future<String> exportAsPlainText() async {
    return _controller.document.toPlainText();
  }

  Future<Map<String, dynamic>> exportAsDeltaJson() async {
    return {'ops': _controller.document.toDelta().toJson()};
  }

  void _handleSave() async {
    final plainText = await exportAsPlainText();
    final deltaJson = await exportAsDeltaJson();
    
    debugPrint('=== Note Export ===');
    debugPrint('Plain Text: $plainText');
    debugPrint('Delta JSON: $deltaJson');
    debugPrint('==================');
    
    // Show a snackbar to confirm save
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved! Check debug console for exported data.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateToolbarState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2A2A2A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _handleSave,
            icon: const Icon(Icons.save),
            tooltip: 'Save Note',
            color: const Color(0xFF6FB8E9),
          ),
        ],
      ),
      body: Column(
        children: [
          // Formatting Toolbar
          Container(
            color: const Color(0xFF2A2A2A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formatting Toolbar:',
                  style: TextStyle(
                    color: Color(0xFF6FB8E9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                NotesFormattingToolbar(
                  controller: _controller,
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
              ],
            ),
          ),
          
          // Editor
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}