import 'dart:convert';

import 'package:boq_mobile/api_client.dart';
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

Map<String, dynamic> _supplier({
  int id = 4,
  String name = 'Kampala Hardware',
  String type = 'supplier',
}) => {
  'id': id,
  'name': name,
  'type': type,
  'location': 'Kampala',
  'region': 'Central',
  'country': 'Uganda',
  'website_url': null,
  'rating': '4.50',
  'ratings_count': 6,
};

List<Map<String, dynamic>> _trend({bool empty = false}) => [
  for (var m = 1; m <= 12; m++)
    {
      'period': '2026-${m.toString().padLeft(2, '0')}',
      'label':
          '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1]} 2026',
      'average': empty || m.isOdd ? null : 4.0 + m / 100,
      'count': empty || m.isOdd ? 0 : m,
    },
];

final _distribution = [
  {'stars': 5, 'count': 3},
  {'stars': 4, 'count': 2},
  {'stars': 3, 'count': 1},
  {'stars': 2, 'count': 0},
  {'stars': 1, 'count': 0},
];

Map<String, dynamic> _leaderboard(String type, {bool empty = false}) => {
  'period': 'month',
  'period_label': 'This month',
  'since': '2026-08-31T00:00:00+03:00',
  'type': type,
  'items': empty
      ? []
      : [
          for (var rank = 1; rank <= 4; rank++)
            {
              'rank': rank,
              'supplier': _supplier(id: rank, name: '$type $rank', type: type),
              'average': 5 - rank * 0.5,
              'score': 4.5 - rank * 0.25,
              'count': 10 - rank,
              'criteria': {
                'price': 4.25,
                'quality': null,
                'delivery': 3,
                'service': '4.5',
              },
            },
        ],
};

Map<String, dynamic> _summary({bool empty = false}) => {
  'period': 'month',
  'period_label': 'This month',
  'total': empty ? 0 : 6,
  'suppliers': empty ? 0 : 3,
  'average': empty ? null : 4.33,
  'distribution': empty
      ? [
          for (var s = 5; s >= 1; s--) {'stars': s, 'count': 0},
        ]
      : _distribution,
  'by_type': {
    'supplier': {'count': empty ? 0 : 4, 'average': empty ? null : 4.5},
    'factory': {'count': empty ? 0 : 2, 'average': empty ? null : 4},
  },
  'criteria': {
    'price': empty ? null : 4.1,
    'quality': empty ? null : 4.4,
    'delivery': null,
    'service': empty ? null : 3.9,
  },
  'trend': _trend(empty: empty),
  'trend_by_type': {
    'supplier': _trend(empty: empty),
    'factory': _trend(empty: true),
  },
};

Map<String, dynamic> _performance({bool withMine = true}) => {
  'supplier': _supplier(),
  'period': 'month',
  'rank': {'rank': 2, 'of': 7},
  'period_total': 3,
  'period_average': 4.67,
  'total': 6,
  'average': 4.5,
  'distribution': _distribution,
  'criteria': {'price': 4, 'quality': 5, 'delivery': null, 'service': 4.5},
  'trend': _trend(),
  'reviews': [
    {
      'id': 11,
      'rating': 5,
      'comment': 'Good prices and quick delivery.',
      'author': null,
      'is_hidden': false,
      'rated_at': '2026-09-20T10:00:00+03:00',
    },
    {
      'id': 12,
      'rating': 3,
      'comment': null,
      'author': 'Jane',
      'is_hidden': true,
      'rated_at': '2026-09-02T10:00:00+03:00',
    },
  ],
  'mine': withMine
      ? {
          'id': 11,
          'supplier_id': 4,
          'rating': 4,
          'price_rating': 5,
          'quality_rating': null,
          'delivery_rating': 3,
          'service_rating': null,
          'comment': 'Fair',
          'period': '2026-09',
          'rated_at': '2026-09-20T10:00:00+03:00',
        }
      : null,
};

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Answers the supplier-ratings endpoints from the fixtures above.
ApiClient _api({bool empty = false, List<http.Request>? sent}) => ApiClient(
  storage: _Storage(),
  httpClient: MockClient((request) async {
    sent?.add(request);
    final path = request.url.path;
    if (path.endsWith('/supplier-ratings/leaderboard')) {
      return _json({
        'success': true,
        'data': _leaderboard(
          request.url.queryParameters['type']!,
          empty: empty,
        ),
      });
    }
    if (path.endsWith('/supplier-ratings/summary')) {
      return _json({'success': true, 'data': _summary(empty: empty)});
    }
    if (path.endsWith('/supplier-ratings/mine')) {
      return _json({
        'success': true,
        'data': empty
            ? []
            : [
                {
                  ..._performance()['mine'] as Map<String, dynamic>,
                  'supplier': _supplier(),
                },
              ],
      });
    }
    if (path.endsWith('/supplier-ratings/suppliers')) {
      return _json({
        'success': true,
        'data': [
          _supplier(),
          _supplier(id: 5, name: 'Jinja Steel', type: 'factory'),
        ],
      });
    }
    if (path.contains('/supplier-ratings/suppliers/')) {
      if (request.method == 'POST') {
        return _json({
          'success': true,
          'message': 'Thank you. Your rating of Kampala Hardware was saved.',
          'data': {
            ..._performance()['mine'] as Map<String, dynamic>,
            'supplier': _supplier(),
          },
        }, 201);
      }
      return _json({'success': true, 'data': _performance()});
    }
    return _json({'message': 'Not found'}, 404);
  }),
);

