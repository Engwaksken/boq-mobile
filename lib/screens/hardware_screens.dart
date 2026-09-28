part of '../main.dart';

class HardwarePricesPage extends StatefulWidget {
  const HardwarePricesPage({super.key, required this.api, required this.l10n});
  final ApiClient api;
  final AppLocalizations l10n;

  @override
  State<HardwarePricesPage> createState() => _HardwarePricesPageState();
}

class _HardwarePricesPageState extends State<HardwarePricesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  HardwarePricePaginated? _result;
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedSupplier;
  String? _selectedLocation;

  /// null = all, 'hardware' = supplier prices, 'factory' = factory prices.
  String? _selectedPriceType;
  List<String> _categories = [];
  final List<String> _suppliers = [];
  final List<String> _locations = [];
  List<HardwarePriceCategory> _categoryStats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetch();
    _fetchFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFilters() async {
    final names = <String>{};
    final stats = <HardwarePriceCategory>[];
    final priceCats =
        await _loadOrNull(widget.api.hardwarePriceCategories) ??
        const <HardwarePriceCategory>[];
    stats.addAll(priceCats);
    names.addAll(priceCats.map((c) => c.name).where((n) => n.isNotEmpty));
    final hardwareCats =
        await _loadOrNull(widget.api.hardwareCategoriesAdmin) ??
        const <HardwareCategory>[];
    names.addAll(hardwareCats.map((c) => c.name).where((n) => n.isNotEmpty));
    if (mounted) {
      setState(() {
        _categories = names.toList()..sort();
        if (stats.isNotEmpty) {
          _categoryStats = stats..sort((a, b) => a.name.compareTo(b.name));
        }
      });
    }
  }

  Future<void> _fetch({bool loadMore = false, int? page}) async {
    if (_loading) return;
    final target = page ?? (loadMore ? _page + 1 : 1);
    if (loadMore) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await widget.api.hardwarePrices(
        priceType: _selectedPriceType,
        category: _selectedCategory,
        supplier: _selectedSupplier,
        location: _selectedLocation,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        page: target,
        perPage: 20,
      );
      if (mounted) {
        setState(() {
          if (loadMore) {
            _result = HardwarePricePaginated(
              data: [...?_result?.data, ...result.data],
              currentPage: result.currentPage,
              lastPage: result.lastPage,
              perPage: result.perPage,
              total: result.total,
            );
            _page = result.currentPage;
          } else {
            _result = result;
            _page = target;
          }
          _loading = false;
          _loadingMore = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _fetch());
  }

  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The home shell's AppBar already shows the page title, so this page only
    // carries a compact tab strip with its actions.
    return Scaffold(
      body: Column(
        children: [
          Material(
            color: scheme.surface,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'All Prices'),
                        Tab(text: 'Categories'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _fetch(),
                    tooltip: 'Refresh',
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More actions',
                    onSelected: (value) {
                      if (value == 'fetch') _fetchNow();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'fetch',
                        child: Row(
                          children: [
                            Icon(Icons.cloud_download_outlined),
                            SizedBox(width: AppSpacing.md),
                            Text('Fetch Latest Prices'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAllTab(), _buildCategoriesTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTab() => Column(
    children: [
      _buildFilters(),
      if (_loading && _result != null)
        const LinearProgressIndicator(minHeight: 2),
      Expanded(child: _buildList()),
      if (_result != null && _result!.data.isNotEmpty) _buildPaginationFooter(),
    ],
  );

  Widget _buildPaginationFooter() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = _result?.lastPage ?? 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Page $_page of $last',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
                onPressed: _page <= 1 ? null : () => _goToPage(_page - 1),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
                onPressed: _page >= last ? null : () => _goToPage(_page + 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToPage(int page) => _fetch(page: page);

  /// Wraps a non-list state (empty/error) so it can still be pulled to refresh.
  Widget _pullable(Future<void> Function() onRefresh, Widget child) =>
      RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [SizedBox(height: constraints.maxHeight, child: child)],
          ),
        ),
      );

  Widget _buildCategoriesTab() {
    if (_categoryStats.isEmpty) {
      return _pullable(
        _fetchFilters,
        EmptyState(
          icon: Icons.category_outlined,
          title: 'No categories loaded',
          actionLabel: 'Load categories',
          actionIcon: Icons.refresh,
          onAction: _fetchFilters,
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final total = _categoryStats.fold<int>(0, (sum, c) => sum + c.count);
    Widget? selectedMark(bool selected) => selected
        ? Icon(Icons.check_circle, size: 20, color: scheme.primary)
        : null;
    return RefreshIndicator(
      onRefresh: _fetchFilters,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page,
        itemCount: _categoryStats.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return ListItemCard(
              leading: const IconTile(icon: Icons.apps),
              title: 'All categories',
              subtitle: '$total items',
              trailing: selectedMark(_selectedCategory == null),
              onTap: () {
                setState(() => _selectedCategory = null);
                _tabController.animateTo(0);
                _fetch();
              },
            );
          }
          final cat = _categoryStats[index - 1];
          return ListItemCard(
            leading: const IconTile(
              icon: Icons.category_outlined,
              tone: StatusTone.neutral,
            ),
            title: cat.name,
            subtitle: '${cat.count} items',
            trailing: selectedMark(_selectedCategory == cat.name),
            onTap: () {
              setState(() => _selectedCategory = cat.name);
              _tabController.animateTo(0);
              _fetch();
            },
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    final scheme = Theme.of(context).colorScheme;
    const priceTypes = <(String?, String, IconData)>[
      (null, 'All', Icons.list),
      ('hardware', 'Supplier', Icons.storefront_outlined),
      ('factory', 'Factory', Icons.factory_outlined),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) => TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.l10n.search,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _fetch();
                          },
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (value, label, icon) in priceTypes) ...[
                    ChoiceChip(
                      avatar: Icon(icon, size: 18),
                      label: Text(label),
                      showCheckmark: false,
                      selected: _selectedPriceType == value,
                      onSelected: (_) {
                        if (_selectedPriceType == value) return;
                        setState(() {
                          _selectedPriceType = value;
                          _fetch();
                        });
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: AppSpacing.sm),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterMenuChip(
                    label: 'Category',
                    icon: Icons.category_outlined,
                    value: _selectedCategory,
                    options: _categories,
                    onChanged: (v) => setState(() {
                      _selectedCategory = v;
                      _fetch();
                    }),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterMenuChip(
                    label: 'Supplier',
                    icon: Icons.storefront_outlined,
                    value: _selectedSupplier,
                    options: _suppliers,
                    onChanged: (v) => setState(() {
                      _selectedSupplier = v;
                      _fetch();
                    }),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterMenuChip(
                    label: 'Location',
                    icon: Icons.place_outlined,
                    value: _selectedLocation,
                    options: _locations,
                    onChanged: (v) => setState(() {
                      _selectedLocation = v;
                      _fetch();
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_error != null && _result == null) {
      return _pullable(
        () => _fetch(),
        ErrorState(error: _error, onRetry: _fetch),
      );
    }
    if (_result == null) {
      return const SkeletonList();
    }
    final items = _result!.data;
    if (items.isEmpty) {
      return _pullable(
        () => _fetch(),
        const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No hardware prices found',
          message: 'Try adjusting your filters',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetch(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200 &&
              !_loadingMore &&
              _page < _result!.lastPage) {
            _fetch(loadMore: true);
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.page,
          itemCount: items.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }
            final item = items[index];
            return _HardwarePriceCard(
              item: item,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HardwarePriceDetailPage(
                    api: widget.api,
                    hardwarePrice: item,
                    l10n: widget.l10n,
                  ),
                ),
              ),
              onCompare: () => _addToCompare(item),
            );
          },
        ),
      ),
    );
  }

  final List<HardwarePrice> _compareItems = [];

  void _addToCompare(HardwarePrice item) {
    if (_compareItems.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 items for comparison')),
      );
      return;
    }
    if (_compareItems.any((i) => i.id == item.id)) return;
    setState(() => _compareItems.add(item));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to comparison (${_compareItems.length}/5)'),
      ),
    );
  }

  void _fetchNow() async {
    try {
      final result = await widget.api.fetchDailyPrices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched: ${result['fetched']} prices')),
        );
        _fetch();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

/// Compact chip that opens a menu of filter options ("All" clears it).
class _FilterMenuChip extends StatelessWidget {
  const _FilterMenuChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = value != null;
    Widget mark(bool on) => on
        ? Icon(Icons.check, size: 18, color: scheme.primary)
        : const SizedBox(width: 18);
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: mark(value == null),
          onPressed: () => onChanged(null),
          child: const Text('All'),
        ),
        for (final option in options)
          MenuItemButton(
            leadingIcon: mark(value == option),
            onPressed: () => onChanged(option),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(option, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
      builder: (context, controller, _) => FilterChip(
        avatar: Icon(icon, size: 18),
        tooltip: '$label filter',
        showCheckmark: false,
        selected: selected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                selected ? value! : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
        onSelected: (_) =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _HardwarePriceCard extends StatelessWidget {
  const _HardwarePriceCard({
    required this.item,
    required this.onTap,
    required this.onCompare,
  });
  final HardwarePrice item;
  final VoidCallback onTap;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final place = [
      item.supplier,
      item.location,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: IconTile(
                        icon: item.isFactory
                            ? Icons.factory_outlined
                            : Icons.storefront_outlined,
                        tone: item.isFactory
                            ? StatusTone.info
                            : StatusTone.brand,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            if (place.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                place,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'More options',
                      onSelected: (v) {
                        if (v == 'compare') onCompare();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'compare',
                          child: Row(
                            children: [
                              Icon(Icons.compare_arrows),
                              SizedBox(width: AppSpacing.md),
                              Text('Compare'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs + 2,
                        runSpacing: AppSpacing.xs + 2,
                        children: [
                          StatusBadge(
                            label: item.isFactory ? 'Factory' : 'Supplier',
                            tone: item.isFactory
                                ? StatusTone.info
                                : StatusTone.brand,
                          ),
                          if (item.brand.isNotEmpty)
                            StatusBadge(
                              label: item.brand,
                              icon: Icons.sell_outlined,
                            ),
                          if (item.category.isNotEmpty)
                            StatusBadge(label: item.category),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: AmountText(
                              item.price,
                              currency: item.currency,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          if (item.unit.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '/ ${item.unit}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Divider(height: 1, color: scheme.outlineVariant),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            item.lastVerifiedAt.isNotEmpty
                                ? Icons.verified_outlined
                                : Icons.access_time,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              '${item.lastVerifiedAt.isNotEmpty ? 'Verified' : 'Updated'}: ${_formatDate(item.updatedAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          if (item.sourceUrl.isNotEmpty)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                textStyle: theme.textTheme.labelSmall,
                              ),
                              onPressed: () => launchUrl(
                                Uri.parse(item.sourceUrl),
                                mode: LaunchMode.externalApplication,
                              ),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: Text(
                                Uri.tryParse(item.sourceUrl)?.host ?? 'Source',
                              ),
                            )
                          else if (item.sourceReference.isNotEmpty)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Text(
                                  item.sourceReference,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

/// Tone for a price trend string ("up" is bad for buyers, "down" is good).
StatusTone _hwTrendTone(String trend) => switch (trend.toLowerCase()) {
  'up' || 'rising' || 'increasing' => StatusTone.danger,
  'down' || 'falling' || 'decreasing' => StatusTone.success,
  _ => StatusTone.neutral,
};

IconData _hwTrendIcon(String trend) => switch (trend.toLowerCase()) {
  'up' || 'rising' || 'increasing' => Icons.trending_up,
  'down' || 'falling' || 'decreasing' => Icons.trending_down,
  _ => Icons.trending_flat,
};

/// One point on a price-history timeline.
class _HwPriceHistoryEntry extends StatelessWidget {
  const _HwPriceHistoryEntry({
    required this.entry,
    required this.date,
    this.isFirst = false,
    this.isLast = false,
    this.boxed = false,
  });

  final PriceHistory entry;
  final String date;
  final bool isFirst;
  final bool isLast;

  /// When true each entry sits in its own card (full-page list).
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lineColor = scheme.outlineVariant;
    final topGap = boxed ? 20.0 : 14.0;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountText(
                entry.price,
                currency: entry.currency,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(entry.supplier, style: theme.textTheme.bodyMedium),
              if (entry.location.isNotEmpty)
                Text(entry.location, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          date,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: topGap,
                  color: isFirst ? Colors.transparent : lineColor,
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst ? scheme.primary : scheme.surface,
                    border: Border.all(
                      color: isFirst ? scheme.primary : scheme.outline,
                      width: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: boxed
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: content,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: content,
                  ),
          ),
        ],
      ),
    );
  }
}

class HardwarePriceDetailPage extends StatelessWidget {
  const HardwarePriceDetailPage({
    super.key,
    required this.api,
    required this.hardwarePrice,
    required this.l10n,
  });
  final ApiClient api;
  final HardwarePrice hardwarePrice;
  final AppLocalizations l10n;

  void _openHistory(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          PriceHistoryPage(api: api, hardwarePrice: hardwarePrice, l10n: l10n),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(hardwarePrice.itemName),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Price History',
          onPressed: () => _openHistory(context),
        ),
      ],
    ),
    body: FutureBuilder<HardwarePriceHistory>(
      future: api.hardwarePriceHistory(hardwarePrice.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const LoadingState();
        }
        final data = snapshot.data!;
        return ListView(
          padding: AppSpacing.page,
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCard(context, data.item, data.summary),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDetailsCard(data.item),
                  const SizedBox(height: AppSpacing.lg),
                  _buildHistoryList(data.history),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => _openHistory(context),
                    icon: const Icon(Icons.history),
                    label: const Text('Price History'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _buildSummaryCard(
    BuildContext context,
    HardwarePrice item,
    PriceHistorySummary summary,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final place = [
      item.supplier,
      item.location,
    ].where((s) => s.isNotEmpty).join(' · ');
    final changeUp = summary.changePercent >= 0;
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(
                  icon: item.isFactory
                      ? Icons.factory_outlined
                      : Icons.storefront_outlined,
                  tone: item.isFactory ? StatusTone.info : StatusTone.brand,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName, style: theme.textTheme.titleLarge),
                      if (place.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(place, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs + 2,
              runSpacing: AppSpacing.xs + 2,
              children: [
                StatusBadge(
                  label: item.isFactory ? 'Factory' : 'Supplier',
                  tone: item.isFactory ? StatusTone.info : StatusTone.brand,
                ),
                if (item.category.isNotEmpty) StatusBadge(label: item.category),
                StatusBadge(
                  label: summary.trend.capitalize(),
                  tone: _hwTrendTone(summary.trend),
                  icon: _hwTrendIcon(summary.trend),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Current',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: AmountText(
                    item.price,
                    currency: item.currency,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
                if (item.unit.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text('/ ${item.unit}', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _stat(
                  context,
                  'Lowest',
                  NumberFormat('#,##0').format(summary.lowest),
                  summary.lowest <= item.price
                      ? AppColors.success
                      : AppColors.danger,
                ),
                _stat(
                  context,
                  'Highest',
                  NumberFormat('#,##0').format(summary.highest),
                  summary.highest >= item.price
                      ? AppColors.danger
                      : AppColors.success,
                ),
                _stat(
                  context,
                  'Average',
                  NumberFormat('#,##0').format(summary.average),
                  AppColors.info,
                ),
                _stat(
                  context,
                  'Change',
                  '${changeUp ? '+' : ''}${summary.changePercent.toStringAsFixed(1)}%',
                  changeUp ? AppColors.danger : AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(HardwarePrice item) => SectionCard(
    title: 'Details',
    icon: Icons.info_outline,
    children: [
      if (item.brand.isNotEmpty) KeyValueRow(label: 'Brand', value: item.brand),
      KeyValueRow(label: 'Category', value: item.category),
      if (item.specification.isNotEmpty)
        KeyValueRow(label: 'Spec', value: item.specification),
      KeyValueRow(label: 'Unit', value: item.unit),
      KeyValueRow(label: 'Supplier', value: item.supplier),
      if (item.location.isNotEmpty)
        KeyValueRow(label: 'Location', value: item.location),
    ],
  );

  Widget _buildHistoryList(List<PriceHistory> history) => SectionCard(
    title: 'Price History (${history.length} records)',
    icon: Icons.timeline,
    children: [
      if (history.isEmpty)
        const EmptyState(
          icon: Icons.history,
          title: 'No history available',
          compact: true,
        ),
      for (var i = 0; i < history.length; i++)
        _HwPriceHistoryEntry(
          entry: history[i],
          date: _formatDate(history[i].recordedAt),
          isFirst: i == 0,
          isLast: i == history.length - 1,
        ),
    ],
  );

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

class PriceHistoryPage extends StatelessWidget {
  const PriceHistoryPage({
    super.key,
    required this.api,
    required this.hardwarePrice,
    required this.l10n,
  });
  final ApiClient api;
  final HardwarePrice hardwarePrice;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${hardwarePrice.itemName} - Price History')),
    body: FutureBuilder<HardwarePriceHistory>(
      future: api.hardwarePriceHistory(hardwarePrice.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error);
        }
        if (!snapshot.hasData) {
          return const SkeletonList();
        }
        final history = snapshot.data!.history;
        if (history.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            title: 'No history available',
          );
        }
        return ListView.builder(
          padding: AppSpacing.page,
          itemCount: history.length,
          itemBuilder: (context, index) {
            final h = history[index];
            return ContentWidth(
              child: _HwPriceHistoryEntry(
                entry: h,
                date: _formatDate(h.recordedAt),
                isFirst: index == 0,
                isLast: index == history.length - 1,
                boxed: true,
              ),
            );
          },
        );
      },
    ),
  );

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

class PriceComparisonPage extends StatefulWidget {
  const PriceComparisonPage({
    super.key,
    required this.api,
    required this.l10n,
    required this.items,
  });
  final ApiClient api;
  final AppLocalizations l10n;
  final List<HardwarePrice> items;

  @override
  State<PriceComparisonPage> createState() => _PriceComparisonPageState();
}

class _PriceComparisonPageState extends State<PriceComparisonPage> {
  PriceComparisonResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _compare();
  }

  Future<void> _compare() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.hardwarePriceCompare(
        widget.items.map((e) => e.id).toList(),
      );
      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  Widget _pullable(Widget child) => RefreshIndicator(
    onRefresh: _compare,
    child: LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: constraints.maxHeight, child: child)],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.l10n.priceComparison),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _compare,
        ),
      ],
    ),
    body: _loading
        ? const SkeletonList(itemCount: 3)
        : _error != null
        ? _pullable(ErrorState(error: _error, onRetry: _compare))
        : _result == null || _result!.items.isEmpty
        ? _pullable(
            const EmptyState(
              icon: Icons.compare_arrows,
              title: 'No comparison data',
            ),
          )
        : _buildComparison(),
  );

  Widget _buildComparison() {
    final items = _result!.items;
    final cheapest = items.map((i) => i.price).reduce((a, b) => a < b ? a : b);
    return RefreshIndicator(
      onRefresh: _compare,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ContentWidth(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildItemCard(
                context,
                item,
                isCheapest: items.length > 1 && item.price == cheapest,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    PriceComparisonItem item, {
    required bool isCheapest,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final variance = item.variancePercent;
    final trend = item.priceHistory.trend;
    Widget group(List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Divider(height: 1, color: scheme.outlineVariant),
        const SizedBox(height: AppSpacing.sm),
        ...rows,
      ],
    );
    return Card(
      shape: isCheapest
          ? const RoundedRectangleBorder(
              borderRadius: AppRadii.card,
              side: BorderSide(color: AppColors.success, width: 1.5),
            )
          : null,
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName, style: theme.textTheme.titleMedium),
                      if (item.brand.isNotEmpty)
                        Text(item.brand, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (isCheapest) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const StatusBadge(
                    label: 'Lowest',
                    tone: StatusTone.success,
                    icon: Icons.savings_outlined,
                  ),
                ],
              ],
            ),
            if (item.badges.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs + 2,
                runSpacing: AppSpacing.xs + 2,
                children: [
                  for (final b in item.badges)
                    StatusBadge(label: b, tone: StatusTone.info),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: AmountText(
                    item.price,
                    currency: item.currency,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isCheapest ? AppColors.success : scheme.primary,
                    ),
                  ),
                ),
                if (item.unit.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text('/ ${item.unit}', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            group([
              KeyValueRow(label: 'Category', value: item.category),
              KeyValueRow(
                label: 'Specification',
                value: item.specification.isEmpty ? '—' : item.specification,
              ),
              KeyValueRow(label: 'Unit', value: item.unit),
              KeyValueRow(
                label: 'Price',
                value:
                    '${NumberFormat('#,##0').format(item.price)} ${item.currency}',
              ),
              KeyValueRow(label: 'Supplier', value: item.supplier),
              KeyValueRow(
                label: 'Location',
                value: item.location.isEmpty ? '—' : item.location,
              ),
              KeyValueRow(
                label: 'Source',
                value: item.sourceReference.isEmpty
                    ? '—'
                    : item.sourceReference,
              ),
              KeyValueRow(label: 'Updated', value: _formatDate(item.fetchedAt)),
              KeyValueRow(label: 'Match %', value: '${item.similarityScore}%'),
              KeyValueRow(
                label: 'Variance',
                value: variance == null
                    ? '—'
                    : '${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)}%',
                valueStyle: variance == null
                    ? null
                    : theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: variance > 0
                            ? AppColors.danger
                            : AppColors.success,
                      ),
              ),
            ]),
            group([
              KeyValueRow(
                label: 'Trend',
                value: trend.capitalize(),
                icon: _hwTrendIcon(trend),
                valueStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _hwTrendTone(trend).foreground(scheme),
                ),
              ),
              KeyValueRow(
                label: 'Records',
                value: '${item.priceHistory.records}',
              ),
              KeyValueRow(
                label: 'Lowest',
                value: NumberFormat('#,##0').format(item.priceHistory.lowest),
              ),
              KeyValueRow(
                label: 'Highest',
                value: NumberFormat('#,##0').format(item.priceHistory.highest),
              ),
              KeyValueRow(
                label: 'Average',
                value: NumberFormat('#,##0').format(item.priceHistory.average),
              ),
            ]),
            group([
              KeyValueRow(
                label: 'Rating',
                value: '${item.rating.overall}/100',
                emphasize: true,
              ),
              KeyValueRow(
                label: 'Value Score',
                value: '${item.rating.valueScore}',
              ),
              KeyValueRow(
                label: 'Stability',
                value: '${item.rating.stabilityScore}',
              ),
              KeyValueRow(
                label: 'Freshness',
                value: '${item.rating.freshnessScore}',
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key, required this.api, required this.l10n});
  final ApiClient api;
  final AppLocalizations l10n;

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  List<PriceComparisonItem> _items = [];
  bool _loading = true;
  String? _error;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final cats = await _loadOrNull(widget.api.hardwarePriceCategories);
    if (cats == null || !mounted) return;
    setState(() => _categories = cats.map((c) => c.name).toList());
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.api.hardwarePriceRecommendations(
        category: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  void _selectCategory(String? v) => setState(() {
    _selectedCategory = v;
    _fetch();
  });

  Widget _pullable(Widget child) => RefreshIndicator(
    onRefresh: _fetch,
    child: LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: constraints.maxHeight, child: child)],
      ),
    ),
  );

  Widget _buildCategoryBar() {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.category_outlined, size: 18),
              label: const Text('All'),
              showCheckmark: false,
              selected: _selectedCategory == null,
              onSelected: (_) => _selectCategory(null),
            ),
            for (final c in _categories) ...[
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: Text(c),
                showCheckmark: false,
                selected: _selectedCategory == c,
                onSelected: (_) => _selectCategory(c),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const SkeletonList();
    if (_error != null) {
      return _pullable(ErrorState(error: _error, onRetry: _fetch));
    }
    if (_items.isEmpty) {
      return _pullable(
        const EmptyState(
          icon: Icons.recommend_outlined,
          title: 'No recommendations available',
        ),
      );
    }
    final bestRating = _items
        .map((i) => i.rating.overall)
        .reduce((a, b) => a > b ? a : b);
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ContentWidth(
            child: _RecommendationCard(
              item: item,
              isBest: item.rating.overall == bestRating,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HardwarePriceDetailPage(
                    api: widget.api,
                    hardwarePrice: HardwarePrice.fromJson({
                      'id': item.id,
                      'item_name': item.itemName,
                      'brand': item.brand,
                      'category': item.category,
                      'specification': item.specification,
                      'unit': item.unit,
                      'price': item.price,
                      'currency': item.currency,
                      'supplier': item.supplier,
                      'location': item.location,
                      'source_reference': item.sourceReference,
                      'fetched_at': item.fetchedAt,
                      'is_active': true,
                    }),
                    l10n: widget.l10n,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.l10n.bestRecommendations),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _fetch,
        ),
      ],
    ),
    body: Column(
      children: [
        _buildCategoryBar(),
        Expanded(child: _buildBody()),
      ],
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.item,
    required this.onTap,
    this.isBest = false,
  });
  final PriceComparisonItem item;
  final VoidCallback onTap;

  /// Highest-rated recommendation in the current list.
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratingTone = _ratingTone(item.rating.overall);
    final place = [
      item.supplier,
      item.location,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: Card(
        shape: isBest
            ? const RoundedRectangleBorder(
                borderRadius: AppRadii.card,
                side: BorderSide(color: AppColors.success, width: 1.5),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          if (item.brand.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(item.brand, style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Semantics(
                      label: 'Rating ${item.rating.overall}',
                      excludeSemantics: true,
                      child: StatusBadge(
                        label: '${item.rating.overall}',
                        tone: ratingTone,
                        icon: isBest
                            ? Icons.workspace_premium_outlined
                            : Icons.star_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Wrap(
                  spacing: AppSpacing.xs + 2,
                  runSpacing: AppSpacing.xs + 2,
                  children: [
                    if (item.category.isNotEmpty)
                      StatusBadge(label: item.category),
                    if (item.unit.isNotEmpty) StatusBadge(label: item.unit),
                    for (final b in item.badges)
                      StatusBadge(label: b, tone: StatusTone.warning),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AmountText(
                  item.price,
                  currency: item.currency,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isBest ? AppColors.success : scheme.primary,
                  ),
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: scheme.outlineVariant),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _miniStat(
                      context,
                      'Value',
                      item.rating.valueScore,
                      AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _miniStat(
                      context,
                      'Stability',
                      item.rating.stabilityScore,
                      AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _miniStat(
                      context,
                      'Freshness',
                      item.rating.freshnessScore,
                      AppColors.warning,
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: onTap,
                      child: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(BuildContext context, String label, int score, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.star_rounded, size: 14, color: color),
            const SizedBox(width: 2),
            Text(
              '$score',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  StatusTone _ratingTone(int rating) {
    if (rating >= 80) return StatusTone.success;
    if (rating >= 60) return StatusTone.warning;
    return StatusTone.danger;
  }
}
