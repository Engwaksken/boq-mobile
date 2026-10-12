part of '../main.dart';

/// Formats an API amount string for display when it is numeric; otherwise the
/// raw string is shown unchanged.
String _displayBoqAmount(String raw, {String? currency}) {
  final value = num.tryParse(raw.trim());
  if (value == null) return raw;
  return formatAmount(
    value,
    currency: currency ?? '',
    decimals: value % 1 == 0 ? 0 : 2,
  );
}

/// Colour family for BOQ workflow statuses.
StatusTone _boqStatusTone(String status) {
  switch (status) {
    case 'uploaded':
      return StatusTone.info;
    case 'analysed':
    case 'under_review':
      return StatusTone.warning;
    case 'approved':
      return StatusTone.success;
    default:
      return StatusTone.forStatus(status);
  }
}

class BoqDetailPage extends StatefulWidget {
  const BoqDetailPage({
    super.key,
    required this.api,
    required this.boqId,
    required this.title,
  });
  final ApiClient api;
  final int boqId;
  final String title;

  @override
  State<BoqDetailPage> createState() => _BoqDetailPageState();
}

class _BoqDetailPageState extends State<BoqDetailPage> {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  Future<BoqDetail>? _boqDetail;
  Locale? _locale;
  late String _title = widget.title;
  bool _changed = false;

  Future<void> _edit() async {
    BoqDetail? boq;
    try {
      boq = await _boqDetail;
    } on Object {
      boq = null;
    }
    if (!mounted) return;
    final saved = await showEditBoqSheet(
      context,
      widget.api,
      BoqListItem(
        id: widget.boqId,
        name: boq?.name ?? _title,
        status: boq?.status ?? '',
        description: boq?.description ?? '',
        projectId: boq?.projectId ?? 0,
        projectName: '',
        itemsCount: 0,
        createdAt: '',
      ),
    );
    if (!saved || !mounted) return;
    _changed = true;
    await _reload();
    try {
      final fresh = await _boqDetail;
      if (mounted && fresh != null) setState(() => _title = fresh.name);
    } on Object {
      // The FutureBuilder shows the error; keep the current title.
    }
  }

