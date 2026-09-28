part of '../main.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.l10n,
    required this.api,
    required this.locale,
    required this.onLocaleChanged,
    required this.onSignedOut,
  });

  final AppLocalizations l10n;
  final ApiClient api;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onSignedOut;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Future<Map<String, dynamic>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.api.currentSubscription();
  }

  void _reloadSubscription() {
    if (!mounted) return;
    setState(() {
      _subscription = widget.api.currentSubscription();
    });
  }

  double? _subscriptionProgress(Map<String, dynamic> subscription) {
    final start = DateTime.tryParse('${subscription['start_date'] ?? ''}');
    final end = DateTime.tryParse('${subscription['end_date'] ?? ''}');
    if (start == null || end == null || !end.isAfter(start)) return null;

    final total = end.difference(start).inSeconds;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0).toDouble();
  }

  int? _daysRemaining(Map<String, dynamic> subscription) {
    final end = DateTime.tryParse('${subscription['end_date'] ?? ''}');
    if (end == null) return null;
    final remaining = end.difference(DateTime.now());
    if (remaining.isNegative) return 0;
    return (remaining.inHours / 24).ceil();
  }

  Future<void> _signOut() async {
    await widget.api.logout();
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.l10n.account,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        FutureBuilder<Map<String, dynamic>>(
          future: _subscription,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l10n.subscription,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text('No active plan'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlansPage(
                                api: widget.api,
                                onSubscriptionCreated: _reloadSubscription,
                              ),
                            ),
                          ),
                          child: Text(widget.l10n.managePlan),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.hasData) {
              final sub = snapshot.data!;
              final progress = _subscriptionProgress(sub);
              final daysRemaining = _daysRemaining(sub);
              final status = '${sub['status'] ?? 'N/A'}';
              final isTrial = status.toLowerCase() == 'trial';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l10n.subscription,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(sub['plan']?['name'] ?? 'No Active Plan'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            avatar: Icon(
                              isTrial
                                  ? Icons.hourglass_top
                                  : Icons.verified_outlined,
                              size: 16,
                            ),
                            label: Text(
                              isTrial ? '7-day trial' : status.toUpperCase(),
                            ),
                          ),
                          if (daysRemaining != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                daysRemaining == 0
                                    ? 'Expires today'
                                    : '$daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining',
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: progress),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        '${widget.l10n.aiCredits}: ${sub['plan']?['max_ai_credits'] ?? 'N/A'}',
                      ),
                      Text(
                        '${widget.l10n.ocrPages}: ${sub['plan']?['max_ocr_pages'] ?? 'N/A'}',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlansPage(
                                api: widget.api,
                                onSubscriptionCreated: _reloadSubscription,
                              ),
                            ),
                          ),
                          child: Text(widget.l10n.managePlan),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(widget.l10n.language),
                trailing: DropdownButton<Locale>(
                  value: widget.locale,
                  underline: const SizedBox(),
                  onChanged: (value) {
                    if (value != null) widget.onLocaleChanged(value);
                  },
                  items: [
                    const DropdownMenuItem(
                      value: Locale('en'),
                      child: Text('English'),
                    ),
                    const DropdownMenuItem(
                      value: Locale('lg'),
                      child: Text('Luganda'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(widget.l10n.notifications),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications')),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(widget.l10n.profile),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfilePage(
                        api: widget.api,
                        locale: widget.locale,
                        onLocaleChanged: widget.onLocaleChanged,
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.business_outlined),
                title: const Text('Company Profile'),
                subtitle: const Text('Logo and details used on your BOQ PDFs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CompanyProfilePage(api: widget.api),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: Text(widget.l10n.signOut),
        ),
      ],
    );
  }
}

class PlansPage extends StatefulWidget {
  const PlansPage({super.key, required this.api, this.onSubscriptionCreated});

  final ApiClient api;
  final VoidCallback? onSubscriptionCreated;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late Future<List<Map<String, dynamic>>> _plans;
  int? _submittingPlanId;

  @override
  void initState() {
    super.initState();
    _plans = widget.api.plans();
  }

