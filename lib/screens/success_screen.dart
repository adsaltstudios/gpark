import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/constants.dart';
import '../widgets/animated_checkmark.dart';

class SuccessScreen extends StatefulWidget {
  final String ticketNumber;
  final bool isStaleQuarter;
  final bool isDuplicate;
  final String? duplicateMessage;

  const SuccessScreen({
    super.key,
    required this.ticketNumber,
    this.isStaleQuarter = false,
    this.isDuplicate = false,
    this.duplicateMessage,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _contentController;
  late final Animation<double> _contentFade;
  late final AnimationController _particleController;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _dismissTimer = Timer(Constants.successAutoDismiss, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _contentController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onCheckmarkComplete() {
    _contentController.forward();
    if (!widget.isDuplicate) {
      _particleController.forward();
    }
  }

  void _dismiss() {
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final successColor = widget.isDuplicate
        ? AppColors.warning(context)
        : AppColors.success(context);

    return GestureDetector(
      onTap: _dismiss,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Particle burst
              if (!widget.isDuplicate)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _ConfettiPainter(
                          progress: _particleController.value,
                          color: AppColors.success(context),
                          accentColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),

              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated checkmark or warning icon
                      if (widget.isDuplicate)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          onEnd: _onCheckmarkComplete,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 80,
                                color: successColor,
                              ),
                            );
                          },
                        )
                      else
                        AnimatedCheckmark(
                          size: 80,
                          color: successColor,
                          onComplete: _onCheckmarkComplete,
                        ),
                      const SizedBox(height: Spacing.lg),

                      // Ticket number
                      FadeTransition(
                        opacity: _contentFade,
                        child: Text(
                          widget.ticketNumber,
                          style: AppTypography.ticketMedium(context),
                        ),
                      ),
                      const SizedBox(height: Spacing.base),

                      // Main message
                      FadeTransition(
                        opacity: _contentFade,
                        child: Text(
                          widget.isDuplicate
                              ? 'This ticket was already submitted today.'
                              : 'Submitted. You are all set.',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),

                      if (!widget.isDuplicate)
                        FadeTransition(
                          opacity: _contentFade,
                          child: Text(
                            'Approval status will be sent to your email.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Stale quarter warning
                      if (widget.isStaleQuarter) ...[
                        const SizedBox(height: Spacing.lg),
                        FadeTransition(
                          opacity: _contentFade,
                          child: Container(
                            padding: const EdgeInsets.all(Spacing.base),
                            decoration: BoxDecoration(
                              color: AppColors.warning(context)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.warning(context)
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline,
                                    color: AppColors.warning(context),
                                    size: 20),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Text(
                                    'Your submission was saved, but the system may need a quarterly update. If your validation is not processed, contact your building admin.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (widget.isDuplicate &&
                          widget.duplicateMessage != null) ...[
                        const SizedBox(height: Spacing.md),
                        FadeTransition(
                          opacity: _contentFade,
                          child: Text(
                            widget.duplicateMessage!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary(context),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      const SizedBox(height: Spacing.xxl),

                      // Dismiss hint
                      FadeTransition(
                        opacity: _contentFade,
                        child: Text(
                          'Tap anywhere to dismiss',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.textTertiary(context),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight confetti particle burst.
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color accentColor;

  _ConfettiPainter({
    required this.progress,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = Offset(size.width / 2, size.height * 0.38);
    final rng = math.Random(42);
    const particleCount = 24;

    for (var i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi + rng.nextDouble() * 0.5;
      final speed = 80.0 + rng.nextDouble() * 120;
      final particleProgress = (progress * 1.5).clamp(0.0, 1.0);

      final x = center.dx + math.cos(angle) * speed * particleProgress;
      final y = center.dy +
          math.sin(angle) * speed * particleProgress +
          (50 * particleProgress * particleProgress); // gravity

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final particleColor = i.isEven ? color : accentColor;
      final particleSize = 3.0 + rng.nextDouble() * 3;

      final paint = Paint()
        ..color = particleColor.withValues(alpha: opacity * 0.8);

      if (i % 3 == 0) {
        // Small rectangles
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle + progress * 4);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: particleSize * 1.5,
              height: particleSize),
          paint,
        );
        canvas.restore();
      } else {
        // Circles
        canvas.drawCircle(Offset(x, y), particleSize / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
