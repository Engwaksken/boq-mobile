import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

/// Shows a "No Internet Connection" screen whenever the device is offline and
/// puts the app back automatically once Wi-Fi or mobile data returns.
///
/// Connectivity is re-checked when the user comes back from device settings.
class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({
    super.key,
    required this.child,
    this.connectivity,
    this.hostLookup,
  });

  final Widget child;

  /// Injectable for tests.
  final Connectivity? connectivity;

  /// Confirms real internet access (Wi-Fi can be connected with no internet).
  final Future<bool> Function()? hostLookup;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate>
    with WidgetsBindingObserver {
  late final Connectivity _connectivity = widget.connectivity ?? Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _connectivity.onConnectivityChanged.listen((_) => _check());
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from Wi-Fi / mobile data settings.
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);

    var online = false;
    try {
      final results = await _connectivity.checkConnectivity();
      final hasNetwork = results.any(
        (result) => result != ConnectivityResult.none,
      );
      online = hasNetwork && await (widget.hostLookup ?? _canReachInternet)();
    } on Object {
      online = false;
    }

    if (!mounted) return;
    setState(() {
      _online = online;
      _checking = false;
    });
  }

  static Future<bool> _canReachInternet() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup(
        'boq.kemmytech.com',
      ).timeout(const Duration(seconds: 6));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on Object {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_online)
          Positioned.fill(
            child: NoInternetScreen(checking: _checking, onRetry: _check),
          ),
      ],
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({
    super.key,
    required this.onRetry,
    this.checking = false,
  });

  final VoidCallback onRetry;
  final bool checking;

  Future<void> _open(AppSettingsType type) async {
    try {
      // Android opens the exact screen; other platforms fall back to app settings.
      await AppSettings.openAppSettings(
        type: !kIsWeb && Platform.isAndroid ? type : AppSettingsType.settings,
      );
    } on Object {
      // Settings could not be opened: the user can still retry.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAndroid = !kIsWeb && Platform.isAndroid;
    // The gate sits above the navigator; fall back to English if it is ever
    // shown without app localizations.
    final l10n =
        AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('en'));
    const buttonSize = Size.fromHeight(AppSizes.buttonHeight);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.xxxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 44,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.connNoInternet,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.connConnectPrompt,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: buttonSize),
                    onPressed: checking ? null : onRetry,
                    icon: checking
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(checking ? l10n.connChecking : l10n.retry),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                    onPressed: () => _open(AppSettingsType.wifi),
                    icon: const Icon(Icons.wifi_rounded),
                    label: Text(l10n.connOpenWifi),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                    onPressed: () => _open(
                      isAndroid
                          ? AppSettingsType.dataRoaming
                          : AppSettingsType.settings,
                    ),
                    icon: const Icon(Icons.signal_cellular_alt_rounded),
                    label: Text(
                      isAndroid
                          ? l10n.connOpenMobileData
                          : l10n.connOpenNetwork,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Flexible(
                        child: Text(
                          l10n.connAutoContinue,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
