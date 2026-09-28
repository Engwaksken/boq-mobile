part of '../main.dart';

class ProxySubscriptionListPage extends StatefulWidget {
  const ProxySubscriptionListPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<ProxySubscriptionListPage> createState() =>
      _ProxySubscriptionListPageState();
}

class _ProxySubscriptionListPageState extends State<ProxySubscriptionListPage> {
  late Future<List<ProxySubscription>> _subscriptions;
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  bool _isAdmin = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(_loadSubscriptions);

  void _loadSubscriptions() {
    final future = widget.api.listProxySubscriptions();
    _subscriptions = future;
    future.then(
      (_) {
        if (mounted && !_isAdmin) setState(() => _isAdmin = true);
      },
      onError: (Object e) {
        if (e is! ApiException || !mounted) return;
        final message = e.message.toLowerCase();
        final denied =
            message.contains('unauthorized') ||
            message.contains('forbidden') ||
            message.contains('admin');
        if (denied) setState(() => _isAdmin = false);
      },
    );
  }

  List<ProxySubscription> _filterSubscriptions(
    List<ProxySubscription> subscriptions,
  ) {
    final query = _searchController.text.toLowerCase().trim();
    return subscriptions.where((sub) {
      final matchesSearch =
          query.isEmpty ||
          sub.beneficiaryName.toLowerCase().contains(query) ||
          sub.beneficiaryEmail.toLowerCase().contains(query) ||
          sub.planName.toLowerCase().contains(query) ||
          sub.payerName.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'all' || sub.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _onPullToRefresh() async {
    _refresh();
    await _subscriptions.catchError((_) => <ProxySubscription>[]);
  }

  /// Centres a compact state inside a scrollable so pull-to-refresh works.
  Widget _fillScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight * 0.7),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.proxySubscriptions)),
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: l10n.adminAccessRequired,
          message: l10n.adminAccessDescription,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.proxySubscriptions),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(l10n),
          Expanded(
            child: FutureBuilder<List<ProxySubscription>>(
              future: _subscriptions,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _onPullToRefresh,
                    child: _fillScrollable(
                      ErrorState(
                        error: snapshot.error,
                        onRetry: _refresh,
                        compact: true,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const SkeletonList();
                }
                final filtered = _filterSubscriptions(snapshot.data!);
                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onPullToRefresh,
                    child: _fillScrollable(
                      EmptyState(
                        icon: Icons.assignment_outlined,
                        title: l10n.noProxySubscriptions,
                        message: l10n.noProxySubscriptionsDescription,
                        compact: true,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _onPullToRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.page,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final sub = filtered[index];
                      return ContentWidth(
                        child: _ProxySubscriptionCard(
                          subscription: sub,
                          onTap: () => _showDetails(sub),
                          formatDate: _formatDate,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final statuses = <(String, String)>[
      ('all', l10n.allStatuses),
      ('active', l10n.statusActive),
      ('pending', l10n.statusPending),
      ('cancelled', l10n.statusCancelled),
      ('expired', l10n.statusExpired),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: l10n.status,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (value, label) in statuses)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _statusFilter == value,
                          onSelected: (_) =>
                              setState(() => _statusFilter = value),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(ProxySubscription sub) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                l10n.proxySubscriptionDetails,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const IconTile(icon: Icons.card_membership_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.beneficiaryName,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (sub.beneficiaryEmail.isNotEmpty)
                          Text(
                            sub.beneficiaryEmail,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusBadge(
                    label: sub.status.capitalize(),
                    tone: StatusTone.forStatus(sub.status),
                  ),
                  StatusBadge(
                    label: sub.paymentStatus.capitalize(),
                    tone: StatusTone.forStatus(sub.paymentStatus),
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                children: [
                  _detailRow(l10n.beneficiary, sub.beneficiaryName),
                  _detailRow(l10n.beneficiaryEmail, sub.beneficiaryEmail),
                  _detailRow(l10n.plan, sub.planName),
                  _detailRow(l10n.payer, sub.payerName),
                  _detailRow(l10n.status, sub.status.capitalize()),
                  _detailRow(
                    l10n.paymentStatus,
                    sub.paymentStatus.capitalize(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SectionCard(
                children: [
                  _detailRow(l10n.startDate, _formatDate(sub.startDate)),
                  _detailRow(l10n.endDate, _formatDate(sub.endDate)),
                  _detailRow(l10n.createdAt, _formatDate(sub.createdAt)),
                  if (sub.transactionId.isNotEmpty)
                    _detailRow(l10n.transactionId, sub.transactionId),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProxySubscriptionCard extends StatelessWidget {
  const _ProxySubscriptionCard({
    required this.subscription,
    required this.onTap,
    required this.formatDate,
  });

  final ProxySubscription subscription;
  final VoidCallback onTap;
  final String Function(String) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget meta(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return ListItemCard(
      title: subscription.beneficiaryName,
      subtitle: subscription.beneficiaryEmail,
      leading: const IconTile(icon: Icons.card_membership_outlined),
      trailing: StatusBadge(
        label: subscription.status.capitalize(),
        tone: StatusTone.forStatus(subscription.status),
      ),
      showChevron: false,
      onTap: onTap,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              meta(Icons.workspace_premium_outlined, subscription.planName),
              meta(Icons.person_outline, subscription.payerName),
              StatusBadge(
                label: subscription.paymentStatus.capitalize(),
                tone: StatusTone.forStatus(subscription.paymentStatus),
                icon: Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: meta(
                    Icons.calendar_today_outlined,
                    formatDate(subscription.createdAt),
                  ),
                ),
              ),
              if (subscription.transactionId.isNotEmpty)
                Flexible(
                  child: Text(
                    subscription.transactionId,
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
