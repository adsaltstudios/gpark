import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ocr_result.dart';
import '../providers/submission_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/constants.dart';
import 'manual_review_screen.dart';
import 'success_screen.dart';
import 'error_screen.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  final String ticketNumber;
  final OcrConfidence confidence;
  final String imagePath;

  const ConfirmationScreen({
    super.key,
    required this.ticketNumber,
    required this.confidence,
    required this.imagePath,
  });

  @override
  ConsumerState<ConfirmationScreen> createState() =>
      _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late int _secondsRemaining;
  Timer? _timer;
  late final AnimationController _entryController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = Constants.autoSubmitCountdown.inSeconds;
    HapticFeedback.heavyImpact();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entryController.forward();

    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _submit();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _submit() async {
    _timer?.cancel();
    final confidenceStr =
        widget.confidence == OcrConfidence.high ? 'high' : 'medium';

    await ref
        .read(submissionProvider.notifier)
        .submit(widget.ticketNumber, confidenceStr);

    if (!mounted) return;

    final state = ref.read(submissionProvider);
    if (state is SubmissionSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            ticketNumber: widget.ticketNumber,
            isStaleQuarter: state.response.isStaleQuarter,
          ),
        ),
      );
    } else if (state is SubmissionDuplicate) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            ticketNumber: widget.ticketNumber,
            isDuplicate: true,
            duplicateMessage: state.response.message,
          ),
        ),
      );
    } else if (state is SubmissionQueued) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ErrorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = Constants.autoSubmitCountdown.inSeconds;
    final progress = _secondsRemaining / totalSeconds;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0)
                    .animate(_scaleAnimation),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Confidence badge with glow
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md, vertical: Spacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.success(context)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success(context)
                                .withValues(alpha: 0.15),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified,
                              color: AppColors.success(context), size: 16),
                          const SizedBox(width: Spacing.xs),
                          Text(
                            widget.confidence == OcrConfidence.high
                                ? 'Matched 2x'
                                : 'Matched 1x',
                            style: TextStyle(
                              color: AppColors.success(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),

                    // Countdown ring around ticket number
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ring
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CustomPaint(
                              painter: _CountdownRingPainter(
                                progress: progress,
                                color: colorScheme.primary,
                                trackColor: AppColors.divider(context),
                              ),
                            ),
                          ),
                          // Ticket number
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.ticketNumber,
                                style: AppTypography.ticketLarge(context)
                                    .copyWith(fontSize: 32),
                              ),
                              const SizedBox(height: Spacing.xs),
                              Text(
                                'Atlanta',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textTertiary(context),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Countdown text
                    Text(
                      'Submitting in $_secondsRemaining...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                    ),
                    const SizedBox(height: Spacing.xl),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            _timer?.cancel();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => ManualReviewScreen(
                                  imagePath: widget.imagePath,
                                  initialTicketNumber: widget.ticketNumber,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 48),
                          ),
                        ),
                        const SizedBox(width: Spacing.base),
                        TextButton.icon(
                          onPressed: () {
                            _timer?.cancel();
                            ref.read(submissionProvider.notifier).reset();
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Cancel'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(120, 48),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a circular countdown ring.
class _CountdownRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
