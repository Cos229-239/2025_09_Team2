import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/card.dart';

/// Perfect visual flashcard widget optimized for visual learners
/// Displays enhanced visual content with diagrams, placeholders, and interactive elements
class VisualFlashcardWidget extends StatefulWidget {
  final FlashCard flashcard;
  final bool showBack;
  final VoidCallback? onTap;

  const VisualFlashcardWidget({
    super.key,
    required this.flashcard,
    this.showBack = false,
    this.onTap,
  });

  @override
  VisualFlashcardWidgetState createState() => VisualFlashcardWidgetState();
}

class VisualFlashcardWidgetState extends State<VisualFlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showDiagramDetails = false;

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
      child: GestureDetector(
        onTap: widget.onTap,
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _getSubjectColor().withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual learner indicator header
                  _buildVisualLearnerHeader(context),
                  const SizedBox(height: 16),
                  
                  // Visual content section
                  if (_hasVisualContent()) ...[
                    _buildVisualContentSection(context),
                    const SizedBox(height: 20),
                  ],
                  
                  // Interactive diagram section
                  if (widget.flashcard.diagramData != null) ...[
                    _buildInteractiveDiagramSection(context),
                    const SizedBox(height: 20),
                  ],
                  
                  // Question section with visual styling
                  _buildQuestionSection(context),
                  
                  // Answer section (if showing back)
                  if (widget.showBack) ...[
                    const SizedBox(height: 16),
                    _buildAnswerSection(context),
                  ],
                  
                  // Visual metadata footer
                  if (_hasVisualMetadata()) ...[
                    const SizedBox(height: 16),
                    _buildVisualMetadataFooter(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build visual learner indicator header
  Widget _buildVisualLearnerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getSubjectColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getSubjectColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            size: 16,
            color: _getSubjectColor(),
          ),
          const SizedBox(width: 6),
          Text(
            'Visual Learning Card',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getSubjectColor(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getSubjectColor(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _getVisualType().toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build visual content section with image placeholder
  Widget _buildVisualContentSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSubjectColor().withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Visual placeholder image
            if (widget.flashcard.imageUrl != null)
              Image.network(
                widget.flashcard.imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildVisualPlaceholder(context);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildVisualPlaceholder(context);
                },
              )
            else
              _buildVisualPlaceholder(context),
            
            // Visual content overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  'Visual representation optimized for your learning style',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build visual placeholder when image is not available
  Widget _buildVisualPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getSubjectColor().withOpacity(0.1),
            _getSubjectColor().withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getSubjectIcon(),
            size: 64,
            color: _getSubjectColor(),
          ),
          const SizedBox(height: 12),
          Text(
            'Visual Learning Content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getSubjectColor(),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getVisualDescription(),
              style: TextStyle(
                fontSize: 12,
                color: _getSubjectColor(),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build interactive diagram section
  Widget _buildInteractiveDiagramSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diagram header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _getDiagramIcon(),
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Interactive ${_getVisualType().replaceAll('_', ' ').toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showDiagramDetails = !_showDiagramDetails;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showDiagramDetails ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showDiagramDetails ? 'Hide' : 'Show',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Diagram content
          Container(
            height: _showDiagramDetails ? null : 140,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: _buildDiagramContent(context),
          ),
        ],
      ),
    );
  }

  /// Build diagram content based on type
  Widget _buildDiagramContent(BuildContext context) {
    try {
      final diagramData = jsonDecode(widget.flashcard.diagramData!);
      final diagramType = diagramData['type'] as String;
      
      switch (diagramType) {
        case 'flowchart':
          return _buildFlowchartDiagram(diagramData);
        case 'concept_map':
          return _buildConceptMapDiagram(diagramData);
        case 'comparison':
          return _buildComparisonDiagram(diagramData);
        case 'structure':
          return _buildStructuralDiagram(diagramData);
        default:
          return _buildGenericDiagram(diagramData);
      }
    } catch (e) {
      return _buildErrorDiagram();
    }
  }

  /// Build flowchart diagram
  Widget _buildFlowchartDiagram(Map<String, dynamic> data) {
    final elements = (data['elements'] as List<dynamic>?) ?? [];
    
    return SingleChildScrollView(
      child: Column(
        children: elements.asMap().entries.map((entry) {
          final index = entry.key;
          final element = entry.value as Map<String, dynamic>;
          
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getElementColor(element['type'] as String? ?? 'process'),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  element['label'] as String? ?? 'Step ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (index < elements.length - 1) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.arrow_downward,
                  color: Colors.blue[400],
                  size: 20,
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Build concept map diagram
  Widget _buildConceptMapDiagram(Map<String, dynamic> data) {
    final elements = (data['elements'] as List<dynamic>?) ?? [];
    
    return Container(
      height: 200,
      child: Stack(
        children: elements.map<Widget>((element) {
          final elementMap = element as Map<String, dynamic>;
          final x = (elementMap['x'] as num?)?.toDouble() ?? 100.0;
          final y = (elementMap['y'] as num?)?.toDouble() ?? 100.0;
          final type = elementMap['type'] as String? ?? 'concept';
          final label = elementMap['label'] as String? ?? 'Concept';
          
          return Positioned(
            left: x - 50,
            top: y - 25,
            child: Container(
              width: 100,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: type == 'central' ? _getSubjectColor() : Colors.white,
                borderRadius: BorderRadius.circular(type == 'central' ? 25 : 8),
                border: Border.all(
                  color: _getSubjectColor(),
                  width: type == 'central' ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: type == 'central' ? FontWeight.bold : FontWeight.w500,
                    color: type == 'central' ? Colors.white : _getSubjectColor(),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build comparison diagram
  Widget _buildComparisonDiagram(Map<String, dynamic> data) {
    final elements = (data['elements'] as List<dynamic>?) ?? [];
    
    return Row(
      children: elements.take(2).map<Widget>((element) {
        final elementMap = element as Map<String, dynamic>;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getSubjectColor().withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  elementMap['label'] as String? ?? 'Item',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getSubjectColor(),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  elementMap['description'] as String? ?? 'Description',
                  style: const TextStyle(fontSize: 10),
                  maxLines: _showDiagramDetails ? null : 3,
                  overflow: _showDiagramDetails ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build structural diagram
  Widget _buildStructuralDiagram(Map<String, dynamic> data) {
    final elements = (data['elements'] as List<dynamic>?) ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: elements.map<Widget>((element) {
        final elementMap = element as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getSubjectColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getSubjectColor().withOpacity(0.3)),
          ),
          child: Text(
            elementMap['label'] as String? ?? 'Component',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _getSubjectColor(),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build generic diagram
  Widget _buildGenericDiagram(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getSubjectColor().withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schema,
            size: 32,
            color: _getSubjectColor(),
          ),
          const SizedBox(height: 8),
          Text(
            data['title'] as String? ?? 'Visual Diagram',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getSubjectColor(),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build error diagram fallback
  Widget _buildErrorDiagram() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Diagram content loading...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build question section with visual styling
  Widget _buildQuestionSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSubjectColor().withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSubjectColor().withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 18,
                color: _getSubjectColor(),
              ),
              const SizedBox(width: 8),
              Text(
                'Visual Learning Question',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getSubjectColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.flashcard.front,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Build answer section with visual enhancements
  Widget _buildAnswerSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: Colors.green[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Visual Learning Answer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.flashcard.back,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build visual metadata footer
  Widget _buildVisualMetadataFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: Colors.purple[700],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enhanced for visual learning with ${_getVisualType().replaceAll('_', ' ')} layout',
              style: TextStyle(
                fontSize: 11,
                color: Colors.purple[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'VISUAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if flashcard has visual content
  bool _hasVisualContent() {
    return widget.flashcard.imageUrl != null;
  }

  /// Check if flashcard has visual metadata
  bool _hasVisualMetadata() {
    return widget.flashcard.visualMetadata != null && 
           widget.flashcard.visualMetadata!.isNotEmpty;
  }

  /// Get visual type from metadata
  String _getVisualType() {
    return widget.flashcard.visualMetadata?['visualType'] ?? 'concept_map';
  }

  /// Get subject-appropriate color
  Color _getSubjectColor() {
    final subject = widget.flashcard.visualMetadata?['subject']?.toLowerCase() ?? '';
    if (subject.contains('biology')) return const Color(0xFF4CAF50);
    if (subject.contains('chemistry')) return const Color(0xFF2196F3);
    if (subject.contains('physics')) return const Color(0xFFFF9800);
    if (subject.contains('math')) return const Color(0xFF9C27B0);
    if (subject.contains('history')) return const Color(0xFF795548);
    if (subject.contains('literature')) return const Color(0xFFE91E63);
    return const Color(0xFF607D8B);
  }

  /// Get subject-appropriate icon
  IconData _getSubjectIcon() {
    final subject = widget.flashcard.visualMetadata?['subject']?.toLowerCase() ?? '';
    if (subject.contains('biology')) return Icons.biotech;
    if (subject.contains('chemistry')) return Icons.science;
    if (subject.contains('physics')) return Icons.electrical_services;
    if (subject.contains('math')) return Icons.calculate;
    if (subject.contains('history')) return Icons.history_edu;
    if (subject.contains('literature')) return Icons.menu_book;
    return Icons.school;
  }

  /// Get diagram type icon
  IconData _getDiagramIcon() {
    final visualType = _getVisualType();
    switch (visualType) {
      case 'flowchart':
        return Icons.account_tree;
      case 'concept_map':
        return Icons.hub;
      case 'comparison':
        return Icons.compare_arrows;
      case 'structure':
        return Icons.schema;
      default:
        return Icons.account_tree;
    }
  }

  /// Get visual description for placeholder
  String _getVisualDescription() {
    final visualType = _getVisualType();
    switch (visualType) {
      case 'flowchart':
        return 'Step-by-step process visualization';
      case 'concept_map':
        return 'Interconnected concept relationships';
      case 'comparison':
        return 'Side-by-side comparison chart';
      case 'structure':
        return 'Structural component diagram';
      default:
        return 'Educational visual representation';
    }
  }

  /// Get color for diagram elements
  Color _getElementColor(String elementType) {
    switch (elementType) {
      case 'start':
        return Colors.green;
      case 'end':
        return Colors.red;
      case 'process':
        return Colors.blue;
      case 'decision':
        return Colors.orange;
      default:
        return _getSubjectColor();
    }
  }
}