part of '../main.dart';

/// Locations a BOQ has been priced for: totals, side-by-side comparison and
/// switching the BOQ to one location's prices.
class BoqLocationPricesPage extends StatefulWidget {
  const BoqLocationPricesPage({
    super.key,
    required this.api,
    required this.boqId,
    required this.currency,
  });

  final ApiClient api;
  final int boqId;
  final String currency;

  @override
  State<BoqLocationPricesPage> createState() => _BoqLocationPricesPageState();
}

class _BoqLocationPricesPageState extends State<BoqLocationPricesPage> {
  late Future<List<BoqLocation>> _locations = widget.api.boqLocations(
    widget.boqId,
  );
  final Set<String> _selected = {};
  bool _busy = false;

  void _reload() =>
      setState(() => _locations = widget.api.boqLocations(widget.boqId));

  String _money(double value) =>
      formatAmount(value, currency: widget.currency, decimals: 0);

  Future<void> _compare() async {
    if (_selected.length < 2) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LocationComparisonView(
          api: widget.api,
          boqId: widget.boqId,
          keys: _selected.take(4).toList(),
          currency: widget.currency,
        ),
      ),
    );
  }

  Future<void> _use(BoqLocation location) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr.locUseTitle(location.location)),
        content: Text(dialogContext.tr.locUseMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr.locUsePrices),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final applied = await widget.api.useBoqLocation(
        widget.boqId,
        location.location,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.locSwitched(applied, location.location)),
        ),
      );
      _reload();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.tr;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pdLocationPrices)),
      floatingActionButton: _selected.length >= 2
          ? FloatingActionButton.extended(
              onPressed: _compare,
              icon: const Icon(Icons.compare_arrows),
              label: Text(l10n.locCompareCount(_selected.length)),
            )
          : null,
      body: FutureBuilder<List<BoqLocation>>(
        future: _locations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _reload);
          }
          if (!snapshot.hasData) return const LoadingState();
          final locations = snapshot.data!;
          if (locations.isEmpty) {
            return EmptyState(
              icon: Icons.map_outlined,
              title: l10n.locNone,
              message: l10n.locNoneHelp,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: AppSpacing.page.copyWith(bottom: 96),
              children: [
                Text(l10n.locTickHint, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.md),
                for (final location in locations)
                  Card(
                    child: CheckboxListTile(
                      value: _selected.contains(location.key),
                      onChanged: _busy
                          ? null
                          : (checked) => setState(() {
                              checked == true
                                  ? _selected.add(location.key)
                                  : _selected.remove(location.key);
                            }),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              location.location,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (location.current)
                            StatusBadge(
                              label: l10n.locInUse,
                              tone: StatusTone.success,
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _money(location.total),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            l10n.locItemsPriced(
                              location.pricedItems,
                              location.totalItems,
                            ),
                          ),
                          if (!location.current)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _busy ? null : () => _use(location),
                                icon: const Icon(Icons.swap_horiz),
                                label: Text(l10n.locUsePrices),
                              ),
                            ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LocationComparisonView extends StatelessWidget {
  const _LocationComparisonView({
    required this.api,
    required this.boqId,
    required this.keys,
    required this.currency,
  });

  final ApiClient api;
  final int boqId;
  final List<String> keys;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.tr;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.locCompareTitle)),
      body: _FutureOnce<LocationComparison>(
        load: () => api.compareBoqLocations(boqId, keys),
        builder: (context, snapshot, retry) {
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: retry);
          }
          if (!snapshot.hasData) return const LoadingState();
          final comparison = snapshot.data!;
          final priced = comparison.locations.where((l) => l.pricedItems > 0);
          final cheapest = priced.isEmpty
              ? null
              : priced.reduce((a, b) => a.total <= b.total ? a : b).key;
          return ListView(
            padding: AppSpacing.page,
            children: [
              SectionCard(
                title: l10n.locTotals,
                icon: Icons.summarize_outlined,
                children: [
                  for (final location in comparison.locations)
                    KeyValueRow(
                      label: l10n.locPricedLabel(
                        location.location,
                        location.pricedItems,
                      ),
                      value: formatAmount(location.total, currency: currency),
                      emphasize: location.key == cheapest,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.locLowestHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              for (final row in comparison.rows)
                Card(
                  child: Padding(
                    padding: AppSpacing.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          [
                            if (row.code.isNotEmpty) row.code,
                            row.description,
                          ].join(' · '),
                          style: theme.textTheme.titleSmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final location in comparison.locations)
                          Row(
                            children: [
                              Expanded(child: Text(location.location)),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                row.rates[location.key] == null
                                    ? '—'
                                    : formatAmount(
                                        row.rates[location.key]!,
                                        currency: '',
                                        decimals: 2,
                                      ),
                                style: TextStyle(
                                  fontWeight: row.lowest == location.key
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: row.lowest == location.key
                                      ? AppColors.success
                                      : null,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Review, approve or reject the suggested prices of several items at once.
class BoqReviewPricesPage extends StatefulWidget {
  const BoqReviewPricesPage({
    super.key,
    required this.api,
    required this.boqId,
    required this.title,
  });

  final ApiClient api;
  final int boqId;
  final String title;

  @override
  State<BoqReviewPricesPage> createState() => _BoqReviewPricesPageState();
}

class _BoqReviewPricesPageState extends State<BoqReviewPricesPage> {
  late Future<List<BoqItemSummary>> _items = widget.api.allBoqItems(
    widget.boqId,
  );
  final Set<int> _selected = {};
  bool _busy = false;

  void _reload() {
    setState(() {
      _selected.clear();
      _items = widget.api.allBoqItems(widget.boqId);
    });
  }

  Future<void> _run(String action) async {
    String? reason;
    if (action == 'reject') {
      reason = await _askReason();
      if (reason == null) return;
    }
    setState(() => _busy = true);
    try {
      final result = await widget.api.bulkReviewItems(
        widget.boqId,
        action: action,
        itemIds: _selected.toList(),
        reason: reason,
      );
      if (!mounted) return;
      final l10n = context.tr;
      final done = switch (action) {
        'accept' => l10n.locItemsReviewed(result.done),
        'approve' => l10n.locItemsApproved(result.done),
        _ => l10n.locItemsRejected(result.done),
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.skipped > 0 ? l10n.locSkipped(done, result.skipped) : done,
          ),
        ),
      );
      _reload();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason() => showDialog<String>(
    context: context,
    builder: (_) => const _RejectReasonDialog(),
  );

  StatusTone _tone(String status) => switch (status) {
    'approved' => StatusTone.success,
    'reviewed' => StatusTone.info,
    'rejected' => StatusTone.danger,
    _ => StatusTone.warning,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selected.isEmpty
              ? context.tr.pdReviewPrices
              : context.tr.locSelected(_selected.length),
        ),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              tooltip: context.tr.locClearSelection,
              onPressed: () => setState(_selected.clear),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _run('accept'),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(context.tr.locReview),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _run('approve'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(context.tr.locApprove),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: _busy ? null : () => _run('reject'),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(context.tr.locReject),
                    ),
                  ],
                ),
              ),
            ),
      body: FutureBuilder<List<BoqItemSummary>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _reload);
          }
          if (!snapshot.hasData) return const LoadingState();
          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: context.tr.locNoItems,
            );
          }
          final selectable = items.where((i) => i.reviewStatus != 'approved');
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: AppSpacing.page.copyWith(bottom: 24),
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(context.tr.locSelectAll),
                  value:
                      selectable.isNotEmpty &&
                      selectable.every((i) => _selected.contains(i.id)),
                  onChanged: (checked) => setState(() {
                    checked == true
                        ? _selected.addAll(selectable.map((i) => i.id))
                        : _selected.clear();
                  }),
                ),
                for (final item in items)
                  Card(
                    child: CheckboxListTile(
                      value: _selected.contains(item.id),
                      onChanged: item.reviewStatus == 'approved' || _busy
                          ? null
                          : (checked) => setState(() {
                              checked == true
                                  ? _selected.add(item.id)
                                  : _selected.remove(item.id);
                            }),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        context.tr.locSuggested(
                          '${item.quantity} ${item.unit}',
                          item.aiRate,
                        ),
                      ),
                      secondary: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: StatusBadge(
                          label: item.reviewStatus.capitalize(),
                          tone: _tone(item.reviewStatus),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Asks why the selected prices are rejected. Owns its controller so it is
/// disposed only after the dialog has fully closed.
class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.locRejectTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.locReason,
            hintText: l10n.locReasonHint,
          ),
          validator: (v) => (v ?? '').trim().isEmpty ? l10n.locEnterReason : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: Text(l10n.locReject),
        ),
      ],
    );
  }
}
