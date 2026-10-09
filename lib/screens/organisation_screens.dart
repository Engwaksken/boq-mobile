part of '../main.dart';

String _orgDate(dynamic value) => '${value ?? ''}'.split('T').first;
int _orgId(dynamic value) => int.parse('$value');

void _orgError(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
}

Widget _orgRetry(BuildContext context, Object error, VoidCallback retry) =>
    Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(friendlyError(error)),
            TextButton(
              onPressed: retry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );

Future<void> _orgWait(Future<Object?> future) async {
  // FutureBuilder owns presentation of failures; refresh must still complete.
  try {
    await future;
  } on Object catch (_) {}
}

/// Keeps paging and failures visible, including organisation authorization errors.
class _ResourceList extends StatelessWidget {
  const _ResourceList({
    required this.future,
    required this.reload,
    required this.tile,
  });
  final Future<ResourcePage> future;
  final Future<void> Function(int page) reload;
  final Widget Function(Map<String, dynamic>) tile;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<ResourcePage>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(friendlyError(snapshot.error!)),
                  TextButton(onPressed: () => reload(1), child: Text(l.retry)),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () => reload(data.page),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (data.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l.orgEmpty),
                ),
              ...data.items.map(tile),
              for (final total in data.totals)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '${total['currency']} ${total['amount']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: data.page > 1
                        ? () => reload(data.page - 1)
                        : null,
                    child: Text(l.orgPrevious),
                  ),
                  Text('${data.page} / ${data.lastPage}'),
                  TextButton(
                    onPressed: data.hasNext
                        ? () => reload(data.page + 1)
                        : null,
                    child: Text(l.orgNext),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  late Future<ResourcePage> _future = widget.api.expenses()..ignore();
  late final Future<List<Map<String, dynamic>>> _projects =
      widget.api.expenseProjects()..ignore();
  final _search = TextEditingController();
  String _query = '';
  int? _projectId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload([int page = 1]) {
    setState(() {
      _future = widget.api.expenses(
        page: page,
        search: _query,
        projectId: _projectId,
      )..ignore();
    });
    return _orgWait(_future);
  }

  Future<void> _open(Map<String, dynamic>? expense) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => expense == null
            ? ExpenseFormPage(api: widget.api)
            : ExpenseDetailPage(api: widget.api, id: _orgId(expense['id'])),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.orgExpenses)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.orgAddExpense,
        onPressed: () => _open(null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  maxLength: 255,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: l.orgSearchExpenses,
                    suffixIcon: IconButton(
                      tooltip: l.orgSearchExpenses,
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        _query = _search.text.trim();
                        _reload();
                      },
                    ),
                  ),
                  onSubmitted: (v) {
                    _query = v.trim();
                    _reload();
                  },
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _projects,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return DropdownButtonFormField<int>(
                      decoration: InputDecoration(labelText: l.orgProject),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<int>(
                          value: null,
                          child: Text(l.orgAllProjects),
                        ),
                        ...snapshot.data!.map(
                          (p) => DropdownMenuItem(
                            value: _orgId(p['id']),
                            child: Text(
                              '${p['name']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        _projectId = v;
                        _reload();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _ResourceList(
              future: _future,
              reload: _reload,
              tile: (e) => Card(
                child: ListTile(
                  title: Text('${e['description']}'),
                  subtitle: Text(
                    '${_orgDate(e['purchase_date'])} · ${e['supplier'] ?? ''}\n${e['currency']} ${e['total']}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(e),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({super.key, required this.api, this.expense});
  final ApiClient api;
  final Map<String, dynamic>? expense;
  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late Future<List<Map<String, dynamic>>> _projects = widget.api
      .expenseProjects();
  int? _project;
  bool _planned = true;
  bool _busy = false;

  final _additionalItems = <Map<String, TextEditingController>>[];
  final _additionalItemLinks = <int?>[];
  int? _boq;
  List<BoqListItem> _approvedBoqs = [];
  List<BoqItemSummary> _boqItems = [];
  int? _firstBoqItem;
  bool _loadingBoqs = false;
  bool _loadingBoqItems = false;
  PlatformFile? _receipt;
  List<String> _warnings = [];
  int? _savedExpenseId;

  Future<void> _extract() async {
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      if (file.bytes == null) {
        throw const ApiException('Unable to read this file.');
      }
      final data = await widget.api.extractExpenseReceipt(
        file.bytes!,
        file.name,
      );
      if (!mounted) return;
      setState(() {
        _receipt = file;
        for (final key in [
          'supplier',
          'purchase_date',
          'description',
          'quantity',
          'unit',
          'rate',
          'currency',
          'payment_method',
        ]) {
          if (data[key] != null) _fields[key]!.text = '${data[key]}';
        }
        _warnings = (data['warnings'] as List? ?? []).map((w) => '$w').toList();
      });
    } on Object catch (e) {
      if (mounted) _orgError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _project = e == null ? null : _orgId(e['project_id']);
    _loadingBoqs = e != null;
    _planned = e?['is_planned'] == null ? true : e!['is_planned'] == true;
    for (final key in [
      'purchase_date',
      'supplier',
      'description',
      'quantity',
      'unit',
      'rate',
      'currency',
      'payment_method',
      'explanation',
    ]) {
      _fields[key] = TextEditingController(
        text:
            '${e?[key] ?? (key == 'currency'
                    ? 'UGX'
                    : key == 'purchase_date'
                    ? DateFormat('yyyy-MM-dd').format(DateTime.now())
                    : '')}',
      );
    }
    if (_project != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadBoqs(_project!);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    for (final item in _additionalItems) {
      for (final controller in item.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  /// Clears the linked BOQ and every line's BOQ item link.
  void _resetBoq() {
    _boq = null;
    _approvedBoqs = [];
    _boqItems = [];
    _firstBoqItem = null;
    for (var i = 0; i < _additionalItemLinks.length; i++) {
      _additionalItemLinks[i] = null;
    }
  }

  /// Loads the project's approved BOQs and auto-links a lone one.
  Future<void> _loadBoqs(int projectId) async {
    setState(() {
      _resetBoq();
      _loadingBoqs = true;
      _loadingBoqItems = false;
    });
    try {
      final page = await widget.api.boqs(
        projectId: projectId,
        status: 'approved',
        perPage: 100,
      );
      if (!mounted || _project != projectId) return;
      setState(() {
        _approvedBoqs = page.items;
        _loadingBoqs = false;
      });
      if (_approvedBoqs.length == 1) {
        await _selectBoq(_approvedBoqs.single.id);
      }
    } on Object {
      if (!mounted || _project != projectId) return;
      setState(() {
        _approvedBoqs = [];
        _loadingBoqs = false;
      });
    }
  }

  /// Loads the approved items of [boqId]; null clears every link.
  Future<void> _selectBoq(int? boqId) async {
    setState(() {
      _boq = boqId;
      _boqItems = [];
      _firstBoqItem = null;
      for (var i = 0; i < _additionalItemLinks.length; i++) {
        _additionalItemLinks[i] = null;
      }
      _loadingBoqItems = boqId != null;
    });
    if (boqId == null) return;
    try {
      final items = await widget.api.boqItems(
        boqId,
        status: 'approved',
        perPage: 100,
      );
      if (!mounted || _boq != boqId) return;
      setState(() {
        _boqItems = items;
        _loadingBoqItems = false;
      });
    } on Object {
      if (!mounted || _boq != boqId) return;
      setState(() {
        _boqItems = [];
        _loadingBoqItems = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_savedExpenseId == null) {
        final payload = <String, dynamic>{
          if (widget.expense == null) 'project_id': _project,
          for (final entry in _fields.entries)
            if (entry.key != 'explanation' || !_planned)
              entry.key: entry.value.text.trim(),
          'currency': _fields['currency']!.text.trim().toUpperCase(),
          'is_planned': _planned,
          if (_boq != null) 'boq_id': _boq,
        };
        if (widget.expense == null && _additionalItems.isNotEmpty) {
          payload['items'] = <Map<String, dynamic>>[
            {
              for (final key in ['description', 'quantity', 'unit', 'rate'])
                key: _fields[key]!.text.trim(),
              if (_firstBoqItem != null) 'boq_item_id': _firstBoqItem,
            },
            for (final item in _additionalItems)
              {
                for (final entry in item.entries)
                  entry.key: entry.value.text.trim(),
                if (_additionalItemLinks[_additionalItems.indexOf(item)] !=
                    null)
                  'boq_item_id':
                      _additionalItemLinks[_additionalItems.indexOf(item)],
              },
          ];
        } else if (_firstBoqItem != null) {
          payload['boq_item_id'] = _firstBoqItem;
        }
        final saved = await widget.api.saveExpense(
          payload,
          id: widget.expense == null ? null : _orgId(widget.expense!['id']),
        );
        _savedExpenseId = _orgId(saved['id']);
      }
      if (_receipt != null) {
        await widget.api.uploadExpenseReceipt(
          _savedExpenseId!,
          _receipt!.bytes!,
          _receipt!.name,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) _orgError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    bool number = false,
    int? maxLength,
  }) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _fields[key],
        enabled: !_busy && _savedExpenseId == null,
        decoration: InputDecoration(labelText: label),
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        maxLength: maxLength,
        maxLines: key == 'description' || key == 'explanation' ? 3 : 1,
        validator: (value) {
          final v = value?.trim() ?? '';
          if (required && v.isEmpty) return l.orgRequired;
          if (number) {
            final n = double.tryParse(v);
            if (n == null ||
                !n.isFinite ||
                (key == 'quantity' ? n <= 0 : n < 0)) {
              return l.orgRequired;
            }
          }
          if (key == 'currency' && !RegExp(r'^[a-zA-Z]{3}$').hasMatch(v)) {
            return l.orgRequired;
          }
          return null;
        },
      ),
    );
  }

  /// Optional approved BOQ selector for the chosen project.
  Widget _boqSection(AppLocalizations l) {
    if (_project == null) return const SizedBox.shrink();
    if (_loadingBoqs) {
      return const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_approvedBoqs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(l.orgNoApprovedBoq),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: DropdownButtonFormField<int>(
        key: ValueKey('expense-boq-$_boq-${_approvedBoqs.length}'),
        initialValue: _boq,
        isExpanded: true,
        hint: Text(l.orgNoBoqLink),
        decoration: InputDecoration(labelText: l.orgApprovedBoq),
        items: [
          DropdownMenuItem<int>(value: null, child: Text(l.orgNoBoqLink)),
          ..._approvedBoqs.map(
            (boq) => DropdownMenuItem<int>(
              value: boq.id,
              child: Text(
                boq.name.isEmpty ? 'BOQ #${boq.id}' : boq.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: _busy || _savedExpenseId != null
            ? null
            : (id) => _selectBoq(id),
      ),
    );
  }

  /// Links one expense line to an approved item of the selected BOQ.
  Widget _lineBoqPicker(
    AppLocalizations l,
    int? value,
    ValueChanged<int?> onChanged,
    String tag,
  ) {
    if (_loadingBoqItems) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        key: ValueKey('boq-item-$tag-$value-${_boqItems.length}'),
        initialValue: value,
        isExpanded: true,
        hint: Text(l.orgNoBoqItem),
        decoration: InputDecoration(labelText: l.orgBoqItem),
        items: [
          DropdownMenuItem<int>(value: null, child: Text(l.orgNoBoqItem)),
          ..._boqItems.map(
            (item) => DropdownMenuItem<int>(
              value: item.id,
              child: Text(
                item.code.isEmpty
                    ? item.description
                    : '${item.code} · ${item.description}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: _busy || _savedExpenseId != null ? null : onChanged,
      ),
    );
  }

  Widget _additionalLineCard(
    AppLocalizations l,
    Map<String, TextEditingController> item,
  ) {
    final index = _additionalItems.indexOf(item);
    final link = index >= 0 && index < _additionalItemLinks.length
        ? _additionalItemLinks[index]
        : null;
    return Card(
      key: ObjectKey(item),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in item.entries)
              TextFormField(
                controller: entry.value,
                enabled: !_busy && _savedExpenseId == null,
                decoration: InputDecoration(
                  labelText: {
                    'description': l.orgDescription,
                    'quantity': l.orgQuantity,
                    'unit': l.orgUnit,
                    'rate': l.orgRate,
                  }[entry.key],
                ),
                keyboardType: entry.key == 'quantity' || entry.key == 'rate'
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l.orgRequired;
                  }
                  if (entry.key == 'quantity' || entry.key == 'rate') {
                    final n = double.tryParse(v);
                    if (n == null ||
                        !n.isFinite ||
                        (entry.key == 'quantity' ? n <= 0 : n < 0)) {
                      return l.orgRequired;
                    }
                  }
                  return null;
                },
              ),
            if (_boq != null)
              _lineBoqPicker(l, link, (id) {
                final at = _additionalItems.indexOf(item);
                if (at < 0 || at >= _additionalItemLinks.length) return;
                setState(() => _additionalItemLinks[at] = id);
              }, 'line-${identityHashCode(item)}'),
            TextButton.icon(
              onPressed: _busy || _savedExpenseId != null
                  ? null
                  : () {
                      final at = _additionalItems.indexOf(item);
                      setState(() {
                        _additionalItems.removeAt(at);
                        if (at >= 0 && at < _additionalItemLinks.length) {
                          _additionalItemLinks.removeAt(at);
                        }
                      });
                      // Dispose after the removed fields leave the widget tree.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        for (final c in item.values) {
                          c.dispose();
                        }
                      });
                    },
              icon: const Icon(Icons.remove_circle_outline),
              label: Text(l.orgRemoveItem),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expense == null ? l.orgAddExpense : l.orgEditExpense,
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _projects,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _orgRetry(context, snapshot.error!, () {
              setState(() {
                _projects = widget.api.expenseProjects()..ignore();
              });
            });
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final projects = [...snapshot.data!];
          if (widget.expense != null &&
              !projects.any((p) => _orgId(p['id']) == _project)) {
            projects.add({
              'id': _project,
              'name': '${l.orgProject} #$_project',
            });
          }
          if (projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.orgNoProjects),
              ),
            );
          }
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.expense == null) ...[
                  OutlinedButton.icon(
                    onPressed: _busy || _savedExpenseId != null
                        ? null
                        : _extract,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(l.orgExtractReceipt),
                  ),
                  if (_receipt != null) ...[
                    Text(_receipt!.name),
                    Text(l.orgReviewExtraction),
                    for (final warning in _warnings) Text(warning),
                  ],
                  const SizedBox(height: 16),
                ],
                DropdownButtonFormField<int>(
                  initialValue: _project,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.orgProject),
                  items: projects
                      .map(
                        (p) => DropdownMenuItem(
                          value: _orgId(p['id']),
                          child: Text(
                            '${p['name']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged:
                      _busy || _savedExpenseId != null || widget.expense != null
                      ? null
                      : (id) {
                          setState(() {
                            _project = id;
                            _fields['currency']!.text =
                                '${projects.firstWhere((p) => _orgId(p['id']) == id)['currency'] ?? 'UGX'}';
                          });
                          if (id != null) _loadBoqs(id);
                        },
                  validator: (id) => id == null ? l.orgRequired : null,
                ),
                _boqSection(l),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fields['purchase_date'],
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l.orgPurchaseDate,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  validator: (v) =>
                      DateTime.tryParse(v ?? '') == null ? l.orgRequired : null,
                  onTap: _busy || _savedExpenseId != null
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.tryParse(
                                  _fields['purchase_date']!.text,
                                ) ??
                                DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (date != null && mounted) {
                            _fields['purchase_date']!.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(date);
                          }
                        },
                ),
                const SizedBox(height: 16),
                _field('supplier', l.orgSupplier, maxLength: 255),
                _field(
                  'description',
                  l.orgDescription,
                  required: true,
                  maxLength: 10000,
                ),
                _field('quantity', l.orgQuantity, required: true, number: true),
                _field('unit', l.orgUnit, required: true, maxLength: 50),
                _field('rate', l.orgRate, required: true, number: true),
                if (_boq != null)
                  _lineBoqPicker(
                    l,
                    _firstBoqItem,
                    (id) => setState(() => _firstBoqItem = id),
                    'first',
                  ),
                for (final item in _additionalItems)
                  _additionalLineCard(l, item),
                if (widget.expense == null)
                  TextButton.icon(
                    onPressed:
                        _busy ||
                            _savedExpenseId != null ||
                            _additionalItems.length >= 99
                        ? null
                        : () => setState(() {
                            _additionalItems.add({
                              for (final key in [
                                'description',
                                'quantity',
                                'unit',
                                'rate',
                              ])
                                key: TextEditingController(
                                  text: key == 'quantity' ? '1' : '',
                                ),
                            });
                            _additionalItemLinks.add(null);
                          }),
                    icon: const Icon(Icons.add),
                    label: Text(l.orgAddItem),
                  ),
                _field('currency', l.currency, required: true, maxLength: 3),
                _field('payment_method', l.orgPaymentMethod, maxLength: 100),
                SwitchListTile(
                  title: Text(l.orgPlanned),
                  value: _planned,
                  onChanged: _busy || _savedExpenseId != null
                      ? null
                      : (v) => setState(() => _planned = v),
                ),
                if (!_planned)
                  _field(
                    'explanation',
                    l.orgExplanation,
                    required: true,
                    maxLength: 10000,
                  ),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _savedExpenseId != null && _receipt != null
                              ? l.orgRetryReceipt
                              : l.orgSave,
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

class ExpenseDetailPage extends StatefulWidget {
  const ExpenseDetailPage({super.key, required this.api, required this.id});
  final ApiClient api;
  final int id;
  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  late Future<Map<String, dynamic>> _future = widget.api.expense(widget.id);
  bool _busy = false;
  void _reload() => setState(() {
    _future = widget.api.expense(widget.id)..ignore();
  });
  Future<void> _attach() async {
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (picked == null) return;
      final file = picked.files.single;
      if (file.bytes == null) {
        throw const ApiException('Unable to read this file.');
      }
      await widget.api.uploadExpenseReceipt(widget.id, file.bytes!, file.name);
      if (mounted) _reload();
    } on Object catch (e) {
      if (mounted) _orgError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(Map<String, dynamic> receipt) async {
    setState(() => _busy = true);
    try {
      final bytes = await widget.api.downloadExpenseReceipt(
        _orgId(receipt['id']),
      );
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: '${receipt['mime_type']}')],
          fileNameOverrides: ['${receipt['original_filename']}'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object catch (e) {
      if (mounted) _orgError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.orgExpenses)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(friendlyError(snapshot.error!)),
                  TextButton(onPressed: _reload, child: Text(l.retry)),
                ],
              ),
            );
          }
          final e = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${e['description']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '${e['currency']} ${e['total']}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('${l.orgPurchaseDate}: ${_orgDate(e['purchase_date'])}'),
              Text('${l.orgSupplier}: ${e['supplier'] ?? ''}'),
              Text('${e['quantity']} ${e['unit']} × ${e['rate']}'),
              if ((e['items'] as List? ?? []).length > 1)
                for (final item
                    in (e['items'] as List).cast<Map<String, dynamic>>())
                  ListTile(
                    title: Text('${item['description']}'),
                    subtitle: Text(
                      '${item['quantity']} ${item['unit']} × ${item['rate']}',
                    ),
                    trailing: Text('${e['currency']} ${item['total']}'),
                  ),
              Text('${l.orgPaymentMethod}: ${e['payment_method'] ?? ''}'),
              if (e['is_planned'] != true)
                Text('${l.orgExplanation}: ${e['explanation'] ?? ''}'),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ExpenseFormPage(api: widget.api, expense: e),
                          ),
                        );
                        if (mounted) _reload();
                      },
                icon: const Icon(Icons.edit),
                label: Text(l.orgEditExpense),
              ),
              const Divider(),
              Text(
                l.orgReceipts,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final receipt
                  in (e['receipts'] as List? ?? [])
                      .cast<Map<String, dynamic>>())
                ListTile(
                  title: Text('${receipt['original_filename']}'),
                  trailing: const Icon(Icons.download),
                  onTap: _busy ? null : () => _download(receipt),
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _attach,
                icon: const Icon(Icons.attach_file),
                label: Text(l.orgAddReceipt),
              ),
              if (_busy) const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }
}

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  late Future<ResourcePage> _future = widget.api.invitations()..ignore();
  bool _busy = false;
  Future<void> _reload([int page = 1]) {
    // Attach an error listener immediately, before the next build. The
    // FutureBuilder still receives and displays errors from this future.
    setState(() {
      _future = widget.api.invitations(page: page)..ignore();
    });
    return _orgWait(_future);
  }

  String _status(Map<String, dynamic> i, AppLocalizations l) {
    if (i['accepted_at'] != null) return l.orgAccepted;
    if (i['revoked_at'] != null) return l.orgRevoked;
    final expiry = DateTime.tryParse('${i['expires_at']}');
    return expiry == null || !expiry.isAfter(DateTime.now())
        ? l.orgExpired
        : l.orgPending;
  }

  Future<void> _edit([Map<String, dynamic>? i]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvitationFormPage(api: widget.api, invitation: i),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _accept() async {
    final l = AppLocalizations.of(context)!;
    final token = await showDialog<String>(
      context: context,
      builder: (_) => const _InvitationTokenDialog(),
    );
    if (token == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.acceptInvitation(token);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.orgAcceptSuccess)));
        _reload();
      }
    } on Object catch (e) {
      if (mounted) _orgError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(Map<String, dynamic> i) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.orgRevokeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.orgRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.revokeInvitation(_orgId(i['id']));
      if (mounted) _reload();
    } on Object catch (e) {
      if (mounted) _orgError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.orgInvitations)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _edit(),
                  icon: const Icon(Icons.person_add),
                  label: Text(l.orgInvite),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _accept,
                  child: Text(l.orgAccept),
                ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: _ResourceList(
              future: _future,
              reload: _reload,
              tile: (i) {
                final pending = _status(i, l) == l.orgPending;
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('${i['email']}'),
                        subtitle: Text(
                          '${_status(i, l)} · ${l.orgExpiry}: ${_orgDate(i['expires_at'])}',
                        ),
                      ),
                      if (pending)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _busy ? null : () => _edit(i),
                              child: Text(l.orgEdit),
                            ),
                            TextButton(
                              onPressed: _busy ? null : () => _revoke(i),
                              child: Text(l.orgRevoke),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationTokenDialog extends StatefulWidget {
  const _InvitationTokenDialog();
  @override
  State<_InvitationTokenDialog> createState() => _InvitationTokenDialogState();
}

class _InvitationTokenDialogState extends State<_InvitationTokenDialog> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.orgAccept),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: l.orgToken),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: Text(l.orgAccept),
        ),
      ],
    );
  }
}

