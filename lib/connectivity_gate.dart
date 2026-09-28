import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    if (_checking) return;
    setState(() => _checking = true);

    var online = false;
    try {
      final results = await _connectivity.checkConnectivity();
      final hasNetwork =
          results.any((result) => result != ConnectivityResult.none);
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
      final result = await InternetAddress.lookup('boq.kemmytech.com')
          .timeout(const Duration(seconds: 6));
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
    final isAndroid = !kIsWeb && Platform.isAndroid;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: .1),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Internet Connection',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please connect to Wi-Fi or mobile data to continue.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: checking ? null : onRetry,
                    icon: checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(checking ? 'Checking...' : 'Retry'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _open(AppSettingsType.wifi),
                    icon: const Icon(Icons.wifi),
                    label: const Text('Open Wi-Fi Settings'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                      isAndroid ? AppSettingsType.dataRoaming : AppSettingsType.settings,
                    ),
                    icon: const Icon(Icons.signal_cellular_alt),
                    label: Text(
                      isAndroid ? 'Open Mobile Data Settings' : 'Open Network Settings',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The app continues automatically once you are back online.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
