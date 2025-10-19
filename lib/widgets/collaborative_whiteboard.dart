import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Collaborative whiteboard widget for live sessions
/// Supports real-time multi-user drawing synchronized via Firestore
class CollaborativeWhiteboard extends StatefulWidget {
  final String sessionId;
  final String userId;

  const CollaborativeWhiteboard({
    super.key,
    required this.sessionId,
    required this.userId,
  });

  @override
  State<CollaborativeWhiteboard> createState() =>
      _CollaborativeWhiteboardState();
}

class _CollaborativeWhiteboardState extends State<CollaborativeWhiteboard> {
  final List<WhiteboardStroke> _strokes = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  WhiteboardTool _selectedTool = WhiteboardTool.pen;

  List<Offset> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    _listenToStrokes();
  }

  void _listenToStrokes() {
    _firestore
        .collection('social_sessions')
        .doc(widget.sessionId)
        .collection('whiteboard_strokes')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _strokes.clear();
        for (var doc in snapshot.docs) {
          try {
            _strokes.add(WhiteboardStroke.fromFirestore(doc.data()));
          } catch (e) {
            debugPrint('⚠️ Failed to parse stroke: $e');
          }
        }
      });
    });
  }

  Future<void> _addStroke(List<Offset> points) async {
    if (points.isEmpty) return;

    final stroke = WhiteboardStroke(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      points: points,
      color: _selectedColor,
      strokeWidth: _strokeWidth,
      tool: _selectedTool,
      timestamp: DateTime.now(),
    );

    try {
      await _firestore
          .collection('social_sessions')
          .doc(widget.sessionId)
          .collection('whiteboard_strokes')
          .doc(stroke.id)
          .set(stroke.toFirestore());
    } catch (e) {
      debugPrint('❌ Failed to save stroke: $e');
    }
  }

  Future<void> _clearWhiteboard() async {
    try {
      final batch = _firestore.batch();
      final strokes = await _firestore
          .collection('social_sessions')
          .doc(widget.sessionId)
          .collection('whiteboard_strokes')
          .get();

      for (var doc in strokes.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      setState(() {
        _strokes.clear();
      });
    } catch (e) {
      debugPrint('❌ Failed to clear whiteboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        _buildToolbar(),

        // Canvas
        Expanded(
          child: Container(
            color: Colors.white,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _currentStroke = [details.localPosition];
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentStroke.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                _addStroke(_currentStroke);
                setState(() {
                  _currentStroke = [];
                });
              },
              child: CustomPaint(
                painter: WhiteboardPainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                  currentColor: _selectedColor,
                  currentWidth: _strokeWidth,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Row(
        children: [
          // Pen tool
          IconButton(
            icon: const Icon(Icons.edit),
            color: _selectedTool == WhiteboardTool.pen
                ? Colors.blue
                : Colors.black,
            onPressed: () => setState(() => _selectedTool = WhiteboardTool.pen),
          ),

          // Eraser tool
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            color: _selectedTool == WhiteboardTool.eraser
                ? Colors.blue
                : Colors.black,
            onPressed: () =>
                setState(() => _selectedTool = WhiteboardTool.eraser),
          ),

          const SizedBox(width: 16),

          // Color picker
          _buildColorButton(Colors.black),
          _buildColorButton(Colors.red),
          _buildColorButton(Colors.blue),
          _buildColorButton(Colors.green),
          _buildColorButton(Colors.orange),
          _buildColorButton(Colors.purple),

          const SizedBox(width: 16),

          // Stroke width slider
          const Text('Width:'),
          SizedBox(
            width: 100,
            child: Slider(
              value: _strokeWidth,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => setState(() => _strokeWidth = value),
            ),
          ),

          const Spacer(),

          // Clear button
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear'),
            onPressed: _clearWhiteboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[100],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.blue : Colors.grey,
            width: _selectedColor == color ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for rendering whiteboard strokes
class WhiteboardPainter extends CustomPainter {
  final List<WhiteboardStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentWidth;

  WhiteboardPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all saved strokes
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != Offset.zero &&
            stroke.points[i + 1] != Offset.zero) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      }
    }

    // Draw current stroke being drawn
    if (currentStroke.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) => true;
}

/// Whiteboard stroke data model
class WhiteboardStroke {
  final String id;
  final String userId;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final WhiteboardTool tool;
  final DateTime timestamp;

  WhiteboardStroke({
    required this.id,
    required this.userId,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.tool,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'tool': tool.toString(),
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory WhiteboardStroke.fromFirestore(Map<String, dynamic> data) {
    final pointsList = data['points'] as List<dynamic>;
    final points = pointsList
        .map((p) => Offset(p['x'] as double, p['y'] as double))
        .toList();

    return WhiteboardStroke(
      id: data['id'] as String,
      userId: data['userId'] as String,
      points: points,
      color: Color(data['color'] as int),
      strokeWidth: (data['strokeWidth'] as num).toDouble(),
      tool: WhiteboardTool.values.firstWhere(
        (t) => t.toString() == data['tool'],
        orElse: () => WhiteboardTool.pen,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Whiteboard drawing tools
enum WhiteboardTool {
  pen,
  eraser,
  shapes, // Future: circles, rectangles, etc.
  text, // Future: text annotations
}
