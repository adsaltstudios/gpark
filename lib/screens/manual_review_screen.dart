import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ocr_result.dart';
import '../providers/submission_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'camera_screen.dart';
import 'success_screen.dart';
import 'error_screen.dart';

class ManualReviewScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final OcrResult? ocrResult;
  final String? initialTicketNumber;

  const ManualReviewScreen({
    super.key,
    required this.imagePath,
    this.ocrResult,
    this.initialTicketNumber,
  });

  @override
  ConsumerState<ManualReviewScreen> createState() =>
      _ManualReviewScreenState();
}

class _ManualReviewScreenState extends ConsumerState<ManualReviewScreen> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTicketNumber ??
        widget.ocrResult?.ticketNumber ??
        '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => RegExp(r'^\d{7}$').hasMatch(_controller.text);

  Future<void> _submit() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    await ref
        .read(submissionProvider.notifier)
        .submit(_controller.text, 'manual');

    if (!mounted) return;

    final state = ref.read(submissionProvider);
    if (state is SubmissionSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            ticketNumber: _controller.text,
            isStaleQuarter: state.response.isStaleQuarter,
          ),
        ),
      );
    } else if (state is SubmissionDuplicate) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            ticketNumber: _controller.text,
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
    final candidates = widget.ocrResult?.candidates ?? [];
    final isAmbiguous =
        widget.ocrResult?.confidence == OcrConfidence.ambiguous;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Review'),
        leading: IconButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Captured image with frame
            Container(
              margin: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.divider(context),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.base),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Helper text
                  Text(
                    isAmbiguous
                        ? 'Multiple ticket numbers found. Select the correct one or type it below.'
                        : 'We could not read the ticket clearly. Please type or correct the ticket number below.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                  ),
                  const SizedBox(height: Spacing.base),

                  // Ambiguous candidates as chips
                  if (isAmbiguous && candidates.length > 1) ...[
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: candidates.map((candidate) {
                        final isSelected = _controller.text == candidate;
                        return ChoiceChip(
                          label: Text(
                            candidate,
                            style: AppTypography.ticketInput(context)
                                .copyWith(fontSize: 14),
                          ),
                          selected: isSelected,
                          selectedColor:
                              colorScheme.primary.withValues(alpha: 0.15),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _controller.text = candidate);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: Spacing.base),
                  ],

                  // Ticket number input
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    maxLength: 7,
                    style: AppTypography.ticketInput(context),
                    decoration: InputDecoration(
                      labelText: 'Ticket Number',
                      helperText: _controller.text.isEmpty
                          ? 'Enter 7-digit ticket number'
                          : _isValid
                              ? 'Valid ticket number'
                              : '${7 - _controller.text.length} more digit${7 - _controller.text.length != 1 ? 's' : ''} needed',
                      helperStyle: TextStyle(
                        color: _isValid
                            ? AppColors.success(context)
                            : AppColors.textSecondary(context),
                      ),
                      counterText: '',
                      suffixIcon: _isValid
                          ? Icon(Icons.check_circle,
                              color: AppColors.success(context), size: 22)
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Actions
                  FilledButton(
                    onPressed: _isValid && !_isSubmitting ? _submit : null,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                  const SizedBox(height: Spacing.md),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const CameraScreen()),
                            );
                          },
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: const Text('Rescan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
