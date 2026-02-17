enum OcrConfidence { high, medium, low, ambiguous }

class OcrResult {
  /// The best-match ticket number, or null if confidence is low.
  final String? ticketNumber;

  /// All distinct 7-digit candidates found in the OCR text.
  final List<String> candidates;

  /// Confidence level based on match count and uniqueness.
  final OcrConfidence confidence;

  /// Full raw text from OCR (for debugging / manual review display).
  final String rawText;

  const OcrResult({
    required this.ticketNumber,
    required this.candidates,
    required this.confidence,
    required this.rawText,
  });
}