Widget _app(Widget home, {ThemeMode mode = ThemeMode.light}) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: mode,
  home: home,
);

/// The page's vertical list (not the horizontal period chips).
final _vertical = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .hitTestable()
    .first;

void main() {
  group('models', () {
    test('leaderboard parses ranks, suppliers and nullable criteria', () {
      final board = SupplierLeaderboard.fromJson(_leaderboard('factory'));

      expect(board.periodLabel, 'This month');
      expect(board.type, 'factory');
      expect(board.items, hasLength(4));
      final first = board.items.first;
      expect(first.rank, 1);
      expect(first.average, 4.5);
      expect(first.count, 9);
      expect(first.supplier.name, 'factory 1');
      expect(first.supplier.isFactory, isTrue);
      expect(first.supplier.rating, 4.5);
      expect(first.supplier.ratingsCount, 6);
      expect(first.supplier.place, 'Kampala, Central');
      expect(first.supplier.websiteUrl, isNull);
      expect(first.criteria.price, 4.25);
      expect(first.criteria.quality, isNull);
      expect(first.criteria.delivery, 3);
      expect(first.criteria.service, 4.5);
      expect(first.criteria.isEmpty, isFalse);
    });

    test('summary parses totals, distribution, types and trends', () {
      final summary = SupplierRatingSummary.fromJson(_summary());

      expect(summary.total, 6);
      expect(summary.suppliers, 3);
      expect(summary.average, 4.33);
      expect(summary.distribution.map((b) => b.stars), [5, 4, 3, 2, 1]);
      expect(summary.distribution.map((b) => b.count), [3, 2, 1, 0, 0]);
      expect(summary.hardware.count, 4);
      expect(summary.factories.average, 4);
      expect(summary.criteria.delivery, isNull);
      expect(summary.trend, hasLength(12));
      expect(summary.trend[1].period, '2026-02');
      expect(summary.trend[1].label, 'Feb 2026');
      expect(summary.trend[1].count, 2);
      expect(summary.trend[0].average, isNull);
      expect(summary.hardwareTrend, hasLength(12));
      expect(summary.factoryTrend.every((p) => p.count == 0), isTrue);
    });

    test('empty summary and missing fields have safe defaults', () {
      final summary = SupplierRatingSummary.fromJson({
        'total': 0,
        'average': null,
        'distribution': [
          {'stars': 5, 'count': 1},
        ],
        'by_type': [],
      });

      expect(summary.average, isNull);
      expect(summary.distribution.map((b) => b.count), [1, 0, 0, 0, 0]);
      expect(summary.hardware.count, 0);
      expect(summary.criteria.isEmpty, isTrue);
      expect(summary.trend, isEmpty);
    });

    test('supplier detail parses rank, reviews and my rating', () {
      final detail = SupplierPerformance.fromJson(_performance());

      expect(detail.supplier.id, 4);
      expect(detail.rank, 2);
      expect(detail.rankOf, 7);
      expect(detail.periodTotal, 3);
      expect(detail.periodAverage, 4.67);
      expect(detail.total, 6);
      expect(detail.average, 4.5);
      expect(detail.distribution.first.count, 3);
      expect(detail.criteria.quality, 5);
      expect(detail.trend, hasLength(12));
      expect(detail.reviews, hasLength(2));
      expect(detail.reviews.first.comment, 'Good prices and quick delivery.');
      expect(detail.reviews.first.author, isNull);
      expect(detail.reviews.last.isHidden, isTrue);
      expect(detail.reviews.last.author, 'Jane');
      final mine = detail.mine!;
      expect(mine.rating, 4);
      expect(mine.priceRating, 5);
      expect(mine.qualityRating, isNull);
      expect(mine.deliveryRating, 3);
      expect(mine.comment, 'Fair');
      expect(mine.period, '2026-09');
    });

    test('supplier detail without a rank or my rating', () {
      final detail = SupplierPerformance.fromJson({
        ..._performance(withMine: false),
        'rank': null,
      });

      expect(detail.rank, isNull);
      expect(detail.rankOf, isNull);
      expect(detail.mine, isNull);
    });
  });

  group('api', () {
    test('leaderboard sends period, type, limit and order', () async {
      final sent = <http.Request>[];
      final board = await _api(
        sent: sent,
      ).supplierLeaderboard(period: 'year', type: 'factory', lowest: true);

      expect(sent.single.url.path, endsWith('/supplier-ratings/leaderboard'));
      expect(sent.single.url.queryParameters, {
        'period': 'year',
        'type': 'factory',
        'limit': '10',
        'order': 'lowest',
      });
      expect(board.items.first.supplier.name, 'factory 1');
    });

    test('rating posts JSON and returns the server message', () async {
      final sent = <http.Request>[];
      final result = await _api(
        sent: sent,
      ).rateSupplier(4, rating: 4, priceRating: 5, comment: '  Fair  ');

      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, endsWith('/supplier-ratings/suppliers/4'));
      expect(jsonDecode(sent.single.body), {
        'rating': 4,
        'price_rating': 5,
        'quality_rating': null,
        'delivery_rating': null,
        'service_rating': null,
        'comment': 'Fair',
      });
      expect(
        result.message,
        'Thank you. Your rating of Kampala Hardware was saved.',
      );
      expect(result.rating.supplier?.name, 'Kampala Hardware');
    });

    test('rating validation errors show the field message', () async {
      final api = ApiClient(
        storage: _Storage(),
        httpClient: MockClient(
          (_) async => _json({
            'message': 'The rating field is required.',
            'errors': {
              'rating': ['The rating field must be between 1 and 5.'],
            },
          }, 422),
        ),
      );

      await expectLater(
        api.rateSupplier(4, rating: 9),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'The rating field must be between 1 and 5.',
          ),
        ),
      );
    });
  });

  group('screens', () {
    Future<void> setPhoneSize(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    testWidgets('Top Suppliers shows rankings, charts and my ratings', (
      tester,
    ) async {
      await setPhoneSize(tester);
      await tester.pumpWidget(_app(TopSuppliersPage(api: _api())));
      await tester.pumpAndSettle();

      expect(find.text('Top 10 Hardware'), findsOneWidget);
      expect(find.text('supplier 1'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('factory 1'),
        200,
        scrollable: _vertical,
      );
      expect(find.text('factory 1'), findsOneWidget);

      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();
      expect(find.text('Rating distribution'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Monthly trend'),
        300,
        scrollable: _vertical,
      );
      expect(find.text('Monthly trend'), findsOneWidget);

      await tester.tap(find.text('My ratings'));
      await tester.pumpAndSettle();
      expect(find.text('Kampala Hardware'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty data shows empty states in dark mode', (tester) async {
      await setPhoneSize(tester);
      await tester.pumpWidget(
        _app(TopSuppliersPage(api: _api(empty: true)), mode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(find.text('No ratings in this period yet.'), findsWidgets);

      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('No ratings in the last 12 months.'),
        300,
        scrollable: _vertical,
      );
      expect(
        find.text('No detailed scores in this period yet.'),
        findsOneWidget,
      );

      await tester.tap(find.text('My ratings'));
      await tester.pumpAndSettle();
      expect(find.text('You have not rated any supplier yet.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supplier performance shows rank, reviews and rate again', (
      tester,
    ) async {
      await setPhoneSize(tester);
      await tester.pumpWidget(
        _app(
          SupplierPerformancePage(
            api: _api(),
            supplier: RatedSupplier.fromJson(_supplier()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Rank 2 of 7'), findsOneWidget);
      expect(find.text('Rate again'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Good prices and quick delivery.'),
        300,
        scrollable: _vertical,
      );
      expect(find.text('Hidden'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rate sheet pre-fills my rating and saves', (tester) async {
      await setPhoneSize(tester);
      final sent = <http.Request>[];
      String? message;
      final api = _api(sent: sent);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    message = await showRateSupplierSheet(
                      context,
                      api,
                      supplier: RatedSupplier.fromJson(_supplier()),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Pre-filled from `mine`, so the button updates the rating.
      expect(find.text('Update Rating'), findsOneWidget);
      expect(find.text('Fair'), findsOneWidget);

      // Price was 5: tapping the 5th price star again clears it.
      final priceStars = find.descendant(
        of: find
            .ancestor(of: find.text('Price'), matching: find.byType(Row))
            .first,
        matching: find.byType(IconButton),
      );
      await tester.tap(priceStars.at(4));
      await tester.pump();

      await tester.tap(find.text('Update Rating'));
      await tester.pumpAndSettle();

      final post = sent.lastWhere((r) => r.method == 'POST');
      expect(jsonDecode(post.body), {
        'rating': 4,
        'price_rating': null,
        'quality_rating': null,
        'delivery_rating': 3,
        'service_rating': null,
        'comment': 'Fair',
      });
      expect(message, 'Thank you. Your rating of Kampala Hardware was saved.');
    });
  });
}
