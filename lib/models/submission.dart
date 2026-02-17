import 'package:uuid/uuid.dart';

class Submission {
  final String ticketNumber;
  final String userEmail;
  final String validationType;
  final String timestamp;
  final String submissionSource;
  final String ocrConfidence;
  final String userName;
  final String userLdap;
  final String officeLocation;

  const Submission({
    required this.ticketNumber,
    required this.userEmail,
    required this.validationType,
    required this.timestamp,
    required this.submissionSource,
    required this.ocrConfidence,
    required this.userName,
    required this.userLdap,
    required this.officeLocation,
  });

  Map<String, dynamic> toPayload() => {
        'ticket_number': ticketNumber,
        'user_email': userEmail,
        'validation_type': validationType,
        'timestamp': timestamp,
        'submission_source': submissionSource,
        'ocr_confidence': ocrConfidence,
        'user_name': userName,
        'user_ldap': userLdap,
        'office_location': officeLocation,
      };

  factory Submission.fromJson(Map<String, dynamic> json) {
    final ticketNumber = json['ticket_number'] as String;
    assert(ticketNumber.length == 7, 'Ticket number must be exactly 7 digits');
    return Submission(
      ticketNumber: ticketNumber,
      userEmail: json['user_email'] as String,
      validationType: json['validation_type'] as String,
      timestamp: json['timestamp'] as String,
      submissionSource: json['submission_source'] as String,
      ocrConfidence: json['ocr_confidence'] as String,
      userName: json['user_name'] as String,
      userLdap: json['user_ldap'] as String,
      officeLocation: json['office_location'] as String,
    );
  }

  Map<String, dynamic> toJson() => toPayload();
}

enum QueueStatus { queued, submitted, failed }

class QueueEntry {
  final String id;
  final Submission payload;
  QueueStatus status;
  int retryCount;
  final DateTime createdAt;
  DateTime? lastRetryAt;

  QueueEntry({
    String? id,
    required this.payload,
    this.status = QueueStatus.queued,
    this.retryCount = 0,
    DateTime? createdAt,
    this.lastRetryAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      id: json['id'] as String,
      payload: Submission.fromJson(json['payload'] as Map<String, dynamic>),
      status: QueueStatus.values.byName(json['status'] as String),
      retryCount: json['retry_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastRetryAt: json['last_retry_at'] != null
          ? DateTime.parse(json['last_retry_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'payload': payload.toJson(),
        'status': status.name,
        'retry_count': retryCount,
        'created_at': createdAt.toIso8601String(),
        'last_retry_at': lastRetryAt?.toIso8601String(),
      };
}

class SubmissionResponse {
  final String status;
  final int? row;
  final String? warning;
  final String? message;

  const SubmissionResponse({
    required this.status,
    this.row,
    this.warning,
    this.message,
  });

  bool get isSuccess => status == 'success';
  bool get isDuplicate => status == 'duplicate';
  bool get isError => status == 'error';
  bool get isStaleQuarter => warning == 'stale_quarter';

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) {
    return SubmissionResponse(
      status: json['status'] as String,
      row: json['row'] as int?,
      warning: json['warning'] as String?,
      message: json['message'] as String?,
    );
  }
}
