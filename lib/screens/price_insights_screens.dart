part of '../main.dart';

// Price history and comparisons, matching the web pages:
// - MonthlyPriceHistoryCard: one market price summarised per month (on its detail page)
// - PriceChangesPage: the latest change of every visible price
// - BoqPriceCheckPage: a BOQ's rates against today's market, with each item's rate history
// - PlanPriceHistoryPage: changes to subscription plan prices

/// "+1,250" / "-1,250" / "0".
String _piSigned(double value, {int decimals = 0}) {
  final pattern = decimals > 0 ? '#,##0.${'0' * decimals}' : '#,##0';
  final text = NumberFormat(pattern, 'en_US').format(value.abs());
  if (value > 0) return '+$text';
  if (value < 0) return '-$text';
  return text;
}

/// "+4.2%" / "-4.2%".
String _piPercent(double value) =>
    '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}%';

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}

bool _piIsZero(double? value) => value == null || value.abs() < 0.005;

/// Increases are red (costs went up), decreases green, no change muted.
Color _piChangeColor(BuildContext context, double? value) => _piIsZero(value)
    ? Theme.of(context).colorScheme.onSurfaceVariant
    : value! > 0
    ? AppColors.danger
    : AppColors.success;

/// "Nov 2026" from "2026-11".
String _piMonth(String month, {String pattern = 'MMM yyyy'}) =>
    displayDate('$month-01', pattern: pattern);

/// Opens a market price's detail page by id (loads it first).
Future<void> _piOpenMarketPrice(
  BuildContext context,
  ApiClient api,
  int id,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    final price = await api.hardwarePrice(id);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            HardwarePriceDetailPage(api: api, hardwarePrice: price, l10n: l10n),
      ),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
  }
}

/// An amount change with an arrow, e.g. "↑ +4,000 (+11.1%)".
class _PiChange extends StatelessWidget {
  const _PiChange({
    required this.value,
    this.percent,
    this.style,
    this.asPercent = false,
  });

  final double? value;
  final double? percent;
  final TextStyle? style;

  /// [value] is itself a percentage ("+4.2%").
  final bool asPercent;

