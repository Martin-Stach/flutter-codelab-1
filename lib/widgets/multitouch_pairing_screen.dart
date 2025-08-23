import 'package:flutter/material.dart';
import 'dart:math' as math;

class MultitouchPairingScreen extends StatefulWidget {
  const MultitouchPairingScreen({super.key});

  @override
  State<MultitouchPairingScreen> createState() => _MultitouchPairingScreenState();
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

class _MultitouchPairingScreenState extends State<MultitouchPairingScreen> 
    with TickerProviderStateMixin {
  Map<int, TouchPoint> activeTouches = {};
  List<TouchPair> pairs = [];
  int pairColorIndex = 0;
  bool isPairing = false;
  bool pairingCompleted = false;
  final int countdown = 1;
  final int minTouches = 4; // Minimum touches required to start pairing
  bool _countdownActive = false; // Track if countdown is currently running
  
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Animation<double> _pulseAnimation;
  
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

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for countdown
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Countdown animation
    _countdownController = AnimationController(
      duration: Duration(seconds: countdown),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _updateTouches(PointerEvent event) {
    if (pairingCompleted) return; // Don't accept new touches after pairing completed
    
    setState(() {
      if (event is PointerDownEvent) {
        // Add new touch
        activeTouches[event.pointer] = TouchPoint(
          id: event.pointer,
          position: event.localPosition,
          color: touchColors[event.pointer % touchColors.length],
        );
        _handleTouchCountChange();
      } else if (event is PointerMoveEvent) {
        // Update existing touch position (allowed during pairing/countdown)
        if (activeTouches.containsKey(event.pointer)) {
          activeTouches[event.pointer] = TouchPoint(
            id: event.pointer,
            position: event.localPosition,
            color: activeTouches[event.pointer]!.color,
            pairedWith: activeTouches[event.pointer]!.pairedWith,
          );
        }
      } else if (event is PointerUpEvent || event is PointerCancelEvent) {
        if (!pairingCompleted) { // Only remove touches if pairing not completed
          activeTouches.remove(event.pointer);
          _handleTouchCountChange();
        }
      }
    });
  }

  void _handleTouchCountChange() {
    if (activeTouches.length >= 2 && activeTouches.length % 2 == 0 && activeTouches.length >= minTouches) {
      // We have an even number of touches (2 or more)
      if (isPairing) {
        // Already pairing, restart the countdown
        _restartPairingCountdown();
      } else {
        // Start new pairing countdown
        _startPairingCountdown();
      }
    } else {
      // Odd number of touches or less than 2, stop pairing
      if (isPairing) {
        _stopPairingCountdown();
      }
    }
  }

  void _checkForPairingStart() {
    if (activeTouches.length >= 2 && activeTouches.length % 2 == 0) {
      _startPairingCountdown();
    }
  }

  void _startPairingCountdown() {
    setState(() {
      isPairing = true;
      // countdown = 1;
    });
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Start countdown
    _runCountdown();
  }

  void _restartPairingCountdown() {
    // Reset the countdown and start over
    _pulseController.stop();
    _pulseController.reset();
    
    setState(() {
      // countdown = 1;
    });
    
    // Start pulse animation again
    _pulseController.repeat(reverse: true);
    
    // Start countdown again
    _runCountdown();
  }

  void _stopPairingCountdown() {
    setState(() {
      isPairing = false;
      // countdown = 1;
    });
    
    _pulseController.stop();
    _pulseController.reset();
  }

  void _runCountdown() async {
    _countdownActive = true;
    
    for (int i = countdown; i > 0; i--) {
      if (!mounted || !isPairing || !_countdownActive) return;
      
      setState(() {
        // countdown = i;
      });
      
      _countdownController.reset();
      _countdownController.forward();
      
      await Future.delayed(const Duration(seconds: 1));
    }
    
    if (mounted && isPairing && _countdownActive) {
      _executePairing();
    }
  }

  void _executePairing() {
    _countdownActive = false;
    _pulseController.stop();
    _pulseController.reset();
    
    setState(() {
      isPairing = false;
      pairingCompleted = true;
    });
    
    _updatePairings();
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
    if (activeTouches[id1] != null && activeTouches[id2] != null) {
      activeTouches[id1]!.pairedWith = id2;
      activeTouches[id2]!.pairedWith = id1;
      
      pairs.add(TouchPair(
        touch1Id: id1,
        touch2Id: id2,
        lineColor: lineColors[pairColorIndex % lineColors.length],
      ));
      
      pairColorIndex++;
    }
  }

  void _resetPairingState() {
    _countdownActive = false;
    
    setState(() {
      isPairing = false;
      pairingCompleted = false;
      // countdown = 3;
    });
    _pulseController.stop();
    _pulseController.reset();
  }

  void _clearTouches() {
    _countdownActive = false;
    
    setState(() {
      activeTouches.clear();
      pairs.clear();
      pairColorIndex = 0;
      isPairing = false;
      pairingCompleted = false;
      // countdown = 3;
    });
    _pulseController.stop();
    _pulseController.reset();
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
              Text('• When you have an even number of touches, countdown starts'),
              Text('• Fingers pulse during the 3-second countdown'),
              Text('• After countdown, touches are randomly paired'),
              Text('• Colored lines show the random pairings'),
              Text('• Results stay until you press Clear'),
              Text('• Works with up to 10 simultaneous touches'),
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
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: TouchPainter(
              touches: activeTouches.values.toList(),
              pairs: pairs,
              isPairing: isPairing,
              pairingCompleted: pairingCompleted,
              countdown: countdown,
              pulseAnimation: _pulseAnimation,
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
  final bool isPairing;
  final bool pairingCompleted;
  final int countdown;
  final Animation<double> pulseAnimation;

  TouchPainter({
    required this.touches,
    required this.pairs,
    required this.isPairing,
    required this.pairingCompleted,
    required this.countdown,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw connection lines first (so they appear behind touch points)
    if (pairingCompleted) {
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
            ..strokeWidth = 6.0
            ..style = PaintingStyle.stroke;
          
          // Draw simple straight line
          canvas.drawLine(touch1.position, touch2.position, paint);
        }
      }
    }

    // Draw touch points
    for (var touch in touches) {
      double pulseScale = isPairing ? pulseAnimation.value : 1.0;
      
      // Outer ring (pulsing during countdown)
      final outerPaint = Paint()
        ..color = touch.color.withOpacity(isPairing ? 0.6 : 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touch.position, 40 * pulseScale, outerPaint);
      
      // Inner circle
      final innerPaint = Paint()
        ..color = touch.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touch.position, 20 * pulseScale, innerPaint);
      
      // Center dot
      final centerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touch.position, 5 * pulseScale, centerPaint);
      
      // Touch ID label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${touch.id}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12 * pulseScale,
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
          touch.position.dy + (30 * pulseScale),
        ),
      );
    }

    // Draw countdown during pairing
    if (isPairing) {
      final countdownPainter = TextPainter(
        text: TextSpan(
          text: countdown.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 80,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 10,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      countdownPainter.layout();
      countdownPainter.paint(
        canvas,
        Offset(
          (size.width - countdownPainter.width) / 2,
          (size.height - countdownPainter.height) / 2,
        ),
      );
    }

    // Draw info text
    String statusText;
    if (isPairing) {
      statusText = 'Pairing in $countdown... | Touches: ${touches.length}';
    } else if (pairingCompleted) {
      statusText = 'Paired! | Touches: ${touches.length} | Pairs: ${pairs.length}';
    } else {
      statusText = 'Active touches: ${touches.length} | ${touches.length % 2 == 0 && touches.length >= 2 ? 'Ready to pair!' : 'Need even number of touches'}';
    }
    
    final infoPainter = TextPainter(
      text: TextSpan(
        text: statusText,
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