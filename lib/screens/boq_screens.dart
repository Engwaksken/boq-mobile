part of '../main.dart';

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
  Future<BoqDetail>? _boqDetail;
  Locale? _locale;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          BoqShareMenu(
            api: widget.api,
            boqId: widget.boqId,
            title: widget.title,
          ),
        ],
      ),
      body: FutureBuilder<BoqDetail>(
        future: _boqDetail,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final boq = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBoqHeader(boq, l10n),
              const SizedBox(height: 16),
              _buildSummaries(boq),
              const SizedBox(height: 16),
              if (boq.metadata.isNotEmpty) ...[
                _buildMetadataSection(boq),
                const SizedBox(height: 16),
              ],
              _buildHierarchy(boq),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBoqHeader(BoqDetail boq, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    boq.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _statusChip(boq.status),
              ],
            ),
            const SizedBox(height: 8),
            if (boq.code.isNotEmpty)
              Text(
                'Code: ${boq.code}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            if (boq.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(boq.description),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(Icons.attach_money, '${boq.currency} ${boq.version}'),
                const SizedBox(width: 12),
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
    final money = NumberFormat('#,##0.00');
    final grandSummary = boq.summaries.firstWhere(
      (s) => s.summaryType == 'grand',
      orElse: () => boq.summaries.first,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _summaryRow(
              'Subtotal',
              '${boq.currency} ${money.format(grandSummary.subtotal)}',
            ),
            _summaryRow(
              'VAT (18%)',
              '${boq.currency} ${money.format(grandSummary.vat)}',
            ),
            _summaryRow(
              'Contingency (5%)',
              '${boq.currency} ${money.format(grandSummary.contingency)}',
            ),
            const Divider(),
            _summaryRow(
              'Grand Total',
              '${boq.currency} ${money.format(grandSummary.grandTotal)}',
              isTotal: true,
            ),
            if (boq.summaries.length > 1) ...[
              const SizedBox(height: 16),
              Text(
                'Breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...boq.summaries
                  .where((s) => s.summaryType != 'grand')
                  .map((s) => _buildBreakdownItem(s, money)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(BoqCostSummary summary, NumberFormat money) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  summary.summaryType == 'facility'
                      ? Icons.apartment
                      : Icons.receipt_long,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.name ?? summary.summaryType.capitalize(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${summary.metadata?['item_count'] ?? 0} items',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniSummary('Subtotal', money.format(summary.subtotal)),
                _miniSummary('VAT', money.format(summary.vat)),
                _miniSummary(
                  'Total',
                  money.format(summary.grandTotal),
                  isTotal: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BoqDetail boq) {
    final metadata = boq.metadata;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Metadata',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (metadata['import_sheets'] != null) ...[
              Text(
                'Sheets: ${(metadata['import_sheets'] as List).length}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ...(metadata['import_sheets'] as List).map<Widget>((sheet) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text(
                    '• ${sheet['sheet_name']} (${sheet['rows_processed']} rows)',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            if (metadata['translation_sources'] != null) ...[
              Text(
                'Translations: ${(metadata['translation_sources'] as Map).keys.join(', ')}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchy(BoqDetail boq) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BOQ Structure',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (boq.facilities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No hierarchy data available. Process the BOQ to generate structure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...boq.facilities.map(
                (facility) => _buildFacilityTile(facility, 0),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityTile(Facility facility, int depth) {
    return ExpansionTile(
      initiallyExpanded: depth == 0,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
        child: const Icon(Icons.apartment, color: Color(0xFF1D4ED8), size: 20),
      ),
      title: Text(
        _localizedName(facility.name, facility.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: facility.description != null
          ? Text(
              facility.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
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
    return ExpansionTile(
      initiallyExpanded: depth <= 1,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF047857).withValues(alpha: 0.12),
        child: const Icon(
          Icons.receipt_long,
          color: Color(0xFF047857),
          size: 18,
        ),
      ),
      title: Text(
        _localizedName(bill.name, bill.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: bill.description != null
          ? Text(
              bill.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
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
    return ExpansionTile(
      initiallyExpanded: depth <= 2,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFB45309).withValues(alpha: 0.12),
        child: const Icon(Icons.category, color: Color(0xFFB45309), size: 18),
      ),
      title: Text(
        _localizedName(element.name, element.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: element.description != null
          ? Text(
              element.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
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
    return ExpansionTile(
      initiallyExpanded: false,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
        child: const Icon(
          Icons.subdirectory_arrow_right,
          color: Color(0xFF7C3AED),
          size: 18,
        ),
      ),
      title: Text(
        _localizedName(subElement.name, subElement.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subElement.description != null
          ? Text(
              subElement.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      children: subElement.items.map((item) => _buildItemTile(item)).toList(),
    );
  }

  Widget _buildItemTile(BoqItemSummary item) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      leading: const Icon(
        Icons.format_list_numbered,
        size: 18,
        color: Colors.grey,
      ),
      title: Text(
        item.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: item.code.isNotEmpty ? Text('Code: ${item.code}') : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${item.quantity} ${item.unit}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            item.amount,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
    final money = NumberFormat('#,##0.00');
    return ListTile(
      dense: true,
      leading: const Icon(Icons.summarize, size: 18, color: Colors.grey),
      title: Text(
        '${summary.summaryType.capitalize()}: ${summary.name ?? ''}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        money.format(summary.grandTotal),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF047857),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? const Color(0xFF047857) : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniSummary(String label, String value, {bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 14 : 12,
            color: isTotal ? const Color(0xFF047857) : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'uploaded':
        color = Colors.blue;
        break;
      case 'analysed':
        color = Colors.orange;
        break;
      case 'under_review':
        color = Colors.amber;
        break;
      case 'approved':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.capitalize(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
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
  Future<BoqItemDetail>? _itemDetail;

  @override
  void initState() {
    super.initState();
    _itemDetail = widget.api.boqItemDetail(widget.itemId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BOQ Item Details')),
      body: FutureBuilder<BoqItemDetail>(
        future: _itemDetail,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(friendlyError(snapshot.error)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (item.code.isNotEmpty)
                        Text(
                          'Code: ${item.code}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 16),
                      _detailRow('Quantity', '${item.quantity} ${item.unit}'),
                      _detailRow('Amount', item.amount),
                      if (item.originalRate != null)
                        _detailRow('Original Rate', '${item.originalRate}'),
                      if (item.aiSuggestedRate != null)
                        _detailRow(
                          'AI Suggested Rate',
                          '${item.aiSuggestedRate} (confidence: ${item.aiConfidence?.toStringAsFixed(0)}%)',
                        ),
                      if (item.approvedRate != null)
                        _detailRow('Approved Rate', '${item.approvedRate}'),
                      _detailRow('Status', item.status!.capitalize()),
                      if (item.workCategory != null)
                        _detailRow('Work Category', item.workCategory!),
                      if (item.materialCategory != null)
                        _detailRow('Material Category', item.materialCategory!),
                      if (item.location != null)
                        _detailRow('Location', item.location!),
                      if (item.pricingSource != null)
                        _detailRow('Pricing Source', item.pricingSource!),
                      if (item.pricingDate != null)
                        _detailRow('Pricing Date', item.pricingDate!),
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Notes',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(item.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              if (item.translations.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Translations',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ...item.translations.map((t) => _translationTile(t)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _translationTile(BoqItemTranslation t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Text(
            t.locale.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(t.translatedDescription),
        subtitle: Text(
          'Provider: ${t.provider ?? 'unknown'}  |  Confidence: ${t.confidence?.toStringAsFixed(0) ?? 'N/A'}%',
        ),
        trailing: Text(
          t.status!.capitalize(),
          style: TextStyle(
            color: t.status == 'accepted' ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
