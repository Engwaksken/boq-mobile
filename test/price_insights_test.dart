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

/// An ApiClient whose server answers every request with [body], recording it.
ApiClient _api(Object body, List<http.Request> sent) => ApiClient(
  storage: _Storage(),
  httpClient: MockClient((request) async {
    sent.add(request);
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  }),
);

void main() {
  test('monthly history reads months, trend and latest change', () async {
    final sent = <http.Request>[];
    final api = _api({
      'success': true,
      'data': {
        'item': {'id': 7, 'item_name': 'Cement', 'currency': 'UGX'},
        'months': [
          {
            'month': '2026-11',
            'records': 2,
            'low': '38000.00',
            'high': 42000,
            'average': 40000,
            'closing': 42000,
            'change': 8000,
            'change_percent': 25,
          },
          {'month': '2026-10', 'records': 0},
          {
            'month': '2026-09',
            'records': 1,
            'average': '32000.00',
            'change': null,
          },
        ],
      },
    }, sent);

    final history = await api.hardwarePriceMonthly(7, months: 6);

    expect(sent.single.url.path, endsWith('/hardware-prices/7/monthly'));
    expect(sent.single.url.queryParameters['months'], '6');
    expect(history.item.itemName, 'Cement');
    expect(history.months, hasLength(3));
    expect(history.months.first.low, 38000);
    // Months without prices are not plotted; the trend runs oldest first.
    expect(history.trend.map((m) => m.month), ['2026-09', '2026-11']);
    expect(history.latestChange?.changePercent, 25);
  });

  test('price changes send filters and read stats and paging', () async {
    final sent = <http.Request>[];
    final api = _api({
      'success': true,
      'data': {
        'current_page': 1,
        'last_page': 2,
        'data': [
          {
            'id': 3,
            'item_name': 'Cement',
            'price': '44000.00',
            'previous_price': '40000.00',
            'price_change': '4000.00',
            'price_change_percent': '10.00',
            'price_changed_at': '2026-11-01T08:00:00.000000Z',
            'organisation_id': null,
          },
          {'id': 4, 'item_name': 'Our blocks', 'organisation_id': 12},
        ],
      },
      'meta': {
        'stats': {'total': 2, 'up': 1, 'down': 1, 'average': -2.5},
        'categories': ['Cement', 'Blocks'],
      },
    }, sent);

    final result = await api.hardwarePriceChanges(
      period: '90',
      direction: 'up',
      source: 'general',
      sort: 'up',
    );

    final query = sent.single.url.queryParameters;
    expect(sent.single.url.path, endsWith('/hardware-prices/changes'));
    expect(query['period'], '90');
    expect(query['direction'], 'up');
    expect(query['source'], 'general');
    expect(query['sort'], 'up');
    expect(query.containsKey('category'), isFalse);

    expect(result.hasNext, isTrue);
    expect(result.stats.up, 1);
    expect(result.stats.average, -2.5);
    expect(result.categories, ['Cement', 'Blocks']);
    final cement = result.items.first;
    expect(cement.isGeneral, isTrue);
    expect(cement.hasChange, isTrue);
    expect(cement.previousPrice, 40000);
    expect(cement.priceChangePercent, 10);
    expect(result.items.last.isGeneral, isFalse);
  });

  test('BOQ price check reads summary and rows', () async {
    final sent = <http.Request>[];
    final api = _api({
      'success': true,
      'data': {
        'currency': 'UGX',
        'filter': 'below',
        'summary': {
          'matched': 2,
          'unmatched': 1,
          'above': 1,
          'below': 1,
          'changed': 1,
          'total_ours': 560000,
          'total_market': 580000,
          'total_difference': 20000,
          'total_percent': 3.57,
        },
        'rows': [
          {
            'boq_item_id': 11,
            'item_code': 'A1',
            'description': 'Cement',
            'quantity': '10.00',
            'unit': 'bag',
            'currency': 'UGX',
            'rate': 36000,
            'rate_field': 'approved_rate',
            'comparable': true,
            'difference': 4000,
            'percent': 11.11,
            'since_match': 4000,
            'market': {
              'id': 3,
              'item_name': 'Cement 50kg',
              'price': 40000,
              'currency': 'UGX',
              'unit': 'bag',
              'supplier': 'Hima',
            },
          },
        ],
      },
    }, sent);

    final check = await api.boqPriceCheck(5, filter: 'below');

    expect(sent.single.url.path, endsWith('/boqs/5/price-check'));
    expect(sent.single.url.queryParameters['filter'], 'below');
    expect(check.summary.unmatched, 1);
    expect(check.summary.totalDifference, 20000);
    final row = check.rows.single;
    expect(row.quantity, 10);
    expect(row.rateField, 'approved_rate');
    expect(row.marketId, 3);
    expect(row.marketPrice, 40000);
    expect(row.comparable, isTrue);
  });

  test('BOQ item rate history reads changes and who made them', () async {
    final sent = <http.Request>[];
    final api = _api({
      'success': true,
      'data': {
        'data': [
          {
            'id': 1,
            'field': 'approved_rate',
            'old_value': '30000.00',
            'new_value': '35000.00',
            'currency': 'UGX',
            'changed_at': '2026-11-02T10:00:00Z',
            'user': {'id': 4, 'name': 'Amina'},
          },
          {'id': 2, 'field': 'original_rate', 'new_value': 30000, 'user': null},
        ],
      },
    }, sent);

    final changes = await api.boqItemRateHistory(11);

    expect(sent.single.url.path, endsWith('/boq-items/11/price-history'));
    expect(changes.first.change, 5000);
    expect(changes.first.userName, 'Amina');
    expect(changes.last.oldValue, isNull);
    expect(changes.last.change, isNull);
    expect(changes.last.userName, isEmpty);
  });

  test('plan price history reads changes for the chosen scope', () async {
    final sent = <http.Request>[];
    final api = _api({
      'success': true,
      'data': {
        'current_page': 1,
        'last_page': 1,
        'data': [
          {
            'id': 9,
            'plan': {
              'id': 2,
              'name': 'Monthly Professional',
              'type': 'monthly',
            },
            'old_price': 50000,
            'new_price': 60000,
            'old_currency': 'UGX',
            'new_currency': 'UGX',
            'difference': 10000,
            'percent_change': 20,
            'changed_at': '2026-11-05T09:00:00Z',
            'is_my_plan': true,
          },
          {
            'id': 8,
            'plan': {'id': 2, 'name': 'Monthly Professional'},
            'old_price': null,
            'new_price': 50000,
            'new_currency': 'UGX',
            'is_my_plan': true,
          },
        ],
      },
    }, sent);

    final result = await api.planPriceHistory(scope: 'all');

    expect(sent.single.url.path, endsWith('/plans/price-history'));
    expect(sent.single.url.queryParameters['scope'], 'all');
    expect(result.hasNext, isFalse);
    expect(result.items.first.planName, 'Monthly Professional');
    expect(result.items.first.percentChange, 20);
    expect(result.items.first.isMyPlan, isTrue);
    expect(result.items.last.oldPrice, isNull);
  });

  test('price list sends the source filter only when set', () async {
    final sent = <http.Request>[];
    final api = _api({
      'success': true,
      'data': {'data': [], 'current_page': 1, 'last_page': 1, 'total': 0},
    }, sent);

    await api.hardwarePrices(source: 'mine');
    await api.hardwarePrices();

    expect(sent.first.url.queryParameters['source'], 'mine');
    expect(sent.last.url.queryParameters.containsKey('source'), isFalse);
  });
}
