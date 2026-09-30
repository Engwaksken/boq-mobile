part of '../main.dart';

// Top Suppliers: rankings of hardware shops and factories by user ratings,
// the charts, one supplier's performance, rating a supplier and "My ratings".

const _ratingPeriods = <(String, String)>[
  ('week', 'This week'),
  ('month', 'This month'),
  ('year', 'This year'),
  ('all', 'All time'),
];

String _ratingPeriodLabel(String period) => _ratingPeriods
    .firstWhere((p) => p.$1 == period, orElse: () => _ratingPeriods[1])
    .$2;

String _supplierTypeLabel(String type) =>
    type == 'factory' ? 'Factory' : 'Hardware';

String _stars(double? value) => value == null ? '—' : value.toStringAsFixed(1);

String _ratingsCount(int count) => count == 1 ? '1 rating' : '$count ratings';

/// Star colour (readable on light and dark surfaces).
const _starColor = Color(0xFFF59E0B);

/// 5 stars down to 1 star.
const _distributionColors = <Color>[
  Color(0xFF15803D),
  Color(0xFF65A30D),
  Color(0xFFF59E0B),
  Color(0xFFEA580C),
  Color(0xFFBE123C),
];

const _factoryColor = Color(0xFF2563EB);

typedef _RatingsOverview = ({
  SupplierLeaderboard hardware,
  SupplierLeaderboard factories,
  SupplierRatingSummary summary,
});

class TopSuppliersPage extends StatefulWidget {
  const TopSuppliersPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<TopSuppliersPage> createState() => _TopSuppliersPageState();
}

class _TopSuppliersPageState extends State<TopSuppliersPage> {
  String _period = 'month';
  bool _lowest = false;
  late Future<_RatingsOverview> _overview = _loadOverview();
  late Future<List<SupplierRatingEntry>> _mine = widget.api.mySupplierRatings();

  Future<_RatingsOverview> _loadOverview() async {
    final period = _period;
    final lowest = _lowest;
    final results = await Future.wait<Object>([
      widget.api.supplierLeaderboard(
        period: period,
        type: 'supplier',
        lowest: lowest,
      ),
      widget.api.supplierLeaderboard(
        period: period,
        type: 'factory',
        lowest: lowest,
      ),
      widget.api.supplierRatingSummary(period: period),
    ]);
    return (
      hardware: results[0] as SupplierLeaderboard,
      factories: results[1] as SupplierLeaderboard,
      summary: results[2] as SupplierRatingSummary,
    );
  }

  void _reload() => setState(() => _overview = _loadOverview());

  void _reloadMine() => setState(() => _mine = widget.api.mySupplierRatings());

  void _setPeriod(String period) {
    if (period == _period) return;
    _period = period;
    _reload();
  }

  Future<void> _rate([RatedSupplier? supplier]) async {
    final message = await showRateSupplierSheet(
      context,
      widget.api,
      supplier: supplier,
    );
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    _reload();
    _reloadMine();
  }

