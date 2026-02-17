import 'package:flutter_test/flutter_test.dart';
import 'package:gpark/models/ocr_result.dart';
import 'package:gpark/utils/ticket_parser.dart';

void main() {
  group('TicketParser', () {
    test('two identical matches → high confidence', () {
      final result = TicketParser.parse(
        'Welcome To 1105 West Peachtree\n0443044\n12/16/25 07:39AM\nPlease take ticket\n0443044',
      );
      expect(result.confidence, OcrConfidence.high);
      expect(result.bestMatch, '0443044');
      expect(result.numbers, ['0443044']);
    });

    test('one match → medium confidence', () {
      final result = TicketParser.parse(
        'Welcome To 1105 West Peachtree\n0443044\n12/16/25 07:39AM',
      );
      expect(result.confidence, OcrConfidence.medium);
      expect(result.bestMatch, '0443044');
      expect(result.numbers, ['0443044']);
    });

    test('no 7-digit numbers → low confidence', () {
      final result = TicketParser.parse(
        'Welcome To 1105 West Peachtree\n12/16/25 07:39AM\nPlease take ticket',
      );
      expect(result.confidence, OcrConfidence.low);
      expect(result.bestMatch, isNull);
      expect(result.numbers, isEmpty);
    });

    test('two different 7-digit numbers → ambiguous', () {
      final result = TicketParser.parse(
        '0443044\n0167006\nSome other text',
      );
      expect(result.confidence, OcrConfidence.ambiguous);
      expect(result.bestMatch, isNull);
      expect(result.numbers, containsAll(['0443044', '0167006']));
    });

    test('6-digit date does not match', () {
      final result = TicketParser.parse('121625 0739');
      expect(result.confidence, OcrConfidence.low);
      expect(result.numbers, isEmpty);
    });

    test('4-digit time does not match', () {
      final result = TicketParser.parse('Time: 0739');
      expect(result.confidence, OcrConfidence.low);
      expect(result.numbers, isEmpty);
    });

    test('leading zeros preserved as string', () {
      final result = TicketParser.parse('0000001 some text 0000001');
      expect(result.confidence, OcrConfidence.high);
      expect(result.bestMatch, '0000001');
    });

    test('8-digit number does not match (word boundary)', () {
      final result = TicketParser.parse('04430441');
      expect(result.confidence, OcrConfidence.low);
      expect(result.numbers, isEmpty);
    });

    test('empty string → low confidence', () {
      final result = TicketParser.parse('');
      expect(result.confidence, OcrConfidence.low);
      expect(result.numbers, isEmpty);
    });

    test('one repeated + one unique → high confidence on repeated', () {
      final result = TicketParser.parse('0443044 0167006 0443044');
      expect(result.confidence, OcrConfidence.high);
      expect(result.bestMatch, '0443044');
      expect(result.numbers, containsAll(['0443044', '0167006']));
    });

    test('real ticket format parses correctly', () {
      const ticketText = '''
Welcome To
1105 West Peachtree
0443044
12/16/25 07:39AM

Please take ticket with you
STICKER HERE

Thank you Have a Wonderful Day!

0443044
12/16/25 07:39AM
''';
      final result = TicketParser.parse(ticketText);
      expect(result.confidence, OcrConfidence.high);
      expect(result.bestMatch, '0443044');
    });

    test('ticket number surrounded by text still matches', () {
      final result = TicketParser.parse('Ticket:0443044 end');
      // Word boundary: digit after colon — depends on regex behavior.
      // \b matches between non-word and word chars. ':' is non-word, '0' is word.
      expect(result.confidence, OcrConfidence.medium);
      expect(result.bestMatch, '0443044');
    });

    test('multiple same + multiple different → high on repeated', () {
      final result = TicketParser.parse('1234567 1234567 7654321 7654321');
      // Two numbers each repeated twice — ambiguous.
      expect(result.confidence, OcrConfidence.ambiguous);
      expect(result.numbers.length, 2);
    });
  });
}
