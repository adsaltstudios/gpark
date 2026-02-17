import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ocr_result.dart';
import '../providers/submission_provider.dart';
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

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = Constants.autoSubmitCountdown.inSeconds;
    // Haptic feedback on ticket match lock.
    HapticFeedback.heavyImpact();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      // Offline — go back to home, card will show queued status.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ErrorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _secondsRemaining / Constants.autoSubmitCountdown.inSeconds;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Confidence badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.confidence == OcrConfidence.high
                            ? 'Matched 2x'
                            : 'Matched 1x',
                        style: const TextStyle(
                          color: Color(0xFF34A853),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ticket number
                    Text(
                      widget.ticketNumber,
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User info + location
                    Text(
                      'Atlanta',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Countdown
                    Text(
                      'Submitting in $_secondsRemaining...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF1A73E8),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
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
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed: () {
                            _timer?.cancel();
                            ref.read(submissionProvider.notifier).reset();
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          child: const Text('Cancel'),
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
