import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ocr_result.dart';
import '../services/ocr_service.dart';
import 'confirmation_screen.dart';
import 'manual_review_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _ocrService.dispose();
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ManualReviewScreen(
                imagePath: image.path,
                ocrResult: ocrResult,
              ),
            ),
          );
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

          // Overlay guide
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanOverlayPainter(),
            ),
          ),

          // "Align your parking ticket" text
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: const Text(
              'Align your parking ticket in the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Reading ticket...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Close button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              tooltip: 'Close camera',
            ),
          ),

          // Flash toggle (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              onPressed: _toggleFlash,
              icon: Icon(
                switch (_flashMode) {
                  FlashMode.auto => Icons.flash_auto,
                  FlashMode.always => Icons.flash_on,
                  FlashMode.off => Icons.flash_off,
                  _ => Icons.flash_auto,
                },
                color: Colors.white,
                size: 28,
              ),
              tooltip: 'Toggle flash',
            ),
          ),

          // Capture button (center-bottom)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isProcessing ? null : _captureAndProcess,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: const Center(
                    child: Icon(Icons.camera, color: Colors.white, size: 32),
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

/// Draws a semi-transparent overlay with a clear rectangle in the center.
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    final rectWidth = size.width * 0.85;
    final rectHeight = size.height * 0.35;
    final left = (size.width - rectWidth) / 2;
    final top = (size.height - rectHeight) / 2;

    final scanRect = Rect.fromLTWH(left, top, rectWidth, rectHeight);

    // Draw overlay around the scan area
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
              RRect.fromRectAndRadius(scanRect, const Radius.circular(12))),
      ),
      paint,
    );

    // Draw border around scan area
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
