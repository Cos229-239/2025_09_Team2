import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class NotesFormattingToolbar extends StatelessWidget {
  final QuillController controller;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isHighlighted;
  final String currentAlignment;
  final VoidCallback onToggleBold;
  final VoidCallback onToggleItalic;
  final VoidCallback onToggleUnderline;
  final VoidCallback onToggleHighlight;
  final Function(Attribute) onSetAlignment;

  const NotesFormattingToolbar({
    super.key,
    required this.controller,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    required this.isHighlighted,
    required this.currentAlignment,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onToggleUnderline,
    required this.onToggleHighlight,
    required this.onSetAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF444444)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Bold Button
          _FormatButton(
            icon: Icons.format_bold,
            label: 'Bold',
            tooltip: 'Bold (Ctrl+B)',
            isActive: isBold,
            onPressed: onToggleBold,
          ),
        
        // Italic Button
        _FormatButton(
          icon: Icons.format_italic,
          label: 'Italic',
          tooltip: 'Italic (Ctrl+I)',
          isActive: isItalic,
          onPressed: onToggleItalic,
        ),
        
        // Underline Button
        _FormatButton(
          icon: Icons.format_underlined,
          label: 'Underline',
          tooltip: 'Underline (Ctrl+U)',
          isActive: isUnderline,
          onPressed: onToggleUnderline,
        ),
        
        // Highlight Button
        _FormatButton(
          icon: Icons.highlight,
          label: 'Highlight',
          tooltip: 'Highlight Text',
          isActive: isHighlighted,
          onPressed: onToggleHighlight,
          activeColor: const Color(0xFFFFFF00),
        ),
        
        // Divider
        Container(
          width: 1,
          height: 40,
          color: const Color(0xFF444444),
          margin: const EdgeInsets.symmetric(horizontal: 4),
        ),
        
        // Alignment Buttons
        _AlignmentButtonGroup(
          currentAlignment: currentAlignment,
          onSetAlignment: onSetAlignment,
        ),
        ],
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;
  final Color? activeColor;

  const _FormatButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = isActive 
        ? Colors.white
        : const Color(0xFF888888);
    
    final backgroundColor = isActive 
        ? (activeColor ?? const Color(0xFF6FB8E9))
        : const Color(0xFF333333);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      elevation: isActive ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 60,
            minHeight: 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? (activeColor ?? const Color(0xFF6FB8E9)) : const Color(0xFF555555),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: buttonColor,
                size: 24,
                semanticLabel: tooltip,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: buttonColor,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlignmentButtonGroup extends StatelessWidget {
  final String currentAlignment;
  final Function(Attribute) onSetAlignment;

  const _AlignmentButtonGroup({
    required this.currentAlignment,
    required this.onSetAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AlignmentButton(
          icon: Icons.format_align_left,
          label: 'Left',
          tooltip: 'Align Left',
          isActive: currentAlignment == 'left',
          onPressed: () => onSetAlignment(Attribute.leftAlignment),
        ),
        const SizedBox(width: 4),
        _AlignmentButton(
          icon: Icons.format_align_center,
          label: 'Center',
          tooltip: 'Align Center',
          isActive: currentAlignment == 'center',
          onPressed: () => onSetAlignment(Attribute.centerAlignment),
        ),
        const SizedBox(width: 4),
        _AlignmentButton(
          icon: Icons.format_align_right,
          label: 'Right',
          tooltip: 'Align Right',
          isActive: currentAlignment == 'right',
          onPressed: () => onSetAlignment(Attribute.rightAlignment),
        ),
      ],
    );
  }
}

class _AlignmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  const _AlignmentButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = isActive 
        ? const Color(0xFF6FB8E9)
        : const Color(0xFF666666);
    
    final backgroundColor = isActive 
        ? const Color(0xFF6FB8E9).withValues(alpha: 0.2)
        : Colors.transparent;

    final borderColor = isActive 
        ? const Color(0xFF6FB8E9)
        : const Color(0xFF444444);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: buttonColor,
            size: 18,
            semanticLabel: tooltip,
          ),
        ),
      ),
    );
  }
}