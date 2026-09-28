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
import 'package:intl/intl.dart';
import 'package:boq_mobile/l10n/app_localizations.dart';

import 'api_client.dart';
import 'app_errors.dart';
import 'company_profile_page.dart';
import 'connectivity_gate.dart';
import 'boq_share_actions.dart';
import 'theme/app_theme.dart';
import 'widgets/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'screens/auth_screens.dart';
part 'screens/home_shell.dart';
part 'screens/dashboard_page.dart';
part 'screens/notifications_page.dart';
part 'screens/projects_screens.dart';
part 'screens/import_page.dart';
part 'screens/account_screens.dart';
part 'screens/project_detail_screens.dart';
part 'screens/hardware_screens.dart';
part 'screens/boq_screens.dart';
part 'screens/proxy_subscriptions_page.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Offline screen above every page, recovering automatically when back online.
      builder: (context, child) =>
          ConnectivityGate(child: child ?? const SizedBox.shrink()),
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
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
  StreamSubscription<String>? _expiredSubscription;

  @override
  void initState() {
    super.initState();
    _session = widget.api.hasSession();
    _expiredSubscription = widget.api.sessionExpired.listen(_onSessionExpired);
  }

  @override
  void dispose() {
    _expiredSubscription?.cancel();
    super.dispose();
  }

  /// The server rejected the token: close any open screens and show sign-in.
  void _onSessionExpired(String message) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    _refresh();
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
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandMark(size: 72),
                  SizedBox(height: AppSpacing.xxl),
                  SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: ErrorState(error: snapshot.error, onRetry: _refresh),
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