  Future<void> _selectPlan(Map<String, dynamic> plan) async {
    final id = int.tryParse('${plan['id'] ?? ''}');
    if (id == null || _submittingPlanId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select subscription plan'),
        content: Text(
          'Create a pending subscription for ${plan['name'] ?? 'this plan'}? '
          'Your plan becomes active only after payment is confirmed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submittingPlanId = id);
    try {
      final subscription = await widget.api.createSubscription(id);
      if (!mounted) return;
      widget.onSubscriptionCreated?.call();
      final status = '${subscription['status'] ?? 'pending'}';

      if (status == 'pending') {
        final activated = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) =>
                PaymentPage(api: widget.api, subscription: subscription),
          ),
        );
        if (activated == true) {
          widget.onSubscriptionCreated?.call();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment confirmed. Your subscription is now active.',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription updated successfully.')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submittingPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.managePlan)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _plans,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    const Text('Unable to load subscription plans.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _plans = widget.api.plans()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data!;
          if (plans.isEmpty) {
            return const Center(
              child: Text('No plans are currently available.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final id = int.tryParse('${plan['id'] ?? ''}');
              final busy = id != null && _submittingPlanId == id;
              final features =
                  (plan['included_features'] as List<dynamic>? ?? const [])
                      .map((item) => '$item')
                      .where((item) => item.trim().isNotEmpty)
                      .take(4)
                      .toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${plan['name'] ?? 'Plan'}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${plan['currency'] ?? 'UGX'} ${plan['price'] ?? '0'}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      if ('${plan['description'] ?? ''}'.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('${plan['description']}'),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (plan['trial_days'] != null)
                            Chip(
                              label: Text('${plan['trial_days']} day trial'),
                            ),
                          if (plan['max_projects'] != null)
                            Chip(
                              label: Text('${plan['max_projects']} projects'),
                            ),
                          if (plan['max_boqs'] != null)
                            Chip(label: Text('${plan['max_boqs']} BOQs')),
                          if (plan['max_ai_credits'] != null)
                            Chip(
                              label: Text(
                                '${plan['max_ai_credits']} AI credits',
                              ),
                            ),
                        ],
                      ),
                      if (features.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...features.map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(feature)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: busy ? null : () => _selectPlan(plan),
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Select plan'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.api, required this.subscription});

  final ApiClient api;
  final Map<String, dynamic> subscription;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Future<List<Map<String, dynamic>>> _gateways;
  String? _selectedGatewayCode;
  String? _selectedMethod;
  Map<String, dynamic>? _paymentData;
  bool _initiating = false;
  bool _verifying = false;
  bool _successHandled = false;
  String? _idempotencyKey;
  Timer? _statusTimer;
  int _pollCount = 0;
  Map<String, dynamic>? _receipt;
  final TextEditingController _phoneNumber = TextEditingController();

  @override
  void initState() {
    super.initState();
    _gateways = widget.api.paymentGateways();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _phoneNumber.dispose();
    super.dispose();
  }

  int? get _subscriptionId =>
      int.tryParse('${widget.subscription['id'] ?? ''}');

  Map<String, dynamic>? get _transaction =>
      _paymentData?['transaction'] as Map<String, dynamic>?;

  Map<String, dynamic>? get _gatewayResult =>
      _paymentData?['gateway'] as Map<String, dynamic>?;

  Future<void> _initiate(Map<String, dynamic> gateway) async {
    final subscriptionId = _subscriptionId;
    final code = '${gateway['code'] ?? ''}'.trim();
    if (subscriptionId == null || code.isEmpty || _initiating) return;

    setState(() {
      _initiating = true;
      _selectedGatewayCode = code;
    });
    try {
      _idempotencyKey ??=
          'mobile-$subscriptionId-$code-${DateTime.now().microsecondsSinceEpoch}';
      final data = await widget.api.initiatePayment(
        subscriptionId: subscriptionId,
        gatewayCode: code,
        idempotencyKey: _idempotencyKey!,
        paymentMethod: _selectedMethod,
        phoneNumber: _phoneNumber.text,
        network: _selectedMethod,
      );
      if (!mounted) return;
      setState(() => _paymentData = data);
      _startStatusPolling();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment started. Follow the instructions below, then verify the payment.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _initiating = false);
    }
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _pollCount = 0;
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollCount++;
      if (_pollCount > 24 || !mounted) {
        timer.cancel();
        return;
      }
      await _refreshTransaction(silent: true);
    });
  }

  Future<void> _loadReceipt(int transactionId) async {
    try {
      final receipt = await widget.api.paymentReceipt(transactionId);
      if (!mounted) return;
      setState(() => _receipt = receipt);
    } on ApiException {
      return;
    }
  }

  Future<void> _handleSuccessfulPayment(
    Map<String, dynamic> transaction,
  ) async {
    if (_successHandled || !mounted) return;
    _successHandled = true;
    _statusTimer?.cancel();
    final transactionId = int.tryParse('${transaction['id'] ?? ''}');
    if (transactionId != null) {
      await _loadReceipt(transactionId);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment confirmed'),
        content: const Text(
          'Your subscription has been activated successfully.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _verify() async {
    final transaction = _transaction;
    final transactionId = int.tryParse('${transaction?['id'] ?? ''}');
    if (transactionId == null || _verifying) return;

    setState(() => _verifying = true);
    try {
      final verified = await widget.api.verifyPayment(transactionId);
      if (!mounted) return;
      setState(() {
        _paymentData = {...?_paymentData, 'transaction': verified};
      });
      final status = '${verified['status'] ?? ''}'.toLowerCase();
      if (status == 'successful') {
        await _handleSuccessfulPayment(verified);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'under_review'
                  ? 'Payment submitted for review. Your plan will activate after confirmation.'
                  : 'Payment status: ${status.isEmpty ? 'pending' : status}.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _refreshTransaction({bool silent = false}) async {
    final transactionId = int.tryParse('${_transaction?['id'] ?? ''}');
    if (transactionId == null) return;
    try {
      final refreshed = await widget.api.transaction(transactionId);
      if (!mounted) return;
      setState(() {
        _paymentData = {...?_paymentData, 'transaction': refreshed};
        final invoice = refreshed['invoice'];
        if (invoice is Map<String, dynamic>) {
          _receipt = invoice;
        }
      });
      final status = '${refreshed['status'] ?? ''}'.toLowerCase();
      if (status == 'successful') {
        await _handleSuccessfulPayment(refreshed);
      }
    } on ApiException catch (e) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _receiptCard() {
    final receipt = _receipt;
    if (receipt == null || receipt.isEmpty) return const SizedBox.shrink();
    final currency = '${receipt['currency'] ?? ''}';
    final total = receipt['total_amount'] ?? receipt['amount'] ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined),
                const SizedBox(width: 8),
                Text(
                  'Payment receipt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText('Invoice: ${receipt['invoice_number'] ?? ''}'),
            SelectableText(
              'Reference: ${receipt['transaction_reference'] ?? _transaction?['reference'] ?? ''}',
            ),
            Text('Amount: $currency $total'),
            if (receipt['payment_date'] != null)
              Text('Paid: ${receipt['payment_date']}'),
          ],
        ),
      ),
    );
  }

  Widget _gatewayInstructions() {
    final gateway = _gatewayResult;
    if (gateway == null || gateway.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];

    void addRow(String label, dynamic value) {
      if (value == null || '$value'.trim().isEmpty) return;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 105,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: SelectableText('$value')),
            ],
          ),
        ),
      );
    }

    addRow('Reference', gateway['transaction_reference']);
    addRow('Provider', gateway['provider']);
    addRow('Phone', gateway['phone']);
    addRow('Mode', gateway['mode']);
    addRow('Instructions', gateway['instructions']);

    final checkoutUrl = '${gateway['checkout_url'] ?? ''}'.trim();
    if (checkoutUrl.isNotEmpty) {
      rows.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.link),
          title: const Text('Checkout URL'),
          subtitle: SelectableText(checkoutUrl),
          trailing: Wrap(
            spacing: 2,
            children: [
              IconButton(
                tooltip: 'Open secure checkout',
                onPressed: () async {
                  final uri = Uri.tryParse(checkoutUrl);
                  if (uri == null ||
                      !await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to open checkout. You can copy the link instead.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
              ),
              IconButton(
                tooltip: 'Copy',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: checkoutUrl));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checkout URL copied.')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
        ),
      );
    }

    final bankDetails = gateway['bank_details'];
    if (bankDetails is Map) {
      for (final entry in bankDetails.entries) {
        addRow('${entry.key}', entry.value);
      }
    } else if (bankDetails != null) {
      addRow('Bank details', bankDetails);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment instructions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan =
        widget.subscription['plan'] as Map<String, dynamic>? ?? const {};
    final transaction = _transaction;
    final status = '${transaction?['status'] ?? 'not started'}';

    return Scaffold(
      appBar: AppBar(title: const Text('Complete payment')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gateways,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 44),
                    const SizedBox(height: 12),
                    const Text('Unable to load payment methods.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(
                        () => _gateways = widget.api.paymentGateways(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final gateways = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${plan['name'] ?? 'Subscription plan'}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${plan['currency'] ?? 'UGX'} ${plan['price'] ?? '0'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Subscription status: ${widget.subscription['status'] ?? 'pending'}',
                      ),
                      if (transaction != null) ...[
                        const Divider(height: 24),
                        Text(
                          'Transaction: ${transaction['reference'] ?? transaction['id'] ?? ''}',
                        ),
                        Text('Payment status: $status'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (gateways.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No payment methods are currently enabled. Please contact the administrator.',
                    ),
                  ),
                )
              else ...[
                Text(
                  'Choose payment method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _selectedGatewayCode,
                  onChanged: (value) {
                    if (_paymentData != null || value == null) return;
                    final gateway = gateways.firstWhere(
                      (g) => '${g['code'] ?? ''}' == value,
                      orElse: () => const <String, dynamic>{},
                    );
                    final methods =
                        (gateway['supported_methods'] as List<dynamic>? ??
                                const [])
                            .map((e) => '$e')
                            .where((e) => e.trim().isNotEmpty)
                            .toList();
                    setState(() {
                      _selectedGatewayCode = value;
                      _selectedMethod = methods.isNotEmpty
                          ? methods.first
                          : null;
                      _idempotencyKey = null;
                    });
                  },
                  child: Column(
                    children: [
                      ...gateways.map((gateway) {
                        final code = '${gateway['code'] ?? ''}';
                        final selected = _selectedGatewayCode == code;
                        return Card(
                          child: RadioListTile<String>(
                            value: code,
                            enabled: _paymentData == null,
                            title: Text('${gateway['name'] ?? code}'),
                            subtitle: Text(
                              '${gateway['description'] ?? gateway['driver'] ?? ''}'
                              '${gateway['is_aggregator'] == true ? ' • Aggregator' : ''}'
                              '${gateway['is_test_mode'] == true ? ' • Test mode' : ''}',
                            ),
                            secondary: selected
                                ? const Icon(Icons.check_circle)
                                : const Icon(Icons.payments_outlined),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (_selectedGatewayCode != null && _paymentData == null) ...[
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final selected = gateways.firstWhere(
                        (g) => '${g['code'] ?? ''}' == _selectedGatewayCode,
                        orElse: () => const <String, dynamic>{},
                      );
                      final methods =
                          (selected['supported_methods'] as List<dynamic>? ??
                                  const [])
                              .map((e) => '$e')
                              .where((e) => e.trim().isNotEmpty)
                              .toList();
                      final driver = '${selected['driver'] ?? ''}';
                      final isAggregator = selected['is_aggregator'] == true;
                      final effectiveMethod = methods.contains(_selectedMethod)
                          ? _selectedMethod
                          : (methods.isNotEmpty ? methods.first : null);
                      final aggregatorMobile =
                          isAggregator &&
                          ![
                            'card',
                            'visa',
                            'mastercard',
                          ].contains((effectiveMethod ?? '').toLowerCase());
                      final needsPhone =
                          driver == 'mtn_momo' ||
                          driver == 'airtel_money' ||
                          aggregatorMobile;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (needsPhone) ...[
                            TextField(
                              controller: _phoneNumber,
                              keyboardType: TextInputType.phone,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: driver == 'mtn_momo'
                                    ? 'MTN MoMo number'
                                    : driver == 'airtel_money'
                                    ? 'Airtel Money number'
                                    : 'Mobile money number',
                                hintText: 'e.g. 0772 123 456',
                                prefixIcon: const Icon(Icons.phone_android),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (methods.length > 1)
                            DropdownButtonFormField<String>(
                              key: ValueKey(
                                'method-$_selectedGatewayCode-$effectiveMethod',
                              ),
                              initialValue: methods.contains(_selectedMethod)
                                  ? _selectedMethod
                                  : methods.first,
                              decoration: const InputDecoration(
                                labelText: 'Payment option',
                              ),
                              items: methods
                                  .map(
                                    (method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(method),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedMethod = value),
                            ),
                          if (methods.length > 1) const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed:
                                _initiating ||
                                    (needsPhone &&
                                        _phoneNumber.text.trim().isEmpty)
                                ? null
                                : () => _initiate(selected),
                            icon: _initiating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_outline),
                            label: Text(
                              _initiating
                                  ? 'Starting payment…'
                                  : 'Continue to payment',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
              if (_paymentData != null) ...[
                const SizedBox(height: 12),
                _gatewayInstructions(),
                if (_receipt != null) ...[
                  const SizedBox(height: 12),
                  _receiptCard(),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _refreshTransaction,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh status'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _verifying ? null : _verify,
                        icon: _verifying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.verified_outlined),
                        label: Text(
                          _verifying ? 'Checking…' : 'Verify payment',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your plan is activated only after the server confirms a successful payment. Closing this screen does not delete the pending subscription.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.api,
    required this.locale,
    required this.onLocaleChanged,
  });

  final ApiClient api;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _password = TextEditingController();
  late final Future<UserProfile> _profile = widget.api.profile();
  late String _selectedLocale = widget.locale.languageCode;
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  late final BiometricService _biometricService;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _biometricService = BiometricService();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    final biometrics = await _biometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _availableBiometrics = biometrics;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _biometricService.setBiometricEnabled(value);
      if (mounted) {
        setState(() => _biometricEnabled = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? l10n.biometricEnabled : l10n.biometricDisabled,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _biometricEnabled = !value);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.biometricError)));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final profile = await widget.api.updateProfile(
        name: _name.text.trim(),
        email: _email.text.trim(),
        locale: _selectedLocale,
        password: _password.text,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      );
      widget.onLocaleChanged(Locale(profile.locale));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: FutureBuilder<UserProfile>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;
          if (!_loaded) {
            _loaded = true;
            _name.text = profile.name;
            _email.text = profile.email;
            _phone.text = profile.phone ?? '';
            _location.text = profile.location ?? '';
            _selectedLocale = profile.locale;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.fullName),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.fullName
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.email),
                  validator: (value) =>
                      value == null || !value.contains('@') ? l10n.email : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l10n.phoneNumber),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _location,
                  decoration: InputDecoration(labelText: l10n.location),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocale,
                  decoration: InputDecoration(labelText: l10n.language),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                    DropdownMenuItem(value: 'lg', child: Text(l10n.luganda)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLocale = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Biometric section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.enableBiometricLogin,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _biometricAvailable
                              ? '${l10n.biometricAvailable} - ${l10n.biometricTypes}${_availableBiometrics.map((t) => _biometricService.getBiometricTypeName(t)).join(', ')}'
                              : l10n.biometricNotAvailable,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _biometricAvailable
                                    ? null
                                    : Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: Text(l10n.enableBiometricLogin),
                          subtitle: Text(l10n.biometricLoginDescription),
                          value: _biometricEnabled,
                          onChanged: _biometricAvailable
                              ? _toggleBiometric
                              : null,
                          secondary: Icon(
                            _biometricAvailable
                                ? Icons.fingerprint
                                : Icons.fingerprint_outlined,
                            color: _biometricAvailable
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    helperText: l10n.passwordHint,
                  ),
                  validator: (value) =>
                      value != null && value.isNotEmpty && value.length < 8
                      ? l10n.newPassword
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFBE123C)),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : () => _save(l10n),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveChanges),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
