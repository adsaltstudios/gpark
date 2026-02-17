import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A checkmark that draws itself with a path animation.
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedCheckmark({
    super.key,
    this.size = 80,
    this.color = const Color(0xFF3DDC84),
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleAnimation;
  late final Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Circle draws first (0.0 → 0.5)
    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Checkmark draws second (0.4 → 1.0)
    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _CheckmarkPainter(
            circleProgress: _circleAnimation.value,
            checkProgress: _checkAnimation.value,
            color: widget.color,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Background glow
    if (circleProgress > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.12 * circleProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(center, radius * 1.3, glowPaint);
    }

    // Circle outline
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * circleProgress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      circlePaint,
    );

    // Fill circle with low opacity
    if (circleProgress >= 1) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.08);
      canvas.drawCircle(center, radius, fillPaint);
    }

    // Checkmark path
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Checkmark points relative to center
      final p1 = Offset(center.dx - radius * 0.32, center.dy + radius * 0.02);
      final p2 = Offset(center.dx - radius * 0.05, center.dy + radius * 0.28);
      final p3 = Offset(center.dx + radius * 0.35, center.dy - radius * 0.22);

      final checkPath = Path();
      if (checkProgress <= 0.5) {
        // First segment: p1 to p2
        final t = checkProgress * 2;
        final currentX = p1.dx + (p2.dx - p1.dx) * t;
        final currentY = p1.dy + (p2.dy - p1.dy) * t;
        checkPath.moveTo(p1.dx, p1.dy);
        checkPath.lineTo(currentX, currentY);
      } else {
        // Full first segment + partial second
        final t = (checkProgress - 0.5) * 2;
        final currentX = p2.dx + (p3.dx - p2.dx) * t;
        final currentY = p2.dy + (p3.dy - p2.dy) * t;
        checkPath.moveTo(p1.dx, p1.dy);
        checkPath.lineTo(p2.dx, p2.dy);
        checkPath.lineTo(currentX, currentY);
      }

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) =>
      oldDelegate.circleProgress != circleProgress ||
      oldDelegate.checkProgress != checkProgress;
}
