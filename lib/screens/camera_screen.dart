import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ocr_result.dart';
import '../services/ocr_service.dart';
import '../theme/app_colors.dart';
import '../widgets/scan_overlay.dart';
import 'confirmation_screen.dart';
import 'manual_review_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.auto;
  late final AnimationController _captureAnimController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _captureAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _ocrService.dispose();
    _captureAnimController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera available.')),
        );
      }
      return;
    }

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    // Capture animation
    _captureAnimController.forward().then((_) {
      _captureAnimController.reverse();
    });

    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final ocrResult = await _ocrService.processImage(inputImage);

      if (!mounted) return;

      switch (ocrResult.confidence) {
        case OcrConfidence.high:
        case OcrConfidence.medium:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ConfirmationScreen(
                ticketNumber: ocrResult.ticketNumber!,
                confidence: ocrResult.confidence,
                imagePath: image.path,
              ),
            ),
          );
        case OcrConfidence.low:
        case OcrConfidence.ambiguous:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ManualReviewScreen(
                imagePath: image.path,
                ocrResult: ocrResult,
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    }
  }

  void _toggleFlash() {
    if (_controller == null) return;
    setState(() {
      _flashMode = switch (_flashMode) {
        FlashMode.auto => FlashMode.always,
        FlashMode.always => FlashMode.off,
        _ => FlashMode.auto,
      };
    });
    _controller!.setFlashMode(_flashMode);
  }

  @override
  Widget build(BuildContext context) {
    final isReady =
        _controller != null && _controller!.value.isInitialized;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (isReady)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Corner bracket overlay
          Positioned.fill(
            child: ScanOverlay(isProcessing: _isProcessing),
          ),

          // Instruction text
          Positioned(
            top: topPad + 80,
            left: 0,
            right: 0,
            child: Text(
              _isProcessing
                  ? 'Reading ticket...'
                  : 'Align your parking ticket in the frame',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
              ),
            ),
          ),

          // Close button (top-left) — frosted glass pill
          Positioned(
            top: topPad + Spacing.sm,
            left: Spacing.sm,
            child: _FrostedButton(
              onTap: () => Navigator.of(context).pop(),
              icon: Icons.close,
              tooltip: 'Close camera',
            ),
          ),

          // Flash toggle (top-right) — frosted glass pill
          Positioned(
            top: topPad + Spacing.sm,
            right: Spacing.sm,
            child: _FrostedButton(
              onTap: _toggleFlash,
              icon: switch (_flashMode) {
                FlashMode.auto => Icons.flash_auto,
                FlashMode.always => Icons.flash_on,
                FlashMode.off => Icons.flash_off,
                _ => Icons.flash_auto,
              },
              tooltip: 'Toggle flash',
            ),
          ),

          // Capture button (center-bottom)
          Positioned(
            bottom: bottomPad + Spacing.xl,
            left: 0,
            right: 0,
            child: Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.9)
                    .animate(_captureAnimController),
                child: GestureDetector(
                  onTap: _isProcessing ? null : _captureAndProcess,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isProcessing
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white,
                      ),
                      child: _isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted glass icon button for camera controls.
class _FrostedButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String tooltip;

  const _FrostedButton({
    required this.onTap,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
