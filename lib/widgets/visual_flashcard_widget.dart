import 'dart:convert';
import 'dart:math' as math;
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
                  _getSubjectColor().withValues(alpha: 0.05),
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
        color: _getSubjectColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getSubjectColor().withValues(alpha: 0.3),
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
          color: _getSubjectColor().withValues(alpha: 0.2),
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
                      Colors.black.withValues(alpha: 0.7),
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
            _getSubjectColor().withValues(alpha: 0.1),
            _getSubjectColor().withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.9),
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
    debugPrint('Building interactive diagram section for card: ${widget.flashcard.id}');
    debugPrint('Diagram data exists: ${widget.flashcard.diagramData != null}');
    if (widget.flashcard.diagramData != null) {
      debugPrint('Diagram data preview: ${widget.flashcard.diagramData!.substring(0, math.min(100, widget.flashcard.diagramData!.length))}...');
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
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
                      color: Colors.blue.withValues(alpha: 0.1),
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
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
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
    final connections = (data['connections'] as List<dynamic>?) ?? [];
    
    debugPrint('🗺️ Building concept map with ${elements.length} elements and ${connections.length} connections');
    
    return Container(
      height: 250, // Increased height for better visibility
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getSubjectColor().withValues(alpha: 0.2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Normalize positions to fit within the available space
          final normalizedElements = _normalizeElementPositions(elements, constraints);
          final normalizedConnections = _normalizeConnections(connections, normalizedElements);
          
          return CustomPaint(
            painter: ConceptMapPainter(
              elements: normalizedElements,
              connections: normalizedConnections,
              subjectColor: _getSubjectColor(),
            ),
            child: Stack(
              children: normalizedElements.map<Widget>((element) {
                final elementMap = element;
                final x = (elementMap['x'] as num?)?.toDouble() ?? 0.0;
                final y = (elementMap['y'] as num?)?.toDouble() ?? 0.0;
                final type = elementMap['type'] as String? ?? 'concept';
                final label = elementMap['label'] as String? ?? 'Concept';
                
                final nodeWidth = type == 'central' ? 140.0 : 110.0;
                final nodeHeight = type == 'central' ? 70.0 : 55.0;
                
                return Positioned(
                  left: math.max(0, math.min(x - nodeWidth/2, constraints.maxWidth - nodeWidth)),
                  top: math.max(0, math.min(y - nodeHeight/2, constraints.maxHeight - nodeHeight)),
                  child: Container(
                    width: type == 'central' ? 140 : 110, // Increased sizes for better visibility
                    height: type == 'central' ? 70 : 55,
                    padding: EdgeInsets.all(type == 'central' ? 14 : 10),
                    decoration: BoxDecoration(
                      color: type == 'central' 
                        ? _getSubjectColor() 
                        : Colors.white,
                      borderRadius: BorderRadius.circular(type == 'central' ? 35 : 16),
                      border: Border.all(
                        color: _getSubjectColor(),
                        width: type == 'central' ? 4 : 3, // Thicker borders for prominence
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: type == 'central' ? 0.3 : 0.15),
                          blurRadius: type == 'central' ? 12 : 8, // More pronounced shadows
                          offset: Offset(0, type == 'central' ? 4 : 3),
                          spreadRadius: type == 'central' ? 2 : 1,
                        ),
                        // Add inner shadow for depth
                        if (type == 'central') BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(-1, -1),
                          spreadRadius: 0,
                        ),
                      ],
                      gradient: type == 'central' ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getSubjectColor().withValues(alpha: 0.9),
                          _getSubjectColor(),
                          _getSubjectColor().withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ) : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          _getSubjectColor().withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Container(
                      decoration: type == 'central' ? BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ) : null,
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: type == 'central' ? 13 : 11, // Larger text
                            fontWeight: type == 'central' ? FontWeight.w900 : FontWeight.w700,
                            color: type == 'central' ? Colors.white : _getSubjectColor(),
                            letterSpacing: type == 'central' ? 0.5 : 0.3,
                            shadows: type == 'central' ? [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ] : null,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
  
  /// Normalize element positions to fit within container bounds
  List<Map<String, dynamic>> _normalizeElementPositions(List<dynamic> elements, BoxConstraints constraints) {
    if (elements.isEmpty) return [];
    
    final normalizedElements = <Map<String, dynamic>>[];
    final containerWidth = constraints.maxWidth;
    final containerHeight = constraints.maxHeight;
    
    debugPrint('🔄 Normalizing ${elements.length} elements in ${containerWidth}x$containerHeight container');
    
    // Find central element first
    var centralIndex = elements.indexWhere((e) => (e as Map<String, dynamic>)['type'] == 'central');
    if (centralIndex == -1) centralIndex = 0;
    
    if (elements.length == 1) {
      // Single element - place in center
      final element = Map<String, dynamic>.from(elements[0] as Map<String, dynamic>);
      element['x'] = containerWidth / 2;
      element['y'] = containerHeight / 2;
      normalizedElements.add(element);
    } else if (elements.length == 2) {
      // Two elements - side by side
      for (int i = 0; i < elements.length; i++) {
        final element = Map<String, dynamic>.from(elements[i] as Map<String, dynamic>);
        element['x'] = (containerWidth / 3) * (i + 1); // 1/3 and 2/3 positions
        element['y'] = containerHeight / 2;
        normalizedElements.add(element);
      }
    } else {
      // Multiple elements - improved circular arrangement
      for (int i = 0; i < elements.length; i++) {
        final element = Map<String, dynamic>.from(elements[i] as Map<String, dynamic>);
        
        if (i == centralIndex) {
          // Central element in the middle
          element['x'] = containerWidth / 2;
          element['y'] = containerHeight / 2;
          element['type'] = 'central'; // Ensure it's marked as central
        } else {
          // Calculate position for non-central elements
          final nonCentralIndex = i - (i > centralIndex ? 1 : 0);
          final totalNonCentral = elements.length - 1;
          
          // Improved angle calculation for better distribution
          final baseAngle = (2 * math.pi * nonCentralIndex) / totalNonCentral;
          final angle = baseAngle - (math.pi / 2); // Start from top
          
          // Calculate radius ensuring no overlap with enhanced spacing
          final minRadius = 140.0; // Increased minimum distance from center
          final maxRadius = math.min(containerWidth, containerHeight) * 0.4;
          final radius = math.max(minRadius, maxRadius);
          
          // Calculate position
          final centerX = containerWidth / 2;
          final centerY = containerHeight / 2;
          
          var x = centerX + radius * math.cos(angle);
          var y = centerY + radius * math.sin(angle);
          
          // Ensure elements stay within bounds with generous margins for new larger sizes
          final nodeWidth = 110.0; // Updated to match new size
          final nodeHeight = 55.0; // Updated to match new size
          final margin = 30.0; // Increased margin
          
          x = math.max(margin + nodeWidth/2, math.min(x, containerWidth - margin - nodeWidth/2));
          y = math.max(margin + nodeHeight/2, math.min(y, containerHeight - margin - nodeHeight/2));
          
          element['x'] = x;
          element['y'] = y;
          
          debugPrint('📍 Element $i: ${element['label']} at (${x.toInt()}, ${y.toInt()})');
        }
        
        normalizedElements.add(element);
      }
    }
    
    return normalizedElements;
  }
  
  /// Normalize connections based on new element positions
  List<Map<String, dynamic>> _normalizeConnections(List<dynamic> connections, List<Map<String, dynamic>> elements) {
    return connections.map((conn) {
      final connection = Map<String, dynamic>.from(conn as Map<String, dynamic>);
      // Connections reference element indices, which remain the same
      return connection;
    }).toList();
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
              border: Border.all(color: _getSubjectColor().withValues(alpha: 0.3)),
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
            color: _getSubjectColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getSubjectColor().withValues(alpha: 0.3)),
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
        border: Border.all(color: _getSubjectColor().withValues(alpha: 0.3)),
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
        color: _getSubjectColor().withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSubjectColor().withValues(alpha: 0.2),
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
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
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
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
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
              color: Colors.purple.withValues(alpha: 0.1),
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

/// Custom painter for drawing concept map connections
class ConceptMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> elements;
  final List<Map<String, dynamic>> connections;
  final Color subjectColor;

  ConceptMapPainter({
    required this.elements,
    required this.connections,
    required this.subjectColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (elements.isEmpty) return;
    
    final paint = Paint()
      ..color = subjectColor.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = subjectColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // If no explicit connections, connect all elements to the central one
    if (connections.isEmpty) {
      final centralIndex = elements.indexWhere((e) => e['type'] == 'central');
      if (centralIndex >= 0) {
        for (int i = 0; i < elements.length; i++) {
          if (i != centralIndex) {
            _drawConnection(canvas, elements[centralIndex], elements[i], linePaint, paint, '');
          }
        }
      }
    } else {
      // Draw explicit connections
      for (final connection in connections) {
        final from = connection['from'] as int?;
        final to = connection['to'] as int?;
        final label = connection['label'] as String? ?? '';

        if (from != null && to != null && from < elements.length && to < elements.length) {
          _drawConnection(canvas, elements[from], elements[to], linePaint, paint, label);
        }
      }
    }
  }

  void _drawConnection(Canvas canvas, Map<String, dynamic> fromElement, Map<String, dynamic> toElement, 
                      Paint linePaint, Paint arrowPaint, String label) {
    final fromX = (fromElement['x'] as num?)?.toDouble() ?? 0.0;
    final fromY = (fromElement['y'] as num?)?.toDouble() ?? 0.0;
    final toX = (toElement['x'] as num?)?.toDouble() ?? 0.0;
    final toY = (toElement['y'] as num?)?.toDouble() ?? 0.0;
    
    final fromType = fromElement['type'] as String? ?? 'concept';
    final toType = toElement['type'] as String? ?? 'concept';

    // Calculate connection points at edge of nodes instead of centers
    final dx = toX - fromX;
    final dy = toY - fromY;
    final length = math.sqrt(dx * dx + dy * dy);
    
    if (length < 40) return; // Skip if nodes are too close
    
    final unitX = dx / length;
    final unitY = dy / length;
    
    // Calculate edge points based on updated node sizes
    final fromRadius = fromType == 'central' ? 70.0 : 55.0; // Updated radii
    final toRadius = toType == 'central' ? 70.0 : 55.0;
    
    final startX = fromX + unitX * fromRadius;
    final startY = fromY + unitY * fromRadius;
    final endX = toX - unitX * toRadius;
    final endY = toY - unitY * toRadius;

    // Enhanced line paint with gradient effect and better visibility
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          subjectColor.withValues(alpha: 0.8),
          subjectColor.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)))
      ..strokeWidth = 3.5 // Thicker lines for better visibility
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Add shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw connection line with smooth curve
    final path = Path();
    path.moveTo(startX, startY);
    
    // Add slight curve for visual appeal
    final midX = (startX + endX) / 2;
    final midY = (startY + endY) / 2;
    final controlOffset = math.min(20.0, length * 0.1);
    final controlX = midX + (endY - startY) * controlOffset / length;
    final controlY = midY - (endX - startX) * controlOffset / length;
    
    path.quadraticBezierTo(controlX, controlY, endX, endY);
    
    // Draw shadow first for depth
    final shadowPath = Path();
    shadowPath.moveTo(startX + 1, startY + 1);
    shadowPath.quadraticBezierTo(controlX + 1, controlY + 1, endX + 1, endY + 1);
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Draw main connection line
    canvas.drawPath(path, gradientPaint);

    // Draw enhanced arrowhead with better visibility
    final arrowLength = 14.0; // Larger arrows
    final arrowAngle = math.pi / 4; // Wider angle for better visibility
    
    final arrowX1 = endX - arrowLength * (unitX * math.cos(arrowAngle) - unitY * math.sin(arrowAngle));
    final arrowY1 = endY - arrowLength * (unitY * math.cos(arrowAngle) + unitX * math.sin(arrowAngle));
    final arrowX2 = endX - arrowLength * (unitX * math.cos(-arrowAngle) - unitY * math.sin(-arrowAngle));
    final arrowY2 = endY - arrowLength * (unitY * math.cos(-arrowAngle) + unitX * math.sin(-arrowAngle));

    final arrowPath = Path();
    arrowPath.moveTo(endX, endY);
    arrowPath.lineTo(arrowX1, arrowY1);
    arrowPath.lineTo(arrowX2, arrowY2);
    arrowPath.close();
    
    final arrowFillPaint = Paint()
      ..color = subjectColor.withValues(alpha: 0.9) // More opaque for visibility
      ..style = PaintingStyle.fill;
    
    // Add arrow shadow
    final arrowShadowPath = Path();
    arrowShadowPath.moveTo(endX + 1, endY + 1);
    arrowShadowPath.lineTo(arrowX1 + 1, arrowY1 + 1);
    arrowShadowPath.lineTo(arrowX2 + 1, arrowY2 + 1);
    arrowShadowPath.close();
    
    canvas.drawPath(arrowShadowPath, Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill);
    
    canvas.drawPath(arrowPath, arrowFillPaint);

    // Draw connection label if provided
    if (label.isNotEmpty) {
      final midX = (fromX + toX) / 2;
      final midY = (fromY + toY) / 2;
      
      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: subjectColor,
          fontSize: 9,
          fontWeight: FontWeight.w500,
          backgroundColor: Colors.white.withValues(alpha: 0.9),
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      // Draw background for text
      final rect = Rect.fromCenter(
        center: Offset(midX, midY),
        width: textPainter.width + 4,
        height: textPainter.height + 2,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
      
      textPainter.paint(canvas, Offset(midX - textPainter.width / 2, midY - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}