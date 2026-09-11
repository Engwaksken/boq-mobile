import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:boq_mobile/l10n/app_localizations.dart';

import 'api_client.dart';

void main() {
  runApp(const BoqApp());
}

class BoqApp extends StatefulWidget {
  const BoqApp({super.key});

  @override
  State<BoqApp> createState() => _BoqAppState();
}

class _BoqAppState extends State<BoqApp> {
  Locale _locale = const Locale('en');
  final ApiClient _api = ApiClient();

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102A43);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        BoqMaterialLocalizationsDelegate(),
        BoqCupertinoLocalizationsDelegate(),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7FA),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF102A43), width: 1.5),
          ),
        ),
      ),
      home: SessionGate(
        api: _api,
        locale: _locale,
        onLocaleChanged: (locale) {
          setState(() => _locale = locale);
        },
      ),
    );
  }
}

class BoqMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const BoqMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultMaterialLocalizations());

  @override
  bool shouldReload(BoqMaterialLocalizationsDelegate old) => false;
}

class BoqCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const BoqCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultCupertinoLocalizations());

  @override
  bool shouldReload(BoqCupertinoLocalizationsDelegate old) => false;
}

class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.api,
    required this.locale,
    required this.onLocaleChanged,
  });

  final ApiClient api;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<bool> _session;

  @override
  void initState() {
    super.initState();
    _session = widget.api.hasSession();
  }

  void _refresh() {
    setState(() {
      _session = widget.api.hasSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (snapshot.data != true) {
          return LoginPage(api: widget.api, onSignedIn: _refresh);
        }

        return HomeScreen(
          api: widget.api,
          locale: widget.locale,
          onLocaleChanged: widget.onLocaleChanged,
          onSignedOut: _refresh,
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.api, required this.onSignedIn});

  final ApiClient api;
  final VoidCallback onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.api.login(
        email: _email.text.trim(),
        password: _password.text,
      );

      if (!mounted) {
        return;
      }

      widget.onSignedIn();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to sign in. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.foundation_outlined,
                      size: 54,
                      color: Color(0xFF102A43),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.signInDescription, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty || !email.contains('@')) {
                          return l10n.email;
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) {
                        if (!_loading) {
                          _signIn();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.password;
                        }

                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDA4AF)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFBE123C)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _loading ? null : _signIn,
                        child: _loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.signIn),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.api,
    required this.locale,
    required this.onLocaleChanged,
    required this.onSignedOut,
  });

  final ApiClient api;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onSignedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = <Widget>[
      DashboardPage(l10n: l10n, api: widget.api),
      ProjectsPage(l10n: l10n, api: widget.api),
      ImportPage(l10n: l10n, api: widget.api),
      AccountPage(
        l10n: l10n,
        api: widget.api,
        locale: widget.locale,
        onLocaleChanged: widget.onLocaleChanged,
        onSignedOut: widget.onSignedOut,
      ),
    ];

    final destinations = [
      (Icons.space_dashboard_outlined, Icons.space_dashboard, l10n.dashboard),
      (Icons.account_tree_outlined, Icons.account_tree, l10n.projects),
      (Icons.document_scanner_outlined, Icons.document_scanner, l10n.importBoq),
      (Icons.person_outline, Icons.person, l10n.account),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          for (final item in destinations)
            NavigationDestination(
              icon: Icon(item.$1),
              selectedIcon: Icon(item.$2),
              label: item.$3,
            ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.l10n, required this.api});

  final AppLocalizations l10n;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: api.dashboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final summary = snapshot.data;

        if (summary == null) {
          return const SizedBox.shrink();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.goodMorning,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.overview,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  tooltip: l10n.notifications,
                  icon: const Icon(Icons.notifications_none_outlined),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ValueCard(
              title: l10n.estimatedValue,
              value: 'UGX ${summary.totalEstimatedValue.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.88,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Metric(
                  label: l10n.totalProjects,
                  value: '${summary.totalProjects}',
                  color: const Color(0xFF1D4ED8),
                ),
                _Metric(
                  label: l10n.activeProjects,
                  value: '${summary.activeProjects}',
                  color: const Color(0xFF047857),
                ),
                _Metric(
                  label: l10n.boqsInReview,
                  value: '${summary.boqsAwaitingReview}',
                  color: const Color(0xFFB45309),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recentProjects,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(body: ProjectsPage(l10n: l10n, api: api)))), child: Text(l10n.viewAll)),
              ],
            ),
            if (summary.recentProjects.isEmpty)
              const Center(child: Text('No recent projects yet')),
            ...summary.recentProjects.map((project) => _ProjectTile(
              name: project.name,
              code: project.code,
              status: project.status == 'active' ? l10n.projectStatusActive : project.status == 'planning' ? l10n.projectStatusPlanning : l10n.draft,
              color: project.status == 'active' ? const Color(0xFF047857) : const Color(0xFFB45309),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectDetailPage(
                    api: api,
                    projectId: project.id,
                  ),
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}

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
                  return Center(child: Text(snapshot.error.toString()));
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
  String _currency = 'UGX';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
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
        code: _code.text.trim(),
        currency: _currency,
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
              decoration: InputDecoration(labelText: l10n.projects),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? l10n.projects : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              decoration: InputDecoration(labelText: l10n.projectCode),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(labelText: l10n.currency),
              items: const [
                DropdownMenuItem(value: 'UGX', child: Text('UGX')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _currency = value);
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

class ImportPage extends StatefulWidget {
  const ImportPage({super.key, required this.l10n, required this.api});

  final AppLocalizations l10n;
  final ApiClient api;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  late final Future<List<ProjectSummary>> _projects = widget.api.projects();
  int? _projectId;
  bool _uploading = false;

  Future<void> _upload() async {
    if (_projectId == null) return;
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf', 'jpg', 'jpeg', 'png'],
    );
    if (selected == null || selected.files.isEmpty) return;
    final file = selected.files.single;
    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && path == null) return;
    setState(() => _uploading = true);
    try {
      if (bytes != null) {
        await widget.api.uploadBoqFromBytes(projectId: _projectId!, fileName: file.name, bytes: bytes);
      } else if (path != null) {
        await widget.api.uploadBoq(projectId: _projectId!, filePath: path);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.l10n.imported}: ${file.name}')));
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed: check the file and try again')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.importTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(l10n.importDescription),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: Color(0xFF1D4ED8),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<ProjectSummary>>(
                future: _projects,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return DropdownButton<int>(
                    value: _projectId,
                    hint: Text(l10n.projects),
                    items: [
                      for (final project in snapshot.data!)
                        DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _projectId = value),
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _projectId == null || _uploading ? null : _upload,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(l10n.uploadDocument),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.supportedFiles,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _projectId == null || _uploading ? null : _upload,
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(l10n.scanPages),
          ),
        ),
      ],
    );
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.l10n,
    required this.api,
    required this.locale,
    required this.onLocaleChanged,
    required this.onSignedOut,
  });

  final AppLocalizations l10n;
  final ApiClient api;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onSignedOut;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late Future<Map<String, dynamic>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.api.currentSubscription();
  }

  Future<void> _signOut() async {
    await widget.api.logout();
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.l10n.account,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        FutureBuilder<Map<String, dynamic>>(
          future: _subscription,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final sub = snapshot.data!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.l10n.subscription,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(sub['plan']?['name'] ?? 'No Active Plan'),
                      const SizedBox(height: 4),
                      Text(sub['status'] ?? 'N/A', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(value: 0.58),
                      const SizedBox(height: 8),
                      Text('${widget.l10n.aiCredits}: ${sub['plan']?['ai_credits'] ?? 'N/A'}'),
                      Text('${widget.l10n.ocrPages}: ${sub['plan']?['ocr_pages'] ?? 'N/A'}'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: () {}, child: Text(widget.l10n.managePlan)),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Card(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(widget.l10n.language),
                trailing: DropdownButton<Locale>(
                  value: widget.locale,
                  underline: const SizedBox(),
                  onChanged: (value) {
                    if (value != null) widget.onLocaleChanged(value);
                  },
                  items: [
                    const DropdownMenuItem(value: Locale('en'), child: Text('English')),
                    const DropdownMenuItem(value: Locale('lg'), child: Text('Luganda')),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(widget.l10n.notifications),
                trailing: const Icon(Icons.chevron_right),
                onTap: () { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications'))); },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(widget.l10n.profile),
                trailing: const Icon(Icons.chevron_right),
                onTap: () { Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfilePage(api: widget.api, locale: widget.locale, onLocaleChanged: widget.onLocaleChanged))); },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _signOut, icon: const Icon(Icons.logout), label: Text(widget.l10n.signOut)),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.api,
    required this.locale,
    required this.onLocaleChanged,
  });

  final ApiClient api;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final Future<UserProfile> _profile = widget.api.profile();
  late String _selectedLocale = widget.locale.languageCode;
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final profile = await widget.api.updateProfile(
        name: _name.text.trim(),
        email: _email.text.trim(),
        locale: _selectedLocale,
        password: _password.text,
      );
      widget.onLocaleChanged(Locale(profile.locale));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: FutureBuilder<UserProfile>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!;
          if (!_loaded) {
            _loaded = true;
            _name.text = profile.name;
            _email.text = profile.email;
            _selectedLocale = profile.locale;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.fullName),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.fullName
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.email),
                  validator: (value) =>
                      value == null || !value.contains('@') ? l10n.email : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocale,
                  decoration: InputDecoration(labelText: l10n.language),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                    DropdownMenuItem(value: 'lg', child: Text(l10n.luganda)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLocale = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    helperText: l10n.passwordHint,
                  ),
                  validator: (value) =>
                      value != null && value.isNotEmpty && value.length < 8
                      ? l10n.newPassword
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFBE123C)),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : () => _save(l10n),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveChanges),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFFBFD7EA))),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

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
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditProjectPage(api: api, projectId: projectId),
                ),
              );
              if (updated == true && context.mounted) {
                // Refresh will happen automatically when popping back
              }
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Project'),
                  content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                try {
                  await api.deleteProject(projectId);
                  if (context.mounted) {
                    Navigator.of(context).pop(true); // Return true to indicate deletion
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project deleted')),
                    );
                  }
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 8), Text('Edit')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ],
    ),
    body: FutureBuilder<ProjectDetail>(
      future: api.project(projectId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
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
                    Text(project.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Code: ${project.code}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    _detailRow('Owner', project.ownerName.isNotEmpty ? project.ownerName : '—'),
                    _detailRow('Status', project.status.capitalize()),
                    _detailRow('Client', project.client.isNotEmpty ? project.client : '—'),
                    _detailRow('Contractor', project.contractor.isNotEmpty ? project.contractor : '—'),
                    _detailRow('Consultant', project.consultant.isNotEmpty ? project.consultant : '—'),
                    _detailRow('Quantity Surveyor', project.quantitySurveyor.isNotEmpty ? project.quantitySurveyor : '—'),
                    _detailRow('Project Manager', project.projectManager.isNotEmpty ? project.projectManager : '—'),
                    _detailRow('Site Engineer', project.siteEngineer.isNotEmpty ? project.siteEngineer : '—'),
                    _detailRow('Funding Organisation', project.fundingOrganisation.isNotEmpty ? project.fundingOrganisation : '—'),
                    _detailRow('Location', _formatLocation(project.country, project.district, project.location)),
                    _detailRow('Project Type', project.projectType.isNotEmpty ? project.projectType : '—'),
                    _detailRow('Start Date', project.startDate.isNotEmpty ? dateFormat.format(DateTime.parse(project.startDate)) : '—'),
                    _detailRow('Expected Completion', project.expectedCompletionDate.isNotEmpty ? dateFormat.format(DateTime.parse(project.expectedCompletionDate)) : '—'),
                    _detailRow('Contract Value', '${NumberFormat('#,##0.00').format(project.contractValue)} ${project.currency}'),
                    if (project.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Description', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(project.description),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('BOQs', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (project.boqs.isEmpty)
              const Center(child: Text('No BOQs yet')),
            for (final boq in project.boqs)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(boq.name),
                  subtitle: Text(boq.status),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BoqItemsPage(
                        api: api,
                        boqId: boq.id,
                        title: boq.name,
                      ),
                    ),
                  ),
                  trailing: boq.status == 'uploaded'
                      ? FilledButton(
                          onPressed: () async {
                            try {
                              final items = await api.processBoq(boq.id);
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$items BOQ items created')),
                                );
                            } on ApiException catch (error) {
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
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
      SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
      Expanded(child: Text(value)),
    ],
  ),
);

String _formatLocation(String country, String district, String location) {
  final parts = [country, district, location].where((e) => e.isNotEmpty).toList();
  return parts.isEmpty ? '—' : parts.join(', ');
}

extension StringCapitalize on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class EditProjectPage extends StatefulWidget {
  const EditProjectPage({super.key, required this.api, required this.projectId});
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
          _status = project.status;
        });
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        quantitySurveyor: _quantitySurveyor.text.isEmpty ? null : _quantitySurveyor.text,
        projectManager: _projectManager.text.isEmpty ? null : _projectManager.text,
        siteEngineer: _siteEngineer.text.isEmpty ? null : _siteEngineer.text,
        fundingOrganisation: _fundingOrganisation.text.isEmpty ? null : _fundingOrganisation.text,
        country: _country.text.isEmpty ? null : _country.text,
        district: _district.text.isEmpty ? null : _district.text,
        location: _location.text.isEmpty ? null : _location.text,
        projectType: _projectType.text.isEmpty ? null : _projectType.text,
        startDate: _startDate.text.isEmpty ? null : _startDate.text,
        expectedCompletionDate: _expectedCompletionDate.text.isEmpty ? null : _expectedCompletionDate.text,
        contractValue: _contractValue.text.isEmpty ? null : double.tryParse(_contractValue.text),
        currency: _currency.text,
        description: _description.text.isEmpty ? null : _description.text,
        status: _status,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project updated')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Project Name *'), validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(controller: _code, decoration: const InputDecoration(labelText: 'Project Code')),
                TextFormField(controller: _client, decoration: const InputDecoration(labelText: 'Client')),
                TextFormField(controller: _contractor, decoration: const InputDecoration(labelText: 'Contractor')),
                TextFormField(controller: _consultant, decoration: const InputDecoration(labelText: 'Consultant')),
                TextFormField(controller: _quantitySurveyor, decoration: const InputDecoration(labelText: 'Quantity Surveyor')),
                TextFormField(controller: _projectManager, decoration: const InputDecoration(labelText: 'Project Manager')),
                TextFormField(controller: _siteEngineer, decoration: const InputDecoration(labelText: 'Site Engineer')),
                TextFormField(controller: _fundingOrganisation, decoration: const InputDecoration(labelText: 'Funding Organisation')),
                TextFormField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
                TextFormField(controller: _district, decoration: const InputDecoration(labelText: 'District')),
                TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
                TextFormField(controller: _projectType, decoration: const InputDecoration(labelText: 'Project Type')),
                TextFormField(
                  controller: _startDate,
                  decoration: const InputDecoration(labelText: 'Start Date', suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: () => _pickDate(_startDate),
                ),
                TextFormField(
                  controller: _expectedCompletionDate,
                  decoration: const InputDecoration(labelText: 'Expected Completion Date', suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: () => _pickDate(_expectedCompletionDate),
                ),
                TextFormField(controller: _contractValue, decoration: const InputDecoration(labelText: 'Contract Value'), keyboardType: TextInputType.number),
                TextFormField(controller: _currency, decoration: const InputDecoration(labelText: 'Currency')),
                TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'archived', child: Text('Archived')),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: _loading ? null : _save, child: _loading ? const CircularProgressIndicator() : const Text('Save Changes')),
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
  Future<List<BoqItemSummary>>? _items;
