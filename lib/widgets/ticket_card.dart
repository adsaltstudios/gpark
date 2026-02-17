import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A parking-ticket-stub styled card with a perforated edge.
class TicketCard extends StatelessWidget {
  final String ticketNumber;
  final String? subtitle;
  final Widget? badge;
  final EdgeInsets margin;

  const TicketCard({
    super.key,
    required this.ticketNumber,
    this.subtitle,
    this.badge,
    this.margin = const EdgeInsets.symmetric(horizontal: Spacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(context);

    return Padding(
      padding: margin,
      child: ClipPath(
        clipper: _TicketStubClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(color: AppColors.divider(context))
                : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: isDark ? 0.06 : 0.03),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badge != null) ...[
                  badge!,
                  const SizedBox(height: Spacing.base),
                ],
                Text(
                  ticketNumber,
                  style: AppTypography.ticketMedium(context),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Creates the perforated-edge ticket stub shape.
class _TicketStubClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notchRadius = 8.0;
    const cornerRadius = 16.0;
    final notchY = size.height * 0.35;

    final path = Path();

    // Top-left corner
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Top edge
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Right edge down to notch
    path.lineTo(size.width, notchY - notchRadius);
    // Right notch (semi-circle inward)
    path.arcToPoint(
      Offset(size.width, notchY + notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right edge to bottom
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
        size.width, size.height, size.width - cornerRadius, size.height);

    // Bottom edge
    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Left edge up to notch
    path.lineTo(0, notchY + notchRadius);
    // Left notch
    path.arcToPoint(
      Offset(0, notchY - notchRadius),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
