// File: lib/widgets/multitouch_pairing_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class MultiTouchPairingScreen extends StatefulWidget {
  const MultiTouchPairingScreen({super.key});

  @override
  State<MultiTouchPairingScreen> createState() => _MultiTouchPairingScreenState();
}

class TouchPoint {
  final int id;
  final Offset position;
  final Color color;
  int? pairedWith;

  TouchPoint({
    required this.id,
    required this.position,
    required this.color,
    this.pairedWith,
  });
}

class TouchPair {
  final int touch1Id;
  final int touch2Id;
  final Color lineColor;

  TouchPair({
    required this.touch1Id,
    required this.touch2Id,
    required this.lineColor,
  });
}

class _MultiTouchPairingScreenState extends State<MultiTouchPairingScreen> {
  Map<int, TouchPoint> activeTouches = {};
  List<TouchPair> pairs = [];
  int pairColorIndex = 0;
  
  final List<Color> touchColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  final List<Color> lineColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  void _updateTouches(PointerEvent event) {
    setState(() {
      if (event is PointerDownEvent) {
        // Add new touch
        activeTouches[event.pointer] = TouchPoint(
          id: event.pointer,
          position: event.localPosition,
          color: touchColors[event.pointer % touchColors.length],
        );
        _updatePairings();
      } else if (event is PointerMoveEvent) {
        // Update existing touch position
        if (activeTouches.containsKey(event.pointer)) {
          activeTouches[event.pointer] = TouchPoint(
            id: event.pointer,
            position: event.localPosition,
            color: activeTouches[event.pointer]!.color,
            pairedWith: activeTouches[event.pointer]!.pairedWith,
          );
        }
      } else if (event is PointerUpEvent || event is PointerCancelEvent) {
        // Remove touch
        activeTouches.remove(event.pointer);
        _updatePairings();
      }
    });
  }

  void _updatePairings() {
    // Clear existing pairings
    for (var touch in activeTouches.values) {
      touch.pairedWith = null;
    }
    pairs.clear();
    pairColorIndex = 0;

    List<int> unpaired = activeTouches.keys.toList();
    
    // Random pairing algorithm
    final random = math.Random();
    unpaired.shuffle(random);
    
    while (unpaired.length >= 2) {
      // Take first two from shuffled list
      int touch1 = unpaired.removeAt(0);
      int touch2 = unpaired.removeAt(0);
      
      _pairTouches(touch1, touch2);
    }
  }

  void _pairTouches(int id1, int id2) {
    activeTouches[id1]?.pairedWith = id2;
    activeTouches[id2]?.pairedWith = id1;
    
    pairs.add(TouchPair(
      touch1Id: id1,
      touch2Id: id2,
      lineColor: lineColors[pairColorIndex % lineColors.length],
    ));
    
    pairColorIndex++;
  }

  void _clearTouches() {
    setState(() {
      activeTouches.clear();
      pairs.clear();
      pairColorIndex = 0;
    });
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('How to Use'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Place multiple fingers on the screen'),
              Text('• Each finger creates a colored touch point'),
              Text('• Touches are randomly paired (2 by 2)'),
              Text('• Colored lines show the random pairings'),
              Text('• Move fingers to see real-time updates'),
              Text('• Works with up to 10 simultaneous touches'),
              Text('• Each pair gets a different line color'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Multitouch Pairing'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: Listener(
        onPointerDown: _updateTouches,
        onPointerMove: _updateTouches,
        onPointerUp: _updateTouches,
        onPointerCancel: _updateTouches,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: TouchPainter(
              touches: activeTouches.values.toList(),
              pairs: pairs,
            ),
            child: Container(),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: _clearTouches,
            backgroundColor: Colors.red,
            child: const Icon(Icons.clear),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _showInstructions,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.help),
          ),
        ],
      ),
    );
  }
}

class TouchPainter extends CustomPainter {
  final List<TouchPoint> touches;
  final List<TouchPair> pairs;

  TouchPainter({required this.touches, required this.pairs});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connection lines first (so they appear behind touch points)
    for (var pair in pairs) {
      TouchPoint? touch1 = touches.firstWhere(
        (t) => t.id == pair.touch1Id, 
        orElse: () => TouchPoint(id: -1, position: Offset.zero, color: Colors.transparent),
      );
      TouchPoint? touch2 = touches.firstWhere(
        (t) => t.id == pair.touch2Id, 
        orElse: () => TouchPoint(id: -1, position: Offset.zero, color: Colors.transparent),
      );
      
      if (touch1.id != -1 && touch2.id != -1) {
        final paint = Paint()
          ..color = pair.lineColor
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke;
        
        // Draw simple straight line
        canvas.drawLine(touch1.position, touch2.position, paint);
      }
    }

    // Draw touch points
    for (var touch in touches) {
      // Outer ring
      final outerPaint = Paint()
        ..color = touch.color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touch.position, 40, outerPaint);
      
      // Inner circle
      final innerPaint = Paint()
        ..color = touch.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touch.position, 20, innerPaint);
      
      // Center dot
      final centerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touch.position, 5, centerPaint);
      
      // Touch ID label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${touch.id}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          touch.position.dx - textPainter.width / 2,
          touch.position.dy + 30,
        ),
      );
    }

    // Draw info text
    final infoPainter = TextPainter(
      text: TextSpan(
        text: 'Active touches: ${touches.length} | Pairs: ${pairs.length}',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    infoPainter.layout();
    infoPainter.paint(canvas, const Offset(20, 20));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}