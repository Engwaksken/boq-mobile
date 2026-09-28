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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.l10n.hardwarePrices),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _fetch(),
          tooltip: 'Refresh',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'fetch') _fetchNow();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'fetch',
              child: Row(
                children: [
                  Icon(Icons.cloud_download),
                  SizedBox(width: 8),
                  Text('Fetch Latest Prices'),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    body: Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Prices'),
              Tab(text: 'Categories'),
            ],
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

  Widget _buildAllTab() => Column(
    children: [
      _buildFilters(),
      Expanded(child: _buildList()),
      if (_result != null && _result!.data.isNotEmpty) _buildPaginationFooter(),
    ],
  );

  Widget _buildPaginationFooter() {
    final last = _result?.lastPage ?? 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_page of $last',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              if (_loadingMore)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
        ],
      ),
    );
  }

  void _goToPage(int page) => _fetch(page: page);

  Widget _buildCategoriesTab() {
    if (_categoryStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No categories loaded'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetchFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Load categories'),
            ),
          ],
        ),
      );
    }
    final total = _categoryStats.fold<int>(0, (sum, c) => sum + c.count);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categoryStats.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.apps)),
              title: const Text('All categories'),
              subtitle: Text('$total items'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() => _selectedCategory = null);
                _tabController.animateTo(0);
                _fetch();
              },
            ),
          );
        }
        final cat = _categoryStats[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.category_outlined)),
            title: Text(cat.name),
            subtitle: Text('${cat.count} items'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() => _selectedCategory = cat.name);
              _tabController.animateTo(0);
              _fetch();
            },
          ),
        );
      },
    );
  }

  Widget _buildFilters() => Container(
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
            labelText: 'Search',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _fetch();
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String?>(
            segments: const [
              ButtonSegment(
                value: null,
                label: Text('All'),
                icon: Icon(Icons.list),
              ),
              ButtonSegment(
                value: 'hardware',
                label: Text('Supplier'),
                icon: Icon(Icons.storefront_outlined),
              ),
              ButtonSegment(
                value: 'factory',
                label: Text('Factory'),
                icon: Icon(Icons.factory_outlined),
              ),
            ],
            selected: {_selectedPriceType},
            onSelectionChanged: (selection) => setState(() {
              _selectedPriceType = selection.first;
              _fetch();
            }),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterDropdown(
              'Category',
              _selectedCategory,
              _categories,
              (v) => setState(() {
                _selectedCategory = v;
                _fetch();
              }),
            ),
            _buildFilterDropdown(
              'Supplier',
              _selectedSupplier,
              _suppliers,
              (v) => setState(() {
                _selectedSupplier = v;
                _fetch();
              }),
            ),
            _buildFilterDropdown(
              'Location',
              _selectedLocation,
              _locations,
              (v) => setState(() {
                _selectedLocation = v;
                _fetch();
              }),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> options,
    void Function(String?) onChanged,
  ) => SizedBox(
    width: 160,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      items:
          <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(value: null, child: Text('All')),
          ] +
          options
              .map((o) => DropdownMenuItem<String>(value: o, child: Text(o)))
              .toList(),
      onChanged: onChanged,
    ),
  );

  Widget _buildList() {
    if (_error != null && _result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(onPressed: _fetch, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_result == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _result!.data;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No hardware prices found'),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
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
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
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
  Widget build(BuildContext context) => Card(
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
                    item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'compare') onCompare();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'compare',
                      child: Row(
                        children: [
                          Icon(Icons.compare_arrows),
                          SizedBox(width: 8),
                          Text('Compare'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  avatar: Icon(
                    item.isFactory
                        ? Icons.factory_outlined
                        : Icons.storefront_outlined,
                    size: 16,
                  ),
                  label: Text(item.isFactory ? 'Factory' : 'Supplier'),
                  backgroundColor: item.isFactory
                      ? Colors.purple[50]
                      : Colors.teal[50],
                ),
                if (item.brand.isNotEmpty)
                  Chip(
                    label: Text(item.brand),
                    backgroundColor: Colors.blue[50],
                  ),
                Chip(
                  label: Text(item.category),
                  backgroundColor: Colors.green[50],
                ),
                Chip(
                  label: Text(item.unit),
                  backgroundColor: Colors.orange[50],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${NumberFormat('#,##0').format(item.price)} ${item.currency}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.supplier,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (item.location.isNotEmpty)
                      Text(
                        item.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${item.lastVerifiedAt.isNotEmpty ? 'Verified' : 'Updated'}: ${_formatDate(item.updatedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (item.sourceUrl.isNotEmpty)
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(item.sourceUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Uri.tryParse(item.sourceUrl)?.host ?? 'Source',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF05645B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.open_in_new,
                          size: 12,
                          color: Color(0xFF05645B),
                        ),
                      ],
                    ),
                  )
                else if (item.sourceReference.isNotEmpty)
                  Flexible(
                    child: Text(
                      item.sourceReference,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(hardwarePrice.itemName),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PriceHistoryPage(
                api: api,
                hardwarePrice: hardwarePrice,
                l10n: l10n,
              ),
            ),
          ),
        ),
      ],
    ),
    body: FutureBuilder<HardwarePriceHistory>(
      future: api.hardwarePriceHistory(hardwarePrice.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(friendlyError(snapshot.error)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(data.item, data.summary),
            const SizedBox(height: 16),
            _buildHistoryList(data.history),
          ],
        );
      },
    ),
  );

  Widget _buildSummaryCard(
    HardwarePrice item,
    PriceHistorySummary summary,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.itemName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (item.brand.isNotEmpty) Text('Brand: ${item.brand}'),
          Text('Category: ${item.category}'),
          if (item.specification.isNotEmpty)
            Text('Spec: ${item.specification}'),
          Text('Unit: ${item.unit}'),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Current: ${NumberFormat('#,##0').format(item.price)} ${item.currency}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Supplier: ${item.supplier}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (item.location.isNotEmpty)
                    Text('Location: ${item.location}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(
                'Lowest',
                NumberFormat('#,##0').format(summary.lowest),
                summary.lowest <= item.price ? Colors.green : Colors.red,
              ),
              _stat(
                'Highest',
                NumberFormat('#,##0').format(summary.highest),
                summary.highest >= item.price ? Colors.red : Colors.green,
              ),
              _stat(
                'Average',
                NumberFormat('#,##0').format(summary.average),
                Colors.blue,
              ),
              _stat(
                'Change',
                '${summary.changePercent >= 0 ? '+' : ''}${summary.changePercent.toStringAsFixed(1)}%',
                summary.changePercent >= 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _stat(String label, String value, Color color) => Column(
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      Text(
        value,
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
    ],
  );

  Widget _buildHistoryList(List<PriceHistory> history) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Price History (${history.length} records)',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      const SizedBox(height: 8),
      if (history.isEmpty) const Center(child: Text('No history available')),
      for (final h in history)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(
              '${NumberFormat('#,##0').format(h.price)} ${h.currency}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            title: Text(h.supplier),
            subtitle: h.location.isNotEmpty ? Text(h.location) : null,
            trailing: Text(_formatDate(h.recordedAt)),
          ),
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
          return Center(child: Text(friendlyError(snapshot.error)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final history = snapshot.data!.history;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final h = history[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(
                  '${NumberFormat('#,##0').format(h.price)} ${h.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                title: Text(h.supplier),
                subtitle: h.location.isNotEmpty ? Text(h.location) : null,
                trailing: Text(_formatDate(h.recordedAt)),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.l10n.priceComparison),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _compare),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!),
                const SizedBox(height: 16),
                FilledButton(onPressed: _compare, child: const Text('Retry')),
              ],
            ),
          )
        : _result == null
        ? const Center(child: Text('No comparison data'))
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Attribute')),
                ..._result!.items.map(
                  (item) => DataColumn(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.itemName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.brand.isNotEmpty)
                          Text(
                            item.brand,
                            style: const TextStyle(fontSize: 11),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: item.badges
                              .map(
                                (b) => Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    b,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              rows: [
                _dataRow('Category', (item) => item.category),
                _dataRow(
                  'Specification',
                  (item) =>
                      item.specification.isEmpty ? '—' : item.specification,
                ),
                _dataRow('Unit', (item) => item.unit),
                _dataRow(
                  'Price',
                  (item) =>
                      '${NumberFormat('#,##0').format(item.price)} ${item.currency}',
                ),
                _dataRow('Supplier', (item) => item.supplier),
                _dataRow(
                  'Location',
                  (item) => item.location.isEmpty ? '—' : item.location,
                ),
                _dataRow(
                  'Source',
                  (item) =>
                      item.sourceReference.isEmpty ? '—' : item.sourceReference,
                ),
                _dataRow('Updated', (item) => _formatDate(item.fetchedAt)),
                _dataRow('Match %', (item) => '${item.similarityScore}%'),
                _dataRow(
                  'Variance',
                  (item) => item.variancePercent == null
                      ? '—'
                      : '${item.variancePercent! >= 0 ? '+' : ''}${item.variancePercent!.toStringAsFixed(1)}%',
                ),
                _dataRow(
                  'Trend',
                  (item) => item.priceHistory.trend.capitalize(),
                ),
                _dataRow('Records', (item) => '${item.priceHistory.records}'),
                _dataRow(
                  'Lowest',
                  (item) =>
                      NumberFormat('#,##0').format(item.priceHistory.lowest),
                ),
                _dataRow(
                  'Highest',
                  (item) =>
                      NumberFormat('#,##0').format(item.priceHistory.highest),
                ),
                _dataRow(
                  'Average',
                  (item) =>
                      NumberFormat('#,##0').format(item.priceHistory.average),
                ),
                _dataRow('Rating', (item) => '${item.rating.overall}/100'),
                _dataRow('Value Score', (item) => '${item.rating.valueScore}'),
                _dataRow(
                  'Stability',
                  (item) => '${item.rating.stabilityScore}',
                ),
                _dataRow(
                  'Freshness',
                  (item) => '${item.rating.freshnessScore}',
                ),
              ],
            ),
          ),
  );

  DataRow _dataRow(String label, String Function(PriceComparisonItem) getter) =>
      DataRow(
        cells: [
          DataCell(
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          ..._result!.items.map((item) => DataCell(Text(getter(item)))),
        ],
      );

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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.l10n.bestRecommendations),
      actions: [
        DropdownButton<String>(
          value: _selectedCategory,
          hint: const Text('Category'),
          items:
              <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(value: null, child: Text('All')),
              ] +
              _categories
                  .map(
                    (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
                  )
                  .toList(),
          onChanged: (v) => setState(() {
            _selectedCategory = v;
            _fetch();
          }),
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!),
                const SizedBox(height: 16),
                FilledButton(onPressed: _fetch, child: const Text('Retry')),
              ],
            ),
          )
        : _items.isEmpty
        ? const Center(child: Text('No recommendations available'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _RecommendationCard(
                item: item,
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
              );
            },
          ),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onTap});
  final PriceComparisonItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
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
                    item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (item.brand.isNotEmpty)
                  Chip(
                    label: Text(item.brand),
                    backgroundColor: Colors.blue[50],
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _ratingColor(item.rating.overall),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.rating.overall}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(item.category),
                  backgroundColor: Colors.green[50],
                ),
                Chip(
                  label: Text(item.unit),
                  backgroundColor: Colors.orange[50],
                ),
                if (item.badges.isNotEmpty)
                  ...item.badges.map(
                    (b) => Chip(
                      label: Text(b),
                      backgroundColor: Colors.amber[100],
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${NumberFormat('#,##0').format(item.price)} ${item.currency}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF047857),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.supplier,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (item.location.isNotEmpty)
                      Text(
                        item.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat('Value', item.rating.valueScore, Colors.green),
                const SizedBox(width: 16),
                _miniStat('Stability', item.rating.stabilityScore, Colors.blue),
                const SizedBox(width: 16),
                _miniStat(
                  'Freshness',
                  item.rating.freshnessScore,
                  Colors.orange,
                ),
                const Spacer(),
                OutlinedButton(onPressed: onTap, child: const Text('Details')),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _miniStat(String label, int score, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      Row(
        children: [
          Icon(Icons.star, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            '$score',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    ],
  );

  Color _ratingColor(int rating) {
    if (rating >= 80) return Colors.green;
    if (rating >= 60) return Colors.orange;
    return Colors.red;
  }
}