  @override
  Widget build(BuildContext context) {
    final color = _piChangeColor(context, value);
    final base = (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (value == null) return Text('—', style: base);
    if (_piIsZero(value)) {
      return Text(context.tr.piNoChange, style: base);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          value! > 0 ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            asPercent
                ? _piPercent(value!)
                : '${_piSigned(value!)}'
                      '${percent != null ? ' (${_piPercent(percent!)})' : ''}',
            style: base,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly market history (on the hardware price detail page)
// ---------------------------------------------------------------------------

class MonthlyPriceHistoryCard extends StatefulWidget {
  const MonthlyPriceHistoryCard({
    super.key,
    required this.api,
    required this.hardwarePriceId,
  });

  final ApiClient api;
  final int hardwarePriceId;

  @override
  State<MonthlyPriceHistoryCard> createState() =>
      _MonthlyPriceHistoryCardState();
}

class _MonthlyPriceHistoryCardState extends State<MonthlyPriceHistoryCard> {
  static const _monthOptions = [6, 12, 24];
  int _months = 12;
  late Future<MonthlyPriceHistory> _future = _load();

  Future<MonthlyPriceHistory> _load() =>
      widget.api.hardwarePriceMonthly(widget.hardwarePriceId, months: _months);

  void _setMonths(int months) {
    setState(() {
      _months = months;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.tr;
    return SectionCard(
      title: l.piMonthlyHistory,
      icon: Icons.calendar_month_outlined,
      children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (final months in _monthOptions)
              ButtonSegment(
                value: months,
                label: Text(l.piMonthsCount(months)),
              ),
          ],
          selected: {_months},
          onSelectionChanged: (selection) => _setMonths(selection.first),
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<MonthlyPriceHistory>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorState(
                error: snapshot.error,
                compact: true,
                onRetry: () => _setMonths(_months),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final history = snapshot.data!;
            if (history.trend.isEmpty) {
              return EmptyState(
                icon: Icons.calendar_month_outlined,
                title: l.piNoPricesPeriod,
                compact: true,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _latest(context, history),
                if (history.trend.length >= 2) ...[
                  const SizedBox(height: AppSpacing.md),
                  _MonthlyTrendChart(
                    points: history.trend,
                    currency: history.item.currency,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                for (final month in history.months)
                  _MonthRow(month: month, currency: history.item.currency),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _latest(BuildContext context, MonthlyPriceHistory history) {
    final latest = history.latestChange ?? history.trend.last;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.piLatestMonth(
            _piMonth(latest.month, pattern: 'MMMM yyyy'),
            formatAmount(latest.average, currency: history.item.currency),
          ),
          style: theme.textTheme.titleSmall,
        ),
        if (latest.change != null) ...[
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            children: [
              _PiChange(value: latest.change, percent: latest.changePercent),
              Text(
                context.tr.piVsPreviousMonth,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month, required this.currency});

  final MonthlyPrice month;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.tr;
    final muted = theme.textTheme.bodySmall;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_piMonth(month.month), style: theme.textTheme.titleSmall),
                Text(l.piRecords(month.records), style: muted),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: month.records == 0
                ? Text(l.piNoPricesMonth, style: muted)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l.piAvg} ${formatAmount(month.average, currency: currency)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${l.piLow} ${formatAmount(month.low, currency: '')} · '
                        '${l.piHigh} ${formatAmount(month.high, currency: '')} · '
                        '${l.piMonthEnd} ${formatAmount(month.closing, currency: '')}',
                        style: muted,
                      ),
                    ],
                  ),
          ),
          if (month.records > 0)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: _PiChange(
                value: month.change,
                percent: month.changePercent,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// Monthly average price as one line (oldest to newest); tap a point for its value.
class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.points, required this.currency});

  final List<MonthlyPrice> points;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final values = points.map((p) => p.average!).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min) == 0 ? (max.abs() * 0.1 + 1) : (max - min);
    final axisStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.tr.piMonthlyAverage} ($currency)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: min - span * 0.15,
              maxY: max + span * 0.15,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: _noTitles,
                rightTitles: _noTitles,
                leftTitles: _noTitles,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      final last = points.length - 1;
                      // First, last and every other month in between when space allows.
                      final show =
                          i == 0 ||
                          i == last ||
                          (points.length <= 12 && (last - i).isEven);
                      if (i < 0 || i > last || !show) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          _piMonth(points[i].month, pattern: 'MMM'),
                          style: axisStyle,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        '${_piMonth(points[spot.x.toInt()].month)}\n'
                        '${formatAmount(spot.y, currency: currency)}',
                        TextStyle(
                          color: scheme.onInverseSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].average!),
                  ],
                  color: scheme.primary,
                  barWidth: 2,
                  isCurved: false,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Price Changes: the latest change of every visible price
// ---------------------------------------------------------------------------

class PriceChangesPage extends StatefulWidget {
  const PriceChangesPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<PriceChangesPage> createState() => _PriceChangesPageState();
}

class _PriceChangesPageState extends State<PriceChangesPage> {
  String _period = '30';
  String _direction = '';
  String _source = '';
  String _sort = 'recent';
  String _category = '';

  final List<HardwarePrice> _items = [];
  PriceChangeStats? _stats;
  List<String> _categories = const [];
  int _page = 1;
  bool _hasNext = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _stats = page.stats;
        _categories = page.categories;
        _page = 1;
        _hasNext = page.hasNext;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _hasNext = page.hasNext;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<PriceChangesResult> _fetch(int page) =>
      widget.api.hardwarePriceChanges(
        period: _period,
        direction: _direction,
        category: _category,
        source: _source,
        sort: _sort,
        page: page,
      );

  void _update(VoidCallback change) {
    setState(change);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.tr;
    return Scaffold(
      appBar: AppBar(title: Text(l.piPriceChanges)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.page,
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.piPriceChangesSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _statsGrid(context),
                  const SizedBox(height: AppSpacing.md),
                  _filters(context),
                  const SizedBox(height: AppSpacing.md),
                  ..._list(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid(BuildContext context) {
    final l = context.tr;
    final stats = _stats;
    Widget card(
      String label,
      String value,
      IconData icon,
      StatusTone tone,
      String direction,
    ) => StatCard(
      label: label,
      value: value,
      icon: icon,
      tone: tone,
      onTap: direction == 'avg'
          ? null
          : () => _update(() => _direction = direction),
    );
    // Two rows of two; cards in a row share the tallest card's height.
    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: b),
        ],
      ),
    );
    return Column(
      children: [
        row(
          card(
            l.piItemsChanged,
            '${stats?.total ?? '—'}',
            Icons.sync_alt,
            StatusTone.info,
            '',
          ),
          card(
            l.piAverageChange,
            stats?.average == null ? '—' : _piPercent(stats!.average!),
            Icons.percent,
            StatusTone.warning,
            'avg',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        row(
          card(
            l.piWentUp,
            '${stats?.up ?? '—'}',
            Icons.arrow_upward,
            StatusTone.danger,
            'up',
          ),
          card(
            l.piWentDown,
            '${stats?.down ?? '—'}',
            Icons.arrow_downward,
            StatusTone.success,
            'down',
          ),
        ),
      ],
    );
  }

  Widget _filters(BuildContext context) {
    final l = context.tr;
    final periods = {
      '7': l.piLast7Days,
      '30': l.piLast30Days,
      '90': l.piLast90Days,
      '365': l.piLast12Months,
      'all': l.piAllTime,
    };
    final sorts = {
      'recent': l.piSortRecent,
      'up': l.piSortUp,
      'down': l.piSortDown,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _menuChip<String>(
              icon: Icons.date_range_outlined,
              label: periods[_period]!,
              options: periods,
              onSelected: (value) => _update(() => _period = value),
            ),
            _menuChip<String>(
              icon: Icons.sort,
              label: sorts[_sort]!,
              options: sorts,
              onSelected: (value) => _update(() => _sort = value),
            ),
            if (_categories.isNotEmpty)
              _menuChip<String>(
                icon: Icons.category_outlined,
                label: _category.isEmpty ? l.piAllCategories : _category,
                options: {
                  '': l.piAllCategories,
                  for (final category in _categories) category: category,
                },
                onSelected: (value) => _update(() => _category = value),
              ),
            for (final (value, label, icon) in [
              ('up', l.piWentUp, Icons.arrow_upward),
              ('down', l.piWentDown, Icons.arrow_downward),
            ])
              FilterChip(
                avatar: Icon(icon, size: 16),
                label: Text(label),
                selected: _direction == value,
                onSelected: (on) => _update(() => _direction = on ? value : ''),
              ),
          ],
        ),
        // Only members of an organisation have prices of their own.
        if (!widget.api.isPersonalAccount) ...[
          const SizedBox(height: AppSpacing.sm),
          _SourceSelector(
            value: _source,
            onChanged: (value) => _update(() => _source = value),
          ),
        ],
      ],
    );
  }

  Widget _menuChip<T>({
    required IconData icon,
    required String label,
    required Map<T, String> options,
    required ValueChanged<T> onSelected,
  }) => PopupMenuButton<T>(
    tooltip: label,
    onSelected: onSelected,
    itemBuilder: (_) => [
      for (final entry in options.entries)
        PopupMenuItem<T>(value: entry.key, child: Text(entry.value)),
    ],
    child: Chip(
      avatar: Icon(icon, size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), const Icon(Icons.arrow_drop_down, size: 18)],
      ),
    ),
  );

  List<Widget> _list(BuildContext context) {
    final l = context.tr;
    if (_loading) {
      return [const _PiLoading()];
    }
    if (_error != null) return [ErrorState(error: _error, onRetry: _reload)];
    if (_items.isEmpty) {
      return [
        EmptyState(
          icon: Icons.trending_up,
          title: l.piNoChanges,
          message: l.piNoChangesHint,
        ),
      ];
    }
    return [
      for (final price in _items)
        _PriceChangeCard(
          price: price,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => HardwarePriceDetailPage(
                api: widget.api,
                hardwarePrice: price,
                l10n: l,
              ),
            ),
          ),
        ),
      if (_hasNext)
        Center(
          child: LoadingButton(
            label: l.piLoadMore,
            icon: Icons.expand_more,
            tonal: true,
            loading: _loadingMore,
            onPressed: _loadMore,
          ),
        ),
    ];
  }
}

