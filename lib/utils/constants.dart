/// Central configuration constants for gPark.
/// Rule 4: URLs are constants. Not hardcoded anywhere else.
class Constants {
  Constants._();

  // --- Endpoints ---
  static const String appsScriptUrl =
      'https://script.google.com/macros/s/DEPLOY_ID/exec';
  static const String googleFormUrl =
      'https://docs.google.com/forms/d/FORM_ID/viewform';

  // --- Submission Defaults ---
  static const String officeLocation = 'Atlanta';
  static const String validationType = 'For myself';
  static const String submissionSource = 'gPark App';

  // --- Network ---
  static const Duration submissionTimeout = Duration(seconds: 30);

  // --- Offline Queue ---
  static const int maxQueueSize = 10;
  static const int maxRetries = 3;
  static const List<Duration> retryBackoffs = [
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 10),
  ];

  // --- UI ---
  static const Duration autoSubmitCountdown = Duration(seconds: 5);
  static const Duration successAutoDismiss = Duration(seconds: 5);
}