final _refreshKey = GlobalKey();
  String? _progress;
  List<Map<String, dynamic>> _history = [];
  bool _historyVisible = false;
  _BoqItemsPageState() : _items = null;
  @override void initState() { super.initState(); _items = widget.api.boqItems(widget.boqId); }
  @override void dispose() { _location.dispose(); super.dispose(); }
  Future<void> _refreshItems() async { if (mounted) setState(() => _items = widget.api.boqItems(widget.boqId)); }
  Future<void> _price() async { if (_location.text.trim().isEmpty) return; setState(() { _progress = 'Starting...'; _history = []; _historyVisible = false; }); var batch = await widget.api.startPricingBatch(widget.boqId, _location.text.trim()); while (batch.status == 'queued' || batch.status == 'running') { await Future<void>.delayed(const Duration(seconds: 2)); batch = await widget.api.pricingBatch(batch.id); if (mounted) setState(() => _progress = '${batch.processed}/${batch.total} (${batch.status})'); } if (mounted) { await _refreshItems(); setState(() => _progress = 'Completed (${batch.processed} items)'); _historyVisible = true; } }
  Future<void> _loadHistory() async { if (!_historyVisible) return; final loc = _location.text.trim(); if (loc.isEmpty) return; final h = await widget.api.pricingHistory(widget.boqId, loc); if (mounted) setState(() => _history = h); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<List<BoqItemSummary>>(
      key: _refreshKey,
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
         final total = snapshot.data!.fold<double>(0, (sum, item) => sum + (double.tryParse(item.amount.replaceAll(',', '')) ?? 0));
         final money = NumberFormat('#,##0.00');
         return ListView(padding: const EdgeInsets.all(16),
           children: [
              Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF102A43), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Overall BOQ Cost', style: TextStyle(color: Color(0xFFBFD7EA))), const SizedBox(height: 4), Text('UGX ${money.format(total)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700))])),
              const SizedBox(height: 16),
              TextField(controller: _location, decoration: const InputDecoration(labelText: 'Select location', prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 10), FilledButton.icon(onPressed: _price, icon: const Icon(Icons.auto_awesome), label: const Text('Get Prices')),
               if (_progress != null) Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(top: 8), color: const Color(0xFFE8F5E9), child: Row(children: [const Icon(Icons.schedule), const SizedBox(width: 8), Expanded(child: Text('Progress: $_progress', style: const TextStyle(fontWeight: FontWeight.w700)))]))
               ,const SizedBox(height: 16),
              if (_historyVisible) ...[const Text('Pricing History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)), const SizedBox(height: 8), if (_history.isEmpty) ...[const SizedBox(height: 8), FilledButton.icon(onPressed: _loadHistory, icon: const Icon(Icons.history), label: Text('Load History'))] else ...[for (final h in _history) ...[Card(child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [Text('${h['suggested_rate'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w700)), const Spacer(), Text('${h['boqItem']?['description'] ?? ''}'), const SizedBox(width: 8), Text('${h['boqItem']?['quantity']} ${h['boqItem']?['unit'] ?? ''}')]))), const SizedBox(height: 8)]], const SizedBox(height: 16)],
           ],
         );
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        try {
          final file = File('${(await getTemporaryDirectory()).path}/boq-${widget.boqId}.pdf');
          await file.writeAsBytes(await widget.api.pdf(widget.boqId));
          await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
        } on ApiException catch (error) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
        }
      },
      icon: const Icon(Icons.share_outlined),
      label: const Text('Share PDF'),
    ),
  );

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
