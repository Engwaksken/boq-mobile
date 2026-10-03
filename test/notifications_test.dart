import 'dart:convert';

import 'package:boq_mobile/api_client.dart';
import 'package:boq_mobile/l10n/app_localizations.dart';
import 'package:boq_mobile/main.dart';
import 'package:boq_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

ApiClient _api(List<Map<String, dynamic>> items) => ApiClient(
  storage: _Storage(),
  httpClient: MockClient((request) async {
    if (request.url.path.endsWith('/notifications')) {
      return _json({
        'success': true,
        'data': {
          'data': items,
          'current_page': 1,
          'last_page': 1,
          'per_page': 20,
          'total': items.length,
        },
      });
    }
    if (request.url.path.endsWith('/read')) {
      return _json({'success': true, 'data': items.first});
    }
    return _json({'message': 'Not found'}, 404);
  }),
);

Widget _app(ApiClient api) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    BoqMaterialLocalizationsDelegate(),
    BoqCupertinoLocalizationsDelegate(),
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: NotificationsPage(api: api),
);

void main() {
  testWidgets('renders a price alert with a dedicated price-change icon', (
    tester,
  ) async {
    final api = _api([
      {
        'id': 1,
        'title': 'Hardware price changed',
        'message': 'Portland cement 50kg price is now UGX 36000.00.',
        'type': 'price_alert',
        'read_at': null,
        'created_at': '2026-10-03T12:00:00+03:00',
        'data': {'hardware_price_id': 9, 'price_history_id': 4},
      },
    ]);

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Hardware price changed'), findsOneWidget);
    expect(find.byIcon(Icons.price_change_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
