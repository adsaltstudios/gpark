import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ocr_result.dart';
import '../providers/submission_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Review'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Captured image
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Helper text
                  Text(
                    isAmbiguous
                        ? 'Multiple ticket numbers found. Select the correct one or type it below.'
                        : 'We could not read the ticket clearly. Please type or correct the ticket number below.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ambiguous candidates as chips
                  if (isAmbiguous && candidates.length > 1) ...[
                    Wrap(
                      spacing: 8,
                      children: candidates.map((num) {
                        return ChoiceChip(
                          label: Text(
                            num,
                            style: const TextStyle(fontFamily: 'RobotoMono'),
                          ),
                          selected: _controller.text == num,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _controller.text = num);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Ticket number input
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    maxLength: 7,
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Ticket Number',
                      helperText: _controller.text.isEmpty
                          ? 'Enter 7-digit ticket number'
                          : _isValid
                              ? 'Valid ticket number'
                              : '${7 - _controller.text.length} more digit${7 - _controller.text.length != 1 ? 's' : ''} needed',
                      helperStyle: TextStyle(
                        color: _isValid
                            ? const Color(0xFF34A853)
                            : const Color(0xFF5F6368),
                      ),
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  FilledButton(
                    onPressed: _isValid && !_isSubmitting ? _submit : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const CameraScreen()),
                            );
                          },
                    icon: const Icon(Icons.camera_alt),
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
