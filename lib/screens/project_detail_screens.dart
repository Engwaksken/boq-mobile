part of '../main.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    super.key,
    required this.api,
    required this.projectId,
  });
  final ApiClient api;
  final int projectId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Project Details'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      EditProjectPage(api: api, projectId: projectId),
                ),
              );
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Project'),
                  content: const Text(
                    'Are you sure you want to delete this project? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                try {
                  await api.deleteProject(projectId);
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project deleted')),
                    );
                  }
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    body: FutureBuilder<ProjectDetail>(
      future: api.project(projectId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(friendlyError(snapshot.error)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final project = snapshot.data!;
        final dateFormat = DateFormat('MMM dd, yyyy');
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
                      project.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${project.code}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    _detailRow(
                      'Owner',
                      project.ownerName.isNotEmpty ? project.ownerName : '—',
                    ),
                    _detailRow('Status', project.status.capitalize()),
                    _detailRow(
                      'Client',
                      project.client.isNotEmpty ? project.client : '—',
                    ),
                    _detailRow(
                      'Contractor',
                      project.contractor.isNotEmpty ? project.contractor : '—',
                    ),
                    _detailRow(
                      'Consultant',
                      project.consultant.isNotEmpty ? project.consultant : '—',
                    ),
                    _detailRow(
                      'Quantity Surveyor',
                      project.quantitySurveyor.isNotEmpty
                          ? project.quantitySurveyor
                          : '—',
                    ),
                    _detailRow(
                      'Project Manager',
                      project.projectManager.isNotEmpty
                          ? project.projectManager
                          : '—',
                    ),
                    _detailRow(
                      'Site Engineer',
                      project.siteEngineer.isNotEmpty
                          ? project.siteEngineer
                          : '—',
                    ),
                    _detailRow(
                      'Funding Organisation',
                      project.fundingOrganisation.isNotEmpty
                          ? project.fundingOrganisation
                          : '—',
                    ),
                    _detailRow(
                      'Location',
                      _formatLocation(
                        project.country,
                        project.district,
                        project.location,
                      ),
                    ),
                    _detailRow(
                      'Project Type',
                      project.projectType.isNotEmpty
                          ? project.projectType
                          : '—',
                    ),
                    _detailRow(
                      'Start Date',
                      project.startDate.isNotEmpty
                          ? dateFormat.format(DateTime.parse(project.startDate))
                          : '—',
                    ),
                    _detailRow(
                      'Expected Completion',
                      project.expectedCompletionDate.isNotEmpty
                          ? dateFormat.format(
                              DateTime.parse(project.expectedCompletionDate),
                            )
                          : '—',
                    ),
                    _detailRow(
                      'Contract Value',
                      '${NumberFormat('#,##0.00').format(project.contractValue)} ${project.currency}',
                    ),
                    if (project.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(project.description),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'BOQs',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (project.boqs.isEmpty) const Center(child: Text('No BOQs yet')),
            for (final boq in project.boqs)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(boq.name),
                  subtitle: Text(boq.status),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BoqDetailPage(
                        api: api,
                        boqId: boq.id,
                        title: boq.name,
                      ),
                    ),
                  ),
                  trailing: boq.status == 'uploaded'
                      ? FilledButton(
                          onPressed: () async {
                            final place = [
                              project.country,
                              project.district,
                              project.location,
                            ].where((e) => e.isNotEmpty).toList().join(', ');
                            try {
                              final created = await api.processBoq(boq.id);
                              if (!context.mounted) return;
                              final items = await api.allBoqItems(boq.id);
                              if (!context.mounted) return;
                              if (items.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$created BOQ items created'),
                                  ),
                                );
                                return;
                              }
                              if (place.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Set a location on the project to fetch prices.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final progress = ValueNotifier<String>(
                                'Preparing to fetch prices...',
                              );
                              final reportFuture = _priceBoqItems(
                                api,
                                items,
                                place,
                                onProgress: (done, total, description) {
                                  progress.value =
                                      'Fetching $done/$total: $description';
                                },
                              );
                              await showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (dialogContext) {
                                  reportFuture.then((_) {
                                    if (dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop();
                                    }
                                  });
                                  return AlertDialog(
                                    title: const Text('Generating BOQ prices'),
                                    content: ValueListenableBuilder<String>(
                                      valueListenable: progress,
                                      builder: (context, value, _) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(width: 16),
                                          Expanded(child: Text(value)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              final report = await reportFuture;
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    report.failedMessages.isEmpty
                                        ? 'Generated prices for ${report.priced} items'
                                        : 'Generated ${report.priced} of ${items.length} (${report.failedMessages.length} failed)',
                                  ),
                                ),
                              );
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BoqItemsPage(
                                    api: api,
                                    boqId: boq.id,
                                    title: boq.name,
                                  ),
                                ),
                              );
                            } on ApiException catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.message)),
                                );
                              }
                            }
                          },
                          child: const Text('Generate BOQ'),
                        )
                      : null,
                ),
              ),
          ],
        );
      },
    ),
  );
}

