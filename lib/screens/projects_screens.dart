part of '../main.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({
    super.key,
    required this.l10n,
    required this.api,
    this.status,
    this.boqStatus,
  });

  final AppLocalizations l10n;
  final ApiClient api;

  /// Only list projects with this status (e.g. `active`).
  final String? status;

  /// Only list projects that have a BOQ with this status (e.g. `under_review`).
  final String? boqStatus;

  bool get _filtered => status != null || boqStatus != null;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late Future<List<ProjectSummary>> _projects = _fetch();

  Future<List<ProjectSummary>> _fetch() => widget.api.projects(
    perPage: 50,
    status: widget.status,
    boqStatus: widget.boqStatus,
  );

  Future<void> _reload() async {
    setState(() => _projects = _fetch());
    await _projects;
  }

  String _statusLabel(String status) {
    return switch (status) {
      'active' => widget.l10n.projectStatusActive,
      'planning' => widget.l10n.projectStatusPlanning,
      _ => widget.l10n.draft,
    };
  }

  Color _statusColor(String status) {
    return status == 'active' ? AppColors.success : AppColors.warning;
  }

  Future<void> _createProject() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateProjectPage(api: widget.api)),
    );
    if (created == true && mounted) {
      await _reload();
    }
  }

  /// Wraps a non-list body so pull-to-refresh still works when it is shown.
  Widget _scrollableFill(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: constraints.maxHeight, child: child)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return FutureBuilder<List<ProjectSummary>>(
      future: _projects,
      builder: (context, snapshot) {
        final isEmpty = snapshot.hasData && snapshot.data!.isEmpty;
        final Widget body;
        if (snapshot.hasError) {
          body = _scrollableFill(
            ErrorState(error: snapshot.error, onRetry: _reload),
          );
        } else if (!snapshot.hasData) {
          body = const SkeletonList();
        } else if (isEmpty) {
          body = _scrollableFill(
            EmptyState(
              icon: Icons.folder_open_outlined,
              title: widget._filtered
                  ? 'No matching projects'
                  : l10n.noProjects,
              actionLabel: widget._filtered ? null : l10n.createProject,
              onAction: widget._filtered ? null : _createProject,
            ),
          );
        } else {
          body = ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.page,
            children: [
              for (final project in snapshot.data!)
                ContentWidth(
                  child: _ProjectTile(
                    name: project.name,
                    code: project.code,
                    status: _statusLabel(project.status),
                    color: _statusColor(project.status),
                    totals: project.totals.items > 0
                        ? boqTotalsLine(project.totals, project.currency)
                        : null,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(
                            api: widget.api,
                            projectId: project.id,
                          ),
                        ),
                      );
                      if (mounted) _reload();
                    },
                  ),
                ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RefreshIndicator(onRefresh: _reload, child: body),
            ),
            if (!isEmpty && !widget._filtered)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: ContentWidth(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSizes.buttonHeight,
                        ),
                      ),
                      onPressed: _createProject,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.createProject),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Text field used by the create / edit project forms.
Widget _projectTextField({
  required TextEditingController controller,
  required String label,
  IconData? icon,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  int maxLines = 1,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      alignLabelWithHint: maxLines > 1,
    ),
    keyboardType: keyboardType,
    maxLines: maxLines,
    validator: validator,
  );
}

/// Project type: pick one of the types stored in the database, or type another.
class _ProjectTypeField extends StatefulWidget {
  const _ProjectTypeField({required this.api, required this.controller});

  final ApiClient api;
  final TextEditingController controller;

  @override
  State<_ProjectTypeField> createState() => _ProjectTypeFieldState();
}

class _ProjectTypeFieldState extends State<_ProjectTypeField> {
  List<String> _types = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final catalog = await _loadOrNull(widget.api.categories);
    if (mounted && catalog != null) {
      setState(() => _types = catalog.projectTypes);
    }
  }

  Future<void> _choose() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Project type',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final type in _types)
                ListTile(
                  title: Text(type),
                  trailing: type == widget.controller.text
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, type),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) widget.controller.text = chosen;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: 'Project Type',
        hintText: 'Choose or type a project type',
        prefixIcon: const Icon(Icons.category_outlined),
        suffixIcon: _types.isEmpty
            ? null
            : IconButton(
                tooltip: 'Choose a project type',
                icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                onPressed: _choose,
              ),
      ),
    );
  }
}

