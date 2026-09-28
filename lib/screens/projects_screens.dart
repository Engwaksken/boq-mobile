part of '../main.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key, required this.l10n, required this.api});

  final AppLocalizations l10n;
  final ApiClient api;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late Future<List<ProjectSummary>> _projects = widget.api.projects();

  Future<void> _reload() async {
    setState(() => _projects = widget.api.projects());
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
    return status == 'active'
        ? const Color(0xFF047857)
        : const Color(0xFFB45309);
  }

  Future<void> _createProject() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateProjectPage(api: widget.api)),
    );
    if (created == true && mounted) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.projects,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<ProjectSummary>>(
              future: _projects,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(friendlyError(snapshot.error)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return Center(child: Text(l10n.noProjects));
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    children: [
                      for (final project in snapshot.data!)
                        _ProjectTile(
                          name: project.name,
                          code: project.code,
                          status: _statusLabel(project.status),
                          color: _statusColor(project.status),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailPage(
                                api: widget.api,
                                projectId: project.id,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _createProject,
              icon: const Icon(Icons.add),
              label: Text(l10n.createProject),
            ),
          ),
        ],
      ),
    );
  }
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
            : double.tryParse(_contractValue.text.trim()),
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
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Project Name *'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              decoration: InputDecoration(labelText: l10n.projectCode),
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
              decoration: const InputDecoration(labelText: 'Quantity Surveyor'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _projectManager,
              decoration: const InputDecoration(labelText: 'Project Manager'),
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
              decoration: const InputDecoration(labelText: 'Contract Value'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currency,
              decoration: InputDecoration(labelText: l10n.currency),
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
              decoration: const InputDecoration(labelText: 'Original Language'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reportLanguage,
              decoration: const InputDecoration(labelText: 'Report Language'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'archived', child: Text('Archived')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFBE123C)),
                ),
              ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : () => _save(l10n),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.createProject),
            ),
          ],
        ),
      ),
    );
  }
}
