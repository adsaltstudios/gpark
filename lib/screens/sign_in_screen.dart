import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SignInScreen extends ConsumerStatefulWidget {
  final String? errorMessage;

  const SignInScreen({super.key, this.errorMessage});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final AnimationController _gridController;
  late final Animation<double> _logoAnimation;
  late final Animation<double> _taglineAnimation;
  late final Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _logoAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _taglineAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );
    _buttonAnimation = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Animated grid background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParkingGridPainter(
                    progress: _gridController.value,
                    color: colorScheme.primary.withValues(
                      alpha: isDark ? 0.06 : 0.04,
                    ),
                    dotColor: colorScheme.primary.withValues(
                      alpha: isDark ? 0.12 : 0.08,
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    FadeTransition(
                      opacity: _logoAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_logoAnimation),
                        child: Column(
                          children: [
                            // Styled "gP" mark
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'gP',
                                  style: AppTypography.brand(context).copyWith(
                                    color: colorScheme.onPrimary,
                                    fontSize: 36,
                                    letterSpacing: -2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: Spacing.lg),
                            Text(
                              'gPark',
                              style: AppTypography.brand(context).copyWith(
                                fontSize: 36,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),

                    // Tagline
                    FadeTransition(
                      opacity: _taglineAnimation,
                      child: Text(
                        'Park. Scan. Done.',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary(context),
                                  letterSpacing: 1.5,
                                ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),

                    // Error message
                    if (widget.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: colorScheme.error, size: 20),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                widget.errorMessage!,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                    ],

                    // Sign-In button
                    FadeTransition(
                      opacity: _buttonAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_buttonAnimation),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: isLoading
                                ? null
                                : () =>
                                    ref.read(authProvider.notifier).signIn(),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login,
                                          size: 20,
                                          color: colorScheme.onPrimary),
                                      const SizedBox(width: Spacing.sm),
                                      Text(
                                        'Sign in with Google',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: colorScheme.onPrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a subtle animated parking-grid pattern in the background.
class _ParkingGridPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color dotColor;

  _ParkingGridPainter({
    required this.progress,
    required this.color,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 40.0;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Slowly drifting grid lines
    final offset = progress * spacing;

    // Vertical lines
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Horizontal lines
    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Dots at intersections
    final dotPaint = Paint()..color = dotColor;
    for (double x = -spacing + offset;
        x < size.width + spacing;
        x += spacing) {
      for (double y = -spacing + offset;
          y < size.height + spacing;
          y += spacing) {
        // Fade dots based on distance from center
        final dx = x - size.width / 2;
        final dy = y - size.height / 2;
        final dist = math.sqrt(dx * dx + dy * dy);
        final maxDist = math.sqrt(
            size.width * size.width / 4 + size.height * size.height / 4);
        final fade = 1.0 - (dist / maxDist).clamp(0, 1);
        dotPaint.color = dotColor.withValues(alpha: dotColor.a * fade);
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParkingGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
