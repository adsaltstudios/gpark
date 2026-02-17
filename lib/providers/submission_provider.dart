import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/submission.dart';
import '../services/submission_service.dart';
import '../services/queue_service.dart';
import '../services/connectivity_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

final submissionServiceProvider =
    Provider<SubmissionService>((ref) => SubmissionService());
final queueServiceProvider =
    Provider<QueueService>((ref) => QueueService());

final submissionProvider =
    StateNotifierProvider<SubmissionNotifier, SubmissionState>((ref) {
  return SubmissionNotifier(
    submissionService: ref.read(submissionServiceProvider),
    queueService: ref.read(queueServiceProvider),
    connectivityService: ref.read(connectivityServiceProvider),
    authNotifier: ref.read(authProvider.notifier),
  );
});

class SubmissionNotifier extends StateNotifier<SubmissionState> {
  final SubmissionService _submissionService;
  final QueueService _queueService;
  final ConnectivityService _connectivityService;
  final AuthNotifier _authNotifier;
  StreamSubscription<bool>? _connectivitySub;

  SubmissionNotifier({
    required SubmissionService submissionService,
    required QueueService queueService,
    required ConnectivityService connectivityService,
    required AuthNotifier authNotifier,
  })  : _submissionService = submissionService,
        _queueService = queueService,
        _connectivityService = connectivityService,
        _authNotifier = authNotifier,
        super(const SubmissionIdle()) {
    _listenConnectivity();
    _processQueue();
  }

  void _listenConnectivity() {
    _connectivitySub = _connectivityService.isOnline.listen((online) {
      if (online) _processQueue();
    });
  }

  Submission _buildSubmission(String ticketNumber, String ocrConfidence) {
    final user = _authNotifier.currentUser!;
    return Submission(
      ticketNumber: ticketNumber,
      userEmail: user.email,
      validationType: Constants.validationType,
      timestamp: DateTime.now().toIso8601String(),
      submissionSource: Constants.submissionSource,
      ocrConfidence: ocrConfidence,
      userName: user.displayName,
      userLdap: user.ldap,
      officeLocation: Constants.officeLocation,
    );
  }

  Future<void> submit(String ticketNumber, String ocrConfidence) async {
    final submission = _buildSubmission(ticketNumber, ocrConfidence);
    state = const SubmissionSubmitting();

    final isOnline = await _connectivityService.checkConnectivity();
    if (!mounted) return;
    if (!isOnline) {
      await _queueService.enqueue(submission);
      if (!mounted) return;
      state = SubmissionQueued(submission);
      return;
    }

    final response = await _submissionService.submit(submission);
    if (!mounted) return;
    if (response.isSuccess) {
      state = SubmissionSuccess(submission, response);
    } else if (response.isDuplicate) {
      state = SubmissionDuplicate(response);
    } else {
      await _queueService.enqueue(submission);
      if (!mounted) return;
      state = SubmissionError(
        response.message ?? 'Submission failed.',
        submission,
      );
    }
  }

  Future<void> _processQueue() async {
    final pending = await _queueService.getPending();
    for (final entry in pending) {
      final response = await _submissionService.submit(entry.payload);
      if (response.isSuccess || response.isDuplicate) {
        await _queueService.markSubmitted(entry.id);
      } else {
        await _queueService.markFailed(entry.id);
      }
    }
  }

  Future<void> retryQueue() async {
    await _processQueue();
  }

  Future<int> queuedCount() => _queueService.queuedCount();

  void reset() {
    state = const SubmissionIdle();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}

sealed class SubmissionState {
  const SubmissionState();
}

class SubmissionIdle extends SubmissionState {
  const SubmissionIdle();
}

class SubmissionSubmitting extends SubmissionState {
  const SubmissionSubmitting();
}

class SubmissionSuccess extends SubmissionState {
  final Submission submission;
  final SubmissionResponse response;
  const SubmissionSuccess(this.submission, this.response);
}

class SubmissionDuplicate extends SubmissionState {
  final SubmissionResponse response;
  const SubmissionDuplicate(this.response);
}

class SubmissionError extends SubmissionState {
  final String message;
  final Submission submission;
  const SubmissionError(this.message, this.submission);
}

class SubmissionQueued extends SubmissionState {
  final Submission submission;
  const SubmissionQueued(this.submission);
}
