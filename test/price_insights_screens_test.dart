import 'dart:convert';

import 'package:boq_mobile/api_client.dart';
import 'package:boq_mobile/l10n/app_localizations.dart';
import 'package:boq_mobile/main.dart';
import 'package:boq_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
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

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

const _cement = {
  'id': 3,
  'item_name': 'Portland cement 50kg bag, extra long name to test wrapping',
  'category': 'Cement',
  'unit': 'bag',
  'price': '44000.00',
  'currency': 'UGX',
  'supplier': 'Hima Cement Distributors Kampala',
  'location': 'Kampala',
  'previous_price': '40000.00',
  'price_change': '4000.00',
  'price_change_percent': '10.00',
  'price_changed_at': '2026-11-01T08:00:00Z',
  'organisation_id': null,
  'is_active': true,
};

ApiClient _api({bool empty = false}) => ApiClient(
  storage: _Storage(),
  httpClient: MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/hardware-prices/changes')) {
      return _json({
        'success': true,
        'data': {
          'current_page': 1,
          'last_page': empty ? 1 : 2,
          'data': empty
              ? []
              : [
                  _cement,
                  {
                    ..._cement,
                    'id': 4,
                    'item_name': 'Sand',
                    'organisation_id': 9,
                    'price_change': '-500',
                    'price_change_percent': '-5',
                  },
                ],
        },
        'meta': {
          'stats': {'total': empty ? 0 : 2, 'up': 1, 'down': 1, 'average': 2.5},
          'categories': ['Cement'],
        },
      });
    }
    if (path.endsWith('/monthly')) {
      return _json({
        'success': true,
        'data': {
          'item': _cement,
          'months': [
            {
              'month': '2026-11',
              'records': 2,
              'low': 42000,
              'high': 44000,
              'average': 43000,
              'closing': 44000,
              'change': 3000,
              'change_percent': 7.5,
            },
            {'month': '2026-10', 'records': 0},
            {
              'month': '2026-09',
              'records': 3,
              'low': 39000,
              'high': 41000,
              'average': 40000,
              'closing': 41000,
            },
          ],
        },
      });
    }
    if (path.endsWith('/history')) {
      return _json({
        'success': true,
        'data': {
          'item': _cement,
          'summary': {
            'lowest_price': 39000,
            'highest_price': 44000,
            'average_price': 41500,
            'price_change_percent': 10,
          },
          'history': {'data': []},
        },
      });
    }
    if (path.endsWith('/price-check')) {
      return _json({
        'success': true,
        'data': {
          'currency': 'UGX',
          'summary': {
            'matched': 1,
            'unmatched': 2,
            'above': 0,
            'below': 1,
            'changed': 1,
            'total_ours': 360000,
            'total_market': 440000,
            'total_difference': 80000,
            'total_percent': 22.2,
          },
          'rows': [
            {
              'boq_item_id': 11,
              'item_code': 'B2.1',
              'description':
                  'Supply and lay cement for foundation works, long description',
              'quantity': 10,
              'unit': 'bag',
              'currency': 'UGX',
              'rate': 36000,
              'rate_field': 'approved_rate',
              'comparable': true,
              'difference': 8000,
              'percent': 22.2,
              'since_match': 4000,
              'market': {
                'id': 3,
                'item_name': 'Portland cement 50kg',
                'price': 44000,
                'currency': 'UGX',
                'unit': 'bag',
                'supplier': 'Hima',
              },
            },
          ],
        },
      });
    }
    if (path.endsWith('/boq-items/11/price-history')) {
      return _json({
        'success': true,
        'data': {
          'data': [
            {
              'id': 1,
              'field': 'approved_rate',
              'old_value': 30000,
              'new_value': 36000,
              'currency': 'UGX',
              'changed_at': '2026-11-02T10:00:00Z',
              'user': {'name': 'Amina'},
            },
          ],
        },
      });
    }
    return _json({'success': true, 'data': {}});
  }),
);

Widget _app(Widget home, {ThemeMode mode = ThemeMode.light}) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: mode,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360 * 3, 760 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Price Changes lists changes with stats and filters', (
    tester,
  ) async {
    await _phone(tester);
    await tester.pumpWidget(_app(PriceChangesPage(api: _api())));
    await tester.pumpAndSettle();

    expect(find.text('Price Changes'), findsOneWidget);
    expect(find.text('Went up'), findsWidgets);
    expect(find.textContaining('Portland cement'), findsOneWidget);
    expect(find.text('Load more'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Price Changes empty state in dark mode', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(
      _app(PriceChangesPage(api: _api(empty: true)), mode: ThemeMode.dark),
    );
    await tester.pumpAndSettle();

    expect(find.text('No price changes found.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('price detail shows the monthly history card', (tester) async {
    await _phone(tester);
    final api = _api();
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => HardwarePriceDetailPage(
            api: api,
            hardwarePrice: HardwarePrice.fromJson(_cement),
            l10n: AppLocalizations.of(context)!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Monthly price history'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Monthly price history'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    // Lowest / highest now come from the history endpoint's summary keys.
    expect(find.text('39,000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BOQ price check shows totals, rows and rate history', (
    tester,
  ) async {
    await _phone(tester);
    await tester.pumpWidget(
      _app(BoqPriceCheckPage(api: _api(), boqId: 5, title: 'Office block')),
    );
    await tester.pumpAndSettle();

    expect(find.text('BOQ at our rates'), findsOneWidget);
    expect(find.textContaining('2 not matched'), findsOneWidget);
    expect(find.textContaining('Supply and lay cement'), findsOneWidget);

    await tester.ensureVisible(find.text('Rate history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rate history'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Amina'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
