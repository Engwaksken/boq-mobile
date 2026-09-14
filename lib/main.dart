import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart' hide Element;
import 'package:flutter/material.dart' hide Element;
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
      HardwarePricesPage(l10n: l10n, api: widget.api),
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
      (Icons.inventory_2_outlined, Icons.inventory_2, l10n.hardwarePrices),
      (Icons.document_scanner_outlined, Icons.document_scanner, l10n.importBoq),
      (Icons.person_outline, Icons.person, l10n.account),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(destinations[_selectedIndex].$3)),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF102A43)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              for (var index = 0; index < destinations.length; index++)
                ListTile(
                  selected: _selectedIndex == index,
                  leading: Icon(destinations[index].$2),
                  title: Text(destinations[index].$3),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.of(context).pop();
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(l10n.managePlan),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlansPage(api: widget.api),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        body: ProjectsPage(l10n: l10n, api: api),
                      ),
                    ),
                  ),
                  child: Text(l10n.viewAll),
                ),
              ],
            ),
            if (summary.recentProjects.isEmpty)
              const Center(child: Text('No recent projects yet')),
            ...summary.recentProjects.map(
              (project) => _ProjectTile(
                name: project.name,
                code: project.code,
                status: project.status == 'active'
                    ? l10n.projectStatusActive
                    : project.status == 'planning'
                    ? l10n.projectStatusPlanning
                    : l10n.draft,
                color: project.status == 'active'
                    ? const Color(0xFF047857)
                    : const Color(0xFFB45309),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProjectDetailPage(api: api, projectId: project.id),
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
      // Android content URIs are not always readable through file.path.
      // Request bytes so uploads work consistently on physical devices.
      withData: true,
    );
    if (selected == null || selected.files.isEmpty) return;
    final file = selected.files.single;
    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && path == null) return;
    setState(() => _uploading = true);
    try {
      if (bytes != null) {
        await widget.api.uploadBoqFromBytes(
          projectId: _projectId!,
          fileName: file.name,
          bytes: bytes,
        );
      } else if (path != null) {
        await widget.api.uploadBoq(projectId: _projectId!, filePath: path);
      }
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.l10n.imported}: ${file.name}')),
        );
    } on ApiException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed: check the file and try again'),
          ),
        );
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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        FutureBuilder<Map<String, dynamic>>(
          future: _subscription,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
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
                      const SizedBox(height: 8),
                      const Text('No active plan'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlansPage(api: widget.api))),
                          child: Text(widget.l10n.managePlan),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(sub['plan']?['name'] ?? 'No Active Plan'),
                      const SizedBox(height: 4),
                      Text(
                        sub['status'] ?? 'N/A',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(value: 0.58),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.l10n.aiCredits}: ${sub['plan']?['ai_credits'] ?? 'N/A'}',
                      ),
                      Text(
                        '${widget.l10n.ocrPages}: ${sub['plan']?['ocr_pages'] ?? 'N/A'}',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlansPage(api: widget.api),
                            ),
                          ),
                          child: Text(widget.l10n.managePlan),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
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
                    const DropdownMenuItem(
                      value: Locale('en'),
                      child: Text('English'),
                    ),
                    const DropdownMenuItem(
                      value: Locale('lg'),
                      child: Text('Luganda'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(widget.l10n.notifications),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications')),
                    );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(widget.l10n.profile),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfilePage(
                        api: widget.api,
                        locale: widget.locale,
                        onLocaleChanged: widget.onLocaleChanged,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: Text(widget.l10n.signOut),
        ),
      ],
    );
  }
}

