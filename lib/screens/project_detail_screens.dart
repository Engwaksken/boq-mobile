part of '../main.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({
    super.key,
    required this.api,
    required this.projectId,
  });
  final ApiClient api;
  final int projectId;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  ApiClient get api => widget.api;
  int get projectId => widget.projectId;
  late Future<ProjectDetail> _project = api.project(projectId);

  void _reload() => setState(() => _project = api.project(projectId));

  Future<String?> _askProjectLocation(
    BuildContext context, {
    String initial = '',
  }) => showDialog<String>(
    context: context,
    builder: (_) => _ProjectLocationDialog(initial: initial),
  );

  Future<void> _generateBoq(
    BuildContext context,
    ProjectDetail project,
    BoqSummary boq,
  ) async {
    // Prices depend on the location: always confirm it first (pre-filled).
    final current = [
      project.location,
      project.district,
      project.country,
    ].firstWhere((e) => e.trim().isNotEmpty, orElse: () => '');
    final entered = await _askProjectLocation(context, initial: current);
    if (entered == null || !context.mounted) return;
    var place = entered;
    if (entered != project.location.trim()) {
      try {
        await api.updateProjectLocation(project.id, entered);
      } on Object catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
        }
        return;
      }
      _reload();
      if (!context.mounted) return;
    }
    try {
      final created = await api.processBoq(boq.id);
      if (!context.mounted) return;
      final items = await api.allBoqItems(boq.id);
      if (!context.mounted) return;
      final l10n = context.tr;
      if (items.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.pdItemsCreated(created))));
        return;
      }
      final progress = ValueNotifier<String>(l10n.pdPreparingPrices);
      final reportFuture = _priceBoqItems(
        api,
        items,
        place,
        onProgress: (done, total, description) {
          progress.value = l10n.pdFetchingProgress(done, total, description);
        },
      );
      // The dialog is closed from here (once) when pricing finishes or fails.
      BuildContext? dialogContext;
      final dialogClosed = showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(l10n.pdGeneratingPrices),
              content: ValueListenableBuilder<String>(
                valueListenable: progress,
                builder: (context, value, _) => Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
            ),
          );
        },
      );
      ItemPricingReport report;
      try {
        report = await reportFuture;
      } finally {
        if (dialogContext == null) await WidgetsBinding.instance.endOfFrame;
        final dialog = dialogContext;
        if (dialog != null && dialog.mounted) Navigator.of(dialog).pop();
        await dialogClosed;
        progress.dispose();
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            report.failedMessages.isEmpty
                ? l10n.pdGeneratedAll(report.priced)
                : l10n.pdGeneratedPartial(
                    report.priced,
                    items.length,
                    report.failedMessages.length,
                  ),
          ),
        ),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BoqItemsPage(api: api, boqId: boq.id, title: boq.name),
        ),
      );
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr.pdTitle),
      actions: [
        PopupMenuButton<String>(
          tooltip: context.tr.pdActions,
          onSelected: (value) async {
            if (value == 'edit') {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      EditProjectPage(api: api, projectId: projectId),
                ),
              );
              if (saved == true && mounted) _reload();
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  title: Text(dialogContext.tr.pdDeleteTitle),
                  content: Text(dialogContext.tr.pdDeleteConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(dialogContext.tr.cancel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Theme.of(
                          dialogContext,
                        ).colorScheme.onError,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(dialogContext.tr.pdDelete),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                try {
                  await api.deleteProject(projectId);
                  if (context.mounted) {
                    final messenger = ScaffoldMessenger.of(context);
                    final message = context.tr.pdDeleted;
                    Navigator.of(context).pop(true);
                    messenger.showSnackBar(SnackBar(content: Text(message)));
                  }
                } on Object catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
                  }
                }
              }
            }
          },
          itemBuilder: (menuContext) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined),
                  const SizedBox(width: AppSpacing.sm),
                  Text(menuContext.tr.orgEdit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    menuContext.tr.pdDelete,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    body: StatefulBuilder(
      builder: (context, rebuild) => FutureBuilder<ProjectDetail>(
        future: _project,
        builder: (context, snapshot) {
          void reload() => _reload();
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _reload);
          }
          if (!snapshot.hasData) {
            return const LoadingState();
          }
          final project = snapshot.data!;
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          final l10n = context.tr;
          return ListView(
            padding: AppSpacing.page,
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: AppSpacing.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const IconTile(
                                  icon: Icons.foundation_outlined,
                                  size: 48,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.name,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        l10n.pdCode(project.code),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 120,
                                  ),
                                  child: StatusBadge(
                                    label: project.status.capitalize(),
                                    tone: StatusTone.forStatus(project.status),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Divider(height: 1),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              l10n.projContractValue,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AmountText(
                              project.contractValue,
                              currency: project.currency,
                              decimals: 2,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionCard(
                      title: l10n.pdOverview,
                      icon: Icons.info_outline,
                      children: [
                        _detailRow(
                          l10n.pdOwner,
                          project.ownerName.isNotEmpty
                              ? project.ownerName
                              : '—',
                        ),
                        _detailRow(l10n.status, project.status.capitalize()),
                        _detailRow(
                          l10n.projProjectType,
                          project.projectType.isNotEmpty
                              ? project.projectType
                              : '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionCard(
                      title: l10n.projParties,
                      icon: Icons.groups_outlined,
                      children: [
                        _detailRow(
                          l10n.projClient,
                          project.client.isNotEmpty ? project.client : '—',
                        ),
                        _detailRow(
                          l10n.projContractor,
                          project.contractor.isNotEmpty
                              ? project.contractor
                              : '—',
                        ),
                        _detailRow(
                          l10n.projConsultant,
                          project.consultant.isNotEmpty
                              ? project.consultant
                              : '—',
                        ),
                        _detailRow(
                          l10n.projQuantitySurveyor,
                          project.quantitySurveyor.isNotEmpty
                              ? project.quantitySurveyor
                              : '—',
                        ),
                        _detailRow(
                          l10n.projProjectManager,
                          project.projectManager.isNotEmpty
                              ? project.projectManager
                              : '—',
                        ),
                        _detailRow(
                          l10n.projSiteEngineer,
                          project.siteEngineer.isNotEmpty
                              ? project.siteEngineer
                              : '—',
                        ),
                        _detailRow(
                          l10n.projFundingOrganisation,
                          project.fundingOrganisation.isNotEmpty
                              ? project.fundingOrganisation
                              : '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionCard(
                      title: l10n.location,
                      icon: Icons.location_on_outlined,
                      children: [
                        _detailRow(
                          l10n.location,
                          _formatLocation(
                            project.country,
                            project.district,
                            project.location,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionCard(
                      title: l10n.pdDates,
                      icon: Icons.event_note_outlined,
                      children: [
                        _detailRow(
                          l10n.startDate,
                          displayDate(project.startDate),
                        ),
                        _detailRow(
                          l10n.pdExpectedCompletion,
                          displayDate(project.expectedCompletionDate),
                        ),
                      ],
                    ),
                    if (project.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      SectionCard(
                        title: l10n.projDescription,
                        icon: Icons.notes_outlined,
                        children: [
                          Text(
                            project.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sectionGap),
                    BoqTotalsCard(
                      totals: project.totals,
                      currency: project.currency,
                      title: l10n.pdProjectTotals,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    SectionHeader(
                      title: l10n.boqs,
                      trailing: project.boqs.isEmpty
                          ? null
                          : StatusBadge(
                              label: '${project.boqs.length}',
                              tone: StatusTone.brand,
                            ),
                    ),
                    if (project.boqs.isEmpty)
                      Card(
                        child: EmptyState(
                          compact: true,
                          icon: Icons.description_outlined,
                          title: l10n.pdNoBoqs,
                        ),
                      ),
                    for (final boq in project.boqs)
                      ListItemCard(
                        leading: const IconTile(
                          icon: Icons.description_outlined,
                        ),
                        title: boq.name,
                        subtitle: boqTotalsLine(
                          boq.totals,
                          project.currency,
                          l10n,
                        ),
                        showChevron: false,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: StatusBadge(
                                label: boq.status.capitalize(),
                                tone: boq.status == 'uploaded'
                                    ? StatusTone.info
                                    : StatusTone.forStatus(boq.status),
                              ),
                            ),
                            BoqActionsMenu(
                              onEdit: () async {
                                final saved = await showEditBoqSheet(
                                  context,
                                  api,
                                  BoqListItem(
                                    id: boq.id,
                                    name: boq.name,
                                    status: boq.status,
                                    description: '',
                                    projectId: project.id,
                                    projectName: project.name,
                                    itemsCount: 0,
                                    createdAt: '',
                                  ),
                                );
                                if (saved && mounted) reload();
                              },
                              onDelete: () async {
                                if (await confirmDeleteBoq(
                                      context,
                                      api,
                                      boq.id,
                                      boq.name,
                                    ) &&
                                    mounted) {
                                  reload();
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          final changed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => BoqDetailPage(
                                    api: api,
                                    boqId: boq.id,
                                    title: boq.name,
                                  ),
                                ),
                              );
                          if (changed == true && mounted) reload();
                        },
                        footer: boq.status == 'uploaded' && api.can('boq.edit')
                            ? FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(
                                    AppSizes.minTap,
                                  ),
                                ),
                                onPressed: () =>
                                    _generateBoq(context, project, boq),
                                icon: const Icon(Icons.auto_awesome),
                                label: Text(l10n.pdGenerateBoq),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

Widget _detailRow(String label, String value) =>
    KeyValueRow(label: label, value: value);

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
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _code,
      _client,
      _contractor,
      _consultant,
      _quantitySurveyor,
      _projectManager,
      _siteEngineer,
      _fundingOrganisation,
      _country,
      _district,
      _location,
      _projectType,
      _startDate,
      _expectedCompletionDate,
      _contractValue,
      _currency,
      _description,
      _originalLanguage,
      _reportLanguage,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProject() async {
    if (_loadError != null) setState(() => _loadError = null);
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
          _contractValue.text = amountFieldText(project.contractValue);
          _currency.text = project.currency;
          _description.text = project.description;
          _originalLanguage.text = project.originalLanguage;
          _reportLanguage.text = project.reportLanguage;
          _status = project.status;
        });
      }
    } on Object catch (e) {
      // Shown as an error state with Retry instead of an endless spinner.
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      controller.text = date.toIso8601String().split('T').first;
    }
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
            : parseAmount(_contractValue.text),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr.pdUpdated)));
        Navigator.pop(context, true);
      }
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pdEditTitle)),
      body: _loadError != null
          ? ErrorState(error: _loadError, onRetry: _loadProject)
          : _project == null
          ? const LoadingState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppSpacing.page,
                children: [
                  ContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionCard(
                          title: l10n.projBasicDetails,
                          icon: Icons.info_outline,
                          spacing: AppSpacing.md,
                          children: [
                            _projectTextField(
                              controller: _name,
                              label: l10n.projNameRequired,
                              icon: Icons.foundation_outlined,
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? l10n.projRequired
                                  : null,
                            ),
                            _projectTextField(
                              controller: _code,
                              label: l10n.projectCode,
                              icon: Icons.tag,
                            ),
                            _ProjectTypeField(
                              api: widget.api,
                              controller: _projectType,
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: InputDecoration(
                                labelText: l10n.status,
                                prefixIcon: const Icon(Icons.flag_outlined),
                              ),
                              items: _projectStatusItems(l10n, _status),
                              onChanged: (v) {
                                if (v != null) setState(() => _status = v);
                              },
                            ),
                            _projectTextField(
                              controller: _description,
                              label: l10n.projDescription,
                              maxLines: 3,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SectionCard(
                          title: l10n.projParties,
                          icon: Icons.groups_outlined,
                          spacing: AppSpacing.md,
                          children: [
                            _projectTextField(
                              controller: _client,
                              label: l10n.projClient,
                              icon: Icons.business_outlined,
                            ),
                            _projectTextField(
                              controller: _contractor,
                              label: l10n.projContractor,
                              icon: Icons.engineering_outlined,
                            ),
                            _projectTextField(
                              controller: _consultant,
                              label: l10n.projConsultant,
                              icon: Icons.support_agent_outlined,
                            ),
                            _projectTextField(
                              controller: _quantitySurveyor,
                              label: l10n.projQuantitySurveyor,
                              icon: Icons.straighten_outlined,
                            ),
                            _projectTextField(
                              controller: _projectManager,
                              label: l10n.projProjectManager,
                              icon: Icons.manage_accounts_outlined,
                            ),
                            _projectTextField(
                              controller: _siteEngineer,
                              label: l10n.projSiteEngineer,
                              icon: Icons.construction_outlined,
                            ),
                            _projectTextField(
                              controller: _fundingOrganisation,
                              label: l10n.projFundingOrganisation,
                              icon: Icons.account_balance_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SectionCard(
                          title: l10n.location,
                          icon: Icons.location_on_outlined,
                          spacing: AppSpacing.md,
                          children: [
                            _projectTextField(
                              controller: _country,
                              label: l10n.projCountry,
                              icon: Icons.public,
                            ),
                            _projectTextField(
                              controller: _district,
                              label: l10n.projDistrict,
                              icon: Icons.map_outlined,
                            ),
                            _projectTextField(
                              controller: _location,
                              label: l10n.location,
                              icon: Icons.place_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SectionCard(
                          title: l10n.projDatesValue,
                          icon: Icons.event_note_outlined,
                          spacing: AppSpacing.md,
                          children: [
                            _projectDateField(
                              controller: _startDate,
                              label: l10n.startDate,
                              onTap: () => _pickDate(_startDate),
                            ),
                            _projectDateField(
                              controller: _expectedCompletionDate,
                              label: l10n.projExpectedCompletionDate,
                              onTap: () => _pickDate(_expectedCompletionDate),
                            ),
                            _projectTextField(
                              controller: _contractValue,
                              label: l10n.projContractValue,
                              icon: Icons.payments_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: const [
                                ThousandsSeparatorInputFormatter(),
                              ],
                            ),
                            _projectTextField(
                              controller: _currency,
                              label: l10n.currency,
                              icon: Icons.currency_exchange,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SectionCard(
                          title: l10n.projLanguages,
                          icon: Icons.translate,
                          spacing: AppSpacing.md,
                          children: [
                            _projectTextField(
                              controller: _originalLanguage,
                              label: l10n.projOriginalLanguage,
                              icon: Icons.language,
                            ),
                            _projectTextField(
                              controller: _reportLanguage,
                              label: l10n.projReportLanguage,
                              icon: Icons.description_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        LoadingButton(
                          label: l10n.saveChanges,
                          icon: Icons.save_outlined,
                          loading: _loading,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
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
      _progress = context.tr.pdLoadingItems;
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
          _progress = context.tr.pdNoItemsToPrice;
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
          _progress = context.tr.pdLoadItemsFailed;
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
          setState(
            () => _progress = context.tr.pdFetchingProgress(
              done,
              total,
              description,
            ),
          );
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
          ? context.tr.pdFetchedAll(report.priced)
          : context.tr.pdFetchedPartial(
              report.priced,
              targets.length,
              report.failedMessages.length,
            );
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
      _progress = context.tr.pdRetrying(targets.length);
    });
    try {
      await _runPricing(targets, location);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _pricing = false;
          _progress = friendlyError(error);
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    if (!_historyVisible) return;
    final loc = _location.text.trim();
    if (loc.isEmpty) return;
    try {
      final h = await widget.api.pricingHistory(widget.boqId, loc);
      if (mounted) setState(() => _history = h);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    }
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
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_tree_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BoqDetailPage(
                api: widget.api,
                boqId: widget.boqId,
                title: widget.title,
              ),
            ),
          ),
          tooltip: context.tr.pdViewHierarchy,
        ),
      ],
    ),
    body: FutureBuilder<BoqDetail>(
      key: _refreshKey,
      future: _boqDetail,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: _refreshItems,
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: ErrorState(
                      error: snapshot.error,
                      onRetry: _refreshItems,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const LoadingState();
        }
        final theme = Theme.of(context);
        final boq = snapshot.data!;
        final items = _flattenBoqItems(boq);
        final total = items.fold<double>(
          0,
          (sum, item) =>
              sum + (double.tryParse(item.amount.replaceAll(',', '')) ?? 0),
        );
        final money = NumberFormat('#,##0.00');
        final l10n = context.tr;
        return RefreshIndicator(
          onRefresh: _refreshItems,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Extra bottom space so the share FAB never covers content.
            padding: AppSpacing.page.copyWith(bottom: 96),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HighlightCard(
                      label: l10n.pdOverallCost,
                      value: '${boq.currency} ${money.format(total)}',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionCard(
                      title: l10n.getPrices,
                      icon: Icons.sell_outlined,
                      spacing: AppSpacing.md,
                      children: [
                        TextField(
                          controller: _location,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _price(),
                          decoration: InputDecoration(
                            labelText: l10n.pdSelectLocation,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                        ),
                        LoadingButton(
                          label: l10n.getPrices,
                          icon: Icons.auto_awesome,
                          loading: _pricing,
                          onPressed: _price,
                        ),
                        if (_progress != null)
                          InfoBanner(
                            message: l10n.pdProgress(_progress!),
                            tone: BannerTone.info,
                            icon: Icons.schedule,
                          ),
                        if (_pricing)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            child: const LinearProgressIndicator(),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BoqReviewPricesPage(
                                  api: widget.api,
                                  boqId: widget.boqId,
                                  title: widget.title,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: Text(l10n.pdReviewPrices),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BoqLocationPricesPage(
                                  api: widget.api,
                                  boqId: widget.boqId,
                                  currency: boq.currency,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.map_outlined),
                            label: Text(l10n.pdLocationPrices),
                          ),
                        ),
                      ],
                    ),
                    if (_failedReport.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      InfoBanner(
                        title: l10n.pdItemsNotPriced(_failedReport.length),
                        message: [
                          for (final failure in _failedReport) '- $failure',
                        ].join('\n'),
                      ),
                      if (_retryItems.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _pricing ? null : _retry,
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.pdRetryFailed),
                          ),
                        ),
                    ],
                    if (_historyVisible) ...[
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppSizes.minTap),
                        ),
                        onPressed: _compareLocations,
                        icon: const Icon(Icons.compare_arrows),
                        label: Text(l10n.pdCompareLocations),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      SectionHeader(title: l10n.pdPricingHistory),
                      if (_history.isEmpty)
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(AppSizes.minTap),
                          ),
                          onPressed: _loadHistory,
                          icon: const Icon(Icons.history),
                          label: Text(l10n.pdLoadHistory),
                        )
                      else
                        for (final h in _history)
                          ListItemCard(
                            leading: const IconTile(
                              icon: Icons.history,
                              tone: StatusTone.info,
                            ),
                            title: jsonString(
                              jsonMap(h['boqItem'])['description'],
                            ),
                            subtitle:
                                '${jsonString(jsonMap(h['boqItem'])['quantity'])} '
                                '${jsonString(jsonMap(h['boqItem'])['unit'])}',
                            trailing: Text(
                              jsonString(
                                h['suggested_rate'],
                                l10n.pdNotAvailable,
                              ),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
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
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () =>
          showBoqShareSheet(context, widget.api, widget.boqId, widget.title),
      icon: const Icon(Icons.share_outlined),
      label: Text(context.tr.pdPdfShare),
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
      final location = jsonString(
        entry['location'],
        context.tr.pdUnknownLocation,
      );
      grouped.putIfAbsent(location, () => []).add(entry);
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.pdLocationComparison)),
      body: history.isEmpty
          ? EmptyState(
              icon: Icons.compare_arrows,
              title: context.tr.pdNoSavedLocations,
            )
          : ListView(
              padding: AppSpacing.page,
              children: [
                ContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(title: context.tr.pdSavedPricesByLocation),
                      for (final location in grouped.keys) ...[
                        SectionCard(
                          title: location,
                          icon: Icons.location_on_outlined,
                          children: [
                            for (
                              var i = 0;
                              i < grouped[location]!.length;
                              i++
                            ) ...[
                              if (i > 0) const Divider(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          jsonString(
                                            jsonMap(
                                              grouped[location]![i]['boqItem'],
                                            )['description'],
                                            context.tr.pdHardwareItem,
                                          ),
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          '${jsonString(jsonMap(grouped[location]![i]['boqItem'])['unit'])}'
                                          '  |  '
                                          '${jsonString(grouped[location]![i]['currency'])}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    jsonString(
                                      grouped[location]![i]['suggested_rate'],
                                      context.tr.pdNotAvailable,
                                    ),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Asks for the project location before generating a BOQ. Owns its text
/// controller so it is disposed only after the dialog has fully closed.
class _ProjectLocationDialog extends StatefulWidget {
  const _ProjectLocationDialog({required this.initial});

  final String initial;

  @override
  State<_ProjectLocationDialog> createState() => _ProjectLocationDialogState();
}

class _ProjectLocationDialogState extends State<_ProjectLocationDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.tr;
    return AlertDialog(
      // Scrolls when the keyboard leaves little room on small phones.
      scrollable: true,
      icon: const Icon(Icons.location_on_outlined),
      title: Text(l10n.pdGenerateBoq),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pdLocationHelp),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.pdProjectLocation,
                hintText: l10n.pdProjectLocationHint,
                prefixIcon: const Icon(Icons.place_outlined),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.pdEnterLocation : null,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.pdGenerateBoq)),
      ],
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
    this.totals,
  });

  /// Optional "Estimated … · Generated …" line.
  final String? totals;

  final String name;
  final String code;
  final String status;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListItemCard(
      leading: IconTile(icon: Icons.foundation_outlined, color: color),
      title: name,
      subtitle: [if (code.isNotEmpty) code, ?totals].join('\n'),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 110),
        child: StatusBadge(label: status, color: color),
      ),
      onTap: onTap,
    );
  }
}
