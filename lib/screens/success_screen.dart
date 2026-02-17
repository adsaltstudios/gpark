import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();

    _dismissTimer = Timer(Constants.successAutoDismiss, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated checkmark or warning icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      widget.isDuplicate
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      size: 80,
                      color: widget.isDuplicate
                          ? const Color(0xFFF9AB00)
                          : const Color(0xFF34A853),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ticket number
                  Text(
                    widget.ticketNumber,
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main message
                  Text(
                    widget.isDuplicate
                        ? 'This ticket was already submitted today.'
                        : 'Submitted. You are all set.',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF202124),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  if (!widget.isDuplicate)
                    const Text(
                      'Approval status will be sent to your email.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F6368),
                      ),
                      textAlign: TextAlign.center,
                    ),

                  // Stale quarter warning banner
                  if (widget.isStaleQuarter) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9AB00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF9AB00).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: Color(0xFFF9AB00), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your submission was saved, but the system may need a quarterly update. If your validation is not processed, contact your building admin.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF202124),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (widget.isDuplicate && widget.duplicateMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.duplicateMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5F6368),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
