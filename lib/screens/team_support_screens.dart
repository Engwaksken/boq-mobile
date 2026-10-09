part of '../main.dart';

class ProjectAssignmentsPage extends StatefulWidget {
  const ProjectAssignmentsPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<ProjectAssignmentsPage> createState() => _ProjectAssignmentsPageState();
}

class _ProjectAssignmentsPageState extends State<ProjectAssignmentsPage> {
  late Future<ResourcePage> _future = widget.api.projectAssignments()..ignore();
  bool _busy = false;

  Future<void> _reload([int page = 1]) {
    setState(() {
      _future = widget.api.projectAssignments(page: page)..ignore();
    });
    return _orgWait(_future);
  }

  Future<void> _assign([Map<String, dynamic>? assignment]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ProjectAssignmentFormPage(api: widget.api, assignment: assignment),
      ),
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _revoke(Map<String, dynamic> assignment) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.orgAssignmentRevokeConfirm),
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
      await widget.api.revokeProjectAssignment(_orgId(assignment['id']));
      if (mounted) await _reload();
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
      appBar: AppBar(title: Text(l.orgAssignments)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.orgAssign,
        onPressed: _busy ? null : () => _assign(),
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          Expanded(
            child: _ResourceList(
              future: _future,
              reload: _reload,
              tile: (a) => Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text('${a['project']?['name'] ?? ''}'),
                      subtitle: Text(
                        '${a['user']?['name'] ?? ''} · ${a['user']?['email'] ?? ''}\n${a['role']}',
                      ),
                      isThreeLine: true,
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: _busy ? null : () => _assign(a),
                          child: Text(l.orgEdit),
                        ),
                        TextButton(
                          onPressed: _busy ? null : () => _revoke(a),
                          child: Text(l.orgRevoke),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectAssignmentFormPage extends StatefulWidget {
  const ProjectAssignmentFormPage({
    super.key,
    required this.api,
    this.assignment,
  });
  final ApiClient api;
  final Map<String, dynamic>? assignment;
  @override
  State<ProjectAssignmentFormPage> createState() =>
      _ProjectAssignmentFormPageState();
}

class _ProjectAssignmentFormPageState extends State<ProjectAssignmentFormPage> {
  final _form = GlobalKey<FormState>();
  late Future<Map<String, dynamic>> _options = widget.api.assignmentOptions()
    ..ignore();
  late int? _project = widget.assignment == null
      ? null
      : _orgId(widget.assignment!['project_id']);
  late int? _member = widget.assignment == null
      ? null
      : _orgId(widget.assignment!['user_id']);
  late String? _role = widget.assignment?['role'] as String?;
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.api.saveProjectAssignment(_project!, _member!, _role!);
      if (mounted) Navigator.pop(context, true);
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
      appBar: AppBar(title: Text(l.orgAssign)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _options,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _orgRetry(context, snapshot.error!, () {
              setState(() {
                _options = widget.api.assignmentOptions()..ignore();
              });
            });
          }
          final projects = (snapshot.data!['projects'] as List)
              .cast<Map<String, dynamic>>();
          final members = (snapshot.data!['members'] as List)
              .cast<Map<String, dynamic>>();
          final roles = (snapshot.data!['roles'] as List).cast<String>();
          if (projects.isEmpty || members.isEmpty || roles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.orgNoAssignmentOptions),
              ),
            );
          }
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: projects.any((p) => _orgId(p['id']) == _project)
                      ? _project
                      : null,
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
                  onChanged: _busy || widget.assignment != null
                      ? null
                      : (v) => _project = v,
                  validator: (v) => v == null ? l.orgRequired : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: members.any((m) => _orgId(m['id']) == _member)
                      ? _member
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.orgMember),
                  items: members
                      .map(
                        (m) => DropdownMenuItem(
                          value: _orgId(m['id']),
                          child: Text(
                            '${m['name']} (${m['email']})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _busy || widget.assignment != null
                      ? null
                      : (v) => _member = v,
                  validator: (v) => v == null ? l.orgRequired : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: roles.contains(_role) ? _role : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.orgRole),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: _busy ? null : (v) => _role = v,
                  validator: (v) => v == null ? l.orgRequired : null,
                ),
                const SizedBox(height: 24),
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

class FaqsPage extends StatefulWidget {
  const FaqsPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<FaqsPage> createState() => _FaqsPageState();
}

class _FaqsPageState extends State<FaqsPage> {
  final _search = TextEditingController();
  String _query = '';
  late Future<ResourcePage> _future = widget.api.faqs()..ignore();
  Future<void> _reload([int page = 1]) {
    setState(() {
      _future = widget.api.faqs(page: page, search: _query)..ignore();
    });
    return _orgWait(_future);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.orgFaqs),
        actions: [
          IconButton(
            tooltip: l.orgManageFaqs,
            icon: const Icon(Icons.edit_note),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FaqAdminPage(api: widget.api),
                ),
              );
              if (mounted) _reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              maxLength: 255,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l.orgSearchFaqs,
                suffixIcon: IconButton(
                  tooltip: l.orgSearchFaqs,
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _query = _search.text.trim();
                    _reload();
                  },
                ),
              ),
              onSubmitted: (value) {
                _query = value.trim();
                _reload();
              },
            ),
          ),
          Expanded(
            child: _ResourceList(
              future: _future,
              reload: _reload,
              tile: (faq) => Card(
                child: ExpansionTile(
                  key: ValueKey(faq['id']),
                  title: Text('${faq['question']}'),
                  childrenPadding: const EdgeInsets.all(16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [SelectableText('${faq['answer']}')],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaqAdminPage extends StatefulWidget {
  const FaqAdminPage({super.key, required this.api});
  final ApiClient api;
  @override
  State<FaqAdminPage> createState() => _FaqAdminPageState();
}

class _FaqAdminPageState extends State<FaqAdminPage> {
  late Future<ResourcePage> _future = widget.api.adminFaqs()..ignore();
  Future<void> _reload([int page = 1]) {
    setState(() {
      _future = widget.api.adminFaqs(page: page)..ignore();
    });
    return _orgWait(_future);
  }

  Future<void> _edit([Map<String, dynamic>? faq]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FaqFormPage(api: widget.api, faq: faq),
      ),
    );
    if (changed == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.orgManageFaqs)),
      body: FutureBuilder<ResourcePage>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _orgRetry(context, snapshot.error!, () => _reload());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: Text(l.orgQuestion),
                ),
              ),
              Expanded(
                child: _ResourceList(
                  future: _future,
                  reload: _reload,
                  tile: (faq) => Card(
                    child: ListTile(
                      title: Text('${faq['question']}'),
                      subtitle: Text('${l.orgSortOrder}: ${faq['sort_order']}'),
                      leading: Icon(
                        faq['is_active'] == true
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _edit(faq),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FaqFormPage extends StatefulWidget {
  const FaqFormPage({super.key, required this.api, this.faq});
  final ApiClient api;
  final Map<String, dynamic>? faq;
  @override
  State<FaqFormPage> createState() => _FaqFormPageState();
}

class _FaqFormPageState extends State<FaqFormPage> {
  final _form = GlobalKey<FormState>();
  late final _question = TextEditingController(
    text: '${widget.faq?['question'] ?? ''}',
  );
  late final _answer = TextEditingController(
    text: '${widget.faq?['answer'] ?? ''}',
  );
  late final _order = TextEditingController(
    text: '${widget.faq?['sort_order'] ?? 0}',
  );
  late bool _active = widget.faq?['is_active'] != false;
  bool _busy = false;

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.api.saveFaq({
        'question': _question.text.trim(),
        'answer': _answer.text.trim(),
        'sort_order': int.parse(_order.text.trim()),
        'is_active': _active,
      }, id: widget.faq == null ? null : _orgId(widget.faq!['id']));
      if (mounted) Navigator.pop(context, true);
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
      appBar: AppBar(title: Text(l.orgManageFaqs)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _question,
              enabled: !_busy,
              maxLength: 255,
              decoration: InputDecoration(labelText: l.orgQuestion),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.orgRequired : null,
            ),
            TextFormField(
              controller: _answer,
              enabled: !_busy,
              minLines: 4,
              maxLines: 12,
              decoration: InputDecoration(labelText: l.orgAnswer),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.orgRequired : null,
            ),
            TextFormField(
              controller: _order,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.orgSortOrder),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                return n == null || n < 0 ? l.orgRequired : null;
              },
            ),
            SwitchListTile(
              title: Text(l.orgFaqActive),
              value: _active,
              onChanged: _busy ? null : (v) => setState(() => _active = v),
            ),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(l.orgSave),
            ),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
