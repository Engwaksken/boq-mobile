part of '../main.dart';

/// Every BOQ the user can see, with search, edit and delete.
class BoqsPage extends StatefulWidget {
  const BoqsPage({super.key, required this.api, required this.l10n});

  final ApiClient api;
  final AppLocalizations l10n;

  @override
  State<BoqsPage> createState() => _BoqsPageState();
}

class _BoqsPageState extends State<BoqsPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<BoqListItem>? _items;
  Object? _error;
  int _page = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result = await widget.api.boqs(search: _search.text);
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _page = 1;
        _lastPage = result.lastPage;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final result = await widget.api.boqs(
        search: _search.text,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _items = [...?_items, ...result.items];
        _page++;
        _lastPage = result.lastPage;
      });
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _open(BoqListItem boq) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            BoqDetailPage(api: widget.api, boqId: boq.id, title: boq.name),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _edit(BoqListItem boq) async {
    if (await showEditBoqSheet(context, widget.api, boq)) _load();
  }

  Future<void> _delete(BoqListItem boq) async {
    if (await confirmDeleteBoq(context, widget.api, boq.id, boq.name)) {
      setState(() => _items?.removeWhere((b) => b.id == boq.id));
    }
  }

  Widget _fill(Widget child) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [SizedBox(height: constraints.maxHeight, child: child)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final Widget body;
    if (_error != null && items == null) {
      body = _fill(ErrorState(error: _error, onRetry: _load));
    } else if (items == null) {
      body = const SkeletonList();
    } else if (items.isEmpty) {
      body = _fill(
        EmptyState(
          icon: Icons.receipt_long_outlined,
          title: _search.text.isEmpty ? 'No BOQs yet' : 'No matching BOQs',
          message: _search.text.isEmpty
              ? 'Import a BOQ into one of your projects to see it here.'
              : 'Try a different search.',
        ),
      );
    } else {
      body = NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) _loadMore();
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.page.copyWith(bottom: 96),
          itemCount: items.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= items.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final boq = items[index];
            return ContentWidth(
              child: _BoqListTile(
                boq: boq,
                onTap: () => _open(boq),
                onEdit: () => _edit(boq),
                onDelete: () => _delete(boq),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('BOQs')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'boqs-import',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(widget.l10n.importBoq)),
                body: ImportPage(l10n: widget.l10n, api: widget.api),
              ),
            ),
          );
          _load();
        },
        icon: const Icon(Icons.upload_file_outlined),
        label: Text(widget.l10n.importBoq),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: ContentWidth(
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: _onSearch,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search BOQs or projects',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _search,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              _load();
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _load, child: body),
          ),
        ],
      ),
    );
  }
}

class _BoqListTile extends StatelessWidget {
  const _BoqListTile({
    required this.boq,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final BoqListItem boq;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final details = [
      [
        if (boq.projectName.isNotEmpty) boq.projectName,
        '${boq.itemsCount} items',
        if (boq.createdAt.isNotEmpty) displayDate(boq.createdAt),
      ].join(' · '),
      ?boqTotalsLine(boq.totals, boq.currency),
    ].join('\n');
    return ListItemCard(
      leading: const IconTile(icon: Icons.receipt_long_outlined),
      title: boq.name.isEmpty ? 'Untitled BOQ' : boq.name,
      subtitle: details,
      showChevron: false,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(
            label: boq.status.replaceAll('_', ' ').capitalize(),
            tone: _boqStatusTone(boq.status),
          ),
          BoqActionsMenu(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

/// "Edit" / "Delete" overflow menu for a BOQ.
class BoqActionsMenu extends StatelessWidget {
  const BoqActionsMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'BOQ actions',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: AppSpacing.md),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.danger),
              SizedBox(width: AppSpacing.md),
              Text('Delete', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Edits a BOQ's name, description and project. Returns true when saved.
Future<bool> showEditBoqSheet(
  BuildContext context,
  ApiClient api,
  BoqListItem boq,
) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _EditBoqSheet(api: api, boq: boq),
  );
  return saved == true;
}

class _EditBoqSheet extends StatefulWidget {
  const _EditBoqSheet({required this.api, required this.boq});

  final ApiClient api;
  final BoqListItem boq;

  @override
  State<_EditBoqSheet> createState() => _EditBoqSheetState();
}

class _EditBoqSheetState extends State<_EditBoqSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.boq.name);
  late final _description = TextEditingController(text: widget.boq.description);
  late int? _projectId = widget.boq.projectId == 0
      ? null
      : widget.boq.projectId;
  late final Future<List<ProjectSummary>> _projects = widget.api.projects(
    perPage: 100,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateBoq(
        widget.boq.id,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        projectId: _projectId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('BOQ updated')));
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit BOQ', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'BOQ name',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                  counterText: '',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FutureBuilder<List<ProjectSummary>>(
                future: _projects,
                builder: (context, snapshot) {
                  final projects = snapshot.data ?? const <ProjectSummary>[];
                  if (projects.isEmpty) return const SizedBox.shrink();
                  final value = projects.any((p) => p.id == _projectId)
                      ? _projectId
                      : null;
                  return DropdownButtonFormField<int>(
                    key: ValueKey('boq-project-$value'),
                    initialValue: value,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      prefixIcon: Icon(Icons.folder_outlined),
                    ),
                    items: [
                      for (final p in projects)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (id) => setState(() => _projectId = id),
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                InfoBanner(message: _error!),
              ],
              const SizedBox(height: AppSpacing.xl),
              LoadingButton(label: 'Save', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks before deleting a BOQ. Returns true when it was deleted.
Future<bool> confirmDeleteBoq(
  BuildContext context,
  ApiClient api,
  int boqId,
  String name,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
      title: const Text('Delete BOQ?'),
      content: Text(
        '"${name.isEmpty ? 'This BOQ' : name}" and all its items will be deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await api.deleteBoq(boqId);
    messenger.showSnackBar(const SnackBar(content: Text('BOQ deleted')));
    return true;
  } on Object catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
    return false;
  }
}

/// "Estimated UGX 11,000 · Generated UGX 12,900" for list rows.
String? boqTotalsLine(BoqTotals totals, String currency) {
  if (totals.items == 0) return null;
  final estimated = totals.hasEstimate
      ? formatAmount(totals.estimatedAmount, currency: currency)
      : '—';
  final generated = totals.hasGenerated
      ? formatAmount(totals.generatedTotal, currency: currency)
      : '—';
  return 'Estimated $estimated · Generated $generated';
}

/// Estimated amount (rates from the uploaded file) next to the generated total
/// (priced rates), with the difference and pricing progress.
class BoqTotalsCard extends StatelessWidget {
  const BoqTotalsCard({
    super.key,
    required this.totals,
    required this.currency,
    this.title = 'Totals',
    this.actions = const [],
  });

  final BoqTotals totals;
  final String currency;
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String money(double value) => formatAmount(value, currency: currency);
    final difference = totals.difference;
    final showDifference = totals.hasEstimate && totals.hasGenerated;

    Widget figure(String label, String value, String note, Color color) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              Text(note, style: theme.textTheme.bodySmall),
            ],
          ),
        );

