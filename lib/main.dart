import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

// Entry point of the application
void main() {
  runApp(const MyApp());
}

// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Character Input',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100], // Light background
      ),
      home: const CharacterInputScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Main screen widget holding the state
class CharacterInputScreen extends StatefulWidget {
  const CharacterInputScreen({super.key});

  @override
  State<CharacterInputScreen> createState() => _CharacterInputScreenState();
}

class _CharacterInputScreenState extends State<CharacterInputScreen> {
  // Use perfect_freehand's PointVector for stroke data
  List<PointVector> _currentLine = [];
  List<List<PointVector>> _currentDrawingPoints = [];
  final List<List<List<PointVector>>> _completedCharactersPoints = [];

  // Size of the drawing area (will be determined by LayoutBuilder)
  Size? _drawingAreaSize;

  // --- Gesture Handlers ---

  // Called when the user starts drawing
  void _handlePanStart(DragStartDetails details) {
    _currentLine = [];
    final point = _getPointVectorFromOffset(details.localPosition);
    if (point != null) {
      setState(() {
        _currentLine.add(point); // Add PointVector
      });
    }
  }

  // Called when the user drags their finger
  void _handlePanUpdate(DragUpdateDetails details) {
    final point = _getPointVectorFromOffset(details.localPosition);
    if (point != null) {
      setState(() {
        _currentLine.add(point); // Add PointVector
      });
    }
  }

  // Called when the user lifts their finger
  void _handlePanEnd(DragEndDetails details) {
    if (_currentLine.isNotEmpty) {
      setState(() {
        // Add a copy of the List<PointVector>
        _currentDrawingPoints.add(List<PointVector>.from(_currentLine));
        _currentLine = [];
      });
    }
  }

  // Helper to convert Flutter's Offset to perfect_freehand's PointVector
  PointVector? _getPointVectorFromOffset(Offset offset) {
    if (_drawingAreaSize == null) return null;
    final double dx = offset.dx.clamp(0.0, _drawingAreaSize!.width);
    final double dy = offset.dy.clamp(0.0, _drawingAreaSize!.height);
    // Use perfect_freehand's PointVector constructor (x, y, pressure)
    return PointVector(dx, dy, 0.5); // Using fixed pressure 0.5
  }

  // --- Button Action ---

  void _nextCharacter() {
    if (_currentDrawingPoints.isNotEmpty) {
      setState(() {
        // Add a copy of List<List<PointVector>>
        _completedCharactersPoints.add(
          List<List<PointVector>>.from(
            _currentDrawingPoints.map((line) => List<PointVector>.from(line)),
          ),
        );
        _currentDrawingPoints = [];
        _currentLine = [];
      });
    } else {
      // Optional: Show a message if the drawing area is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw a character first.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chinese Character Input'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // 1. Result Display Area
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(
                    (255 * 0.1).round(),
                  ), // 0.1 opacity
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minHeight: 50,
            ), // Ensure some height
            alignment: Alignment.topLeft, // Align items to the top-left
            child: Wrap(
              spacing: 6.0, // Horizontal spacing between characters
              runSpacing: 6.0, // Vertical spacing between lines
              children: _buildCompletedCharacterWidgets(),
            ),
          ),

          const Divider(height: 20, thickness: 1, indent: 20, endIndent: 20),