  Future<void> _open(RatedSupplier supplier) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SupplierPerformancePage(
          api: widget.api,
          supplier: supplier,
          period: _period,
        ),
      ),
    );
    if (changed == true && mounted) {
      _reload();
      _reloadMine();
    }
  }

  Widget _periodPicker() =>
      _RatingPeriodPicker(value: _period, onChanged: _setPeriod);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Top Suppliers'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rankings'),
              Tab(text: 'Charts'),
              Tab(text: 'My ratings'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _rate(),
          icon: const Icon(Icons.star_rate_outlined),
          label: const Text('Rate a Supplier'),
        ),
        body: TabBarView(
          children: [
            _overviewTab(_rankings),
            _overviewTab(_charts),
            _myRatings(),
          ],
        ),
      ),
    );
  }

  Widget _overviewTab(List<Widget> Function(_RatingsOverview) build) {
    return FutureBuilder<_RatingsOverview>(
      future: _overview,
      builder: (context, snapshot) {
        final Widget content;
        if (snapshot.hasError) {
          content = ErrorState(error: snapshot.error, onRetry: _reload);
        } else if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          content = const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xxxl),
            child: LoadingState(),
          );
        } else {
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _overview;
            },
            child: ListView(
              padding: AppSpacing.page.copyWith(bottom: 96),
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _periodPicker(),
                      const SizedBox(height: AppSpacing.md),
                      ...build(snapshot.data!),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: AppSpacing.page,
          children: [
            _periodPicker(),
            const SizedBox(height: AppSpacing.md),
            content,
          ],
        );
      },
    );
  }

  List<Widget> _rankings(_RatingsOverview data) {
    final theme = Theme.of(context);
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              'Ratings of hardware suppliers and factories by users. Rate the '
              'ones you buy from to reward good prices and service.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilterChip(
            label: const Text('Lowest rated'),
            selected: _lowest,
            onSelected: (value) {
              _lowest = value;
              _reload();
            },
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      _LeaderboardCard(
        title: _lowest ? 'Hardware needing improvement' : 'Top 10 Hardware',
        icon: Icons.storefront_outlined,
        board: data.hardware,
        onTap: _open,
        onRate: () => _rate(),
      ),
      const SizedBox(height: AppSpacing.sectionGap),
      _LeaderboardCard(
        title: _lowest ? 'Factories needing improvement' : 'Top 10 Factories',
        icon: Icons.factory_outlined,
        board: data.factories,
        onTap: _open,
        onRate: () => _rate(),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Rankings use a weighted score: a supplier needs several good ratings '
        'to rank above one with many, so a single 5-star rating does not top '
        'the list.',
        style: theme.textTheme.bodySmall,
      ),
    ];
  }

  List<Widget> _charts(_RatingsOverview data) {
    final summary = data.summary;
    final scheme = Theme.of(context).colorScheme;
    final prefix = _lowest ? 'Lowest rated' : 'Top';
    return [
      Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Ratings',
              value: '${summary.total}',
              icon: Icons.reviews_outlined,
            ),
          ),
          Expanded(
            child: StatCard(
              label: 'Average rating',
              value: _stars(summary.average),
              icon: Icons.star_outline,
              tone: StatusTone.warning,
            ),
          ),
          Expanded(
            child: StatCard(
              label: 'Suppliers rated',
              value: '${summary.suppliers}',
              icon: Icons.storefront_outlined,
              tone: StatusTone.info,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: '$prefix hardware · average rating',
        icon: Icons.bar_chart,
        children: [
          _AverageBarChart(entries: data.hardware.items, color: scheme.primary),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: '$prefix factories · average rating',
        icon: Icons.bar_chart,
        children: [
          _AverageBarChart(entries: data.factories.items, color: _factoryColor),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Rating distribution',
        icon: Icons.donut_large_outlined,
        children: [_DistributionChart(buckets: summary.distribution)],
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Ratings by type',
        icon: Icons.pie_chart_outline,
        children: [
          _TypeChart(hardware: summary.hardware, factories: summary.factories),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Scores by area',
        icon: Icons.insights_outlined,
        children: [
          _CriteriaChart(
            criteria: summary.criteria,
            emptyMessage: 'No detailed scores in this period yet.',
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Monthly trend',
        icon: Icons.show_chart,
        trailing: Text(
          'Last 12 months',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          _TrendChart(
            points: summary.trend,
            series: [
              ('Hardware', scheme.primary, summary.hardwareTrend),
              ('Factories', _factoryColor, summary.factoryTrend),
            ],
          ),
        ],
      ),
    ];
  }

  Widget _myRatings() {
    return FutureBuilder<List<SupplierRatingEntry>>(
      future: _mine,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error, onRetry: _reloadMine);
        }
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const LoadingState();
        }
        final ratings = snapshot.data!;
        if (ratings.isEmpty) {
          return EmptyState(
            icon: Icons.star_border,
            title: 'You have not rated any supplier yet.',
            message:
                'Rate the hardware shops and factories you buy from. You can '
                'rate each one again every month.',
            actionLabel: 'Rate a Supplier',
            actionIcon: Icons.star_rate_outlined,
            onAction: () => _rate(),
          );
        }
        final theme = Theme.of(context);
        return RefreshIndicator(
          onRefresh: () async {
            _reloadMine();
            await _mine;
          },
          child: ListView(
            padding: AppSpacing.page.copyWith(bottom: 96),
            children: [
              for (final rating in ratings)
                ContentWidth(
                  child: ListItemCard(
                    title: rating.supplier?.name ?? 'Supplier',
                    subtitle: [
                      if (rating.supplier != null)
                        _supplierTypeLabel(rating.supplier!.type),
                      if ((rating.supplier?.place ?? '').isNotEmpty)
                        rating.supplier!.place,
                      displayDate(rating.ratedAt),
                    ].join(' · '),
                    leading: _StarBadge(value: rating.rating.toDouble()),
                    footer: rating.comment == null
                        ? null
                        : Text(
                            rating.comment!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                    onTap: rating.supplier == null
                        ? null
                        : () => _open(rating.supplier!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// This week / This month / This year / All time.
class _RatingPeriodPicker extends StatelessWidget {
  const _RatingPeriodPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (key, label) in _ratingPeriods)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(label),
                selected: value == key,
                onSelected: (_) => onChanged(key),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.title,
    required this.icon,
    required this.board,
    required this.onTap,
    required this.onRate,
  });

  final String title;
  final IconData icon;
  final SupplierLeaderboard board;
  final ValueChanged<RatedSupplier> onTap;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: title,
      icon: icon,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      trailing: Text(
        board.periodLabel.isEmpty
            ? _ratingPeriodLabel(board.period)
            : board.periodLabel,
        style: theme.textTheme.bodySmall,
      ),
      children: [
        if (board.items.isEmpty)
          EmptyState(
            compact: true,
            icon: Icons.star_border,
            title: 'No ratings in this period yet.',
            message: 'Be the first to rate one.',
            actionLabel: 'Rate a Supplier',
            onAction: onRate,
          )
        else
          for (final entry in board.items)
            InkWell(
              borderRadius: AppRadii.input,
              onTap: () => onTap(entry.supplier),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    _RankBadge(rank: entry.rank),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.supplier.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (entry.supplier.place.isNotEmpty)
                            Text(
                              entry.supplier.place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: _starColor,
                              size: 18,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _stars(entry.average),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _ratingsCount(entry.count),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

/// Rank number; gold, silver and bronze for the first three.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  static const _medals = {
    1: Color(0xFFD4A017),
    2: Color(0xFF9CA3AF),
    3: Color(0xFFB87333),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final medal = _medals[rank];
    return Semantics(
      label: 'Rank $rank',
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: medal ?? scheme.surfaceContainerHighest,
        ),
        child: medal != null && rank == 1
            ? const Icon(Icons.emoji_events, color: Colors.white, size: 18)
            : Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: medal != null ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

/// Five stars for a 0 to 5 value, with half stars.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.value, this.size = 18});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.outline;
    return Semantics(
      label: '${value.toStringAsFixed(1)} out of 5 stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              value >= i
                  ? Icons.star_rounded
                  : value >= i - 0.5
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: value >= i - 0.5 ? _starColor : muted,
            ),
        ],
      ),
    );
  }
}

/// Compact "4 ★" tile for list rows.
class _StarBadge extends StatelessWidget {
  const _StarBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _starColor.withValues(alpha: 0.16),
        borderRadius: AppRadii.input,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toStringAsFixed(0),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const Icon(Icons.star_rounded, color: _starColor, size: 18),
        ],
      ),
    );
  }
}

/// Tap a star to choose 1 to 5. With [clearable], tapping the chosen star
/// again clears the value (optional scores).
class _StarPicker extends StatelessWidget {
  const _StarPicker({
    required this.value,
    required this.onChanged,
    this.clearable = false,
    this.size = 32,
    this.enabled = true,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final bool clearable;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            constraints: BoxConstraints.tight(Size.square(size + 8)),
            tooltip: i == 1 ? '1 star' : '$i stars',
            isSelected: (value ?? 0) >= i,
            onPressed: !enabled
                ? null
                : () => onChanged(clearable && value == i ? null : i),
            icon: Icon(
              (value ?? 0) >= i
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: (value ?? 0) >= i ? _starColor : muted,
            ),
          ),
      ],
    );
  }
}