class InvitationFormPage extends StatefulWidget {
  const InvitationFormPage({super.key, required this.api, this.invitation});
  final ApiClient api;
  final Map<String, dynamic>? invitation;
  @override
  State<InvitationFormPage> createState() => _InvitationFormPageState();
}

class _InvitationFormPageState extends State<InvitationFormPage> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(
    text: '${widget.invitation?['email'] ?? ''}',
  );
  late Future<List<Map<String, dynamic>>> _roles = widget.api.invitationRoles();
  late DateTime _expiry =
      DateTime.tryParse('${widget.invitation?['expires_at']}') ??
      DateTime.now().add(const Duration(days: 7));
  int? _role;
  bool _busy = false;
  String? _token;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final data = {
        'email': _email.text.trim(),
        'expires_at': _expiry.toUtc().toIso8601String(),
      };
      if (widget.invitation == null) {
        final token = await widget.api.createInvitation({
          ...data,
          'role_id': _role,
        });
        if (mounted) setState(() => _token = token);
      } else {
        await widget.api.updateInvitation(
          _orgId(widget.invitation!['id']),
          data,
        );
        if (mounted) Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) _orgError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.orgInvite)),
      body: _token != null
          ? ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(l.orgTokenHelp),
                const SizedBox(height: 16),
                SelectableText(_token!),
                TextButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _token!)),
                  icon: const Icon(Icons.copy),
                  label: Text(l.orgCopy),
                ),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final box = context.findRenderObject() as RenderBox?;
                      await SharePlus.instance.share(
                        ShareParams(
                          text: _token!,
                          sharePositionOrigin: box == null
                              ? null
                              : box.localToGlobal(Offset.zero) & box.size,
                        ),
                      );
                    } on Object catch (e) {
                      if (context.mounted) _orgError(context, e);
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: Text(l.orgShareToken),
                ),
              ],
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _roles,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _orgRetry(context, snapshot.error!, () {
                    setState(() {
                      _roles = widget.api.invitationRoles()..ignore();
                    });
                  });
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 255,
                        decoration: InputDecoration(labelText: l.email),
                        validator: (v) =>
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(v?.trim() ?? '')
                            ? null
                            : l.orgRequired,
                      ),
                      if (widget.invitation == null)
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l.orgRole),
                          items: snapshot.data!
                              .map(
                                (r) => DropdownMenuItem(
                                  value: _orgId(r['id']),
                                  child: Text('${r['name']}'),
                                ),
                              )
                              .toList(),
                          onChanged: _busy ? null : (v) => _role = v,
                          validator: (v) => v == null ? l.orgRequired : null,
                        ),
                      const SizedBox(height: 16),
                      FormField<DateTime>(
                        validator: (_) => _expiry.isAfter(DateTime.now())
                            ? null
                            : l.orgRequired,
                        builder: (state) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(l.orgExpiry),
                              subtitle: Text(
                                DateFormat(
                                  'yyyy-MM-dd HH:mm',
                                ).format(_expiry.toLocal()),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _busy
                                  ? null
                                  : () async {
                                      final now = DateTime.now();
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _expiry.isAfter(now)
                                            ? _expiry
                                            : now,
                                        firstDate: DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                        ),
                                        lastDate: DateTime(now.year + 5),
                                      );
                                      if (date != null && mounted) {
                                        setState(
                                          () => _expiry = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            23,
                                            59,
                                          ),
                                        );
                                      }
                                    },
                            ),
                            if (state.hasError)
                              Text(
                                state.errorText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: _busy ? null : _save,
                        child: Text(l.orgSave),
                      ),
                      if (_busy) const LinearProgressIndicator(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
