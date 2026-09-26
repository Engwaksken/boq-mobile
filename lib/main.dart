import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart' hide Element;
import 'package:flutter/material.dart' hide Element;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:boq_mobile/l10n/app_localizations.dart';

import 'api_client.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling biometric authentication operations.
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Checks if biometric hardware is available on the device.
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Gets the list of available biometric types on the device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }

  /// Authenticates the user using biometric authentication.
  /// Returns true if authentication succeeds, false otherwise.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks if the user has enabled biometric login.
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Enables or disables biometric login for the user.
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
    } on PlatformException catch (_) {
      // Ignore storage errors
    }
  }

  /// Gets a localized name for the given biometric type.
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }
}

void main() {
  runApp(const BoqApp());
}

Future<T?> _loadOrNull<T>(Future<T> Function() load) async {
  try {
    return await load();
  } on Object catch (error) {
    if (error is ApiException ||
        error is http.ClientException ||
        error is IOException) {
      return null;
    }
    rethrow;
  }
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

  late final BiometricService _biometricService;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _biometricService = BiometricService();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometric() async {
    final l10n = AppLocalizations.of(context)!;
    final success = await _biometricService.authenticate(
      localizedReason: l10n.useBiometricToLogin,
    );
    if (success && mounted) {
      widget.onSignedIn();
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.biometricError)));
    }
  }

  Future<void> _promptEnableBiometric() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.biometricPromptTitle),
        content: Text(l10n.biometricPromptMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.biometricPromptCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.biometricPromptEnable),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _biometricService.setBiometricEnabled(true);
      if (mounted) {
        setState(() => _biometricEnabled = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.biometricEnabled)));
      }
    }
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

      // Check if biometric is available but not enabled, prompt to enable
      if (_biometricAvailable && !_biometricEnabled) {
        await _promptEnableBiometric();
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
                        hintText: l10n.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF102A43),
                            width: 1.5,
                          ),
                        ),
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
                        hintText: l10n.password,
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF102A43),
                            width: 1.5,
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
                    if (_biometricEnabled && _biometricAvailable) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : _authenticateWithBiometric,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(l10n.useBiometricToLogin),
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
              value: _status,
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
  XFile? _pickedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedImage = picked);
      _uploadPickedImage();
    }
  }

  Future<void> _uploadPickedImage() async {
    if (_projectId == null) return;
    final bytes = await _pickedImage!.readAsBytes();
    setState(() => _uploading = true);
    try {
      final boq = await widget.api.uploadBoqFromBytes(
        projectId: _projectId!,
        fileName: _pickedImage!.name,
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.l10n.imported}: ${_pickedImage!.name}'),
        ),
      );
      await _reviewUploadedBoq(boq);
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
      if (mounted) setState(() => _pickedImage = null);
    }
  }

  Future<void> _upload() async {
    if (_projectId == null) return;
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (selected == null || selected.files.isEmpty) return;
    final file = selected.files.single;
    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && path == null) return;
    setState(() => _uploading = true);
    try {
      final boq = bytes != null
          ? await widget.api.uploadBoqFromBytes(
              projectId: _projectId!,
              fileName: file.name,
              bytes: bytes,
            )
          : await widget.api.uploadBoq(
              projectId: _projectId!,
              filePath: path!,
              name: file.name,
            );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.l10n.imported}: ${file.name}')),
      );
      await _reviewUploadedBoq(boq);
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

  /// Auto-processes the uploaded BOQ ("Generate BOQ") then opens its
  /// review page so the user can verify items and fetch prices. Falls back
  /// to the project page when processing fails so nothing is lost.
  Future<void> _reviewUploadedBoq(BoqSummary boq) async {
    if (!mounted) return;
    try {
      final imported = await widget.api.processBoq(boq.id);
      if (!mounted) return;
      if (imported > 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Imported $imported BOQ items')));
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BoqItemsPage(api: widget.api, boqId: boq.id, title: boq.name),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${error.message} (open the project to retry)')),
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ProjectDetailPage(api: widget.api, projectId: _projectId!),
        ),
      );
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
            onPressed: _projectId == null || _uploading ? null : _pickImage,
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

  void _reloadSubscription() {
    if (!mounted) return;
    setState(() {
      _subscription = widget.api.currentSubscription();
    });
  }

  double? _subscriptionProgress(Map<String, dynamic> subscription) {
    final start = DateTime.tryParse('${subscription['start_date'] ?? ''}');
    final end = DateTime.tryParse('${subscription['end_date'] ?? ''}');
    if (start == null || end == null || !end.isAfter(start)) return null;

    final total = end.difference(start).inSeconds;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0).toDouble();
  }

  int? _daysRemaining(Map<String, dynamic> subscription) {
    final end = DateTime.tryParse('${subscription['end_date'] ?? ''}');
    if (end == null) return null;
    final remaining = end.difference(DateTime.now());
    if (remaining.isNegative) return 0;
    return (remaining.inHours / 24).ceil();
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text('No active plan'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlansPage(
                                api: widget.api,
                                onSubscriptionCreated: _reloadSubscription,
                              ),
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
            if (snapshot.hasData) {
              final sub = snapshot.data!;
              final progress = _subscriptionProgress(sub);
              final daysRemaining = _daysRemaining(sub);
              final status = '${sub['status'] ?? 'N/A'}';
              final isTrial = status.toLowerCase() == 'trial';
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
                      Row(
                        children: [
                          Chip(
                            avatar: Icon(
                              isTrial
                                  ? Icons.hourglass_top
                                  : Icons.verified_outlined,
                              size: 16,
                            ),
                            label: Text(
                              isTrial ? '7-day trial' : status.toUpperCase(),
                            ),
                          ),
                          if (daysRemaining != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                daysRemaining == 0
                                    ? 'Expires today'
                                    : '$daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining',
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: progress),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        '${widget.l10n.aiCredits}: ${sub['plan']?['max_ai_credits'] ?? 'N/A'}',
                      ),
                      Text(
                        '${widget.l10n.ocrPages}: ${sub['plan']?['max_ocr_pages'] ?? 'N/A'}',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlansPage(
                                api: widget.api,
                                onSubscriptionCreated: _reloadSubscription,
                              ),
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

class PlansPage extends StatefulWidget {
  const PlansPage({super.key, required this.api, this.onSubscriptionCreated});

  final ApiClient api;
  final VoidCallback? onSubscriptionCreated;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late Future<List<Map<String, dynamic>>> _plans;
  int? _submittingPlanId;

  @override
  void initState() {
    super.initState();
    _plans = widget.api.plans();
  }

  Future<void> _selectPlan(Map<String, dynamic> plan) async {
    final id = int.tryParse('${plan['id'] ?? ''}');
    if (id == null || _submittingPlanId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select subscription plan'),
        content: Text(
          'Create a pending subscription for ${plan['name'] ?? 'this plan'}? '
          'Your plan becomes active only after payment is confirmed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submittingPlanId = id);
    try {
      final subscription = await widget.api.createSubscription(id);
      if (!mounted) return;
      widget.onSubscriptionCreated?.call();
      final status = '${subscription['status'] ?? 'pending'}';

      if (status == 'pending') {
        final activated = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) =>
                PaymentPage(api: widget.api, subscription: subscription),
          ),
        );
        if (activated == true) {
          widget.onSubscriptionCreated?.call();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment confirmed. Your subscription is now active.',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription updated successfully.')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submittingPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.managePlan)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _plans,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    const Text('Unable to load subscription plans.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _plans = widget.api.plans()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data!;
          if (plans.isEmpty) {
            return const Center(
              child: Text('No plans are currently available.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final id = int.tryParse('${plan['id'] ?? ''}');
              final busy = id != null && _submittingPlanId == id;
              final features =
                  (plan['included_features'] as List<dynamic>? ?? const [])
                      .map((item) => '$item')
                      .where((item) => item.trim().isNotEmpty)
                      .take(4)
                      .toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${plan['name'] ?? 'Plan'}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${plan['currency'] ?? 'UGX'} ${plan['price'] ?? '0'}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      if ('${plan['description'] ?? ''}'.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('${plan['description']}'),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (plan['trial_days'] != null)
                            Chip(
                              label: Text('${plan['trial_days']} day trial'),
                            ),
                          if (plan['max_projects'] != null)
                            Chip(
                              label: Text('${plan['max_projects']} projects'),
                            ),
                          if (plan['max_boqs'] != null)
                            Chip(label: Text('${plan['max_boqs']} BOQs')),
                          if (plan['max_ai_credits'] != null)
                            Chip(
                              label: Text(
                                '${plan['max_ai_credits']} AI credits',
                              ),
                            ),
                        ],
                      ),
                      if (features.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...features.map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(feature)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: busy ? null : () => _selectPlan(plan),
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Select plan'),
                        ),
                      ),
                    ],
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

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.api, required this.subscription});

  final ApiClient api;
  final Map<String, dynamic> subscription;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late Future<List<Map<String, dynamic>>> _gateways;
  String? _selectedGatewayCode;
  String? _selectedMethod;
  Map<String, dynamic>? _paymentData;
  bool _initiating = false;
  bool _verifying = false;
  bool _successHandled = false;
  String? _idempotencyKey;
  Timer? _statusTimer;
  int _pollCount = 0;
  Map<String, dynamic>? _receipt;
  final TextEditingController _phoneNumber = TextEditingController();

  @override
  void initState() {
    super.initState();
    _gateways = widget.api.paymentGateways();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _phoneNumber.dispose();
    super.dispose();
  }

  int? get _subscriptionId =>
      int.tryParse('${widget.subscription['id'] ?? ''}');

  Map<String, dynamic>? get _transaction =>
      _paymentData?['transaction'] as Map<String, dynamic>?;

  Map<String, dynamic>? get _gatewayResult =>
      _paymentData?['gateway'] as Map<String, dynamic>?;

  Future<void> _initiate(Map<String, dynamic> gateway) async {
    final subscriptionId = _subscriptionId;
    final code = '${gateway['code'] ?? ''}'.trim();
    if (subscriptionId == null || code.isEmpty || _initiating) return;

    setState(() {
      _initiating = true;
      _selectedGatewayCode = code;
    });
    try {
      _idempotencyKey ??=
          'mobile-$subscriptionId-$code-${DateTime.now().microsecondsSinceEpoch}';
      final data = await widget.api.initiatePayment(
        subscriptionId: subscriptionId,
        gatewayCode: code,
        idempotencyKey: _idempotencyKey!,
        paymentMethod: _selectedMethod,
        phoneNumber: _phoneNumber.text,
        network: _selectedMethod,
      );
      if (!mounted) return;
      setState(() => _paymentData = data);
      _startStatusPolling();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment started. Follow the instructions below, then verify the payment.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _initiating = false);
    }
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _pollCount = 0;
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollCount++;
      if (_pollCount > 24 || !mounted) {
        timer.cancel();
        return;
      }
      await _refreshTransaction(silent: true);
    });
  }

  Future<void> _loadReceipt(int transactionId) async {
    try {
      final receipt = await widget.api.paymentReceipt(transactionId);
      if (!mounted) return;
      setState(() => _receipt = receipt);
    } on ApiException {
      return;
    }
  }

  Future<void> _handleSuccessfulPayment(
    Map<String, dynamic> transaction,
  ) async {
    if (_successHandled || !mounted) return;
    _successHandled = true;
    _statusTimer?.cancel();
    final transactionId = int.tryParse('${transaction['id'] ?? ''}');
    if (transactionId != null) {
      await _loadReceipt(transactionId);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment confirmed'),
        content: const Text(
          'Your subscription has been activated successfully.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _verify() async {
    final transaction = _transaction;
    final transactionId = int.tryParse('${transaction?['id'] ?? ''}');
    if (transactionId == null || _verifying) return;

    setState(() => _verifying = true);
    try {
      final verified = await widget.api.verifyPayment(transactionId);
      if (!mounted) return;
      setState(() {
        _paymentData = {...?_paymentData, 'transaction': verified};
      });
      final status = '${verified['status'] ?? ''}'.toLowerCase();
      if (status == 'successful') {
        await _handleSuccessfulPayment(verified);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'under_review'
                  ? 'Payment submitted for review. Your plan will activate after confirmation.'
                  : 'Payment status: ${status.isEmpty ? 'pending' : status}.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _refreshTransaction({bool silent = false}) async {
    final transactionId = int.tryParse('${_transaction?['id'] ?? ''}');
    if (transactionId == null) return;
    try {
      final refreshed = await widget.api.transaction(transactionId);
      if (!mounted) return;
      setState(() {
        _paymentData = {...?_paymentData, 'transaction': refreshed};
        final invoice = refreshed['invoice'];
        if (invoice is Map<String, dynamic>) {
          _receipt = invoice;
        }
      });
      final status = '${refreshed['status'] ?? ''}'.toLowerCase();
      if (status == 'successful') {
        await _handleSuccessfulPayment(refreshed);
      }
    } on ApiException catch (e) {
      if (!mounted || silent) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _receiptCard() {
    final receipt = _receipt;
    if (receipt == null || receipt.isEmpty) return const SizedBox.shrink();
    final currency = '${receipt['currency'] ?? ''}';
    final total = receipt['total_amount'] ?? receipt['amount'] ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined),
                const SizedBox(width: 8),
                Text(
                  'Payment receipt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText('Invoice: ${receipt['invoice_number'] ?? ''}'),
            SelectableText(
              'Reference: ${receipt['transaction_reference'] ?? _transaction?['reference'] ?? ''}',
            ),
            Text('Amount: $currency $total'),
            if (receipt['payment_date'] != null)
              Text('Paid: ${receipt['payment_date']}'),
          ],
        ),
      ),
    );
  }

  Widget _gatewayInstructions() {
    final gateway = _gatewayResult;
    if (gateway == null || gateway.isEmpty) return const SizedBox.shrink();
    final rows = <Widget>[];

    void addRow(String label, dynamic value) {
      if (value == null || '$value'.trim().isEmpty) return;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 105,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: SelectableText('$value')),
            ],
          ),
        ),
      );
    }

    addRow('Reference', gateway['transaction_reference']);
    addRow('Provider', gateway['provider']);
    addRow('Phone', gateway['phone']);
    addRow('Mode', gateway['mode']);
    addRow('Instructions', gateway['instructions']);

    final checkoutUrl = '${gateway['checkout_url'] ?? ''}'.trim();
    if (checkoutUrl.isNotEmpty) {
      rows.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.link),
          title: const Text('Checkout URL'),
          subtitle: SelectableText(checkoutUrl),
          trailing: Wrap(
            spacing: 2,
            children: [
              IconButton(
                tooltip: 'Open secure checkout',
                onPressed: () async {
                  final uri = Uri.tryParse(checkoutUrl);
                  if (uri == null ||
                      !await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to open checkout. You can copy the link instead.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
              ),
              IconButton(
                tooltip: 'Copy',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: checkoutUrl));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checkout URL copied.')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
        ),
      );
    }

    final bankDetails = gateway['bank_details'];
    if (bankDetails is Map) {
      for (final entry in bankDetails.entries) {
        addRow('${entry.key}', entry.value);
      }
    } else if (bankDetails != null) {
      addRow('Bank details', bankDetails);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment instructions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan =
        widget.subscription['plan'] as Map<String, dynamic>? ?? const {};
    final transaction = _transaction;
    final status = '${transaction?['status'] ?? 'not started'}';

    return Scaffold(
      appBar: AppBar(title: const Text('Complete payment')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gateways,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 44),
                    const SizedBox(height: 12),
                    const Text('Unable to load payment methods.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(
                        () => _gateways = widget.api.paymentGateways(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final gateways = snapshot.data!;
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
                        '${plan['name'] ?? 'Subscription plan'}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${plan['currency'] ?? 'UGX'} ${plan['price'] ?? '0'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Subscription status: ${widget.subscription['status'] ?? 'pending'}',
                      ),
                      if (transaction != null) ...[
                        const Divider(height: 24),
                        Text(
                          'Transaction: ${transaction['reference'] ?? transaction['id'] ?? ''}',
                        ),
                        Text('Payment status: $status'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (gateways.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No payment methods are currently enabled. Please contact the administrator.',
                    ),
                  ),
                )
              else ...[
                Text(
                  'Choose payment method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...gateways.map((gateway) {
                  final code = '${gateway['code'] ?? ''}';
                  final methods =
                      (gateway['supported_methods'] as List<dynamic>? ??
                              const [])
                          .map((e) => '$e')
                          .where((e) => e.trim().isNotEmpty)
                          .toList();
                  final selected = _selectedGatewayCode == code;
                  return Card(
                    child: RadioListTile<String>(
                      value: code,
                      groupValue: _selectedGatewayCode,
                      onChanged: _paymentData != null
                          ? null
                          : (value) => setState(() {
                              _selectedGatewayCode = value;
                              _selectedMethod = methods.isNotEmpty
                                  ? methods.first
                                  : null;
                              _idempotencyKey = null;
                            }),
                      title: Text('${gateway['name'] ?? code}'),
                      subtitle: Text(
                        '${gateway['description'] ?? gateway['driver'] ?? ''}'
                        '${gateway['is_aggregator'] == true ? ' • Aggregator' : ''}'
                        '${gateway['is_test_mode'] == true ? ' • Test mode' : ''}',
                      ),
                      secondary: selected
                          ? const Icon(Icons.check_circle)
                          : const Icon(Icons.payments_outlined),
                    ),
                  );
                }),
                if (_selectedGatewayCode != null && _paymentData == null) ...[
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final selected = gateways.firstWhere(
                        (g) => '${g['code'] ?? ''}' == _selectedGatewayCode,
                        orElse: () => const <String, dynamic>{},
                      );
                      final methods =
                          (selected['supported_methods'] as List<dynamic>? ??
                                  const [])
                              .map((e) => '$e')
                              .where((e) => e.trim().isNotEmpty)
                              .toList();
                      final driver = '${selected['driver'] ?? ''}';
                      final isAggregator = selected['is_aggregator'] == true;
                      final effectiveMethod = methods.contains(_selectedMethod)
                          ? _selectedMethod
                          : (methods.isNotEmpty ? methods.first : null);
                      final aggregatorMobile =
                          isAggregator &&
                          ![
                            'card',
                            'visa',
                            'mastercard',
                          ].contains('${effectiveMethod ?? ''}'.toLowerCase());
                      final needsPhone =
                          driver == 'mtn_momo' ||
                          driver == 'airtel_money' ||
                          aggregatorMobile;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (needsPhone) ...[
                            TextField(
                              controller: _phoneNumber,
                              keyboardType: TextInputType.phone,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: driver == 'mtn_momo'
                                    ? 'MTN MoMo number'
                                    : driver == 'airtel_money'
                                    ? 'Airtel Money number'
                                    : 'Mobile money number',
                                hintText: 'e.g. 0772 123 456',
                                prefixIcon: const Icon(Icons.phone_android),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (methods.length > 1)
                            DropdownButtonFormField<String>(
                              value: methods.contains(_selectedMethod)
                                  ? _selectedMethod
                                  : methods.first,
                              decoration: const InputDecoration(
                                labelText: 'Payment option',
                              ),
                              items: methods
                                  .map(
                                    (method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(method),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedMethod = value),
                            ),
                          if (methods.length > 1) const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed:
                                _initiating ||
                                    (needsPhone &&
                                        _phoneNumber.text.trim().isEmpty)
                                ? null
                                : () => _initiate(selected),
                            icon: _initiating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_outline),
                            label: Text(
                              _initiating
                                  ? 'Starting payment…'
                                  : 'Continue to payment',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
              if (_paymentData != null) ...[
                const SizedBox(height: 12),
                _gatewayInstructions(),
                if (_receipt != null) ...[
                  const SizedBox(height: 12),
                  _receiptCard(),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _refreshTransaction,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh status'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _verifying ? null : _verify,
                        icon: _verifying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.verified_outlined),
                        label: Text(
                          _verifying ? 'Checking…' : 'Verify payment',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your plan is activated only after the server confirms a successful payment. Closing this screen does not delete the pending subscription.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
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

  late final BiometricService _biometricService;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _biometricService = BiometricService();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    final biometrics = await _biometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _availableBiometrics = biometrics;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _biometricService.setBiometricEnabled(value);
      if (mounted) {
        setState(() => _biometricEnabled = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? l10n.biometricEnabled : l10n.biometricDisabled,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _biometricEnabled = !value);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.biometricError)));
      }
    }
  }

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
                // Biometric section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.enableBiometricLogin,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _biometricAvailable
                              ? '${l10n.biometricAvailable} - ${l10n.biometricTypes}${_availableBiometrics.map((t) => _biometricService.getBiometricTypeName(t)).join(', ')}'
                              : l10n.biometricNotAvailable,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _biometricAvailable
                                    ? null
                                    : Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: Text(l10n.enableBiometricLogin),
                          subtitle: Text(l10n.biometricLoginDescription),
                          value: _biometricEnabled,
                          onChanged: _biometricAvailable
                              ? _toggleBiometric
                              : null,
                          secondary: Icon(
                            _biometricAvailable
                                ? Icons.fingerprint
                                : Icons.fingerprint_outlined,
                            color: _biometricAvailable
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
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
    if (mounted)
      setState(() => _boqDetail = widget.api.boqDetail(widget.boqId));
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
  List<String> _categories = [];
  List<String> _suppliers = [];
  List<String> _locations = [];
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
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.message)));
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _statusChip(boq.status),
              ],
            ),
            const SizedBox(height: 8),
            if (boq.code.isNotEmpty)
              Text(
                'Code: ${boq.code}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _summaryRow(
              'Subtotal',
              '${boq.currency} ${money.format(grandSummary.subtotal)}',
            ),
            _summaryRow(
              'VAT (18%)',
              '${boq.currency} ${money.format(grandSummary.vat)}',
            ),
            _summaryRow(
              'Contingency (5%)',
              '${boq.currency} ${money.format(grandSummary.contingency)}',
            ),
            const Divider(),
            _summaryRow(
              'Grand Total',
              '${boq.currency} ${money.format(grandSummary.grandTotal)}',
              isTotal: true,
            ),
            if (boq.summaries.length > 1) ...[
              const SizedBox(height: 16),
              Text(
                'Breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                _miniSummary(
                  'Total',
                  '${money.format(summary.grandTotal)}',
                  isTotal: true,
                ),
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
          ? Text(
              facility.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
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
        child: const Icon(
          Icons.receipt_long,
          color: Color(0xFF047857),
          size: 18,
        ),
      ),
      title: Text(
        _localizedName(bill.name, bill.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: bill.description != null
          ? Text(
              bill.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
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
          ? Text(
              element.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
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
        child: const Icon(
          Icons.subdirectory_arrow_right,
          color: Color(0xFF7C3AED),
          size: 18,
        ),
      ),
      title: Text(
        _localizedName(subElement.name, subElement.nameTranslations),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subElement.description != null
          ? Text(
              subElement.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      children: subElement.items.map((item) => _buildItemTile(item)).toList(),
    );
  }

  Widget _buildItemTile(BoqItemSummary item) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      leading: const Icon(
        Icons.format_list_numbered,
        size: 18,
        color: Colors.grey,
      ),
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
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF047857),
        ),
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
                        Text(
                          'Code: ${item.code}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 16),
                      _detailRow('Quantity', '${item.quantity} ${item.unit}'),
                      _detailRow('Amount', item.amount),
                      if (item.originalRate != null)
                        _detailRow('Original Rate', '${item.originalRate}'),
                      if (item.aiSuggestedRate != null)
                        _detailRow(
                          'AI Suggested Rate',
                          '${item.aiSuggestedRate} (confidence: ${item.aiConfidence?.toStringAsFixed(0)}%)',
                        ),
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
                        Text(
                          'Notes',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
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
                        ...item.translations
                            .map((t) => _translationTile(t))
                            .toList(),
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
          child: Text(
            t.locale.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(t.translatedDescription),
        subtitle: Text(
          'Provider: ${t.provider ?? 'unknown'}  |  Confidence: ${t.confidence?.toStringAsFixed(0) ?? 'N/A'}%',
        ),
        trailing: Text(
          t.status!.capitalize(),
          style: TextStyle(
            color: t.status == 'accepted' ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
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

class ProxySubscriptionListPage extends StatefulWidget {
  const ProxySubscriptionListPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<ProxySubscriptionListPage> createState() =>
      _ProxySubscriptionListPageState();
}

class _ProxySubscriptionListPageState extends State<ProxySubscriptionListPage> {
  late Future<List<ProxySubscription>> _subscriptions;
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  bool _isAdmin = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _error = null;
    });
    try {
      final subscriptions = await widget.api.listProxySubscriptions();
      if (mounted) {
        setState(() {
          _subscriptions = Future.value(subscriptions);
          _isAdmin = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isAdmin =
              e.message.toLowerCase().contains('unauthorized') ||
              e.message.toLowerCase().contains('forbidden') ||
              e.message.toLowerCase().contains('admin');
        });
      }
    }
  }

  List<ProxySubscription> _filterSubscriptions(
    List<ProxySubscription> subscriptions,
  ) {
    final query = _searchController.text.toLowerCase().trim();
    return subscriptions.where((sub) {
      final matchesSearch =
          query.isEmpty ||
          sub.beneficiaryName.toLowerCase().contains(query) ||
          sub.beneficiaryEmail.toLowerCase().contains(query) ||
          sub.planName.toLowerCase().contains(query) ||
          sub.payerName.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'all' || sub.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF047857);
      case 'pending':
        return const Color(0xFFB45309);
      case 'cancelled':
        return const Color(0xFFBE123C);
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.proxySubscriptions)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  l10n.adminAccessRequired,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.adminAccessDescription,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.proxySubscriptions),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscriptions,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(l10n),
          Expanded(
            child: FutureBuilder<List<ProxySubscription>>(
              future: _subscriptions,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(snapshot.error.toString()),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loadSubscriptions,
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filtered = _filterSubscriptions(snapshot.data!);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noProxySubscriptions),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noProxySubscriptionsDescription,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadSubscriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final sub = filtered[index];
                      return _ProxySubscriptionCard(
                        subscription: sub,
                        onTap: () => _showDetails(sub),
                        statusColor: _statusColor(sub.status),
                        formatDate: _formatDate,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Container(
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
              labelText: l10n.search,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: InputDecoration(
              labelText: l10n.status,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            items: [
              DropdownMenuItem(value: 'all', child: Text(l10n.allStatuses)),
              DropdownMenuItem(value: 'active', child: Text(l10n.statusActive)),
              DropdownMenuItem(
                value: 'pending',
                child: Text(l10n.statusPending),
              ),
              DropdownMenuItem(
                value: 'cancelled',
                child: Text(l10n.statusCancelled),
              ),
              DropdownMenuItem(
                value: 'expired',
                child: Text(l10n.statusExpired),
              ),
            ],
            onChanged: (value) =>
                setState(() => _statusFilter = value ?? 'all'),
          ),
        ],
      ),
    );
  }

  void _showDetails(ProxySubscription sub) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.proxySubscriptionDetails,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _detailRow(l10n.beneficiary, sub.beneficiaryName),
              _detailRow(l10n.beneficiaryEmail, sub.beneficiaryEmail),
              _detailRow(l10n.plan, sub.planName),
              _detailRow(l10n.payer, sub.payerName),
              _detailRow(l10n.status, sub.status.capitalize()),
              _detailRow(l10n.paymentStatus, sub.paymentStatus.capitalize()),
              _detailRow(l10n.startDate, _formatDate(sub.startDate)),
              _detailRow(l10n.endDate, _formatDate(sub.endDate)),
              _detailRow(l10n.createdAt, _formatDate(sub.createdAt)),
              if (sub.transactionId.isNotEmpty)
                _detailRow(l10n.transactionId, sub.transactionId),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProxySubscriptionCard extends StatelessWidget {
  const _ProxySubscriptionCard({
    required this.subscription,
    required this.onTap,
    required this.statusColor,
    required this.formatDate,
  });

  final ProxySubscription subscription;
  final VoidCallback onTap;
  final Color statusColor;
  final String Function(String) formatDate;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      subscription.beneficiaryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subscription.status.capitalize(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subscription.beneficiaryEmail,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(subscription.planName),
                    backgroundColor: Colors.blue[50],
                  ),
                  Chip(
                    label: Text(subscription.payerName),
                    backgroundColor: Colors.green[50],
                  ),
                  Chip(
                    label: Text('${subscription.paymentStatus.capitalize()}'),
                    backgroundColor: subscription.paymentStatus == 'paid'
                        ? Colors.green[50]
                        : Colors.orange[50],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${formatDate(subscription.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (subscription.transactionId.isNotEmpty)
                    Text(
                      subscription.transactionId,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
