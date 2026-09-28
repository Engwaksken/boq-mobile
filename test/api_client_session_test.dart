import 'dart:convert';

import 'package:boq_mobile/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory secure storage so tests don't need the platform plugin.
class _MemoryStorage extends FlutterSecureStorage {
  _MemoryStorage(this.values);

  final Map<String, String> values;

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
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

void main() {
  test('a 401 clears the stored token and reports session expiry', () async {
    final storage = _MemoryStorage({'auth_token': 'stale-token'});
    final api = ApiClient(
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'success': false, 'message': 'Unauthenticated.'}),
          401,
        ),
      ),
      storage: storage,
    );

    final expired = api.sessionExpired.first;

    await expectLater(api.dashboard(), throwsA(isA<ApiException>()));
    expect(await expired, contains('session has expired'));
    await Future<void>.delayed(Duration.zero);
    expect(await api.hasSession(), isFalse);
  });

  test(
    'a disabled account signs the user out with the server message',
    () async {
      final storage = _MemoryStorage({'auth_token': 'token'});
      final api = ApiClient(
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'success': false,
              'error_code': 'ACCOUNT_DISABLED',
              'message': 'Your account has been disabled.',
            }),
            403,
          ),
        ),
        storage: storage,
      );

      final expired = api.sessionExpired.first;

      await expectLater(api.dashboard(), throwsA(isA<ApiException>()));
      expect(await expired, 'Your account has been disabled.');
    },
  );

  test('a failed login does not trigger session expiry', () async {
    final api = ApiClient(
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'success': false, 'message': 'Invalid credentials.'}),
          401,
        ),
      ),
      storage: _MemoryStorage({}),
    );

    var expiredCount = 0;
    final subscription = api.sessionExpired.listen((_) => expiredCount++);

    await expectLater(
      api.login(email: 'a@b.test', password: 'wrong'),
      throwsA(isA<ApiException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(expiredCount, 0);
    await subscription.cancel();
  });
}