Widget _detailRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 140,
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

String _formatLocation(String country, String district, String location) {
  final parts = [
    country,
    district,
    location,
  ].where((e) => e.isNotEmpty).toList();
  return parts.isEmpty ? '—' : parts.join(', ');
}

class ItemPricingReport {
  const ItemPricingReport({
    required this.priced,
    required this.failedMessages,
    required this.failedItems,
  });
  final int priced;
  final List<String> failedMessages;
  final List<BoqItemSummary> failedItems;
}

Future<ItemPricingReport> _priceBoqItems(
  ApiClient api,
  List<BoqItemSummary> targets,
  String location, {
  void Function(int done, int total, String description)? onProgress,
}) async {
  var priced = 0;
  final failedMessages = <String>[];
  final failedItems = <BoqItemSummary>[];
  for (var i = 0; i < targets.length; i++) {
    final item = targets[i];
    onProgress?.call(i + 1, targets.length, item.description);
    try {
      await api.priceItem(item.id, location);
      priced++;
    } on ApiException catch (error) {
      failedMessages.add(
        '${item.description} (${item.unit}): ${error.message}',
      );
      failedItems.add(item);
    } catch (_) {
      failedMessages.add('${item.description} (${item.unit}): failed');
      failedItems.add(item);
    }
  }
  return ItemPricingReport(
    priced: priced,
    failedMessages: failedMessages,
    failedItems: failedItems,
  );
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class EditProjectPage extends StatefulWidget {
  const EditProjectPage({
    super.key,
    required this.api,
    required this.projectId,
  });
  final ApiClient api;
  final int projectId;

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _client = TextEditingController();
  final _contractor = TextEditingController();
  final _consultant = TextEditingController();
  final _quantitySurveyor = TextEditingController();
  final _projectManager = TextEditingController();
  final _siteEngineer = TextEditingController();
  final _fundingOrganisation = TextEditingController();
  final _country = TextEditingController();
  final _district = TextEditingController();
  final _location = TextEditingController();
  final _projectType = TextEditingController();
  final _startDate = TextEditingController();
  final _expectedCompletionDate = TextEditingController();
  final _contractValue = TextEditingController();
  final _currency = TextEditingController(text: 'UGX');
  final _description = TextEditingController();
  final _originalLanguage = TextEditingController();
  final _reportLanguage = TextEditingController();
  String _status = 'draft';
  bool _loading = false;
  ProjectDetail? _project;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      final project = await widget.api.project(widget.projectId);
      if (mounted) {
        setState(() {
          _project = project;
          _name.text = project.name;
          _code.text = project.code;
          _client.text = project.client;
          _contractor.text = project.contractor;
          _consultant.text = project.consultant;
          _quantitySurveyor.text = project.quantitySurveyor;
          _projectManager.text = project.projectManager;
          _siteEngineer.text = project.siteEngineer;
          _fundingOrganisation.text = project.fundingOrganisation;
          _country.text = project.country;
          _district.text = project.district;
          _location.text = project.location;
          _projectType.text = project.projectType;
          _startDate.text = project.startDate;
          _expectedCompletionDate.text = project.expectedCompletionDate;
          _contractValue.text = project.contractValue.toString();
          _currency.text = project.currency;
          _description.text = project.description;
          _originalLanguage.text = project.originalLanguage;
          _reportLanguage.text = project.reportLanguage;
          _status = project.status;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) controller.text = date.toIso8601String().split('T').first;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.api.updateProject(
        id: widget.projectId,
        name: _name.text,
        code: _code.text.isEmpty ? null : _code.text,
        client: _client.text.isEmpty ? null : _client.text,
        contractor: _contractor.text.isEmpty ? null : _contractor.text,
        consultant: _consultant.text.isEmpty ? null : _consultant.text,
        quantitySurveyor: _quantitySurveyor.text.isEmpty
            ? null
            : _quantitySurveyor.text,
        projectManager: _projectManager.text.isEmpty
            ? null
            : _projectManager.text,
        siteEngineer: _siteEngineer.text.isEmpty ? null : _siteEngineer.text,
        fundingOrganisation: _fundingOrganisation.text.isEmpty
            ? null
            : _fundingOrganisation.text,
        country: _country.text.isEmpty ? null : _country.text,
        district: _district.text.isEmpty ? null : _district.text,
        location: _location.text.isEmpty ? null : _location.text,
        projectType: _projectType.text.isEmpty ? null : _projectType.text,
        startDate: _startDate.text.isEmpty ? null : _startDate.text,
        expectedCompletionDate: _expectedCompletionDate.text.isEmpty
            ? null
            : _expectedCompletionDate.text,
        contractValue: _contractValue.text.isEmpty
            ? null
            : double.tryParse(_contractValue.text),
        currency: _currency.text,
        description: _description.text.isEmpty ? null : _description.text,
        status: _status,
        originalLanguage: _originalLanguage.text.isEmpty
            ? null
            : _originalLanguage.text,
        reportLanguage: _reportLanguage.text.isEmpty
            ? null
            : _reportLanguage.text,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Project updated')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Project')),
    body: _project == null
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _code,
                  decoration: const InputDecoration(labelText: 'Project Code'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _client,
                  decoration: const InputDecoration(labelText: 'Client'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contractor,
                  decoration: const InputDecoration(labelText: 'Contractor'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _consultant,
                  decoration: const InputDecoration(labelText: 'Consultant'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantitySurveyor,
                  decoration: const InputDecoration(
                    labelText: 'Quantity Surveyor',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _projectManager,
                  decoration: const InputDecoration(
                    labelText: 'Project Manager',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _siteEngineer,
                  decoration: const InputDecoration(labelText: 'Site Engineer'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fundingOrganisation,
                  decoration: const InputDecoration(
                    labelText: 'Funding Organisation',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _country,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _district,
                  decoration: const InputDecoration(labelText: 'District'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _projectType,
                  decoration: const InputDecoration(labelText: 'Project Type'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _startDate,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _pickDate(_startDate),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _expectedCompletionDate,
                  decoration: const InputDecoration(
                    labelText: 'Expected Completion Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _pickDate(_expectedCompletionDate),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contractValue,
                  decoration: const InputDecoration(
                    labelText: 'Contract Value',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _originalLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Original Language',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reportLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Report Language',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: 'archived',
                      child: Text('Archived'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
  );
}

class BoqItemsPage extends StatefulWidget {
  const BoqItemsPage({
    super.key,
    required this.api,
    required this.boqId,
    required this.title,
  });
  final ApiClient api;
  final int boqId;
  final String title;
  @override
  State<BoqItemsPage> createState() => _BoqItemsPageState();
}

class _BoqItemsPageState extends State<BoqItemsPage> {
  final _location = TextEditingController();
  Future<BoqDetail>? _boqDetail;
  final _refreshKey = GlobalKey();
  String? _progress;
  List<Map<String, dynamic>> _history = [];
  bool _historyVisible = false;
  bool _pricing = false;
  List<String> _failedReport = [];
  List<BoqItemSummary> _retryItems = [];
  _BoqItemsPageState() : _boqDetail = null;
  @override
  void initState() {
    super.initState();
    _boqDetail = widget.api.boqDetail(widget.boqId);
  }

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _refreshItems() async {
    if (mounted) {
      setState(() => _boqDetail = widget.api.boqDetail(widget.boqId));
    }
  }

  List<BoqItemSummary> _flattenBoqItems(BoqDetail boq) {
    final items = <BoqItemSummary>[];
    for (final facility in boq.facilities) {
      for (final bill in facility.bills) {
        for (final element in bill.elements) {
          items.addAll(element.items);
          for (final subElement in element.subElements) {
            items.addAll(subElement.items);
          }
        }
      }
    }
    return items;
  }

  Future<void> _price() async {
    final location = _location.text.trim();
    if (location.isEmpty || _pricing) return;
    setState(() {
      _pricing = true;
      _progress = 'Loading BOQ items...';
      _history = [];
      _historyVisible = false;
      _failedReport = [];
      _retryItems = [];
    });
    try {
      final items = await widget.api.allBoqItems(widget.boqId);
      if (!mounted) return;
      if (items.isEmpty) {
        setState(() {
          _pricing = false;
          _progress = 'No BOQ items found to price';
        });
        return;
      }
      await _runPricing(items, location);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _pricing = false;
          _progress = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pricing = false;
          _progress = 'Failed to load BOQ items';
        });
      }
    }
  }

  Future<void> _runPricing(
    List<BoqItemSummary> targets,
    String location,
  ) async {
    final report = await _priceBoqItems(
      widget.api,
      targets,
      location,
      onProgress: (done, total, description) {
        if (mounted) {
          setState(() => _progress = 'Fetching $done/$total: $description');
        }
      },
    );
    await _refreshItems();
    if (!mounted) return;
    setState(() {
      _pricing = false;
      _failedReport = report.failedMessages;
      _retryItems = report.failedItems;
      _progress = report.failedMessages.isEmpty
          ? 'Fetched prices for ${report.priced} items'
          : 'Fetched ${report.priced} of ${targets.length} items (${report.failedMessages.length} failed)';
      _historyVisible = true;
    });
    await _loadHistory();
  }

  Future<void> _retry() async {
    if (_retryItems.isEmpty || _pricing) return;
    final location = _location.text.trim();
    if (location.isEmpty) return;
    final targets = _retryItems;
    setState(() {
      _pricing = true;
      _failedReport = [];
      _retryItems = [];
      _progress = 'Retrying ${targets.length} failed items...';
    });
    try {
      await _runPricing(targets, location);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _pricing = false;
          _progress = error.message;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    if (!_historyVisible) return;
    final loc = _location.text.trim();
    if (loc.isEmpty) return;
    final h = await widget.api.pricingHistory(widget.boqId, loc);
    if (mounted) setState(() => _history = h);
  }

  Future<void> _compareLocations() async {
    try {
      final history = await widget.api.allPricingHistory(widget.boqId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LocationComparisonPage(history: history),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_tree),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BoqDetailPage(
                api: widget.api,
                boqId: widget.boqId,
                title: widget.title,
              ),
            ),
          ),
          tooltip: 'View Hierarchy',
        ),
      ],
    ),
    body: FutureBuilder<BoqDetail>(
      key: _refreshKey,
      future: _boqDetail,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(friendlyError(snapshot.error)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final boq = snapshot.data!;
        final items = _flattenBoqItems(boq);
        final total = items.fold<double>(
          0,
          (sum, item) =>
              sum + (double.tryParse(item.amount.replaceAll(',', '')) ?? 0),
        );
        final money = NumberFormat('#,##0.00');
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF102A43),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall BOQ Cost',
                    style: TextStyle(color: Color(0xFFBFD7EA)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${boq.currency} ${money.format(total)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Select location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _pricing ? null : _price,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Get Prices'),
            ),
            if (_progress != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(top: 8),
                color: const Color(0xFFE8F5E9),
                child: Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          'Progress: $_progress',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_pricing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (_failedReport.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(top: 8),
                color: const Color(0xFFFFEBEE),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_failedReport.length} item(s) could not be priced:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB71C1C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final failure in _failedReport)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '- $failure',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      if (_retryItems.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _pricing ? null : _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry failed items'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_historyVisible) ...[
              OutlinedButton.icon(
                onPressed: _compareLocations,
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Compare saved locations'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pricing History',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              if (_history.isEmpty) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _loadHistory,
                  icon: const Icon(Icons.history),
                  label: Text('Load History'),
                ),
              ] else ...[
                for (final h in _history) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Text(
                            '${h['suggested_rate'] ?? 'N/A'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text('${h['boqItem']?['description'] ?? ''}'),
                          const SizedBox(width: 8),
                          Text(
                            '${h['boqItem']?['quantity']} ${h['boqItem']?['unit'] ?? ''}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () =>
          showBoqShareSheet(context, widget.api, widget.boqId, widget.title),
      icon: const Icon(Icons.share_outlined),
      label: const Text('PDF & Share'),
    ),
  );
}

class LocationComparisonPage extends StatelessWidget {
  const LocationComparisonPage({super.key, required this.history});

  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final entry in history) {
      final location = '${entry['location'] ?? 'Unknown location'}';
      grouped.putIfAbsent(location, () => []).add(entry);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Location Price Comparison')),
      body: history.isEmpty
          ? const Center(child: Text('No saved location prices yet'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Saved prices by hardware and location',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 12),
                for (final location in grouped.keys) ...[
                  Text(
                    location,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  for (final entry in grouped[location]!)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${entry['boqItem']?['description'] ?? 'Hardware item'}',
                        ),
                        subtitle: Text(
                          '${entry['boqItem']?['unit'] ?? ''}  |  ${entry['currency'] ?? ''}',
                        ),
                        trailing: Text(
                          '${entry['suggested_rate'] ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.name,
    required this.code,
    required this.status,
    required this.color,
    this.onTap,
  });

  final String name;
  final String code;
  final String status;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.foundation_outlined, color: color),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(code),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
