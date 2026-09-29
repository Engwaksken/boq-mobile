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

  test('categories come from the API', () async {
    final api = ApiClient(
      storage: _Storage(),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'project_types': ['Health Facility', 'Road Works'],
              'work_sections': ['Substructure'],
              'materials': [
                {
                  'name': 'Cement',
                  'items': ['Portland Cement 42.5N'],
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    final catalog = await api.categories();

    expect(catalog.projectTypes, ['Health Facility', 'Road Works']);
    expect(catalog.materials.single.items, ['Portland Cement 42.5N']);
  });

  test('importing without a plan explains what to do', () async {
    final api = ApiClient(
      storage: _Storage(),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'error_code': 'FEATURE_TOPUP_REQUIRED',
            'message': 'This feature is not included in your current plan.',
          }),
          403,
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
          contains('Start a trial or choose a plan'),
        ),
      ),
    );
  });

  test('location prices and bulk review', () async {
    final requests = <http.Request>[];
    final api = ApiClient(
      storage: _Storage(),
      httpClient: MockClient((request) async {
        requests.add(request);
        final body = request.url.path.endsWith('/locations')
            ? {
                'data': [
                  {
                    'key': 'gulu',
                    'location': 'Gulu',
                    'priced_items': 2,
                    'total_items': 3,
                    'total': '400000.00',
                    'current': true,
                  },
                ],
              }
            : {
                'data': {'done': 2, 'skipped': 1},
              };
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final locations = await api.boqLocations(5);
    expect(locations.single.location, 'Gulu');
    expect(locations.single.total, 400000);
    expect(locations.single.current, isTrue);

    final result = await api.bulkReviewItems(
      5,
      action: 'reject',
      itemIds: [1, 2, 3],
      reason: 'Too high',
    );
    expect(result.done, 2);
    expect(jsonDecode(requests.last.body), {
      'action': 'reject',
      'item_ids': [1, 2, 3],
      'reason': 'Too high',
    });
  });
}