/// All prices / General market / My organisation.
class _SourceSelector extends StatelessWidget {
  const _SourceSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.tr;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: '', label: Text(l.piAllPrices)),
          ButtonSegment(
            value: 'general',
            icon: const Icon(Icons.public, size: 16),
            label: Text(l.piGeneralMarket),
          ),
          ButtonSegment(
            value: 'mine',
            icon: const Icon(Icons.business_outlined, size: 16),
            label: Text(l.piMyOrganisation),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

/// General market or My organisation badge for a price.
class PriceSourceBadge extends StatelessWidget {
  const PriceSourceBadge({super.key, required this.price});

  final HardwarePrice price;

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: price.isGeneral ? context.tr.piGeneral : context.tr.piMyOrganisation,
    icon: price.isGeneral ? Icons.public : Icons.business_outlined,
    tone: price.isGeneral ? StatusTone.neutral : StatusTone.brand,
  );
}

class _PriceChangeCard extends StatelessWidget {
  const _PriceChangeCard({required this.price, required this.onTap});

  final HardwarePrice price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.tr;
    final theme = Theme.of(context);
    final place = [
      price.supplier,
      price.location,
    ].where((s) => s.isNotEmpty).join(' · ');
    return ListItemCard(
      onTap: onTap,
      title: price.itemName,
      subtitle: [
        if (price.category.isNotEmpty) price.category,
        if (place.isNotEmpty) place,
      ].join(' · ').ifEmptyNull,
      trailing: _PiChange(
        value: price.priceChange,
        percent: price.priceChangePercent,
        style: theme.textTheme.bodySmall,
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatAmount(
                    price.previousPrice,
                    currency: price.currency,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const TextSpan(text: '  →  '),
                TextSpan(
                  text: formatAmount(price.price, currency: price.currency),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (price.unit.isNotEmpty)
                  TextSpan(
                    text: ' / ${price.unit}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PriceSourceBadge(price: price),
              if (price.priceChangedAt.isNotEmpty)
                Text(
                  l.piChangedOn(displayDate(price.priceChangedAt)),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BOQ price check
// ---------------------------------------------------------------------------

class BoqPriceCheckPage extends StatefulWidget {
  const BoqPriceCheckPage({
    super.key,
    required this.api,
    required this.boqId,
    required this.title,
  });

  final ApiClient api;
  final int boqId;
  final String title;

  @override
  State<BoqPriceCheckPage> createState() => _BoqPriceCheckPageState();
}

class _BoqPriceCheckPageState extends State<BoqPriceCheckPage> {
  String _filter = 'all';
  late Future<BoqPriceCheck> _future = _load();

  Future<BoqPriceCheck> _load() =>
      widget.api.boqPriceCheck(widget.boqId, filter: _filter);

  Future<void> _reload() async {
    final future = _load();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  void _setFilter(String filter) {
    _filter = filter;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.tr;
    return Scaffold(
      appBar: AppBar(title: Text(l.piPriceCheck)),
      body: FutureBuilder<BoqPriceCheck>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _reload);
          }
          if (!snapshot.hasData) return const LoadingState();
          final check = snapshot.data!;
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
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        l.piPriceCheckSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _summary(context, check),
                      const SizedBox(height: AppSpacing.md),
                      _filterChips(context, check.summary),
                      const SizedBox(height: AppSpacing.md),
                      ..._rows(context, check),
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

  Widget _summary(BuildContext context, BoqPriceCheck check) {
    final l = context.tr;
    final s = check.summary;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyValueRow(
              label: l.piTotalOurs,
              value: formatAmount(s.totalOurs, currency: check.currency),
            ),
            KeyValueRow(
              label: l.piTotalMarket,
              value: formatAmount(s.totalMarket, currency: check.currency),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.piMarketVsOurs,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                _PiChange(value: s.totalDifference, percent: s.totalPercent),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l.piMatchedItems}: ${s.matched}'
              '${s.unmatched > 0 ? ' · ${l.piNotMatched(s.unmatched)}' : ''}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChips(BuildContext context, BoqPriceCheckSummary s) {
    final l = context.tr;
    final filters = [
      ('all', l.piFilterAll, s.matched),
      ('above', l.piFilterAbove, s.above),
      ('below', l.piFilterBelow, s.below),
      ('changed', l.piFilterChanged, s.changed),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (value, label, count) in filters)
          ChoiceChip(
            label: Text('$label ($count)'),
            selected: _filter == value,
            onSelected: (_) => _setFilter(value),
          ),
      ],
    );
  }

  List<Widget> _rows(BuildContext context, BoqPriceCheck check) {
    final l = context.tr;
    if (check.rows.isEmpty) {
      return [
        EmptyState(
          icon: Icons.compare_arrows,
          title: check.summary.matched == 0
              ? l.piNoMatchedItems
              : l.piNoItemsInView,
          message: check.summary.matched == 0 ? l.piNoMatchedItemsHint : null,
        ),
      ];
    }
    return [
      for (final row in check.rows)
        _PriceCheckRowCard(
          row: row,
          onRateHistory: () => showBoqItemRateHistory(context, widget.api, row),
          onMarketHistory: widget.api.can('hardware-prices.view')
              ? () => _piOpenMarketPrice(context, widget.api, row.marketId)
              : null,
        ),
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          l.piDifferenceHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ];
  }
}

String _piRateLabel(AppLocalizations l, String? field) => switch (field) {
  'approved_rate' => l.piRateApproved,
  'reviewed_rate' => l.piRateReviewed,
  'ai_suggested_rate' => l.piRateSuggested,
  'original_rate' => l.piRateOriginal,
  _ => field ?? '',
};

class _PriceCheckRowCard extends StatelessWidget {
  const _PriceCheckRowCard({
    required this.row,
    required this.onRateHistory,
    this.onMarketHistory,
  });

  final BoqPriceCheckRow row;
  final VoidCallback onRateHistory;
  final VoidCallback? onMarketHistory;

  @override
  Widget build(BuildContext context) {
    final l = context.tr;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall;
    final title = [
      if (row.itemCode.isNotEmpty) row.itemCode,
      row.description,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              '${row.marketName}'
              '${row.marketSupplier.isNotEmpty ? ' · ${row.marketSupplier}' : ''}',
              style: muted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _figure(
                    context,
                    l.piOurRate,
                    row.rate == null
                        ? l.piNoRateYet
                        : formatAmount(row.rate, currency: row.currency),
                    row.rateField == null
                        ? null
                        : _piRateLabel(l, row.rateField),
                  ),
                ),
                Expanded(
                  child: _figure(
                    context,
                    l.piMarketToday,
                    formatAmount(row.marketPrice, currency: row.marketCurrency),
                    row.marketUnit.isEmpty ? null : '/ ${row.marketUnit}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.piDifference, style: muted),
                      row.comparable
                          ? _PiChange(
                              value: row.difference,
                              percent: row.percent,
                            )
                          : Text(
                              row.rate == null ? '—' : l.piDifferentCurrency,
                              style: muted,
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.piSinceMatching, style: muted),
                      _PiChange(value: row.sinceMatch),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton.icon(
                  onPressed: onRateHistory,
                  icon: const Icon(Icons.history, size: 18),
                  label: Text(l.piRateHistory),
                ),
                if (onMarketHistory != null)
                  TextButton.icon(
                    onPressed: onMarketHistory,
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: Text(l.piMarketHistory),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _figure(
    BuildContext context,
    String label,
    String value,
    String? note,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (note != null) Text(note, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Bottom sheet with every change to a BOQ item's rates.
Future<void> showBoqItemRateHistory(
  BuildContext context,
  ApiClient api,
  BoqPriceCheckRow row,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.9,
    builder: (context, controller) {
      final l = context.tr;
      final theme = Theme.of(context);
      return FutureBuilder<List<BoqItemRateChange>>(
        future: api.boqItemRateHistory(row.boqItemId),
        builder: (context, snapshot) {
          final header = <Widget>[
            Text(l.piRateHistory, style: theme.textTheme.titleMedium),
            Text(
              row.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
          ];
          final List<Widget> body;
          if (snapshot.hasError) {
            body = [ErrorState(error: snapshot.error, compact: true)];
          } else if (!snapshot.hasData) {
            body = [const Center(child: CircularProgressIndicator())];
          } else if (snapshot.data!.isEmpty) {
            body = [
              EmptyState(
                icon: Icons.history,
                title: l.piNoRateChanges,
                compact: true,
              ),
            ];
          } else {
            body = [
              for (final change in snapshot.data!)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_piRateLabel(l, change.field)),
                  subtitle: Text(
                    '${displayDate(change.changedAt)} · '
                    '${change.userName.isEmpty ? l.piSystem : change.userName}\n'
                    '${formatAmount(change.oldValue, currency: change.currency)}  →  '
                    '${formatAmount(change.newValue, currency: change.currency)}',
                  ),
                  isThreeLine: true,
                  trailing: _PiChange(value: change.change),
                ),
            ];
          }
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [...header, ...body],
          );
        },
      );
    },
  ),
);

// ---------------------------------------------------------------------------
// Plan price history
// ---------------------------------------------------------------------------

class PlanPriceHistoryPage extends StatefulWidget {
  const PlanPriceHistoryPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<PlanPriceHistoryPage> createState() => _PlanPriceHistoryPageState();
}

class _PlanPriceHistoryPageState extends State<PlanPriceHistoryPage> {
  String _scope = 'mine';
  final List<PlanPriceChange> _items = [];
  int _page = 1;
  bool _hasNext = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.api.planPriceHistory(scope: _scope);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _page = page.page;
        _hasNext = page.hasNext;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.api.planPriceHistory(
        scope: _scope,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.page;
        _hasNext = page.hasNext;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.tr;
    return Scaffold(
      appBar: AppBar(title: Text(l.piPlanPriceHistory)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.page,
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.piPlanHistoryHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'mine', label: Text(l.piMyPlans)),
                      ButtonSegment(value: 'all', label: Text(l.piAllPlans)),
                    ],
                    selected: {_scope},
                    onSelectionChanged: (selection) {
                      _scope = selection.first;
                      _reload();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_loading)
                    const _PiLoading()
                  else if (_error != null)
                    ErrorState(error: _error, onRetry: _reload)
                  else if (_items.isEmpty)
                    EmptyState(icon: Icons.history, title: l.piNoPlanChanges)
                  else ...[
                    for (final change in _items)
                      _PlanChangeCard(change: change),
                    if (_hasNext)
                      Center(
                        child: LoadingButton(
                          label: l.piLoadMore,
                          icon: Icons.expand_more,
                          tonal: true,
                          loading: _loadingMore,
                          onPressed: _loadMore,
                        ),
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
}

class _PlanChangeCard extends StatelessWidget {
  const _PlanChangeCard({required this.change});

  final PlanPriceChange change;

  @override
  Widget build(BuildContext context) {
    final l = context.tr;
    final theme = Theme.of(context);
    return ListItemCard(
      showChevron: false,
      title: change.planName,
      subtitle: displayDate(change.changedAt),
      trailing: change.oldPrice == null
          ? null
          : _PiChange(
              value: change.difference,
              percent: change.percentChange,
              style: theme.textTheme.bodySmall,
            ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                if (change.oldPrice == null)
                  TextSpan(
                    text: '${l.piInitialPrice}: ',
                    style: theme.textTheme.bodySmall,
                  )
                else ...[
                  TextSpan(
                    text: formatAmount(
                      change.oldPrice,
                      currency: change.oldCurrency ?? change.newCurrency,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const TextSpan(text: '  →  '),
                ],
                TextSpan(
                  text: formatAmount(
                    change.newPrice,
                    currency: change.newCurrency,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (change.isMyPlan) ...[
            const SizedBox(height: AppSpacing.xs),
            StatusBadge(label: l.piYourPlan, tone: StatusTone.info),
          ],
        ],
      ),
    );
  }
}

/// Loading indicator for use inside a scrolling list.
class _PiLoading extends StatelessWidget {
  const _PiLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.xxl),
    child: Center(child: CircularProgressIndicator()),
  );
}
