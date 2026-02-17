import '../models/ocr_result.dart';

/// Rule 5: Ticket parsing is isolated.
/// Takes raw OCR text, returns structured parse result with confidence.
class TicketParseResult {
  final List<String> numbers;
  final OcrConfidence confidence;
  final String? bestMatch;

  const TicketParseResult({
    required this.numbers,
    required this.confidence,
    this.bestMatch,
  });
}

class TicketParser {
  TicketParser._();

  static final _pattern = RegExp(r'\b\d{7}\b');

  /// Parse raw OCR text and extract 7-digit ticket numbers.
  ///
  /// Confidence logic (per PRD):
  /// - 2+ identical matches → HIGH (ticket number printed twice on stub)
  /// - 1 unique match → MEDIUM
  /// - 0 matches → LOW
  /// - 2+ different 7-digit numbers → AMBIGUOUS
  static TicketParseResult parse(String ocrText) {
    final allMatches =
        _pattern.allMatches(ocrText).map((m) => m.group(0)!).toList();

    if (allMatches.isEmpty) {
      return const TicketParseResult(
        numbers: [],
        confidence: OcrConfidence.low,
      );
    }

    // Count occurrences of each unique number.
    final counts = <String, int>{};
    for (final match in allMatches) {
      counts[match] = (counts[match] ?? 0) + 1;
    }

    final unique = counts.keys.toList();

    if (unique.length == 1) {
      // Single unique number found.
      final number = unique.first;
      final confidence =
          counts[number]! >= 2 ? OcrConfidence.high : OcrConfidence.medium;
      return TicketParseResult(
        numbers: unique,
        confidence: confidence,
        bestMatch: number,
      );
    }

    // Multiple different 7-digit numbers found.
    // Check if any appears 2+ times (that's likely the ticket number).
    final repeatedEntries =
        counts.entries.where((e) => e.value >= 2).toList();
    if (repeatedEntries.length == 1) {
      // One number repeated, others appeared once — high confidence on the repeated one.
      return TicketParseResult(
        numbers: unique,
        confidence: OcrConfidence.high,
        bestMatch: repeatedEntries.first.key,
      );
    }

    // Truly ambiguous: multiple different numbers, none clearly dominant.
    return TicketParseResult(
      numbers: unique,
      confidence: OcrConfidence.ambiguous,
    );
  }
}
