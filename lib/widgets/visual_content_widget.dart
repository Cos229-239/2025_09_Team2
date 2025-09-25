import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card.dart';
import '../models/user.dart';
import 'dart:convert';

/// Multi-modal content widget that displays visual, audio, and interactive content
/// based on user learning preferences and card content type
class VisualContentWidget extends StatefulWidget {
  final FlashCard card;
  final User user;
  final bool showFront;
  final VoidCallback? onContentTap;

  const VisualContentWidget({
    super.key,
    required this.card,
    required this.user,
    this.showFront = true,
    this.onContentTap,
  });

  @override
  VisualContentWidgetState createState() => VisualContentWidgetState();
}

class VisualContentWidgetState extends State<VisualContentWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _getBackgroundColor(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual content for visual learners
            if (_shouldShowVisualContent()) _buildVisualContent(),
            
            // Audio content for auditory learners
            if (_shouldShowAudioContent()) _buildAudioContent(),
            
            // Interactive diagram for kinesthetic learners
            if (_shouldShowDiagramContent()) _buildDiagramContent(),
            
            // Main text content (always shown)
            _buildTextContent(),
            
            // Content controls
            if (_hasMultiModalContent()) _buildContentControls(),
          ],
        ),
      ),
    );
  }

  /// Determine if visual content should be displayed
  bool _shouldShowVisualContent() {
    return widget.card.imageUrl != null && 
           (widget.user.preferences.learningStyle == 'visual' || 
            widget.user.preferences.learningStyle == 'adaptive');
  }

  /// Determine if audio content should be displayed
  bool _shouldShowAudioContent() {
    return widget.card.audioUrl != null && 
           (widget.user.preferences.learningStyle == 'auditory' || 
            widget.user.preferences.learningStyle == 'adaptive');
  }

  /// Determine if diagram content should be displayed
  bool _shouldShowDiagramContent() {
    return widget.card.diagramData != null && 
           (widget.user.preferences.learningStyle == 'kinesthetic' || 
            widget.user.preferences.learningStyle == 'visual' ||
            widget.user.preferences.learningStyle == 'adaptive');
  }

  /// Check if card has any multi-modal content
  bool _hasMultiModalContent() {
    return widget.card.imageUrl != null || 
           widget.card.audioUrl != null || 
           widget.card.diagramData != null;
  }

  /// Build visual content display
  Widget _buildVisualContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Visual Representation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.card.imageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Visual content unavailable',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build audio content controls
  Widget _buildAudioContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.headphones,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Content Available',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'Optimized for auditory learning',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleAudio,
            icon: Icon(
              _isAudioPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build interactive diagram content
  Widget _buildDiagramContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Interactive Diagram',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _buildDiagramVisualization(),
          ),
        ],
      ),
    );
  }

  /// Build diagram visualization from JSON data
  Widget _buildDiagramVisualization() {
    try {
      final diagramData = jsonDecode(widget.card.diagramData!);
      final elements = diagramData['elements'] as List;
      
      return Stack(
        children: elements.map<Widget>((element) {
          final x = (element['x'] as num).toDouble();
          final y = (element['y'] as num).toDouble();
          final label = element['label'] as String;
          final type = element['type'] as String;
          
          return Positioned(
            left: x - 40,
            top: y - 15,
            child: GestureDetector(
              onTap: () => _showElementDetails(element),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getElementColor(type),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Diagram unavailable',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Build main text content
  Widget _buildTextContent() {
    final content = widget.showFront ? widget.card.front : widget.card.back;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        content,
        style: TextStyle(
          fontSize: _getTextSize(),
          fontWeight: FontWeight.w500,
          color: _getTextColor(),
          height: 1.4,
        ),
      ),
    );
  }

  /// Build content controls for multi-modal features
  Widget _buildContentControls() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (widget.card.imageUrl != null)
            _buildControlButton(
              icon: Icons.image,
              label: 'Visual',
              onTap: _showFullScreenImage,
            ),
          if (widget.card.audioUrl != null)
            _buildControlButton(
              icon: _isAudioPlaying ? Icons.pause : Icons.play_arrow,
              label: 'Audio',
              onTap: _toggleAudio,
            ),
          if (widget.card.diagramData != null)
            _buildControlButton(
              icon: Icons.fullscreen,
              label: 'Diagram',
              onTap: _showFullScreenDiagram,
            ),
        ],
      ),
    );
  }

  /// Build individual control button
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle audio playback
  void _toggleAudio() {
    setState(() {
      _isAudioPlaying = !_isAudioPlaying;
    });
    
    // In production, integrate with actual audio player
    HapticFeedback.selectionClick();
    
    if (_isAudioPlaying) {
      // Start audio playback
      debugPrint('Playing audio: ${widget.card.audioUrl}');
      // Simulate audio duration
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isAudioPlaying = false;
          });
        }
      });
    } else {
      // Stop audio playback
      debugPrint('Stopping audio playback');
    }
  }

  /// Show full-screen image
  void _showFullScreenImage() {
    if (widget.card.imageUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.network(
              widget.card.imageUrl!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  /// Show full-screen diagram
  void _showFullScreenDiagram() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Interactive Diagram',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: _buildDiagramVisualization(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show element details
  void _showElementDetails(Map<String, dynamic> element) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(element['label'] as String),
        content: Text('Type: ${element['type']}\nPosition: (${element['x']}, ${element['y']})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get background color based on theme
  Color _getBackgroundColor() {
    final theme = widget.user.preferences.theme;
    if (theme == 'dark') {
      return const Color(0xFF2c3e50);
    } else {
      return Colors.white;
    }
  }

  /// Get text color based on theme
  Color _getTextColor() {
    final theme = widget.user.preferences.theme;
    if (theme == 'dark') {
      return const Color(0xFFecf0f1);
    } else {
      return const Color(0xFF2c3e50);
    }
  }

  /// Get text size based on user preferences
  double _getTextSize() {
    return widget.user.preferences.fontSize * 16.0;
  }

  /// Get element color based on type
  Color _getElementColor(String type) {
    switch (type) {
      case 'start':
        return Colors.green;
      case 'end':
        return Colors.red;
      case 'process':
        return Colors.blue;
      case 'decision':
        return Colors.orange;
      case 'node':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}