class PlansPage extends StatelessWidget {
  const PlansPage({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.managePlan)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: api.plans(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(snapshot.error.toString()),
              ),
            );
          }
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final plans = snapshot.data!;
          if (plans.isEmpty)
            return const Center(
              child: Text('No plans are currently available.'),
            );
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text('${plan['name'] ?? 'Plan'}'),
                  subtitle: Text('${plan['description'] ?? ''}'),
                  trailing: Text(
                    '${plan['currency'] ?? ''} ${plan['price'] ?? ''}',
                  ),
                ),
              );
            },
          );
        },
      ),
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
                  builder: (_) =>
                      EditProjectPage(api: api, projectId: projectId),
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
                    Navigator.of(
                      context,
                    ).pop(true); // Return true to indicate deletion
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
                            try {
                              final items = await api.processBoq(boq.id);
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$items BOQ items created'),
                                  ),
                                );
                            } on ApiException catch (error) {
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error.message)),
                                );
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Project updated')));
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
                TextFormField(
                  controller: _code,
                  decoration: const InputDecoration(labelText: 'Project Code'),
                ),
                TextFormField(
                  controller: _client,
                  decoration: const InputDecoration(labelText: 'Client'),
                ),
                TextFormField(
                  controller: _contractor,
                  decoration: const InputDecoration(labelText: 'Contractor'),
                ),
                TextFormField(
                  controller: _consultant,
                  decoration: const InputDecoration(labelText: 'Consultant'),
                ),
                TextFormField(
                  controller: _quantitySurveyor,
                  decoration: const InputDecoration(
                    labelText: 'Quantity Surveyor',
                  ),
                ),
                TextFormField(
                  controller: _projectManager,
                  decoration: const InputDecoration(
                    labelText: 'Project Manager',
                  ),
                ),
                TextFormField(
                  controller: _siteEngineer,
                  decoration: const InputDecoration(labelText: 'Site Engineer'),
                ),
                TextFormField(
                  controller: _fundingOrganisation,
                  decoration: const InputDecoration(
                    labelText: 'Funding Organisation',
                  ),
                ),
                TextFormField(
                  controller: _country,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
                TextFormField(
                  controller: _district,
                  decoration: const InputDecoration(labelText: 'District'),
                ),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                TextFormField(
                  controller: _projectType,
                  decoration: const InputDecoration(labelText: 'Project Type'),
                ),
                TextFormField(
                  controller: _startDate,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _pickDate(_startDate),
                ),
                TextFormField(
                  controller: _expectedCompletionDate,
                  decoration: const InputDecoration(
                    labelText: 'Expected Completion Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _pickDate(_expectedCompletionDate),
                ),
                TextFormField(
                  controller: _contractValue,
                  decoration: const InputDecoration(
                    labelText: 'Contract Value',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                DropdownButtonFormField<String>(
                  value: _status,
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
    if (mounted) setState(() => _boqDetail = widget.api.boqDetail(widget.boqId));
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
    if (_location.text.trim().isEmpty) return;
    setState(() {
      _progress = 'Starting...';
      _history = [];
      _historyVisible = false;
    });
    try {
      var batch = await widget.api.startPricingBatch(
        widget.boqId,
        _location.text.trim(),
      );
      if (mounted) {
        setState(() => _progress = '0/${batch.total} fetched (${batch.status})');
      }
      while (batch.status == 'queued' || batch.status == 'running') {
        await Future<void>.delayed(const Duration(seconds: 2));
        batch = await widget.api.pricingBatch(batch.id);
        if (mounted)
          setState(
            () => _progress =
                '${batch.processed}/${batch.total} fetched (${batch.status})',
          );
      }
      if (mounted) {
        await _refreshItems();
        setState(() {
          _progress = 'Saved ${batch.processed} prices for ${_location.text.trim()}';
          _historyVisible = true;
        });
        await _loadHistory();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _progress = error.message);
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
              builder: (_) => BoqDetailPage(api: widget.api, boqId: widget.boqId, title: widget.title),
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
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
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
              onPressed: _price,
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
                      child: Text(
                        'Progress: $_progress',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
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
      onPressed: () async {
        try {
          final file = File(
            '${(await getTemporaryDirectory()).path}/boq-${widget.boqId}.pdf',
          );
          await file.writeAsBytes(await widget.api.pdf(widget.boqId));
          await SharePlus.instance.share(
            ShareParams(files: [XFile(file.path)]),
          );
        } on ApiException catch (error) {
          if (context.mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.message)));
        }
      },
      icon: const Icon(Icons.share_outlined),
      label: const Text('Share PDF'),
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

class HardwarePricesPage extends StatefulWidget {
  const HardwarePricesPage({super.key, required this.api, required this.l10n});
  final ApiClient api;
  final AppLocalizations l10n;

  @override
  State<HardwarePricesPage> createState() => _HardwarePricesPageState();
}

class _HardwarePricesPageState extends State<HardwarePricesPage> {
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  HardwarePricePaginated? _result;
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedSupplier;
  String? _selectedLocation;
  List<String> _categories = [];
  List<String> _suppliers = [];
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFilters() async {
    try {
      final cats = await widget.api.hardwarePriceCategories();
      if (mounted) {
        setState(() {
          _categories = cats.map((c) => c.name).toList();
        });
      }
    } catch (e) {
      // Ignore filter fetch errors
    }
  }

  Future<void> _fetch({bool loadMore = false}) async {
    if (_loading) return;
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
        category: _selectedCategory,
        supplier: _selectedSupplier,
        location: _selectedLocation,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        page: loadMore ? _page + 1 : 1,
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
            _page = 1;
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
        _buildFilters(),
        Expanded(child: _buildList()),
      ],
    ),
  );

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
      value: value,
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
                  'Updated: ${_formatDate(item.fetchedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (item.sourceReference.isNotEmpty)
                  Text(
                    item.sourceReference,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
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
                '${NumberFormat('#,##0').format(summary.lowest)}',
                summary.lowest <= item.price ? Colors.green : Colors.red,
              ),
              _stat(
                'Highest',
                '${NumberFormat('#,##0').format(summary.highest)}',
                summary.highest >= item.price ? Colors.red : Colors.green,
              ),
              _stat(
                'Average',
                '${NumberFormat('#,##0').format(summary.average)}',
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
        if (snapshot.hasError)
          return Center(child: Text(snapshot.error.toString()));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
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
      if (mounted)
        setState(() {
          _result = result;
          _loading = false;
        });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
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
                      '${NumberFormat('#,##0').format(item.priceHistory.lowest)}',
                ),
                _dataRow(
                  'Highest',
                  (item) =>
                      '${NumberFormat('#,##0').format(item.priceHistory.highest)}',
                ),
                _dataRow(
                  'Average',
                  (item) =>
                      '${NumberFormat('#,##0').format(item.priceHistory.average)}',
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
    try {
      final cats = await widget.api.hardwarePriceCategories();
      if (mounted)
        setState(() => _categories = cats.map((c) => c.name).toList());
    } catch (_) {}
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
      if (mounted)
        setState(() {
          _items = items;
          _loading = false;
        });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
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

class BoqDetailPage extends StatefulWidget {
  const BoqDetailPage({
    super.key,
    required this.api,
    required this.boqId,
    required this.title,
  });
  final ApiClient api;
  final int boqId;
  final String title;

  @override
  State<BoqDetailPage> createState() => _BoqDetailPageState();
}

class _BoqDetailPageState extends State<BoqDetailPage> {
  Future<BoqDetail>? _boqDetail;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _boqDetail = widget.api.boqDetail(widget.boqId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              try {
                final file = File(
                  '${(await getTemporaryDirectory()).path}/boq-${widget.boqId}.pdf',
                );
                await file.writeAsBytes(await widget.api.pdf(widget.boqId));
                await SharePlus.instance.share(
                  ShareParams(files: [XFile(file.path)]),
                );
              } on ApiException catch (error) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
              }
            },
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: FutureBuilder<BoqDetail>(
        future: _boqDetail,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text(snapshot.error.toString()));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final boq = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBoqHeader(boq, l10n),
              const SizedBox(height: 16),
              _buildSummaries(boq),
              const SizedBox(height: 16),
              if (boq.metadata.isNotEmpty) ...[
                _buildMetadataSection(boq),
                const SizedBox(height: 16),
              ],
              _buildHierarchy(boq),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBoqHeader(BoqDetail boq, AppLocalizations l10n) {
    final money = NumberFormat('#,##0.00');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    boq.name,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _statusChip(boq.status),
              ],
            ),
            const SizedBox(height: 8),
            if (boq.code.isNotEmpty)
              Text('Code: ${boq.code}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600])),
            if (boq.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(boq.description),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _infoChip(Icons.attach_money, '${boq.currency} ${boq.version}'),
                const SizedBox(width: 12),
                if (boq.metadata['detected_language'] != null)
                  _infoChip(
                    Icons.translate,
                    boq.metadata['detected_language'].toString().toUpperCase(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaries(BoqDetail boq) {
    final money = NumberFormat('#,##0.00');
    final grandSummary = boq.summaries.firstWhere(
      (s) => s.summaryType == 'grand',
      orElse: () => boq.summaries.first,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _summaryRow('Subtotal', '${boq.currency} ${money.format(grandSummary.subtotal)}'),
            _summaryRow('VAT (18%)', '${boq.currency} ${money.format(grandSummary.vat)}'),
            _summaryRow('Contingency (5%)',
                '${boq.currency} ${money.format(grandSummary.contingency)}'),
            const Divider(),
            _summaryRow('Grand Total', '${boq.currency} ${money.format(grandSummary.grandTotal)}',
                isTotal: true),
            if (boq.summaries.length > 1) ...[
              const SizedBox(height: 16),
              Text(
                'Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...boq.summaries
                  .where((s) => s.summaryType != 'grand')
                  .map((s) => _buildBreakdownItem(s, money)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(BoqCostSummary summary, NumberFormat money) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  summary.summaryType == 'facility'
                      ? Icons.apartment
                      : Icons.receipt_long,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.name ?? summary.summaryType.capitalize(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${summary.metadata?['item_count'] ?? 0} items',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniSummary('Subtotal', '${money.format(summary.subtotal)}'),
                _miniSummary('VAT', '${money.format(summary.vat)}'),
                _miniSummary('Total', '${money.format(summary.grandTotal)}',
                    isTotal: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BoqDetail boq) {
    final metadata = boq.metadata;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Metadata',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (metadata['import_sheets'] != null) ...[
              Text(
                'Sheets: ${(metadata['import_sheets'] as List).length}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ...(metadata['import_sheets'] as List).map<Widget>((sheet) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text(
                    '• ${sheet['sheet_name']} (${sheet['rows_processed']} rows)',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            if (metadata['translation_sources'] != null) ...[
              Text(
                'Translations: ${(metadata['translation_sources'] as Map).keys.join(', ')}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchy(BoqDetail boq) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BOQ Structure',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (boq.facilities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No hierarchy data available. Process the BOQ to generate structure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...boq.facilities
                  .map((facility) => _buildFacilityTile(facility, 0))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityTile(Facility facility, int depth) {
    return ExpansionTile(
      initiallyExpanded: depth == 0,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
        child: const Icon(Icons.apartment, color: Color(0xFF1D4ED8), size: 20),
      ),
      title: Text(
        _localizedName(facility.name, facility.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: facility.description != null
          ? Text(facility.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      children: [
        ...facility.bills
            .map((bill) => _buildBillTile(bill, depth + 1))
            .toList(),
        if (facility.summaries.isNotEmpty) ...[
          const Divider(),
          ...facility.summaries.map((s) => _buildSummaryTile(s)),
        ],
      ],
    );
  }

  Widget _buildBillTile(Bill bill, int depth) {
    return ExpansionTile(
      initiallyExpanded: depth <= 1,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF047857).withValues(alpha: 0.12),
        child: const Icon(Icons.receipt_long, color: Color(0xFF047857), size: 18),
      ),
      title: Text(
        _localizedName(bill.name, bill.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: bill.description != null
          ? Text(bill.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      children: [
        ...bill.elements
            .map((element) => _buildElementTile(element, depth + 1))
            .toList(),
        if (bill.summaries.isNotEmpty) ...[
          const Divider(),
          ...bill.summaries.map((s) => _buildSummaryTile(s)),
        ],
      ],
    );
  }

  Widget _buildElementTile(Element element, int depth) {
    return ExpansionTile(
      initiallyExpanded: depth <= 2,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFB45309).withValues(alpha: 0.12),
        child: const Icon(Icons.category, color: Color(0xFFB45309), size: 18),
      ),
      title: Text(
        _localizedName(element.name, element.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: element.description != null
          ? Text(element.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      children: [
        if (element.items.isNotEmpty)
          ...element.items.map((item) => _buildItemTile(item)).toList(),
        if (element.subElements.isNotEmpty)
          ...element.subElements
              .map((sub) => _buildSubElementTile(sub, depth + 1))
              .toList(),
      ],
    );
  }

  Widget _buildSubElementTile(SubElement subElement, int depth) {
    return ExpansionTile(
      initiallyExpanded: false,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
        child: const Icon(Icons.subdirectory_arrow_right, color: Color(0xFF7C3AED), size: 18),
      ),
      title: Text(
        _localizedName(subElement.name, subElement.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subElement.description != null
          ? Text(subElement.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      children: subElement.items.map((item) => _buildItemTile(item)).toList(),
    );
  }

  Widget _buildItemTile(BoqItemSummary item) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      leading: const Icon(Icons.format_list_numbered, size: 18, color: Colors.grey),
      title: Text(
        item.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: item.code.isNotEmpty ? Text('Code: ${item.code}') : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${item.quantity} ${item.unit}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            item.amount,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BoqItemDetailPage(
            api: widget.api,
            itemId: item.id,
            boqId: widget.boqId,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(BoqCostSummary summary) {
    final money = NumberFormat('#,##0.00');
    return ListTile(
      dense: true,
      leading: const Icon(Icons.summarize, size: 18, color: Colors.grey),
      title: Text(
        '${summary.summaryType.capitalize()}: ${summary.name ?? ''}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        '${money.format(summary.grandTotal)}',
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF047857)),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? const Color(0xFF047857) : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniSummary(String label, String value, {bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 14 : 12,
            color: isTotal ? const Color(0xFF047857) : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'uploaded':
        color = Colors.blue;
        break;
      case 'analysed':
        color = Colors.orange;
        break;
      case 'under_review':
        color = Colors.amber;
        break;
      case 'approved':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.capitalize(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  String _localizedName(String name, Map<String, String>? translations) {
    if (translations != null && _locale != null) {
      return translations[_locale!.languageCode] ?? name;
    }
    return name;
  }
}

class BoqItemDetailPage extends StatefulWidget {
  const BoqItemDetailPage({
    super.key,
    required this.api,
    required this.itemId,
    required this.boqId,
  });
  final ApiClient api;
  final int itemId;
  final int boqId;

  @override
  State<BoqItemDetailPage> createState() => _BoqItemDetailPageState();
}

class _BoqItemDetailPageState extends State<BoqItemDetailPage> {
  Future<BoqItemDetail>? _itemDetail;

  @override
  void initState() {
    super.initState();
    _itemDetail = widget.api.boqItemDetail(widget.itemId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('BOQ Item Details')),
      body: FutureBuilder<BoqItemDetail>(
        future: _itemDetail,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text(snapshot.error.toString()));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final item = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (item.code.isNotEmpty)
                        Text('Code: ${item.code}',
                            style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      _detailRow('Quantity', '${item.quantity} ${item.unit}'),
                      _detailRow('Amount', item.amount),
                      if (item.originalRate != null)
                        _detailRow('Original Rate', '${item.originalRate}'),
                      if (item.aiSuggestedRate != null)
                        _detailRow('AI Suggested Rate',
                            '${item.aiSuggestedRate} (confidence: ${item.aiConfidence?.toStringAsFixed(0)}%)'),
                      if (item.approvedRate != null)
                        _detailRow('Approved Rate', '${item.approvedRate}'),
                      _detailRow('Status', item.status!.capitalize()),
                      if (item.workCategory != null)
                        _detailRow('Work Category', item.workCategory!),
                      if (item.materialCategory != null)
                        _detailRow('Material Category', item.materialCategory!),
                      if (item.location != null)
                        _detailRow('Location', item.location!),
                      if (item.pricingSource != null)
                        _detailRow('Pricing Source', item.pricingSource!),
                      if (item.pricingDate != null)
                        _detailRow('Pricing Date', item.pricingDate!),
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Notes', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(item.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              if (item.translations.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Translations',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ...item.translations.map((t) => _translationTile(t)).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _translationTile(BoqItemTranslation t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Text(t.locale.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ),
        title: Text(t.translatedDescription),
        subtitle: Text(
          'Provider: ${t.provider ?? 'unknown'}  |  Confidence: ${t.confidence?.toStringAsFixed(0) ?? 'N/A'}%',
        ),
        trailing: Text(t.status!.capitalize(),
            style: TextStyle(
              color: t.status == 'accepted' ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
  }
}
