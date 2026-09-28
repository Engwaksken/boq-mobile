import 'dart:convert';

import 'package:boq_mobile/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => 'token';
}

void main() {
  test('comparison posts JSON ids and reads decimal strings', () async {
    late http.Request sent;
    final api = ApiClient(
      storage: _Storage(),
      httpClient: MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': '7',
                  'item_name': 'Cement',
                  'price': '34000.00',
                  'fetched_at': null,
                  'variance_percent': 0,
                  'price_history': {'records': 1, 'lowest': '34000.00'},
                  'rating': {
                    'overall': 85.0,
                    'factors': {'a': 1},
                  },
                  'badges': ['Lowest Price'],
                },
              ],
              'summary': {'lowest_price': 7},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await api.hardwarePriceCompare([7, 9]);

    expect(sent.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(sent.body), {
      'ids': [7, 9],
    });
    final item = result.items.single;
    expect(item.id, 7);
    expect(item.price, 34000);
    expect(item.priceHistory.lowest, 34000);
    expect(item.rating.overall, 85);
    expect(item.badges, ['Lowest Price']);
  });

  test('validation errors show the field message', () async {
    final api = ApiClient(
      storage: _Storage(),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'The given data was invalid.',
            'errors': {
              'boq': ['The BOQ columns were not found.'],
            },
          }),
          422,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    await expectLater(
      api.processBoq(1),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'The BOQ columns were not found.',
        ),
      ),
    );
  });
}