// Charts.

TextStyle? _axisStyle(BuildContext context) => Theme.of(
  context,
).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline);

FlGridData _starGrid(BuildContext context) => FlGridData(
  drawVerticalLine: false,
  horizontalInterval: 1,
  getDrawingHorizontalLine: (_) => FlLine(
    color: Theme.of(context).colorScheme.outlineVariant,
    strokeWidth: 1,
    dashArray: const [4, 4],
  ),
);

AxisTitles _starAxis(BuildContext context) => AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    interval: 1,
    reservedSize: 24,
    getTitlesWidget: (value, meta) => SideTitleWidget(
      meta: meta,
      child: Text(value.toInt().toString(), style: _axisStyle(context)),
    ),
  ),
);

const _noTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

Widget _chartEmpty(String message) => EmptyState(
  compact: true,
  icon: Icons.insert_chart_outlined,
  title: message,
);

/// Average stars of a top 10 (x axis = rank).
class _AverageBarChart extends StatelessWidget {
  const _AverageBarChart({required this.entries, required this.color});

  final List<SupplierLeaderboardEntry> entries;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return _chartEmpty('No ratings in this period yet.');
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 5,
          alignment: BarChartAlignment.spaceAround,
          gridData: _starGrid(context),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: _noTitles,
            rightTitles: _noTitles,
            leftTitles: _starAxis(context),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '#${entries[i].rank}',
                      style: _axisStyle(context),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 180,
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = entries[group.x];
                return BarTooltipItem(
                  '${entry.supplier.name}\n'
                  '${_stars(entry.average)} ★ · ${_ratingsCount(entry.count)}',
                  TextStyle(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].average.clamp(0, 5).toDouble(),
                    color: color,
                    width: entries.length > 6 ? 14 : 22,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Average score in each area.
class _CriteriaChart extends StatelessWidget {
  const _CriteriaChart({required this.criteria, required this.emptyMessage});

  final RatingCriteria criteria;
  final String emptyMessage;

  static const _colors = [
    Color(0xFF05645B),
    Color(0xFF2563EB),
    Color(0xFFF59E0B),
    Color(0xFF9333EA),
  ];

  @override
  Widget build(BuildContext context) {
    if (criteria.isEmpty) return _chartEmpty(emptyMessage);
    final scheme = Theme.of(context).colorScheme;
    final entries = criteria.entries;
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 5,
          alignment: BarChartAlignment.spaceAround,
          gridData: _starGrid(context),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: _noTitles,
            rightTitles: _noTitles,
            leftTitles: _starAxis(context),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(entries[i].$1, style: _axisStyle(context)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    '${entries[group.x].$1}: ${_stars(entries[group.x].$2)}',
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (entries[i].$2 ?? 0).clamp(0, 5).toDouble(),
                    color: _colors[i % _colors.length],
                    width: 26,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A donut chart with a legend underneath.
class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.slices, required this.centerLabel});

  /// Label, count and colour of each slice.
  final List<(String, int, Color)> slices;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = slices.fold<int>(0, (sum, s) => sum + s.$2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 52,
                  sectionsSpace: 2,
                  sections: [
                    for (final slice in slices)
                      if (slice.$2 > 0)
                        PieChartSectionData(
                          value: slice.$2.toDouble(),
                          color: slice.$3,
                          radius: 36,
                          title: '${(slice.$2 * 100 / total).round()}%',
                          showTitle: slice.$2 * 100 / total >= 8,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(centerLabel, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.center,
          children: [
            for (final slice in slices)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: slice.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${slice.$1}: ${slice.$2}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// How many ratings gave 5 stars down to 1 star.
class _DistributionChart extends StatelessWidget {
  const _DistributionChart({required this.buckets});

  final List<RatingBucket> buckets;

  @override
  Widget build(BuildContext context) {
    if (buckets.every((b) => b.count == 0)) {
      return _chartEmpty('No ratings in this period yet.');
    }
    return _DonutChart(
      centerLabel: 'ratings',
      slices: [
        for (final bucket in buckets)
          (
            '${bucket.stars}★',
            bucket.count,
            _distributionColors[(5 - bucket.stars).clamp(0, 4)],
          ),
      ],
    );
  }
}

/// Ratings of hardware shops against factories.
class _TypeChart extends StatelessWidget {
  const _TypeChart({required this.hardware, required this.factories});

  final RatingTypeStat hardware;
  final RatingTypeStat factories;

  @override
  Widget build(BuildContext context) {
    if (hardware.count + factories.count == 0) {
      return _chartEmpty('No ratings in this period yet.');
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DonutChart(
          centerLabel: 'ratings',
          slices: [
            ('Hardware', hardware.count, theme.colorScheme.primary),
            ('Factories', factories.count, _factoryColor),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        KeyValueRow(
          label: 'Hardware average',
          value: '${_stars(hardware.average)} ★',
        ),
        KeyValueRow(
          label: 'Factory average',
          value: '${_stars(factories.average)} ★',
        ),
      ],
    );
  }
}

/// Monthly average stars (lines) and number of ratings (bars) for 12 months.
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points, this.series = const []});

  final List<RatingTrendPoint> points;

  /// Extra lines (label, colour, points), e.g. hardware and factories.
  final List<(String, Color, List<RatingTrendPoint>)> series;

  static String _month(RatingTrendPoint point) => point.label.split(' ').first;

  @override
  Widget build(BuildContext context) {
    if (points.every((p) => p.count == 0)) {
      return _chartEmpty('No ratings in the last 12 months.');
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = <(String, Color, List<RatingTrendPoint>)>[
      ('All', _starColor, points),
      for (final extra in series)
        if (extra.$3.any((p) => p.count > 0)) extra,
    ];
    final maxCount = points.fold<int>(0, (m, p) => p.count > m ? p.count : m);

    AxisTitles monthAxis({bool show = true}) => AxisTitles(
      sideTitles: SideTitles(
        showTitles: show,
        interval: 1,
        reservedSize: 22,
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          // Every other month keeps the labels readable on phones.
          if (i < 0 || i >= points.length || (points.length - 1 - i).isOdd) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            child: Text(_month(points[i]), style: _axisStyle(context)),
          );
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: 0,
              maxY: 5,
              gridData: _starGrid(context),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: _noTitles,
                rightTitles: _noTitles,
                leftTitles: _starAxis(context),
                bottomTitles: monthAxis(),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  maxContentWidth: 180,
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      () {
                        final line = lines[spot.barIndex];
                        final point = line.$3[spot.x.toInt()];
                        return LineTooltipItem(
                          '${spot.barIndex == 0 ? '${point.label}\n' : ''}'
                          '${line.$1}: ${_stars(point.average)} ★ · '
                          '${_ratingsCount(point.count)}',
                          TextStyle(
                            color: scheme.onInverseSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }(),
                  ],
                ),
              ),
              lineBarsData: [
                for (final line in lines)
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < line.$3.length; i++)
                        line.$3[i].average == null
                            ? FlSpot.nullSpot
                            : FlSpot(i.toDouble(), line.$3[i].average!),
                    ],
                    color: line.$2,
                    barWidth: line.$1 == 'All' ? 3 : 2,
                    isCurved: false,
                    dashArray: line.$1 == 'All' ? null : const [5, 3],
                    dotData: FlDotData(show: line.$1 == 'All'),
                  ),
              ],
            ),
          ),
        ),
        if (lines.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            alignment: WrapAlignment.center,
            children: [
              for (final line in lines)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 14, height: 3, color: line.$2),
                    const SizedBox(width: AppSpacing.xs),
                    Text(line.$1, style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text('Ratings per month', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 110,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxCount == 0 ? 1 : maxCount * 1.25,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: _noTitles,
                rightTitles: _noTitles,
                // A blank axis keeps the bars aligned with the months above.
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) => const SizedBox.shrink(),
                  ),
                ),
                bottomTitles: monthAxis(),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        '${points[group.x].label}\n'
                        '${_ratingsCount(points[group.x].count)}',
                        TextStyle(
                          color: scheme.onInverseSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: points[i].count.toDouble(),
                        color: scheme.primary.withValues(alpha: 0.55),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
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
  }
}

/// One supplier's or factory's performance.
class SupplierPerformancePage extends StatefulWidget {
  const SupplierPerformancePage({
    super.key,
    required this.api,
    required this.supplier,
    this.period = 'month',
  });

  final ApiClient api;
  final RatedSupplier supplier;
  final String period;

  @override
  State<SupplierPerformancePage> createState() =>
      _SupplierPerformancePageState();
}

class _SupplierPerformancePageState extends State<SupplierPerformancePage> {
  late String _period = widget.period;
  late Future<SupplierPerformance> _data = _load();
  bool _changed = false;

  Future<SupplierPerformance> _load() =>
      widget.api.supplierPerformance(widget.supplier.id, period: _period);

  void _reload() => setState(() => _data = _load());

  Future<void> _rate(SupplierPerformance data) async {
    final message = await showRateSupplierSheet(
      context,
      widget.api,
      supplier: data.supplier,
      mine: data.mine,
    );
    if (message == null || !mounted) return;
    _changed = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    _reload();
  }

  Future<void> _openWebsite(String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the website.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.supplier.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: FutureBuilder<SupplierPerformance>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorState(error: snapshot.error, onRetry: _reload);
            }
            if (snapshot.connectionState != ConnectionState.done ||
                !snapshot.hasData) {
              return const LoadingState();
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _data;
              },
              child: ListView(
                padding: AppSpacing.page,
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _sections(data),
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

  List<Widget> _sections(SupplierPerformance data) {
    final theme = Theme.of(context);
    final supplier = data.supplier;
    final average = data.average ?? 0;
    return [
      Card(
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      supplier.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusBadge(
                    label: _supplierTypeLabel(supplier.type),
                    tone: supplier.isFactory
                        ? StatusTone.info
                        : StatusTone.brand,
                  ),
                ],
              ),
              if (supplier.place.isNotEmpty || supplier.country != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    if (supplier.place.isNotEmpty) supplier.place,
                    ?supplier.country,
                  ].join(', '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _stars(data.average),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StarRow(value: average, size: 22),
                        Text(
                          'All time · ${_ratingsCount(data.total)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _RatingPeriodPicker(
                value: _period,
                onChanged: (period) {
                  if (period == _period) return;
                  _period = period;
                  _reload();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (data.rank != null) ...[
                    _RankBadge(rank: data.rank!),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      data.rank == null
                          ? 'Not rated in this period'
                          : 'Rank ${data.rank} of ${data.rankOf ?? data.rank} '
                                '${supplier.isFactory ? 'factories' : 'hardware shops'}'
                                ' · ${_stars(data.periodAverage)} ★ from '
                                '${_ratingsCount(data.periodTotal)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: () => _rate(data),
                    icon: const Icon(Icons.star_rate_outlined),
                    label: Text(data.mine == null ? 'Rate' : 'Rate again'),
                  ),
                  if (supplier.websiteUrl != null)
                    OutlinedButton.icon(
                      onPressed: () => _openWebsite(supplier.websiteUrl!),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Website'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Rating distribution',
        icon: Icons.donut_large_outlined,
        trailing: Text('All time', style: theme.textTheme.bodySmall),
        children: [_DistributionChart(buckets: data.distribution)],
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Scores by area',
        icon: Icons.insights_outlined,
        children: [
          _CriteriaChart(
            criteria: data.criteria,
            emptyMessage: 'No detailed scores yet.',
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Monthly trend',
        icon: Icons.show_chart,
        trailing: Text('Last 12 months', style: theme.textTheme.bodySmall),
        children: [_TrendChart(points: data.trend)],
      ),
      const SizedBox(height: AppSpacing.md),
      SectionCard(
        title: 'Recent reviews',
        icon: Icons.rate_review_outlined,
        children: [
          if (data.reviews.isEmpty)
            const EmptyState(
              compact: true,
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet.',
            )
          else
            for (final (index, review) in data.reviews.indexed) ...[
              if (index > 0) const Divider(height: AppSpacing.xl),
              _ReviewTile(review: review),
            ],
        ],
      ),
    ];
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final SupplierReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: review.isHidden ? 0.6 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StarRow(value: review.rating.toDouble(), size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${review.author ?? 'Verified user'} · '
                  '${displayDate(review.ratedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (review.isHidden)
                const StatusBadge(label: 'Hidden', tone: StatusTone.neutral),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(review.comment!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Opens the rating form. Pass [supplier] to rate that one (otherwise the
/// user searches for one) and [mine] to pre-fill the user's rating this
/// month. Returns the server's success message, or null when cancelled.
Future<String?> showRateSupplierSheet(
  BuildContext context,
  ApiClient api, {
  RatedSupplier? supplier,
  SupplierRatingEntry? mine,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _RateSupplierSheet(api: api, supplier: supplier, mine: mine),
  );
}

class _RateSupplierSheet extends StatefulWidget {
  const _RateSupplierSheet({required this.api, this.supplier, this.mine});

  final ApiClient api;
  final RatedSupplier? supplier;
  final SupplierRatingEntry? mine;

  @override
  State<_RateSupplierSheet> createState() => _RateSupplierSheetState();
}

class _RateSupplierSheetState extends State<_RateSupplierSheet> {
  late RatedSupplier? _supplier = widget.supplier;
  final _search = TextEditingController();
  final _comment = TextEditingController();
  Timer? _debounce;
  Future<List<RatedSupplier>>? _results;
  bool _loadingMine = false;
  bool _saving = false;
  bool _rerating = false;
  String? _error;

  int? _rating;
  int? _price;
  int? _quality;
  int? _delivery;
  int? _service;

  @override
  void initState() {
    super.initState();
    if (widget.mine != null) {
      _fill(widget.mine);
    } else if (_supplier != null) {
      _loadMine(_supplier!);
    } else {
      _results = widget.api.ratableSuppliers();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _comment.dispose();
    super.dispose();
  }

  void _fill(SupplierRatingEntry? mine) {
    _rerating = mine != null;
    _rating = mine?.rating == 0 ? null : mine?.rating;
    _price = mine?.priceRating;
    _quality = mine?.qualityRating;
    _delivery = mine?.deliveryRating;
    _service = mine?.serviceRating;
    _comment.text = mine?.comment ?? '';
  }

  Future<void> _loadMine(RatedSupplier supplier) async {
    setState(() => _loadingMine = true);
    SupplierRatingEntry? mine;
    try {
      mine = (await widget.api.supplierPerformance(supplier.id)).mine;
    } on Object {
      // Not pre-filled; the user can still rate.
    }
    if (!mounted || _supplier?.id != supplier.id) return;
    setState(() {
      _fill(mine);
      _loadingMine = false;
    });
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _results = widget.api.ratableSuppliers(search: text));
    });
  }

  void _select(RatedSupplier supplier) {
    setState(() {
      _supplier = supplier;
      _error = null;
    });
    _loadMine(supplier);
  }

  void _change() {
    setState(() {
      _supplier = null;
      _error = null;
      _fill(null);
      _results ??= widget.api.ratableSuppliers(search: _search.text);
    });
  }

  Future<void> _save() async {
    final supplier = _supplier;
    if (supplier == null) return;
    if (_rating == null) {
      setState(() => _error = 'Choose an overall rating from 1 to 5 stars.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.api.rateSupplier(
        supplier.id,
        rating: _rating!,
        priceRating: _price,
        qualityRating: _quality,
        deliveryRating: _delivery,
        serviceRating: _service,
        comment: _comment.text,
      );
      if (mounted) Navigator.of(context).pop(result.message);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supplier = _supplier;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rate a Supplier',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'You can rate each supplier once a month; rating again in '
                'the same month updates your rating.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (supplier == null) ..._picker(theme) else ..._form(supplier),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _picker(ThemeData theme) => [
    TextField(
      controller: _search,
      autofocus: false,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        labelText: 'Hardware or factory',
        hintText: 'Search by name or location...',
      ),
      onChanged: _onSearch,
    ),
    const SizedBox(height: AppSpacing.sm),
    FutureBuilder<List<RatedSupplier>>(
      future: _results,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(
            compact: true,
            error: snapshot.error,
            onRetry: () => setState(
              () =>
                  _results = widget.api.ratableSuppliers(search: _search.text),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final suppliers = snapshot.data!;
        if (suppliers.isEmpty) {
          return const EmptyState(
            compact: true,
            icon: Icons.search_off,
            title: 'No active hardware or factory matches your search.',
          );
        }
        return Column(
          children: [
            for (final s in suppliers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  s.isFactory
                      ? Icons.factory_outlined
                      : Icons.storefront_outlined,
                ),
                title: Text(s.name, maxLines: 2),
                subtitle: Text(
                  [
                    _supplierTypeLabel(s.type),
                    if (s.place.isNotEmpty) s.place,
                  ].join(' · '),
                ),
                trailing: s.ratingsCount == 0
                    ? null
                    : Text(
                        '${_stars(s.rating)} ★',
                        style: theme.textTheme.labelLarge,
                      ),
                onTap: () => _select(s),
              ),
          ],
        );
      },
    ),
  ];

  List<Widget> _form(RatedSupplier supplier) {
    final theme = Theme.of(context);
    final enabled = !_saving && !_loadingMine;
    Widget criterion(String label, int? value, ValueChanged<int?> onChanged) {
      return Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          _StarPicker(
            value: value,
            clearable: true,
            size: 26,
            enabled: enabled,
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ],
      );
    }

    return [
      Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(
            supplier.isFactory
                ? Icons.factory_outlined
                : Icons.storefront_outlined,
          ),
          title: Text(supplier.name),
          subtitle: Text(
            [
              _supplierTypeLabel(supplier.type),
              if (supplier.place.isNotEmpty) supplier.place,
            ].join(' · '),
          ),
          trailing: widget.supplier == null
              ? TextButton(
                  onPressed: _saving ? null : _change,
                  child: const Text('Change'),
                )
              : null,
        ),
      ),
      if (_loadingMine) const LinearProgressIndicator(),
      const SizedBox(height: AppSpacing.lg),
      Text('Overall rating *', style: theme.textTheme.titleSmall),
      const SizedBox(height: AppSpacing.xs),
      Center(
        child: _StarPicker(
          value: _rating,
          size: 40,
          enabled: enabled,
          onChanged: (v) => setState(() {
            _rating = v;
            _error = null;
          }),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Scores by area (optional, tap a chosen star again to clear)',
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.xs),
      criterion('Price', _price, (v) => _price = v),
      criterion('Quality', _quality, (v) => _quality = v),
      criterion('Delivery', _delivery, (v) => _delivery = v),
      criterion('Service', _service, (v) => _service = v),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _comment,
        enabled: enabled,
        maxLength: 1000,
        maxLines: 4,
        minLines: 2,
        decoration: const InputDecoration(
          labelText: 'Comment',
          hintText:
              'What was good, and what could be better? (prices, stock, '
              'delivery, service)',
          alignLabelWithHint: true,
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          _error!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      LoadingButton(
        label: _rerating ? 'Update Rating' : 'Save Rating',
        icon: Icons.check,
        loading: _saving,
        onPressed: enabled ? _save : null,
      ),
    ];
  }
}
