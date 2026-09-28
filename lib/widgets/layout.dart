import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Title row for a group of content, with optional subtitle and trailing
/// action (e.g. "View all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Large page title + optional subtitle used at the top of tab pages.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.headlineSmall),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// KPI tile: icon, big value and caption.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = StatusTone.brand,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatusTone tone;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(icon: icon, tone: tone, color: color, size: 36),
              const SizedBox(height: AppSpacing.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branded hero card highlighting a single headline figure.
class HighlightCard extends StatelessWidget {
  const HighlightCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.footer,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.sm),
            DefaultTextStyle.merge(
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Label / value pair laid out on one line (value right-aligned) or stacked.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.emphasize = false,
    this.icon,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool emphasize;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style:
                  valueStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                    color: emphasize ? theme.colorScheme.primary : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats money consistently: "UGX 1,250,000".
String formatAmount(num? amount, {String currency = 'UGX', int decimals = 0}) {
  if (amount == null) return '—';
  final pattern = decimals > 0 ? '#,##0.${'0' * decimals}' : '#,##0';
  final formatted = NumberFormat(pattern, 'en_US').format(amount);
  return currency.isEmpty ? formatted : '$currency $formatted';
}

/// Money text with a subdued currency prefix.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.currency = 'UGX',
    this.decimals = 0,
    this.style,
    this.textAlign,
  });

  final num? amount;
  final String currency;
  final int decimals;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.titleMedium;
    if (amount == null) return Text('—', style: base, textAlign: textAlign);
    final number = formatAmount(amount, currency: '', decimals: decimals);
    return Text.rich(
      TextSpan(
        children: [
          if (currency.isNotEmpty)
            TextSpan(
              text: '$currency ',
              style: base?.copyWith(
                fontSize: (base.fontSize ?? 14) * 0.72,
                fontWeight: FontWeight.w600,
                color: (base.color ?? theme.colorScheme.onSurface).withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          TextSpan(text: number),
        ],
      ),
      style: base?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      textAlign: textAlign,
      semanticsLabel: formatAmount(
        amount,
        currency: currency,
        decimals: decimals,
      ),
    );
  }
}

/// Constrains page content to a readable width on tablets.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Card with an optional heading used to group related fields or details.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.children,
    this.padding = AppSpacing.card,
    this.spacing = 0,
  });

  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title!, style: theme.textTheme.titleMedium),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0 && spacing > 0) SizedBox(height: spacing),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Tappable list row in a card: leading tile, title, subtitle, trailing.
class ListItemCard extends StatelessWidget {
  const ListItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.itemGap),
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: margin,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: AppSpacing.md + 2),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        trailing!,
                      ],
                      if (onTap != null && showChevron) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary button that shows a spinner while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.tonal = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final spinner = SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: tonal
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onPrimary,
      ),
    );
    final child = loading
        ? spinner
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
    );
    return Semantics(
      button: true,
      label: loading ? label : null,
      child: tonal
          ? FilledButton.tonal(
              style: style,
              onPressed: loading ? null : onPressed,
              child: child,
            )
          : FilledButton(
              style: style,
              onPressed: loading ? null : onPressed,
              child: child,
            ),
    );
  }
}

/// Brand mark used on auth screens and the drawer header.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64, this.icon});

  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon ?? Icons.foundation_outlined,
            color: Colors.white,
            size: size * 0.52,
          ),
          Positioned(
            right: size * 0.16,
            top: size * 0.16,
            child: Container(
              width: size * 0.14,
              height: size * 0.14,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
