import 'dart:convert';

import 'package:boq_mobile/api_client.dart';
import 'package:boq_mobile/app_errors.dart';
import 'package:boq_mobile/l10n/app_localizations.dart';
import 'package:boq_mobile/l10n/app_localizations_en.dart';
import 'package:boq_mobile/main.dart';
import 'package:boq_mobile/theme/app_theme.dart';
import 'package:boq_mobile/widgets/layout.dart';
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

ApiClient _api({
  required List<Map<String, dynamic>> plans,
  http.Response Function(http.Request request)? onSubscription,
}) => ApiClient(
  storage: _Storage(),
  httpClient: MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/plans')) {
      return _json({'success': true, 'data': plans});
    }
    if (path.endsWith('/subscriptions') && request.method == 'POST') {
      return onSubscription?.call(request) ??
          _json({'message': 'Not found'}, 404);
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
  home: PlansPage(api: api),
);

Map<String, dynamic> _oneTimePlan({
  int id = 9,
  String name = 'One-Time BOQ Access',
  num price = 12000,
  String currency = 'UGX',
  int? durationHours = 72,
  int? durationDays,
  int? maxProjects = 1,
  int? maxBoqs = 1,
  int? maxAiCredits = 10,
  int? maxOcrPages = 5,
  Object? autoRenewal = false,
  List<String> features = const ['PDF & Excel export'],
}) => {
  'id': id,
  'name': name,
  'code': 'ONE_TIME',
  'description': '',
  'type': 'one_time',
  'price': price,
  'currency': currency,
  'duration_hours': durationHours,
  'duration_days': durationDays,
  'max_users': 1,
  'max_projects': maxProjects,
  'max_boqs': maxBoqs,
  'max_ai_credits': maxAiCredits,
  'max_ocr_pages': maxOcrPages,
  'auto_renewal': autoRenewal,
  'display_order': 1,
  'features': features,
};

void main() {
  testWidgets('one-time plan card is fully data-driven', (tester) async {
    final api = _api(plans: [_oneTimePlan()]);
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Buy One-Time Access'), findsOneWidget);
    expect(find.text('One-Time BOQ Access'), findsOneWidget);
    expect(find.text('For occasional BOQ preparation'), findsOneWidget);
    expect(
      find.text(formatAmount(12000, currency: 'UGX', decimals: 0)),
      findsOneWidget,
    );
    expect(find.text('72 hours'), findsOneWidget);
    expect(find.text('1 project'), findsOneWidget);
    expect(find.text('1 BOQ'), findsOneWidget);
    expect(find.text('10 AI credits'), findsOneWidget);
    expect(find.text('Current Hardware & Factory prices'), findsOneWidget);
    expect(find.text('PDF & Excel export'), findsOneWidget);
    expect(find.text('Company branding'), findsOneWidget);
    expect(find.text('No recurring payment'), findsOneWidget);
    expect(find.text('Select plan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duration_days and auto_renewal drive the card', (tester) async {
    final api = _api(
      plans: [
        _oneTimePlan(
          id: 10,
          name: 'One-Time Days',
          durationHours: null,
          durationDays: 14,
          autoRenewal: true,
        ),
      ],
    );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('14 days'), findsOneWidget);
    expect(find.text('Renews automatically'), findsOneWidget);
    expect(find.text('No recurring payment'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan limit error code shows the friendly localized message', (
    tester,
  ) async {
    final api = _api(
      plans: [_oneTimePlan()],
      onSubscription: (_) => _json({
        'message': 'raw internal error',
        'error_code': 'ONE_TIME_PROJECT_LIMIT_REACHED',
      }, 403),
    );
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buy One-Time Access'));
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsEn().errorOneTimeProjectLimit),
      findsOneWidget,
    );
    expect(find.text('raw internal error'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('planLimitErrorMessage maps all five one-time codes', () {
    final l10n = AppLocalizationsEn();
    expect(
      planLimitErrorMessage(l10n, 'ONE_TIME_PROJECT_LIMIT_REACHED'),
      l10n.errorOneTimeProjectLimit,
    );
    expect(
      planLimitErrorMessage(l10n, 'ONE_TIME_BOQ_LIMIT_REACHED'),
      l10n.errorOneTimeBoqLimit,
    );
    expect(
      planLimitErrorMessage(l10n, 'AI_CREDITS_EXHAUSTED'),
      l10n.errorAiCreditsExhausted,
    );
    expect(
      planLimitErrorMessage(l10n, 'OCR_LIMIT_REACHED'),
      l10n.errorOcrLimitReached,
    );
    expect(
      planLimitErrorMessage(l10n, 'ONE_TIME_ACCESS_EXPIRED'),
      l10n.errorOneTimeAccessExpired,
    );
    expect(planLimitErrorMessage(l10n, null), isNull);
  });
}
