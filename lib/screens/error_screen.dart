import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/submission_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

class ErrorScreen extends ConsumerStatefulWidget {
  const ErrorScreen({super.key});

  @override
  ConsumerState<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends ConsumerState<ErrorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // Trigger shake after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _shakeController.forward();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shake-animated error icon
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final shake = _shakeController.value < 1.0
                        ? _shakeOffset(_shakeController.value)
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 44,
                      color: colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                Text(
                  'Submission failed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Don\'t worry — it\'s saved on your device and we\'ll retry automatically when you\'re back online.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xl),

                // Retry button — prominent
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(submissionProvider.notifier).retryQueue();
                    if (context.mounted) {
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Retry Now'),
                ),
                const SizedBox(height: Spacing.md),

                // Google Form fallback
                OutlinedButton.icon(
                  onPressed: () {
                    launchUrl(
                      Uri.parse(Constants.googleFormUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Use Google Form'),
                ),
                const SizedBox(height: Spacing.md),

                // Back to Home
                TextButton(
                  onPressed: () {
                    ref.read(submissionProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Generates a decaying sinusoidal shake offset.
  double _shakeOffset(double t) {
    return 12 * (1 - t) * _sin(t * 4 * 3.14159);
  }

  double _sin(double x) {
    // Simple sine approximation
    x = x % (2 * 3.14159);
    if (x > 3.14159) x -= 2 * 3.14159;
    return x - (x * x * x / 6) + (x * x * x * x * x / 120);
  }
}
