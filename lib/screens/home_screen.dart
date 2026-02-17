import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/submission_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ticket_card.dart';
import 'camera_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _queuedCount = 0;
  late final AnimationController _entryController;
  late final Animation<double> _contentAnimation;
  late final Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshQueueCount();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _contentAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _fabAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entryController.dispose();
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
    final colorScheme = Theme.of(context).colorScheme;

    final user = authState.when(
      loading: () => null,
      authenticated: (user) => user,
      unauthenticated: () => null,
      error: (_) => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'gPark',
          style: AppTypography.brand(context).copyWith(fontSize: 24),
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.displayName[0].toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Queue banner
          AnimatedSlide(
            offset: _queuedCount > 0 ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _queuedCount > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.base,
                  vertical: Spacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning(context).withValues(alpha: 0.12),
                  border: Border(
                    bottom: BorderSide(
                      color:
                          AppColors.warning(context).withValues(alpha: 0.25),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off,
                        color: AppColors.warning(context), size: 18),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      '$_queuedCount submission${_queuedCount > 1 ? 's' : ''} waiting to sync',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.warning(context),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: FadeTransition(
              opacity: _contentAnimation,
              child: Center(
                child: _buildContent(submissionState),
              ),
            ),
          ),

          // Attestation footer
          Padding(
            padding: const EdgeInsets.all(Spacing.base),
            child: Text(
              'By submitting, I attest this is for valid business use.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary(context),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _openScanner(context),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Scan Ticket'),
          tooltip: 'Scan your parking ticket',
        ),
      ),
    );
  }

  Widget _buildContent(SubmissionState submissionState) {
    // Show today's submission card if we have one.
    if (submissionState is SubmissionSuccess) {
      return TicketCard(
        ticketNumber: submissionState.submission.ticketNumber,
        subtitle: submissionState.submission.timestamp,
        badge: _StatusBadge(
          label: 'Submitted',
          icon: Icons.cloud_done_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (submissionState is SubmissionQueued) {
      return TicketCard(
        ticketNumber: submissionState.submission.ticketNumber,
        subtitle: submissionState.submission.timestamp,
        badge: _StatusBadge(
          label: 'Queued',
          icon: Icons.cloud_off_outlined,
          color: AppColors.warning(context),
        ),
      );
    }

    // Empty state
    return _EmptyState();
  }

  void _openScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatefulWidget {
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated ticket outline
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final opacity = 0.15 + (_pulseController.value * 0.15);
            return Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: opacity),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 36,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: opacity + 0.1),
                  ),
                  const SizedBox(height: Spacing.sm),
                  // Dashed lines suggesting text
                  for (var i = 0; i < 3; i++) ...[
                    Container(
                      width: 40.0 - (i * 8),
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.divider(context)
                            .withValues(alpha: isDark ? 0.4 : 0.6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          'Ready to Scan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary(context),
              ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Tap below to scan your parking ticket',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary(context),
              ),
        ),
      ],
    );
  }
}
