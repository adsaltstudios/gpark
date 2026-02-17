import 'package:flutter_test/flutter_test.dart';
import 'package:gpark/models/submission.dart';

void main() {
  group('Submission', () {
    test('toJson / fromJson round-trip', () {
      final submission = Submission(
        ticketNumber: '0443044',
        userEmail: 'adame@google.com',
        validationType: 'For myself',
        timestamp: '2026-02-16T08:32:00-05:00',
        submissionSource: 'gPark App',
        ocrConfidence: 'high',
        userName: 'Adam E',
        userLdap: 'adame',
        officeLocation: 'Atlanta',
      );

      final json = submission.toJson();
      final restored = Submission.fromJson(json);

      expect(restored.ticketNumber, '0443044');
      expect(restored.userEmail, 'adame@google.com');
      expect(restored.validationType, 'For myself');
      expect(restored.submissionSource, 'gPark App');
      expect(restored.ocrConfidence, 'high');
      expect(restored.userName, 'Adam E');
      expect(restored.userLdap, 'adame');
      expect(restored.officeLocation, 'Atlanta');
    });

    test('toPayload produces correct keys', () {
      final submission = Submission(
        ticketNumber: '0443044',
        userEmail: 'adame@google.com',
        validationType: 'For myself',
        timestamp: '2026-02-16T08:32:00-05:00',
        submissionSource: 'gPark App',
        ocrConfidence: 'high',
        userName: 'Adam E',
        userLdap: 'adame',
        officeLocation: 'Atlanta',
      );

      final payload = submission.toPayload();
      expect(payload['ticket_number'], '0443044');
      expect(payload['user_email'], 'adame@google.com');
      expect(payload['validation_type'], 'For myself');
      expect(payload['submission_source'], 'gPark App');
      expect(payload['ocr_confidence'], 'high');
      expect(payload['user_name'], 'Adam E');
      expect(payload['user_ldap'], 'adame');
      expect(payload['office_location'], 'Atlanta');
    });

    test('leading zeros preserved in ticket number', () {
      final submission = Submission(
        ticketNumber: '0000001',
        userEmail: 'test@google.com',
        validationType: 'For myself',
        timestamp: '2026-02-16T08:32:00-05:00',
        submissionSource: 'gPark App',
        ocrConfidence: 'manual',
        userName: 'Test',
        userLdap: 'test',
        officeLocation: 'Atlanta',
      );

      final json = submission.toJson();
      final restored = Submission.fromJson(json);
      expect(restored.ticketNumber, '0000001');
      expect(restored.ticketNumber.length, 7);
    });
  });

  group('QueueEntry', () {
    test('toJson / fromJson round-trip', () {
      final entry = QueueEntry(
        payload: Submission(
          ticketNumber: '0443044',
          userEmail: 'adame@google.com',
          validationType: 'For myself',
          timestamp: '2026-02-16T08:32:00-05:00',
          submissionSource: 'gPark App',
          ocrConfidence: 'high',
          userName: 'Adam E',
          userLdap: 'adame',
          officeLocation: 'Atlanta',
        ),
      );

      final json = entry.toJson();
      final restored = QueueEntry.fromJson(json);

      expect(restored.id, entry.id);
      expect(restored.status, QueueStatus.queued);
      expect(restored.retryCount, 0);
      expect(restored.payload.ticketNumber, '0443044');
      expect(restored.lastRetryAt, isNull);
    });

    test('status and retry count persist', () {
      final entry = QueueEntry(
        payload: Submission(
          ticketNumber: '0443044',
          userEmail: 'adame@google.com',
          validationType: 'For myself',
          timestamp: '2026-02-16T08:32:00-05:00',
          submissionSource: 'gPark App',
          ocrConfidence: 'high',
          userName: 'Adam E',
          userLdap: 'adame',
          officeLocation: 'Atlanta',
        ),
      );

      entry.status = QueueStatus.failed;
      entry.retryCount = 3;
      entry.lastRetryAt = DateTime(2026, 2, 16, 9, 0);

      final json = entry.toJson();
      final restored = QueueEntry.fromJson(json);

      expect(restored.status, QueueStatus.failed);
      expect(restored.retryCount, 3);
      expect(restored.lastRetryAt, isNotNull);
    });
  });

  group('SubmissionResponse', () {
    test('parses success response', () {
      final response = SubmissionResponse.fromJson({
        'status': 'success',
        'row': 142,
      });
      expect(response.isSuccess, true);
      expect(response.isDuplicate, false);
      expect(response.isStaleQuarter, false);
      expect(response.row, 142);
    });

    test('parses success with stale quarter warning', () {
      final response = SubmissionResponse.fromJson({
        'status': 'success',
        'row': 142,
        'warning': 'stale_quarter',
        'message': 'Submitted, but system may need quarterly update.',
      });
      expect(response.isSuccess, true);
      expect(response.isStaleQuarter, true);
    });

    test('parses duplicate response', () {
      final response = SubmissionResponse.fromJson({
        'status': 'duplicate',
        'message': 'Ticket 0443044 already submitted on 2/16/2026',
      });
      expect(response.isDuplicate, true);
      expect(response.isSuccess, false);
    });

    test('parses error response', () {
      final response = SubmissionResponse.fromJson({
        'status': 'error',
        'message': 'Sheet write failed',
      });
      expect(response.isError, true);
    });
  });
}