  Future<void> _delete() async {
    if (await confirmDeleteBoq(context, widget.api, widget.boqId, _title) &&
        mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void initState() {
    super.initState();
    _boqDetail = widget.api.boqDetail(widget.boqId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context);
  }

  Future<void> _reload() async {
    final future = widget.api.boqDetail(widget.boqId);
    setState(() => _boqDetail = future);
    try {
      await future;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(result ?? _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          actions: [
            BoqShareMenu(api: widget.api, boqId: widget.boqId, title: _title),
            BoqActionsMenu(onEdit: _edit, onDelete: _delete),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'boq-share-${widget.boqId}',
          onPressed: () =>
              showBoqShareSheet(context, widget.api, widget.boqId, _title),
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.boqShareBoq),
        ),
        body: FutureBuilder<BoqDetail>(
          future: _boqDetail,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorState(error: snapshot.error, onRetry: _reload);
            }
            if (!snapshot.hasData) {
              return const LoadingState();
            }
            final boq = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.page.copyWith(bottom: 96),
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBoqHeader(boq, l10n),
                        const SizedBox(height: AppSpacing.lg),
                        BoqTotalsCard(
                          totals: boq.totals,
                          currency: boq.currency,
                          actions: [
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                if (await uploadBoqEstimates(
                                  context,
                                  widget.api,
                                  widget.boqId,
                                )) {
                                  _changed = true;
                                  _reload();
                                }
                              },
                              icon: const Icon(Icons.upload_file_outlined),
                              label: Text(l10n.boqUploadEstimates),
                            ),
                            TextButton.icon(
                              onPressed: () => shareBoqEstimatesTemplate(
                                context,
                                widget.api,
                                widget.boqId,
                                _title,
                              ),
                              icon: const Icon(Icons.download_outlined),
                              label: Text(l10n.boqTemplate),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSummaries(boq),
                        const SizedBox(height: AppSpacing.lg),
                        if (boq.metadata.isNotEmpty) ...[
                          _buildMetadataSection(boq),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        _buildHierarchy(boq),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBoqHeader(BoqDetail boq, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconTile(icon: Icons.receipt_long_outlined, size: 48),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(boq.name, style: theme.textTheme.titleLarge),
                      if (boq.code.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.boqCodeValue(boq.code),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  label: boq.status.capitalize(),
                  tone: _boqStatusTone(boq.status),
                ),
              ],
            ),
            if (boq.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                boq.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _infoChip(
                  Icons.payments_outlined,
                  '${boq.currency} ${boq.version}',
                ),
                if (boq.metadata['detected_language'] != null)
                  _infoChip(
                    Icons.translate,
                    boq.metadata['detected_language'].toString().toUpperCase(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaries(BoqDetail boq) {
    if (boq.summaries.isEmpty) {
      return Card(
        child: EmptyState(
          compact: true,
          icon: Icons.summarize_outlined,
          title: _l10n.boqNoSummaries,
          message: _l10n.boqNoSummariesMessage,
        ),
      );
    }
    final grandSummary = boq.summaries.firstWhere(
      (s) => s.summaryType == 'grand',
      orElse: () => boq.summaries.first,
    );
    String money(double value) =>
        formatAmount(value, currency: boq.currency, decimals: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighlightCard(
          label: _l10n.boqGrandTotal,
          value: money(grandSummary.grandTotal),
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: _l10n.boqSummary,
          icon: Icons.summarize_outlined,
          children: [
            KeyValueRow(
              label: _l10n.boqSubtotal,
              value: money(grandSummary.subtotal),
            ),
            KeyValueRow(label: _l10n.boqVat18, value: money(grandSummary.vat)),
            KeyValueRow(
              label: _l10n.boqContingency5,
              value: money(grandSummary.contingency),
            ),
            const Divider(height: AppSpacing.lg),
            KeyValueRow(
              label: _l10n.boqGrandTotal,
              value: money(grandSummary.grandTotal),
              emphasize: true,
            ),
            if (boq.summaries.length > 1) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: _l10n.boqBreakdown,
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              ),
              ...boq.summaries
                  .where((s) => s.summaryType != 'grand')
                  .map(_buildBreakdownItem),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(BoqCostSummary summary) {
    final theme = Theme.of(context);
    final money = NumberFormat('#,##0.00');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: summary.summaryType == 'facility'
                    ? Icons.apartment
                    : Icons.receipt_long,
                tone: summary.summaryType == 'facility'
                    ? StatusTone.info
                    : StatusTone.success,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  summary.name ?? summary.summaryType.capitalize(),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              StatusBadge(
                label: _l10n.boqItemsCount(
                  jsonInt(summary.metadata?['item_count']),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _miniSummary(
                  _l10n.boqSubtotal,
                  money.format(summary.subtotal),
                ),
              ),
              Expanded(
                child: _miniSummary(_l10n.boqVat, money.format(summary.vat)),
              ),
              Expanded(
                child: _miniSummary(
                  _l10n.boqTotal,
                  money.format(summary.grandTotal),
                  isTotal: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(BoqDetail boq) {
    final theme = Theme.of(context);
    final metadata = boq.metadata;
    final sheets = jsonMaps(metadata['import_sheets']);
    final translationSources = jsonMapOrNull(metadata['translation_sources']);
    return SectionCard(
      title: _l10n.boqImportMetadata,
      icon: Icons.info_outline,
      children: [
        if (sheets.isNotEmpty) ...[
          KeyValueRow(
            label: _l10n.boqSheets,
            value: '${sheets.length}',
            icon: Icons.table_chart_outlined,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...sheets.map<Widget>((sheet) {
            return Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xxl + 2,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                '• ${_l10n.boqSheetRows(jsonString(sheet['sheet_name']), jsonInt(sheet['rows_processed']))}',
                style: theme.textTheme.bodySmall,
              ),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (translationSources != null)
          KeyValueRow(
            label: _l10n.boqTranslations,
            value: translationSources.keys.join(', '),
            icon: Icons.translate,
          ),
      ],
    );
  }

  Widget _buildHierarchy(BoqDetail boq) {
    return SectionCard(
      title: _l10n.boqStructure,
      icon: Icons.account_tree_outlined,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      children: [
        if (boq.facilities.isEmpty)
          EmptyState(
            icon: Icons.account_tree_outlined,
            title: _l10n.boqNoHierarchy,
            message: _l10n.boqNoHierarchyMessage,
            compact: true,
          )
        else
          ...boq.facilities.map((facility) => _buildFacilityTile(facility, 0)),
      ],
    );
  }

  Widget _treeTile({
    required bool initiallyExpanded,
    required IconData icon,
    required StatusTone tone,
    required String title,
    required String? description,
    required List<Widget> children,
    bool bold = false,
  }) {
    final theme = Theme.of(context);
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      childrenPadding: const EdgeInsets.only(
        left: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      leading: IconTile(icon: icon, tone: tone, size: 36),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: description != null
          ? Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            )
          : null,
      children: children,
    );
  }

  Widget _buildFacilityTile(Facility facility, int depth) {
    return _treeTile(
      initiallyExpanded: depth == 0,
      icon: Icons.apartment,
      tone: StatusTone.info,
      title: _localizedName(facility.name, facility.nameTranslations),
      description: facility.description,
      bold: true,
      children: [
        ...facility.bills.map((bill) => _buildBillTile(bill, depth + 1)),
        if (facility.summaries.isNotEmpty) ...[
          const Divider(),
          ...facility.summaries.map((s) => _buildSummaryTile(s)),
        ],
      ],
    );
  }

  Widget _buildBillTile(Bill bill, int depth) {
    return _treeTile(
      initiallyExpanded: depth <= 1,
      icon: Icons.receipt_long,
      tone: StatusTone.success,
      title: _localizedName(bill.name, bill.nameTranslations),
      description: bill.description,
      children: [
        ...bill.elements.map(
          (element) => _buildElementTile(element, depth + 1),
        ),
        if (bill.summaries.isNotEmpty) ...[
          const Divider(),
          ...bill.summaries.map((s) => _buildSummaryTile(s)),
        ],
      ],
    );
  }

  Widget _buildElementTile(Element element, int depth) {
    return _treeTile(
      initiallyExpanded: depth <= 2,
      icon: Icons.category_outlined,
      tone: StatusTone.warning,
      title: _localizedName(element.name, element.nameTranslations),
      description: element.description,
      children: [
        if (element.items.isNotEmpty)
          ...element.items.map((item) => _buildItemTile(item)),
        if (element.subElements.isNotEmpty)
          ...element.subElements.map(
            (sub) => _buildSubElementTile(sub, depth + 1),
          ),
      ],
    );
  }

  Widget _buildSubElementTile(SubElement subElement, int depth) {
    return _treeTile(
      initiallyExpanded: false,
      icon: Icons.subdirectory_arrow_right,
      tone: StatusTone.brand,
      title: _localizedName(subElement.name, subElement.nameTranslations),
      description: subElement.description,
      children: subElement.items.map((item) => _buildItemTile(item)).toList(),
    );
  }

  Widget _buildItemTile(BoqItemSummary item) {
    final theme = Theme.of(context);
    return ListItemCard(
      margin: const EdgeInsets.only(
        right: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      leading: const IconTile(
        icon: Icons.format_list_numbered,
        tone: StatusTone.neutral,
        size: 36,
      ),
      title: item.description,
      subtitle: item.code.isNotEmpty ? _l10n.boqCodeValue(item.code) : null,
      footer: Row(
        children: [
          Expanded(
            child: _miniSummary(_l10n.boqQty, '${item.quantity} ${item.unit}'),
          ),
          Expanded(
            child: _miniSummary(
              _l10n.boqRate,
              _displayBoqAmount(item.currentRate),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_l10n.boqAmount, style: theme.textTheme.labelSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.amount,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BoqItemDetailPage(
            api: widget.api,
            itemId: item.id,
            boqId: widget.boqId,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(BoqCostSummary summary) {
    final theme = Theme.of(context);
    final money = NumberFormat('#,##0.00');
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      leading: Icon(
        Icons.summarize_outlined,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        '${summary.summaryType.capitalize()}: ${summary.name ?? ''}',
        style: theme.textTheme.titleSmall,
      ),
      trailing: Text(
        money.format(summary.grandTotal),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.success,
        ),
      ),
    );
  }

  Widget _miniSummary(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs + 2),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _localizedName(String name, Map<String, String>? translations) {
    if (translations != null && _locale != null) {
      return translations[_locale!.languageCode] ?? name;
    }
    return name;
  }
}

class BoqItemDetailPage extends StatefulWidget {
  const BoqItemDetailPage({
    super.key,
    required this.api,
    required this.itemId,
    required this.boqId,
  });
  final ApiClient api;
  final int itemId;
  final int boqId;

  @override
  State<BoqItemDetailPage> createState() => _BoqItemDetailPageState();
}

class _BoqItemDetailPageState extends State<BoqItemDetailPage> {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  Future<BoqItemDetail>? _itemDetail;

  @override
  void initState() {
    super.initState();
    _itemDetail = widget.api.boqItemDetail(widget.itemId);
  }

  Future<void> _reload() async {
    final future = widget.api.boqItemDetail(widget.itemId);
    setState(() => _itemDetail = future);
    try {
      await future;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.boqItemDetails)),
      body: FutureBuilder<BoqItemDetail>(
        future: _itemDetail,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const LoadingState();
          }
          final item = snapshot.data!;
          final hasPricing =
              item.originalRate != null ||
              item.aiSuggestedRate != null ||
              item.approvedRate != null ||
              item.pricingSource != null ||
              item.pricingDate != null;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.page,
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(item),
                      const SizedBox(height: AppSpacing.lg),
                      HighlightCard(
                        label: l10n.boqAmount,
                        value: _displayBoqAmount(
                          item.amount,
                          currency: item.currency,
                        ),
                        icon: Icons.payments_outlined,
                        footer: Text('${item.quantity} ${item.unit}'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        title: l10n.boqQuantityAmount,
                        icon: Icons.straighten_outlined,
                        children: [
                          _detailRow(
                            l10n.boqQuantity,
                            '${item.quantity} ${item.unit}',
                          ),
                          _detailRow(l10n.boqAmount, item.amount),
                        ],
                      ),
                      if (hasPricing) ...[
                        const SizedBox(height: AppSpacing.lg),
                        SectionCard(
                          title: l10n.boqPricing,
                          icon: Icons.sell_outlined,
                          children: [
                            if (item.originalRate != null)
                              _detailRow(
                                l10n.boqOriginalRate,
                                '${item.originalRate}',
                              ),
                            if (item.aiSuggestedRate != null)
                              _detailRow(
                                l10n.boqAiSuggestedRate,
                                l10n.boqAiRateValue(
                                  '${item.aiSuggestedRate}',
                                  item.aiConfidence?.toStringAsFixed(0) ?? '—',
                                ),
                              ),
                            if (item.approvedRate != null)
                              _detailRow(
                                l10n.boqApprovedRate,
                                '${item.approvedRate}',
                              ),
                            if (item.pricingSource != null)
                              _detailRow(
                                l10n.boqPricingSource,
                                item.pricingSource!,
                              ),
                            if (item.pricingDate != null)
                              _detailRow(
                                l10n.boqPricingDate,
                                displayDate(item.pricingDate),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        title: l10n.boqClassification,
                        icon: Icons.category_outlined,
                        children: [
                          _detailRow(
                            l10n.status,
                            item.status?.capitalize() ?? l10n.statusPending,
                          ),
                          if (item.workCategory != null)
                            _detailRow(
                              l10n.boqWorkCategory,
                              item.workCategory!,
                            ),
                          if (item.materialCategory != null)
                            _detailRow(
                              l10n.boqMaterialCategory,
                              item.materialCategory!,
                            ),
                          if (item.location != null)
                            _detailRow(l10n.location, item.location!),
                        ],
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        SectionCard(
                          title: l10n.boqNotes,
                          icon: Icons.sticky_note_2_outlined,
                          children: [Text(item.notes!)],
                        ),
                      ],
                      if (item.translations.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        SectionCard(
                          title: l10n.boqTranslations,
                          icon: Icons.translate,
                          children: item.translations
                              .map((t) => _translationTile(t))
                              .toList(),
                        ),
                      ],
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

  Widget _buildHeader(BoqItemDetail item) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IconTile(icon: Icons.format_list_numbered, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.description, style: theme.textTheme.titleLarge),
                  if (item.code.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _l10n.boqCodeValue(item.code),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (item.status != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    StatusBadge(
                      label: item.status!.capitalize(),
                      tone: StatusTone.forStatus(item.status),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _translationTile(BoqItemTranslation t) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StatusTone.info.background(theme.colorScheme),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              t.locale.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.info,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translatedDescription,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _l10n.boqTranslationMeta(
                    t.provider ?? _l10n.boqUnknown,
                    t.confidence?.toStringAsFixed(0) ?? 'N/A',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(
            label: t.status?.capitalize() ?? _l10n.statusPending,
            tone: t.status == 'accepted'
                ? StatusTone.success
                : StatusTone.warning,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return KeyValueRow(label: label, value: value);
  }
}
