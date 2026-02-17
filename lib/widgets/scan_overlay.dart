import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Modern corner-bracket scan overlay for the camera screen.
class ScanOverlay extends StatefulWidget {
  final bool isProcessing;

  const ScanOverlay({super.key, this.isProcessing = false});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: _CornerBracketPainter(
            pulseValue: _pulseController.value,
            isProcessing: widget.isProcessing,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  final double pulseValue;
  final bool isProcessing;

  _CornerBracketPainter({
    required this.pulseValue,
    required this.isProcessing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scan area dimensions
    final rectWidth = size.width * 0.82;
    final rectHeight = size.height * 0.34;
    final left = (size.width - rectWidth) / 2;
    final top = (size.height - rectHeight) / 2;
    final scanRect = Rect.fromLTWH(left, top, rectWidth, rectHeight);
    const radius = 16.0;

    // Semi-transparent overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(radius))),
      ),
      overlayPaint,
    );

    // Corner bracket properties
    final bracketLength = math.min(rectWidth, rectHeight) * 0.15;
    final opacity = 0.7 + (pulseValue * 0.3);
    final bracketPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    _drawCorner(canvas, scanRect.left, scanRect.top, bracketLength, radius,
        bracketPaint, topLeft: true);
    // Top-right corner
    _drawCorner(canvas, scanRect.right, scanRect.top, bracketLength, radius,
        bracketPaint, topRight: true);
    // Bottom-left corner
    _drawCorner(canvas, scanRect.left, scanRect.bottom, bracketLength, radius,
        bracketPaint, bottomLeft: true);
    // Bottom-right corner
    _drawCorner(canvas, scanRect.right, scanRect.bottom, bracketLength, radius,
        bracketPaint, bottomRight: true);

    // Scanning line animation during processing
    if (isProcessing) {
      final scanLineY =
          scanRect.top + (scanRect.height * pulseValue);
      final scanLinePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF4D9FFF).withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(scanRect.left, scanLineY - 1, scanRect.width, 2),
        );
      canvas.drawLine(
        Offset(scanRect.left + radius, scanLineY),
        Offset(scanRect.right - radius, scanLineY),
        scanLinePaint..strokeWidth = 2,
      );
    }
  }

  void _drawCorner(
    Canvas canvas,
    double x,
    double y,
    double length,
    double radius,
    Paint paint, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    final path = Path();

    if (topLeft) {
      path.moveTo(x, y + length);
      path.lineTo(x, y + radius);
      path.quadraticBezierTo(x, y, x + radius, y);
      path.lineTo(x + length, y);
    } else if (topRight) {
      path.moveTo(x - length, y);
      path.lineTo(x - radius, y);
      path.quadraticBezierTo(x, y, x, y + radius);
      path.lineTo(x, y + length);
    } else if (bottomLeft) {
      path.moveTo(x, y - length);
      path.lineTo(x, y - radius);
      path.quadraticBezierTo(x, y, x + radius, y);
      path.lineTo(x + length, y);
    } else if (bottomRight) {
      path.moveTo(x - length, y);
      path.lineTo(x - radius, y);
      path.quadraticBezierTo(x, y, x, y - radius);
      path.lineTo(x, y - length);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.isProcessing != isProcessing;
}
