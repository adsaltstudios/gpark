import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/submission_provider.dart';
import '../utils/constants.dart';

class ErrorScreen extends ConsumerWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Color(0xFFD93025),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Submission failed.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saved to your device. We will retry automatically.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await ref.read(submissionProvider.notifier).retryQueue();
                      if (context.mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                    child: const Text('Retry Now'),
                  ),
                ),
                const SizedBox(height: 12),

                // Google Form fallback
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      launchUrl(
                        Uri.parse(Constants.googleFormUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: const Text('Use Google Form'),
                  ),
                ),
                const SizedBox(height: 12),

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
}
