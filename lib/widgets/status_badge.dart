import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Semantic colour families used by badges, icon tiles and banners.
enum StatusTone {
  brand,
  success,
  warning,
  danger,
  info,
  neutral;

  /// Best-effort mapping from backend status strings to a tone.
  static StatusTone forStatus(String? status) {
    final value = (status ?? '').toLowerCase().trim();
    switch (value) {
      case 'active':
      case 'approved':
      case 'paid':
      case 'completed':
      case 'complete':
      case 'success':
      case 'successful':
      case 'verified':
      case 'processed':
      case 'published':
        return StatusTone.success;
      case 'planning':
      case 'pending':
      case 'review':
      case 'in_review':
      case 'submitted':
      case 'processing':
      case 'queued':
      case 'warning':
      case 'trial':
        return StatusTone.warning;
      case 'failed':
      case 'rejected':
      case 'cancelled':
      case 'canceled':
      case 'expired':
      case 'error':
      case 'inactive':
        return StatusTone.danger;
      case 'info':
        return StatusTone.info;
      default:
        return StatusTone.neutral;
    }
  }

  Color foreground(ColorScheme scheme) => switch (this) {
    StatusTone.brand => scheme.primary,
    StatusTone.success => AppColors.success,
    StatusTone.warning => AppColors.warning,
    StatusTone.danger => AppColors.danger,
    StatusTone.info => AppColors.info,
    StatusTone.neutral => scheme.onSurfaceVariant,
  };

  Color background(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    if (dark) return foreground(scheme).withValues(alpha: 0.18);
    return switch (this) {
      StatusTone.brand => scheme.primaryContainer,
      StatusTone.success => AppColors.successContainer,
      StatusTone.warning => AppColors.warningContainer,
      StatusTone.danger => AppColors.dangerContainer,
      StatusTone.info => AppColors.infoContainer,
      StatusTone.neutral => scheme.surfaceContainer,
    };
  }
}

/// Small pill label for statuses ("Active", "Draft", "Paid" ...).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.color,
    this.icon,
  });

  final String label;
  final StatusTone tone;

  /// Optional explicit colour; overrides [tone].
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? tone.foreground(scheme);
    final bg = color?.withValues(alpha: 0.12) ?? tone.background(scheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded tinted square holding an icon; used as a list leading element.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.tone = StatusTone.brand,
    this.color,
    this.size = AppSizes.iconBadge,
  });

  final IconData icon;
  final StatusTone tone;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? tone.foreground(scheme);
    final bg = color?.withValues(alpha: 0.12) ?? tone.background(scheme);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}
