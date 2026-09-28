import 'package:flutter/material.dart';

import '../app_errors.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Centred placeholder: icon, title, optional message and action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// Compact variant for use inside cards / sections rather than full pages.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 52 : 72,
          height: compact ? 52 : 72,
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: compact ? 26 : 34, color: scheme.primary),
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: compact
              ? theme.textTheme.titleSmall
              : theme.textTheme.titleMedium,
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          FilledButton.tonalIcon(
            onPressed: onAction,
            icon: Icon(actionIcon ?? Icons.add),
            label: Text(actionLabel!),
          ),
        ],
      ],
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: content),
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: content,
        ),
      ),
    );
  }
}

/// Friendly error with an optional Retry button.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  /// Raw error object; converted with [friendlyError]. A [String] is shown as is.
  final Object? error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final message = error is String ? error as String : friendlyError(error);
    final retryLabel = AppLocalizations.of(context)?.retry ?? 'Retry';
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 52 : 72,
          height: compact ? 52 : 72,
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_off_outlined,
            size: compact ? 26 : 34,
            color: scheme.error,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(retryLabel),
          ),
        ],
      ],
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: content),
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: content,
        ),
      ),
    );
  }
}

/// Centred progress indicator with optional caption.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grey placeholder block used to build skeleton layouts.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadii.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A gently pulsing list of card-shaped skeletons shown while a list loads.
class SkeletonList extends StatefulWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = AppSpacing.page,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.itemGap),
          itemBuilder: (context, _) => const Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Row(
                children: [
                  SkeletonBox(width: 40, height: 40, radius: AppRadii.sm),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 180, height: 14),
                        SizedBox(height: AppSpacing.sm),
                        SkeletonBox(width: 110, height: 11),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  SkeletonBox(width: 56, height: 20, radius: AppRadii.pill),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline coloured message box (errors, success notices, hints).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.tone = BannerTone.error,
    this.icon,
    this.title,
  });

  final String message;
  final String? title;
  final BannerTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (fg, bg, defaultIcon) = switch (tone) {
      BannerTone.error => (
        AppColors.danger,
        AppColors.dangerContainer,
        Icons.error_outline,
      ),
      BannerTone.success => (
        AppColors.success,
        AppColors.successContainer,
        Icons.check_circle_outline,
      ),
      BannerTone.warning => (
        AppColors.warning,
        AppColors.warningContainer,
        Icons.warning_amber_rounded,
      ),
      BannerTone.info => (
        theme.colorScheme.primary,
        theme.colorScheme.primaryContainer,
        Icons.info_outline,
      ),
    };
    final dark = theme.brightness == Brightness.dark;
    return Semantics(
      liveRegion: tone == BannerTone.error,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: dark ? fg.withValues(alpha: 0.16) : bg,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? defaultIcon, color: fg, size: 20),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: theme.textTheme.titleSmall?.copyWith(color: fg),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: dark ? theme.colorScheme.onSurface : fg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BannerTone { error, success, warning, info }