          // 2. Square Writing Area
          Expanded(
            child: Center(
              // Center the square aspect ratio box
              child: AspectRatio(
                aspectRatio: 1.0, // Make it square
                child: LayoutBuilder(
                  // Use LayoutBuilder to get the size
                  builder: (context, constraints) {
                    // Store the size once available
                    // Use post frame callback to avoid setting state during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_drawingAreaSize == null ||
                          _drawingAreaSize != constraints.biggest) {
                        if (mounted) {
                          // Check if the widget is still mounted
                          setState(() {
                            _drawingAreaSize = constraints.biggest;
                          });
                        }
                      }
                    });

                    // Get the processed stroke outlines for the current drawing
                    final List<List<Offset>> currentStrokeOutlines =
                        _getStrokeOutlines(_currentDrawingPoints, _currentLine);

                    return Container(
                      margin: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blueGrey, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(
                              (255 * 0.2).round(),
                            ), // 0.2 opacity
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onPanStart: _handlePanStart,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        // Use CustomPaint to draw the strokes
                        child: CustomPaint(
                          painter: DrawingPainter(
                            strokeOutlines: currentStrokeOutlines,
                          ),
                          size: Size.infinite, // Take available space
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. "Next Character" Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _nextCharacter,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Next Character'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the small character display widgets
  List<Widget> _buildCompletedCharacterWidgets() {
    if (_drawingAreaSize == null) {
      return [const Text("Loading drawing area...")]; // Placeholder
    }

    const double displaySize = 18.0; // Target height (and width)

    return _completedCharactersPoints.map((characterPoints) {
      // Get the stroke outlines for this completed character
      final List<List<Offset>> strokeOutlines = _getStrokeOutlines(
        characterPoints,
        [],
      ); // No active line for completed chars

      return SizedBox(
        width: displaySize,
        height: displaySize,
        child: CustomPaint(
          painter: CharacterPainter(
            strokeOutlines: strokeOutlines,
            originalSize: _drawingAreaSize!, // Pass the original size
            displaySize: const Size(
              displaySize,
              displaySize,
            ), // Pass target size
          ),
        ),
      );
    }).toList();
  }

  // Helper function to convert point lists to perfect_freehand stroke outlines
  // Input types are now List<List<PointVector>> and List<PointVector>
  List<List<Offset>> _getStrokeOutlines(
    List<List<PointVector>> lines,
    List<PointVector> currentLine,
  ) {
    final List<List<Offset>> strokeOutlines = [];

    final options = StrokeOptions(
      size: 6,
      thinning: 0.6,
      smoothing: 0.5,
      streamline: 0.5,
      simulatePressure: true,
    );

    for (final line in lines) {
      if (line.isNotEmpty) {
        final strokeOutline = getStroke(
          line, // Pass List<PointVector>
          options: options,
        );
        strokeOutlines.add(strokeOutline); // Add List<Offset>
      }
    }

    if (currentLine.isNotEmpty) {
      final strokeOutline = getStroke(
        currentLine, // Pass List<PointVector>
        options: options,
      );
      strokeOutlines.add(strokeOutline); // Add List<Offset>
    }

    return strokeOutlines;
  }
}

// CustomPainter for the main drawing area
class DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokeOutlines;

  DrawingPainter({required this.strokeOutlines});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color =
              Colors
                  .black // Drawing color
          ..style = PaintingStyle.fill; // Fill the stroke outlines

    // Draw each stroke outline
    for (final strokeOutline in strokeOutlines) {
      if (strokeOutline.isNotEmpty) {
        final path = _getSvgPathFromStroke(strokeOutline);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    // Repaint if the stroke outlines list changes
    return oldDelegate.strokeOutlines != strokeOutlines;
  }
}

// CustomPainter for the small character display area
class CharacterPainter extends CustomPainter {
  final List<List<Offset>> strokeOutlines;
  final Size originalSize; // The size of the canvas where it was drawn
  final Size displaySize; // The target size for display (e.g., 18x18)

  CharacterPainter({
    required this.strokeOutlines,
    required this.originalSize,
    required this.displaySize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color =
              Colors
                  .black // Character color in display
          ..style = PaintingStyle.fill;

    // Calculate scale factors
    // Use the minimum scale factor to fit the drawing within the display box
    // while maintaining aspect ratio.
    final double scaleX = displaySize.width / originalSize.width;
    final double scaleY = displaySize.height / originalSize.height;
    final double scale =
        scaleX < scaleY ? scaleX : scaleY; // Use min scale factor

    // Calculate translation to center the scaled drawing
    final double scaledWidth = originalSize.width * scale;
    final double scaledHeight = originalSize.height * scale;
    final double translateX = (displaySize.width - scaledWidth) / 2.0;
    final double translateY = (displaySize.height - scaledHeight) / 2.0;

    // Apply scaling and translation
    canvas.save(); // Save canvas state
    canvas.translate(translateX, translateY);
    canvas.scale(scale, scale);

    // Draw each stroke outline (scaled)
    for (final strokeOutline in strokeOutlines) {
      if (strokeOutline.isNotEmpty) {
        final path = _getSvgPathFromStroke(strokeOutline);
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore(); // Restore canvas state
  }

  @override
  bool shouldRepaint(covariant CharacterPainter oldDelegate) {
    // Repaint if stroke outlines or sizes change
    return oldDelegate.strokeOutlines != strokeOutlines ||
        oldDelegate.originalSize != originalSize ||
        oldDelegate.displaySize != displaySize;
  }
}

// Helper function to convert perfect_freehand stroke points (Offsets) to a Flutter Path
Path _getSvgPathFromStroke(List<Offset> points) {
  if (points.isEmpty) {
    return Path();
  }

  final path = Path();
  path.moveTo(points.first.dx, points.first.dy);

  for (int i = 0; i < points.length - 1; i++) {
    final p0 = points[i];
    final p1 = points[i + 1];
    // Using quadratic Bezier for smoother curves between points
    final controlPointX = (p0.dx + p1.dx) / 2;
    final controlPointY = (p0.dy + p1.dy) / 2;
    path.quadraticBezierTo(p0.dx, p0.dy, controlPointX, controlPointY);
  }

  return path;
}

// REMINDER: Add perfect_freehand to your pubspec.yaml
/*
dependencies:
  flutter:
    sdk: flutter
  perfect_freehand: ^2.1.0 # Or latest version
*/
