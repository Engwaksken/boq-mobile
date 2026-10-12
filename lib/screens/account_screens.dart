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
  UserProfile? _user;

  /// Invited members must not see the account owner's billing (plans,
  /// subscriptions, top-ups); only roles with `subscriptions.view` may.
  bool get _canViewBilling => widget.api.can('subscriptions.view');

  @override
  void initState() {
    super.initState();
    _subscription = _canViewBilling
        ? widget.api.currentSubscription()
        : Future<Map<String, dynamic>>.value(const <String, dynamic>{});
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _loadOrNull(widget.api.profile);
    if (mounted && user != null) setState(() => _user = user);
  }

  Future<void> _changeAvatar() async {
    final updated = await changeProfilePicture(context, widget.api, _user);
    if (mounted && updated != null) setState(() => _user = updated);
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

  void _openPlans() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlansPage(
          api: widget.api,
          onSubscriptionCreated: _reloadSubscription,
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePage(
          api: widget.api,
          locale: widget.locale,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
    _loadUser();
  }

  Widget _profileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openProfile,
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            children: [
              ProfileAvatar(user: _user, size: 56, onEdit: _changeAvatar),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_user?.name.isNotEmpty ?? false)
                          ? _user!.name
                          : widget.l10n.profile,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_user?.email.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        _user!.email,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      widget.l10n.editProfile,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _managePlanButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.minTap),
      ),
      onPressed: _openPlans,
      icon: const Icon(Icons.workspace_premium_outlined),
      label: Text(widget.l10n.managePlan),
    );
  }

  Widget _subscriptionCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FutureBuilder<Map<String, dynamic>>(
      future: _subscription,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SectionCard(
            title: widget.l10n.subscription,
            icon: Icons.workspace_premium_outlined,
            children: [
              Row(
                children: [
                  const IconTile(
                    icon: Icons.info_outline,
                    tone: StatusTone.warning,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.l10n.acctNoActivePlan,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _managePlanButton(),
            ],
          );
        }
        if (snapshot.hasData) {
          final sub = snapshot.data!;
          final progress = _subscriptionProgress(sub);
          final daysRemaining = _daysRemaining(sub);
          final status = '${sub['status'] ?? 'N/A'}';
          final isTrial = status.toLowerCase() == 'trial';
          return SectionCard(
            title: widget.l10n.subscription,
            icon: Icons.workspace_premium_outlined,
            trailing: StatusBadge(
              label: isTrial
                  ? widget.l10n.acctTrialDays(7)
                  : status.toUpperCase(),
              tone: isTrial ? StatusTone.info : StatusTone.forStatus(status),
              icon: isTrial ? Icons.hourglass_top : Icons.verified_outlined,
            ),
            children: [
              Text(
                jsonStringOrNull(jsonMap(sub['plan'])['name']) ??
                    widget.l10n.acctNoActivePlan,
                style: theme.textTheme.titleLarge,
              ),
              if (daysRemaining != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  daysRemaining == 0
                      ? widget.l10n.acctExpiresToday
                      : widget.l10n.acctDaysRemaining(daysRemaining),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: daysRemaining <= 3
                        ? AppColors.warning
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              KeyValueRow(
                icon: Icons.document_scanner_outlined,
                label: widget.l10n.ocrPages,
                value: '${jsonMap(sub['plan'])['max_ocr_pages'] ?? 'N/A'}',
              ),
              const SizedBox(height: AppSpacing.md),
              _managePlanButton(),
            ],
          );
        }
        return const SectionCard(
          children: [
            SkeletonBox(width: 120, height: 16),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: 200, height: 22),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(height: 6),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: 160),
          ],
        );
      },
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      minTileHeight: 60,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: IconTile(icon: icon, size: 36),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        _reloadSubscription();
        try {
          await _subscription;
        } catch (_) {
          // The subscription card renders the error state.
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page,
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _profileHeader(context),
                if (_canViewBilling) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _subscriptionCard(context),
                ],
                const SizedBox(height: AppSpacing.sectionGap),
                SectionHeader(title: widget.l10n.acctSettings),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _settingsTile(
                        icon: Icons.language,
                        title: widget.l10n.language,
                        trailing: DropdownButton<Locale>(
                          value: widget.locale,
                          underline: const SizedBox(),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          onChanged: (value) {
                            if (value != null) widget.onLocaleChanged(value);
                          },
                          items: [
                            DropdownMenuItem(
                              value: const Locale('en'),
                              child: Text(widget.l10n.english),
                            ),
                            DropdownMenuItem(
                              value: const Locale('lg'),
                              child: Text(widget.l10n.luganda),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 68),
                      _settingsTile(
                        icon: Icons.notifications_outlined,
                        title: widget.l10n.notifications,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => NotificationsPage(api: widget.api),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 68),
                      _settingsTile(
                        icon: Icons.person_outline,
                        title: widget.l10n.profile,
                        onTap: _openProfile,
                      ),
                      // Only organisation admins and personal accounts may
                      // edit the company identity used on BOQ exports.
                      if (widget.api.canManageCompanyProfile) ...[
                        const Divider(height: 1, indent: 68),
                        _settingsTile(
                          icon: Icons.business_outlined,
                          title: widget.l10n.acctCompanyProfile,
                          subtitle: widget.l10n.acctCompanyProfileSubtitle,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CompanyProfilePage(api: widget.api),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                      color: theme.colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(widget.l10n.signOut),
                ),
              ],
            ),
          ),
        ],
      ),
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

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmPurchaseTitle),
        content: Text(l10n.confirmPurchaseMessage('${plan['name'] ?? ''}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.continueAction),
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
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.acctPaymentConfirmedActive,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.acctSubscriptionUpdated)));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final friendly = planLimitErrorMessage(l10n, e.errorCode);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly ?? e.message)));
    } finally {
      if (mounted) setState(() => _submittingPlanId = null);
    }
  }

  void _reloadPlans() {
    setState(() => _plans = widget.api.plans());
  }

  String _planPrice(Map<String, dynamic> plan) {
    final currency = '${plan['currency'] ?? 'UGX'}';
    final raw = plan['price'] ?? '0';
    final amount = raw is num ? raw : num.tryParse('$raw');
    if (amount == null) return '$currency $raw';
    return formatAmount(
      amount,
      currency: currency,
      decimals: amount % 1 == 0 ? 0 : 2,
    );
  }

  Widget _planCard(BuildContext context, Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final id = int.tryParse('${plan['id'] ?? ''}');
    final busy = id != null && _submittingPlanId == id;
    final l10n = AppLocalizations.of(context)!;
    final isOneTime = '${plan['type'] ?? ''}' == 'one_time';

    int? asInt(dynamic value) =>
        value is num ? value.toInt() : int.tryParse('$value');

    final hours = asInt(plan['duration_hours']);
    final days = asInt(plan['duration_days']);
    final maxProjects = asInt(plan['max_projects']);
    final maxBoqs = asInt(plan['max_boqs']);
    final maxAiCredits = asInt(plan['max_ai_credits']);
    final autoRenewal = plan['auto_renewal'];

    final limits = <(IconData, String)>[
      if (hours != null)
        (Icons.schedule_outlined, l10n.validityHours(hours))
      else if (days != null)
        (Icons.schedule_outlined, l10n.validityDays(days)),
      if (maxProjects != null)
        (Icons.folder_outlined, l10n.maxProjectsLabel(maxProjects)),
      if (maxBoqs != null)
        (Icons.receipt_long_outlined, l10n.maxBoqsLabel(maxBoqs)),
      if (isOneTime && maxAiCredits != null)
        (Icons.auto_awesome_outlined, l10n.maxAiCreditsLabel(maxAiCredits)),
    ];

    final checks = <String>[
      if (isOneTime) ...[
        l10n.featureHardwareFactoryPrices,
        l10n.featurePdfExcelExport,
        l10n.featureCompanyBranding,
        if (maxAiCredits == null) l10n.featureLimitedAiCredits,
      ],
      if (autoRenewal == false) l10n.noRecurringPayment,
      if (autoRenewal == true) l10n.renewsAutomatically,
    ];
    final seen = checks.map((c) => c.toLowerCase()).toSet();
    final rawFeatures = jsonList(plan['features'] ?? plan['included_features']);
    for (final raw in rawFeatures) {
      final feature =
          (raw is Map ? '${raw['name'] ?? raw['code'] ?? ''}' : '$raw').trim();
      if (feature.isEmpty) continue;
      if (feature.toLowerCase().contains('credit')) continue;
      if (seen.add(feature.toLowerCase())) checks.add(feature);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(
            color: busy ? scheme.primary : scheme.outlineVariant,
            width: busy ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: AppSpacing.card,
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconTile(icon: Icons.workspace_premium_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plan['name'] ?? ''}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _planPrice(plan),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOneTime)
                    StatusBadge(
                      label: l10n.oneTimeBadge,
                      tone: StatusTone.brand,
                      icon: Icons.bolt_outlined,
                    )
                  else if (plan['trial_days'] != null)
                    StatusBadge(
                      label: l10n.acctTrialDays(jsonInt(plan['trial_days'])),
                      tone: StatusTone.info,
                      icon: Icons.hourglass_top,
                    ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isOneTime) ...[
                    Text(
                      l10n.oneTimeSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if ('${plan['description'] ?? ''}'.trim().isNotEmpty) ...[
                    Text(
                      '${plan['description']}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (limits.isNotEmpty) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final (icon, label) in limits)
                          StatusBadge(
                            label: label,
                            tone: StatusTone.brand,
                            icon: icon,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ...checks.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              feature,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LoadingButton(
                    label: isOneTime ? l10n.buyOneTimeAccess : l10n.selectPlan,
                    icon: Icons.arrow_forward,
                    loading: busy,
                    onPressed: () => _selectPlan(plan),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            return ErrorState(
              error: l10n.acctPlansLoadError,
              onRetry: _reloadPlans,
            );
          }
          if (!snapshot.hasData) {
            return const SkeletonList(itemCount: 3);
          }
          final indexed =
              [
                for (var i = 0; i < snapshot.data!.length; i++)
                  (
                    order:
                        int.tryParse(
                          '${snapshot.data![i]['display_order'] ?? ''}',
                        ) ??
                        0,
                    index: i,
                    plan: snapshot.data![i],
                  ),
              ]..sort((a, b) {
                final byOrder = a.order.compareTo(b.order);
                return byOrder != 0 ? byOrder : a.index.compareTo(b.index);
              });
          final plans = [for (final entry in indexed) entry.plan];
          return RefreshIndicator(
            onRefresh: () async {
              _reloadPlans();
              try {
                await _plans;
              } catch (_) {
                // The error state is rendered by the builder.
              }
            },
            child: plans.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.page,
                    children: [
                      const SizedBox(height: AppSpacing.xxxl),
                      EmptyState(
                        icon: Icons.workspace_premium_outlined,
                        title: l10n.acctNoPlans,
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.page,
                    itemCount: plans.length,
                    itemBuilder: (context, index) =>
                        ContentWidth(child: _planCard(context, plans[index])),
                  ),
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

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  int? get _subscriptionId =>
      int.tryParse('${widget.subscription['id'] ?? ''}');

  Map<String, dynamic>? get _transaction =>
      jsonMapOrNull(_paymentData?['transaction']);

  Map<String, dynamic>? get _gatewayResult =>
      jsonMapOrNull(_paymentData?['gateway']);

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_l10n.acctPaymentStarted)));
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
        title: Text(_l10n.acctPaymentConfirmed),
        content: Text(_l10n.acctSubscriptionActivated),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_l10n.continueAction),
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
                  ? _l10n.acctPaymentUnderReview
                  : _l10n.acctPaymentStatusValue(
                      status.isEmpty ? _l10n.statusPending : status,
                    ),
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
    } on Object catch (e) {
      // Polling runs from a timer: never let an error escape uncaught.
      if (!mounted || silent) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  Widget _detailLine(String label, dynamic value, {bool selectable = true}) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: selectable
                ? SelectableText('$value', style: valueStyle)
                : Text('$value', style: valueStyle),
          ),
        ],
      ),
    );
  }

  Widget _receiptCard() {
    final receipt = _receipt;
    if (receipt == null || receipt.isEmpty) return const SizedBox.shrink();
    final currency = '${receipt['currency'] ?? ''}';
    final total = receipt['total_amount'] ?? receipt['amount'] ?? '';
    return SectionCard(
      title: _l10n.acctPaymentReceipt,
      icon: Icons.receipt_long_outlined,
      children: [
        _detailLine(_l10n.acctInvoice, receipt['invoice_number'] ?? ''),
        _detailLine(
          _l10n.acctReference,
          receipt['transaction_reference'] ?? _transaction?['reference'] ?? '',
        ),
        _detailLine(_l10n.acctAmount, '$currency $total', selectable: false),
        if (receipt['payment_date'] != null)
          _detailLine(
            _l10n.acctPaid,
            receipt['payment_date'],
            selectable: false,
          ),
      ],
    );
  }

  Widget _gatewayInstructions() {
    final gateway = _gatewayResult;
    if (gateway == null || gateway.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];

    void addRow(String label, dynamic value) {
      if (value == null || '$value'.trim().isEmpty) return;
      rows.add(_detailLine(label, value));
    }

    addRow(_l10n.acctReference, gateway['transaction_reference']);
    addRow(_l10n.acctProvider, gateway['provider']);
    addRow(_l10n.acctPhone, gateway['phone']);
    addRow(_l10n.acctMode, gateway['mode']);
    addRow(_l10n.acctInstructions, gateway['instructions']);

    final checkoutUrl = '${gateway['checkout_url'] ?? ''}'.trim();
    if (checkoutUrl.isNotEmpty) {
      rows.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const IconTile(icon: Icons.link, size: 36),
          title: Text(_l10n.acctCheckoutUrl),
          subtitle: SelectableText(checkoutUrl),
          trailing: Wrap(
            spacing: 2,
            children: [
              IconButton(
                tooltip: _l10n.acctOpenCheckout,
                onPressed: () async {
                  final uri = Uri.tryParse(checkoutUrl);
                  if (uri == null ||
                      !await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_l10n.acctCheckoutOpenFailed)),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
              ),
              IconButton(
                tooltip: _l10n.acctCopy,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: checkoutUrl));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_l10n.acctCheckoutCopied)),
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
      addRow(_l10n.acctBankDetails, bankDetails);
    }

    return SectionCard(
      title: _l10n.acctPaymentInstructions,
      icon: Icons.fact_check_outlined,
      children: rows,
    );
  }

  String _formatPlanPrice(Map<String, dynamic> plan) {
    final currency = '${plan['currency'] ?? 'UGX'}';
    final raw = plan['price'] ?? '0';
    final amount = raw is num ? raw : num.tryParse('$raw');
    if (amount == null) return '$currency $raw';
    return formatAmount(
      amount,
      currency: currency,
      decimals: amount % 1 == 0 ? 0 : 2,
    );
  }

  BannerTone _statusBannerTone(String status) {
    switch (StatusTone.forStatus(status)) {
      case StatusTone.success:
        return BannerTone.success;
      case StatusTone.danger:
        return BannerTone.error;
      case StatusTone.warning:
        return BannerTone.warning;
      default:
        return status.toLowerCase() == 'under_review'
            ? BannerTone.warning
            : BannerTone.info;
    }
  }

  Widget _summaryCard(
    BuildContext context,
    Map<String, dynamic> plan,
    Map<String, dynamic>? transaction,
    String status,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subscriptionStatus = '${widget.subscription['status'] ?? 'pending'}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: AppSpacing.card,
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconTile(icon: Icons.shopping_bag_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${plan['name'] ?? _l10n.acctSubscriptionPlan}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatPlanPrice(plan),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _badgeRow(
                  context,
                  _l10n.acctSubscriptionStatus,
                  subscriptionStatus,
                ),
                if (transaction != null) ...[
                  const Divider(height: AppSpacing.lg),
                  KeyValueRow(
                    label: _l10n.acctTransaction,
                    value:
                        '${transaction['reference'] ?? transaction['id'] ?? ''}',
                  ),
                  _badgeRow(context, _l10n.paymentStatus, status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          StatusBadge(label: value, tone: StatusTone.forStatus(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = _l10n;
    final plan = jsonMap(widget.subscription['plan']);
    final transaction = _transaction;
    final status = '${transaction?['status'] ?? l10n.acctNotStarted}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.acctCompletePayment)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gateways,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              error: l10n.acctGatewaysLoadError,
              onRetry: () =>
                  setState(() => _gateways = widget.api.paymentGateways()),
            );
          }
          if (!snapshot.hasData) {
            return const LoadingState();
          }
          final gateways = snapshot.data!;
          return ListView(
            padding: AppSpacing.page,
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _summaryCard(context, plan, transaction, status),
                    if (_paymentData != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      InfoBanner(
                        tone: _statusBannerTone(status),
                        title: l10n.acctPaymentStatusValue(status),
                        message: l10n.acctPaymentActivationNote,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sectionGap),
                    if (gateways.isEmpty)
                      InfoBanner(
                        tone: BannerTone.warning,
                        message: l10n.acctNoGateways,
                      )
                    else ...[
                      SectionHeader(title: l10n.acctChoosePaymentMethod),
                      RadioGroup<String>(
                        groupValue: _selectedGatewayCode,
                        onChanged: (value) {
                          if (_paymentData != null || value == null) return;
                          final gateway = gateways.firstWhere(
                            (g) => '${g['code'] ?? ''}' == value,
                            orElse: () => const <String, dynamic>{},
                          );
                          final methods = jsonList(gateway['supported_methods'])
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
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  color: selected
                                      ? scheme.primaryContainer.withValues(
                                          alpha: 0.35,
                                        )
                                      : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadii.card,
                                    side: BorderSide(
                                      color: selected
                                          ? scheme.primary
                                          : scheme.outlineVariant,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: RadioListTile<String>(
                                    value: code,
                                    enabled: _paymentData == null,
                                    title: Text(
                                      '${gateway['name'] ?? code}',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    subtitle: Text(
                                      '${gateway['description'] ?? gateway['driver'] ?? ''}'
                                      '${gateway['is_aggregator'] == true ? ' • ${l10n.acctAggregator}' : ''}'
                                      '${gateway['is_test_mode'] == true ? ' • ${l10n.acctTestMode}' : ''}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    secondary: IconTile(
                                      icon: selected
                                          ? Icons.check_circle
                                          : Icons.payments_outlined,
                                      tone: selected
                                          ? StatusTone.success
                                          : StatusTone.brand,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      if (_selectedGatewayCode != null &&
                          _paymentData == null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Builder(
                          builder: (context) {
                            final selected = gateways.firstWhere(
                              (g) =>
                                  '${g['code'] ?? ''}' == _selectedGatewayCode,
                              orElse: () => const <String, dynamic>{},
                            );
                            final methods =
                                jsonList(selected['supported_methods'])
                                    .map((e) => '$e')
                                    .where((e) => e.trim().isNotEmpty)
                                    .toList();
                            final driver = '${selected['driver'] ?? ''}';
                            final isAggregator =
                                selected['is_aggregator'] == true;
                            final effectiveMethod =
                                methods.contains(_selectedMethod)
                                ? _selectedMethod
                                : (methods.isNotEmpty ? methods.first : null);
                            final aggregatorMobile =
                                isAggregator &&
                                !['card', 'visa', 'mastercard'].contains(
                                  (effectiveMethod ?? '').toLowerCase(),
                                );
                            final needsPhone =
                                driver == 'mtn_momo' ||
                                driver == 'airtel_money' ||
                                aggregatorMobile;
                            return SectionCard(
                              title: l10n.acctPaymentDetails,
                              icon: Icons.lock_outline,
                              children: [
                                if (needsPhone) ...[
                                  TextField(
                                    controller: _phoneNumber,
                                    keyboardType: TextInputType.phone,
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      labelText: driver == 'mtn_momo'
                                          ? l10n.acctMtnNumber
                                          : driver == 'airtel_money'
                                          ? l10n.acctAirtelNumber
                                          : l10n.acctMobileMoneyNumber,
                                      hintText: l10n.acctPhoneHint,
                                      prefixIcon: const Icon(
                                        Icons.phone_android,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                if (methods.length > 1)
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(
                                      'method-$_selectedGatewayCode-$effectiveMethod',
                                    ),
                                    initialValue:
                                        methods.contains(_selectedMethod)
                                        ? _selectedMethod
                                        : methods.first,
                                    decoration: InputDecoration(
                                      labelText: l10n.acctPaymentOption,
                                      prefixIcon: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                      ),
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
                                if (methods.length > 1)
                                  const SizedBox(height: AppSpacing.md),
                                LoadingButton(
                                  label: l10n.acctContinueToPayment,
                                  icon: Icons.lock_outline,
                                  loading: _initiating,
                                  onPressed:
                                      needsPhone &&
                                          _phoneNumber.text.trim().isEmpty
                                      ? null
                                      : () => _initiate(selected),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                    if (_paymentData != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _gatewayInstructions(),
                      if (_receipt != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _receiptCard(),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(
                                  AppSizes.buttonHeight,
                                ),
                              ),
                              onPressed: _refreshTransaction,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                l10n.acctRefreshStatus,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: LoadingButton(
                              label: l10n.acctVerifyPayment,
                              icon: Icons.verified_outlined,
                              loading: _verifying,
                              onPressed: _verify,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
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
  final _currentPassword = TextEditingController();
  late final Future<UserProfile> _profile = widget.api.profile();
  late String _selectedLocale = widget.locale.languageCode;
  bool _loaded = false;
  bool _saving = false;
  String? _error;
  UserProfile? _current;

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
    final bool available;
    final bool enabled;
    final List<BiometricType> biometrics;
    try {
      available = await _biometricService.isBiometricAvailable();
      enabled = await _biometricService.isBiometricEnabled();
      biometrics = await _biometricService.getAvailableBiometrics();
    } on Object {
      return; // Leave biometrics shown as unavailable.
    }
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
    _currentPassword.dispose();
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
        currentPassword: _currentPassword.text,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: FutureBuilder<UserProfile>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error);
          }
          if (!snapshot.hasData) {
            return const LoadingState();
          }

          final profile = snapshot.data!;
          if (!_loaded) {
            _loaded = true;
            _current = profile;
            _name.text = profile.name;
            _email.text = profile.email;
            _phone.text = profile.phone ?? '';
            _location.text = profile.location ?? '';
            _selectedLocale = profile.locale;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.page,
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ProfileAvatar(
                          user: _current,
                          size: 96,
                          onEdit: () async {
                            final updated = await changeProfilePicture(
                              context,
                              widget.api,
                              _current,
                            );
                            if (mounted && updated != null) {
                              setState(() => _current = updated);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final updated = await changeProfilePicture(
                              context,
                              widget.api,
                              _current,
                            );
                            if (mounted && updated != null) {
                              setState(() => _current = updated);
                            }
                          },
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(
                            _current?.avatarUrl == null
                                ? l10n.acctAddPhoto
                                : l10n.acctChangePhoto,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        title: l10n.acctPersonalDetails,
                        icon: Icons.person_outline,
                        spacing: AppSpacing.lg,
                        children: [
                          TextFormField(
                            controller: _name,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.fullName,
                              prefixIcon: const Icon(Icons.badge_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? l10n.acctNameRequired
                                : null,
                          ),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.email,
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator: (value) =>
                                value == null || !value.contains('@')
                                ? l10n.commonInvalidEmail
                                : null,
                          ),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.phoneNumber,
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                          TextFormField(
                            controller: _location,
                            decoration: InputDecoration(
                              labelText: l10n.location,
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        title: l10n.language,
                        icon: Icons.language,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedLocale,
                            decoration: InputDecoration(
                              labelText: l10n.language,
                              prefixIcon: const Icon(Icons.translate),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(l10n.english),
                              ),
                              DropdownMenuItem(
                                value: 'lg',
                                child: Text(l10n.luganda),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedLocale = value);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Biometric section
                      SectionCard(
                        title: l10n.enableBiometricLogin,
                        icon: Icons.fingerprint,
                        children: [
                          Text(
                            _biometricAvailable
                                ? '${l10n.biometricAvailable} - ${l10n.biometricTypes}${_availableBiometrics.map((t) => _biometricService.getBiometricTypeName(t, l10n)).join(', ')}'
                                : l10n.biometricNotAvailable,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.enableBiometricLogin),
                            subtitle: Text(l10n.biometricLoginDescription),
                            value: _biometricEnabled,
                            onChanged: _biometricAvailable
                                ? _toggleBiometric
                                : null,
                            secondary: IconTile(
                              icon: _biometricAvailable
                                  ? Icons.fingerprint
                                  : Icons.fingerprint_outlined,
                              tone: _biometricAvailable
                                  ? StatusTone.brand
                                  : StatusTone.neutral,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        title: l10n.acctSecurity,
                        icon: Icons.lock_outline,
                        children: [
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: l10n.newPassword,
                              helperText: l10n.passwordHint,
                              prefixIcon: const Icon(Icons.key_outlined),
                            ),
                            validator: (value) =>
                                value != null &&
                                    value.isNotEmpty &&
                                    value.length < 8
                                ? l10n.passwordTooShort
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _currentPassword,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: l10n.currentPassword,
                              helperText: l10n.currentPasswordHint,
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              final emailChanged =
                                  _email.text.trim().toLowerCase() !=
                                  (_current?.email ?? '').toLowerCase();
                              final passwordChanged = _password.text.isNotEmpty;
                              return (emailChanged || passwordChanged) &&
                                      (value == null || value.isEmpty)
                                  ? l10n.currentPasswordRequired
                                  : null;
                            },
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        InfoBanner(message: _error!),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      LoadingButton(
                        label: l10n.saveChanges,
                        icon: Icons.save_outlined,
                        loading: _saving,
                        onPressed: () => _save(l10n),
                      ),
                    ],
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

/// Round profile picture with an initials fallback and an edit badge.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.user,
    this.size = 56,
    this.onEdit,
  });

  final UserProfile? user;
  final double size;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = user?.avatarUrl;
    final placeholder = Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      alignment: Alignment.center,
      child: user == null
          ? Icon(Icons.person, color: Colors.white, size: size * 0.54)
          : Text(
              user!.initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    final avatar = SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: url == null
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder,
              ),
      ),
    );

    if (onEdit == null) return avatar;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.acctChangePhoto,
      child: GestureDetector(
        onTap: onEdit,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.all(size > 70 ? 7 : 4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera,
                  size: size > 70 ? 18 : 12,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the user take, choose or remove a profile photo. Returns the updated
/// profile, or null when nothing changed.
Future<UserProfile?> changeProfilePicture(
  BuildContext context,
  ApiClient api,
  UserProfile? current,
) async {
  final l10n = AppLocalizations.of(context)!;
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.acctTakePhoto),
            onTap: () => Navigator.pop(sheetContext, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.acctChooseGallery),
            onTap: () => Navigator.pop(sheetContext, 'gallery'),
          ),
          if (current?.avatarUrl != null)
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: Text(l10n.acctRemovePhoto),
              onTap: () => Navigator.pop(sheetContext, 'remove'),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;

  final messenger = ScaffoldMessenger.of(context);
  void show(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  try {
    if (choice == 'remove') {
      final updated = await api.deleteAvatar();
      show(l10n.acctPhotoRemoved);
      return updated;
    }

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.front,
        // Matches the server's profile picture size.
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
        requestFullMetadata: false,
      );
    } on Object {
      show(choice == 'camera' ? l10n.acctCameraDenied : l10n.acctPhotosDenied);
      return null;
    }
    if (picked == null) return null;

    show(l10n.acctPhotoUploading);
    final updated = await api.uploadAvatar(
      bytes: await picked.readAsBytes(),
      fileName: 'avatar.jpg',
    );
    show(l10n.acctPhotoUpdated);
    return updated;
  } on Object catch (error) {
    show(friendlyError(error));
    return null;
  }
}
