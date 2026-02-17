import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ocr_result.dart';
import '../utils/ticket_parser.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Process an image and extract ticket number.
  /// Runs entirely on-device (Rule 2).
  Future<OcrResult> processImage(InputImage inputImage) async {
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final rawText = recognizedText.text;
    final parseResult = TicketParser.parse(rawText);

    return OcrResult(
      ticketNumber: parseResult.bestMatch,
      candidates: parseResult.numbers,
      confidence: parseResult.confidence,
      rawText: rawText,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
