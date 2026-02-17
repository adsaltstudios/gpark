import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/submission.dart';
import '../utils/constants.dart';

class SubmissionService {
  final http.Client _client;

  SubmissionService({http.Client? client}) : _client = client ?? http.Client();

  /// Submit a validation to the Apps Script endpoint.
  /// Rule 1: Never write directly to Google Sheets.
  Future<SubmissionResponse> submit(Submission submission) async {
    try {
      final response = await _client
          .post(
            Uri.parse(Constants.appsScriptUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(submission.toPayload()),
          )
          .timeout(Constants.submissionTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SubmissionResponse.fromJson(json);
      }

      return SubmissionResponse(
        status: 'error',
        message: 'Server returned status ${response.statusCode}',
      );
    } on Exception catch (e) {
      return SubmissionResponse(
        status: 'error',
        message: e.toString(),
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
