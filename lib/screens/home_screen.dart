import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/submission_provider.dart';
import '../utils/constants.dart';
import 'camera_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _queuedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshQueueCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshQueueCount();
      ref.read(submissionProvider.notifier).retryQueue();
    }
  }

  Future<void> _refreshQueueCount() async {
    final count = await ref.read(submissionProvider.notifier).queuedCount();
    if (mounted) setState(() => _queuedCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final submissionState = ref.watch(submissionProvider);

    final user = authState.when(
      loading: () => null,
      authenticated: (user) => user,
      unauthenticated: () => null,
      error: (_) => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('gPark'),
        actions: [
          if (user != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'sign_out') {
                  ref.read(authProvider.notifier).signOut();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'sign_out',
                  child: Text('Sign Out'),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(user.displayName[0].toUpperCase())
                      : null,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Queue banner
          if (_queuedCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF9AB00).withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Color(0xFFF9AB00), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$_queuedCount submission${_queuedCount > 1 ? 's' : ''} waiting to sync',
                    style: const TextStyle(
                      color: Color(0xFF202124),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: Center(
              child: _buildContent(submissionState),
            ),
          ),

          // Attestation footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'By submitting, I attest this is for valid business use.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScanner(context),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Ticket'),
        tooltip: 'Scan your parking ticket',
      ),
    );
  }

  Widget _buildContent(SubmissionState submissionState) {
    // Show today's submission card if we have one.
    if (submissionState is SubmissionSuccess) {
      return _TodayCard(
        ticketNumber: submissionState.submission.ticketNumber,
        timestamp: submissionState.submission.timestamp,
        isQueued: false,
      );
    }
    if (submissionState is SubmissionQueued) {
      return _TodayCard(
        ticketNumber: submissionState.submission.ticketNumber,
        timestamp: submissionState.submission.timestamp,
        isQueued: true,
      );
    }

    // Empty state
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.directions_car_outlined,
          size: 80,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Text(
          'Ready to Scan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the button below to scan your parking ticket.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final String ticketNumber;
  final String timestamp;
  final bool isQueued;

  const _TodayCard({
    required this.ticketNumber,
    required this.timestamp,
    required this.isQueued,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isQueued ? Icons.cloud_off : Icons.hourglass_top,
                  color: isQueued
                      ? const Color(0xFFF9AB00)
                      : const Color(0xFF1A73E8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isQueued ? 'Queued' : 'Submitted',
                  style: TextStyle(
                    color: isQueued
                        ? const Color(0xFFF9AB00)
                        : const Color(0xFF1A73E8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ticketNumber,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF202124),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timestamp,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
