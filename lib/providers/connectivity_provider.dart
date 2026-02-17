import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

final connectivityServiceProvider =
    Provider<ConnectivityService>((ref) => ConnectivityService());

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.read(connectivityServiceProvider);
  return service.isOnline;
});

/// One-shot connectivity check.
final connectivityCheckProvider = FutureProvider<bool>((ref) {
  final service = ref.read(connectivityServiceProvider);
  return service.checkConnectivity();
});