/// Read-only date field that opens a picker when tapped.
Widget _projectDateField({
  required TextEditingController controller,
  required String label,
  required VoidCallback onTap,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.calendar_today_outlined),
    ),
    readOnly: true,
    onTap: onTap,
  );
}

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key, required this.api});
  final ApiClient api;

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
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
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _client.dispose();
    _contractor.dispose();
    _consultant.dispose();
    _quantitySurveyor.dispose();
    _projectManager.dispose();
    _siteEngineer.dispose();
    _fundingOrganisation.dispose();
    _country.dispose();
    _district.dispose();
    _location.dispose();
    _projectType.dispose();
    _startDate.dispose();
    _expectedCompletionDate.dispose();
    _contractValue.dispose();
    _currency.dispose();
    _description.dispose();
    _originalLanguage.dispose();
    _reportLanguage.dispose();
    super.dispose();
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

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.createProject(
        name: _name.text.trim(),
        code: _code.text.trim().isEmpty ? null : _code.text.trim(),
        client: _client.text.trim().isEmpty ? null : _client.text.trim(),
        contractor: _contractor.text.trim().isEmpty
            ? null
            : _contractor.text.trim(),
        consultant: _consultant.text.trim().isEmpty
            ? null
            : _consultant.text.trim(),
        quantitySurveyor: _quantitySurveyor.text.trim().isEmpty
            ? null
            : _quantitySurveyor.text.trim(),
        projectManager: _projectManager.text.trim().isEmpty
            ? null
            : _projectManager.text.trim(),
        siteEngineer: _siteEngineer.text.trim().isEmpty
            ? null
            : _siteEngineer.text.trim(),
        fundingOrganisation: _fundingOrganisation.text.trim().isEmpty
            ? null
            : _fundingOrganisation.text.trim(),
        country: _country.text.trim().isEmpty ? null : _country.text.trim(),
        district: _district.text.trim().isEmpty ? null : _district.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        projectType: _projectType.text.trim().isEmpty
            ? null
            : _projectType.text.trim(),
        startDate: _startDate.text.isEmpty ? null : _startDate.text,
        expectedCompletionDate: _expectedCompletionDate.text.isEmpty
            ? null
            : _expectedCompletionDate.text,
        contractValue: _contractValue.text.trim().isEmpty
            ? null
            : parseAmount(_contractValue.text),
        currency: _currency.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        status: _status,
        originalLanguage: _originalLanguage.text.trim().isEmpty
            ? null
            : _originalLanguage.text.trim(),
        reportLanguage: _reportLanguage.text.trim().isEmpty
            ? null
            : _reportLanguage.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.projectCreated)));
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createProject)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: 'Basic details',
                    icon: Icons.info_outline,
                    spacing: AppSpacing.md,
                    children: [
                      _projectTextField(
                        controller: _name,
                        label: 'Project Name *',
                        icon: Icons.foundation_outlined,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
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
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'draft',
                            child: Text('Draft'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'archived',
                            child: Text('Archived'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                      _projectTextField(
                        controller: _description,
                        label: 'Description',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    title: 'Parties',
                    icon: Icons.groups_outlined,
                    spacing: AppSpacing.md,
                    children: [
                      _projectTextField(
                        controller: _client,
                        label: 'Client',
                        icon: Icons.business_outlined,
                      ),
                      _projectTextField(
                        controller: _contractor,
                        label: 'Contractor',
                        icon: Icons.engineering_outlined,
                      ),
                      _projectTextField(
                        controller: _consultant,
                        label: 'Consultant',
                        icon: Icons.support_agent_outlined,
                      ),
                      _projectTextField(
                        controller: _quantitySurveyor,
                        label: 'Quantity Surveyor',
                        icon: Icons.straighten_outlined,
                      ),
                      _projectTextField(
                        controller: _projectManager,
                        label: 'Project Manager',
                        icon: Icons.manage_accounts_outlined,
                      ),
                      _projectTextField(
                        controller: _siteEngineer,
                        label: 'Site Engineer',
                        icon: Icons.construction_outlined,
                      ),
                      _projectTextField(
                        controller: _fundingOrganisation,
                        label: 'Funding Organisation',
                        icon: Icons.account_balance_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    title: 'Location',
                    icon: Icons.location_on_outlined,
                    spacing: AppSpacing.md,
                    children: [
                      _projectTextField(
                        controller: _country,
                        label: 'Country',
                        icon: Icons.public,
                      ),
                      _projectTextField(
                        controller: _district,
                        label: 'District',
                        icon: Icons.map_outlined,
                      ),
                      _projectTextField(
                        controller: _location,
                        label: 'Location',
                        icon: Icons.place_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SectionCard(
                    title: 'Dates & value',
                    icon: Icons.event_note_outlined,
                    spacing: AppSpacing.md,
                    children: [
                      _projectDateField(
                        controller: _startDate,
                        label: 'Start Date',
                        onTap: () => _pickDate(_startDate),
                      ),
                      _projectDateField(
                        controller: _expectedCompletionDate,
                        label: 'Expected Completion Date',
                        onTap: () => _pickDate(_expectedCompletionDate),
                      ),
                      _projectTextField(
                        controller: _contractValue,
                        label: 'Contract Value',
                        icon: Icons.payments_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
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
                    title: 'Languages',
                    icon: Icons.translate,
                    spacing: AppSpacing.md,
                    children: [
                      _projectTextField(
                        controller: _originalLanguage,
                        label: 'Original Language',
                        icon: Icons.language,
                      ),
                      _projectTextField(
                        controller: _reportLanguage,
                        label: 'Report Language',
                        icon: Icons.description_outlined,
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    InfoBanner(message: _error!),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  LoadingButton(
                    label: l10n.createProject,
                    icon: Icons.check,
                    loading: _saving,
                    onPressed: () => _save(l10n),
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
