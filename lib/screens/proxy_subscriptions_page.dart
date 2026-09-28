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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF047857);
      case 'pending':
        return const Color(0xFFB45309);
      case 'cancelled':
        return const Color(0xFFBE123C);
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.proxySubscriptions)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  l10n.adminAccessRequired,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.adminAccessDescription,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(friendlyError(snapshot.error)),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _refresh,
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filtered = _filterSubscriptions(snapshot.data!);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noProxySubscriptions),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noProxySubscriptionsDescription,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _refresh();
                    await _subscriptions.catchError(
                      (_) => <ProxySubscription>[],
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final sub = filtered[index];
                      return _ProxySubscriptionCard(
                        subscription: sub,
                        onTap: () => _showDetails(sub),
                        statusColor: _statusColor(sub.status),
                        formatDate: _formatDate,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: l10n.search,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('status-$_statusFilter'),
            initialValue: _statusFilter,
            decoration: InputDecoration(
              labelText: l10n.status,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(value: 'all', child: Text(l10n.allStatuses)),
              DropdownMenuItem(value: 'active', child: Text(l10n.statusActive)),
              DropdownMenuItem(
                value: 'pending',
                child: Text(l10n.statusPending),
              ),
              DropdownMenuItem(
                value: 'cancelled',
                child: Text(l10n.statusCancelled),
              ),
              DropdownMenuItem(
                value: 'expired',
                child: Text(l10n.statusExpired),
              ),
            ],
            onChanged: (value) =>
                setState(() => _statusFilter = value ?? 'all'),
          ),
        ],
      ),
    );
  }

  void _showDetails(ProxySubscription sub) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.proxySubscriptionDetails,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _detailRow(l10n.beneficiary, sub.beneficiaryName),
              _detailRow(l10n.beneficiaryEmail, sub.beneficiaryEmail),
              _detailRow(l10n.plan, sub.planName),
              _detailRow(l10n.payer, sub.payerName),
              _detailRow(l10n.status, sub.status.capitalize()),
              _detailRow(l10n.paymentStatus, sub.paymentStatus.capitalize()),
              _detailRow(l10n.startDate, _formatDate(sub.startDate)),
              _detailRow(l10n.endDate, _formatDate(sub.endDate)),
              _detailRow(l10n.createdAt, _formatDate(sub.createdAt)),
              if (sub.transactionId.isNotEmpty)
                _detailRow(l10n.transactionId, sub.transactionId),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProxySubscriptionCard extends StatelessWidget {
  const _ProxySubscriptionCard({
    required this.subscription,
    required this.onTap,
    required this.statusColor,
    required this.formatDate,
  });

  final ProxySubscription subscription;
  final VoidCallback onTap;
  final Color statusColor;
  final String Function(String) formatDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subscription.beneficiaryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subscription.status.capitalize(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subscription.beneficiaryEmail,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(subscription.planName),
                    backgroundColor: Colors.blue[50],
                  ),
                  Chip(
                    label: Text(subscription.payerName),
                    backgroundColor: Colors.green[50],
                  ),
                  Chip(
                    label: Text(subscription.paymentStatus.capitalize()),
                    backgroundColor: subscription.paymentStatus == 'paid'
                        ? Colors.green[50]
                        : Colors.orange[50],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(subscription.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (subscription.transactionId.isNotEmpty)
                    Text(
                      subscription.transactionId,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