    return SectionCard(
      title: title,
      icon: Icons.account_balance_wallet_outlined,
      children: [
        if (totals.items == 0)
          Text(
            'Totals appear once BOQ items have been imported.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              figure(
                'Estimated amount',
                totals.hasEstimate ? money(totals.estimatedAmount) : '—',
                '${totals.estimatedItems} of ${totals.items} items',
                scheme.onSurface,
              ),
              const SizedBox(width: AppSpacing.md),
              figure(
                'Generated total',
                totals.hasGenerated ? money(totals.generatedTotal) : '—',
                '${totals.pricedItems} of ${totals.items} priced',
                scheme.primary,
              ),
            ],
          ),
          if (showDifference) ...[
            const SizedBox(height: AppSpacing.md),
            KeyValueRow(
              label: difference >= 0 ? 'Above estimate' : 'Below estimate',
              value: money(difference.abs()),
              valueStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: difference > 0 ? AppColors.danger : AppColors.success,
              ),
            ),
          ],
          if (totals.pricedItems < totals.items) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: totals.pricedItems / totals.items,
              minHeight: 6,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ],
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: actions,
          ),
        ],
      ],
    );
  }
}

/// Picks a file of estimated rates and applies it to the BOQ.
/// Returns true when prices were uploaded.
Future<bool> uploadBoqEstimates(
  BuildContext context,
  ApiClient api,
  int boqId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  void show(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  FilePickerResult? picked;
  try {
    picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xlsm', 'ods', 'csv', 'tsv', 'txt'],
      withData: kIsWeb,
    );
  } on Object {
    try {
      picked = await FilePicker.platform.pickFiles(withData: kIsWeb);
    } on Object {
      show('Files could not be opened on this device. Try again.');
      return false;
    }
  }
  if (picked == null || picked.files.isEmpty) return false;
  final file = picked.files.single;
  final path = kIsWeb ? null : file.path;
  if (path == null && file.bytes == null) {
    show('The file could not be read. Choose it again.');
    return false;
  }

  show('Uploading estimated prices...');
  try {
    final result = await api.uploadBoqEstimates(
      boqId,
      fileName: file.name,
      filePath: path,
      bytes: file.bytes,
    );
    show(result.message);
    return true;
  } on Object catch (error) {
    show(friendlyError(error));
    return false;
  }
}

/// Shares the estimated prices template (CSV of the BOQ items) so it can be
/// filled in with Excel or sent to a quantity surveyor.
Future<void> shareBoqEstimatesTemplate(
  BuildContext context,
  ApiClient api,
  int boqId,
  String title,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await api.boqEstimatesTemplate(boqId);
    final slug = title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').toLowerCase();
    final name = '${slug.isEmpty ? 'boq' : slug}-estimated-prices.csv';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: name)],
        fileNameOverrides: [name],
        subject: 'Estimated prices – $title',
      ),
    );
  } on Object catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(friendlyError(error))));
  }
}
