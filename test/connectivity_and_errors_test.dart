import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:boq_mobile/api_client.dart';
import 'package:boq_mobile/app_errors.dart';
import 'package:boq_mobile/connectivity_gate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeConnectivity implements Connectivity {
  List<ConnectivityResult> current = [ConnectivityResult.none];
  final _changes = StreamController<List<ConnectivityResult>>.broadcast();

  void set(List<ConnectivityResult> results) {
    current = results;
    _changes.add(results);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _changes.stream;
}

class _MemoryStorage extends FlutterSecureStorage {
  final values = <String, String>{'auth_token': 'token'};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values.remove(key);
}

void main() {
  testWidgets('shows the offline screen and recovers when back online', (tester) async {
    final connectivity = _FakeConnectivity();
    var internet = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ConnectivityGate(
          connectivity: connectivity,
          hostLookup: () async => internet,
          child: const Text('App content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Internet Connection'), findsOneWidget);
    expect(find.text('Please connect to Wi-Fi or mobile data to continue.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Open Wi-Fi Settings'), findsOneWidget);

    // Connectivity returns: the app continues automatically.
    internet = true;
    connectivity.set([ConnectivityResult.wifi]);
    await tester.pumpAndSettle();

    expect(find.text('No Internet Connection'), findsNothing);
    expect(find.text('App content'), findsOneWidget);
  });

  testWidgets('Wi-Fi without internet still counts as offline until Retry succeeds', (tester) async {
    final connectivity = _FakeConnectivity()..current = [ConnectivityResult.wifi];
    var internet = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ConnectivityGate(
          connectivity: connectivity,
          hostLookup: () async => internet,
          child: const Text('App content'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No Internet Connection'), findsOneWidget);

    internet = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('No Internet Connection'), findsNothing);
  });

  test('friendly messages never expose raw errors', () {
    expect(friendlyError(const SocketException('Failed host lookup: boq.kemmytech.com')), AppErrorMessages.noInternet);
    expect(friendlyError(TimeoutException('x')), AppErrorMessages.timeout);
    expect(friendlyError(StateError('Bad state: null check operator')), AppErrorMessages.generic);
    expect(friendlyError(const ApiException('Please add a project location.')), 'Please add a project location.');
    expect(friendlyStatusMessage(403), AppErrorMessages.forbidden);
    expect(friendlyStatusMessage(500), AppErrorMessages.server);
  });

  test('server errors and HTML error pages become friendly messages', () async {
    Future<ApiClient> clientReturning(int status, String body, {String type = 'application/json'}) async => ApiClient(
      httpClient: MockClient((_) async => http.Response(body, status, headers: {'content-type': type})),
      storage: _MemoryStorage(),
    );

    final sqlLeak = await clientReturning(500, jsonEncode({'message': 'SQLSTATE[42S02]: Base table not found'}));
    await expectLater(
      sqlLeak.dashboard(),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', AppErrorMessages.server)),
    );

    final htmlPage = await clientReturning(502, '<html><body>Bad Gateway nginx</body></html>', type: 'text/html');
    await expectLater(
      htmlPage.dashboard(),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', AppErrorMessages.server)),
    );
  });

  test('connection failures surface as a no-internet ApiException', () async {
    final api = ApiClient(
      httpClient: MockClient((_) async => throw const SocketException('Connection refused')),
      storage: _MemoryStorage(),
    );

    await expectLater(
      api.dashboard(),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', AppErrorMessages.noInternet)),
    );
  });
}
