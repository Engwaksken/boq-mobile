import 'dart:convert';

import 'package:boq_mobile/api_client.dart';
import 'package:boq_mobile/company_profile_page.dart';
import 'package:boq_mobile/l10n/app_localizations.dart';
import 'package:boq_mobile/l10n/app_localizations_en.dart';
import 'package:boq_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// In-memory secure storage so tests don't need the platform plugin.
class _MemoryStorage extends FlutterSecureStorage {
  _MemoryStorage([Map<String, String>? values]) : values = values ?? {};

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

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _meData({
  required List<String> permissions,
  required List<String> roles,
  required bool hasOrganisation,
}) => {
  'user': {
    'id': 1,
    'name': 'Test User',
    'email': 'user@example.test',
    'roles': [
      for (final slug in roles) {'id': 1, 'name': slug, 'slug': slug},
    ],
    'organisation': hasOrganisation ? {'id': 3, 'name': 'Acme'} : null,
  },
  'permissions': permissions,
};

/// A client whose `/auth/me` grants [permissions]/[roles] and serves minimal
/// payloads for the pages the home shell builds.
ApiClient _accessApi({
  required List<String> permissions,
  required List<String> roles,
  required bool hasOrganisation,
}) {
  return ApiClient(
    storage: _MemoryStorage({'auth_token': 'token'}),
    httpClient: MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/auth/me')) {
        return _json({
          'data': _meData(
            permissions: permissions,
            roles: roles,
            hasOrganisation: hasOrganisation,
          ),
        });
      }
      if (path.endsWith('/dashboard')) return _json({'data': {}});
      if (path.endsWith('/projects')) {
        return _json({
          'data': {'data': [], 'last_page': 1},
        });
      }
      if (path.endsWith('/hardware-prices/categories')) {
        return _json({'data': []});
      }
      if (path.endsWith('/hardware-prices/filters')) {
        return _json({
          'data': {'suppliers': [], 'locations': [], 'regions': []},
        });
      }
      if (path.endsWith('/hardware-prices')) {
        return _json({
          'data': {
            'data': [],
            'last_page': 1,
            'current_page': 1,
            'per_page': 20,
            'total': 0,
          },
        });
      }
      if (path.endsWith('/subscriptions/current')) return _json({'data': {}});
      if (path.endsWith('/categories')) return _json({'data': {}});
      if (path.endsWith('/boqs')) {
        return _json({
          'data': {'data': [], 'last_page': 1},
        });
      }
      if (path.endsWith('/company-profile')) return _json({'data': null});
      if (path.endsWith('/mobile-config')) {
        return _json({
          'data': {'countries_detailed': []},
        });
      }
      return _json({'data': []});
    }),
  );
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

Finder _inDrawer(String text) =>
    find.descendant(of: find.byType(Drawer), matching: find.text(text));

Future<void> _openDrawer(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
  await tester.pumpAndSettle();
}

Future<void> _pumpHome(WidgetTester tester, ApiClient api) async {
  // A tall surface keeps every drawer entry laid out (the drawer list is lazy).
  await tester.binding.setSurfaceSize(const Size(900, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await api.loadAccess();
  await tester.pumpWidget(
    _app(
      HomeScreen(
        api: api,
        locale: const Locale('en'),
        onLocaleChanged: (_) {},
        onSignedOut: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('login persists and exposes permissions, roles and organisation', () async {
    final storage = _MemoryStorage();
    final api = ApiClient(
      storage: storage,
      httpClient: MockClient(
        (request) async => _json({
          'data': {
            'token': 'tok',
            ..._meData(
              permissions: ['boq.edit', 'hardware-prices.view'],
              roles: ['project-manager'],
              hasOrganisation: true,
            ),
          },
        }),
      ),
    );

    await api.login(email: 'pm@example.test', password: 'secret');

    expect(api.can('boq.edit'), isTrue);
    expect(api.can('subscriptions.view'), isFalse);
    expect(api.hasRole('project-manager'), isTrue);
    expect(api.hasRole('administrator'), isFalse);
    expect(api.isPersonalAccount, isFalse);
    // Persisted for the next app launch.
    expect(storage.values.containsKey('auth_permissions'), isTrue);
    expect(storage.values.containsKey('auth_roles'), isTrue);
  });

  test('permissions omitted by the API are treated as empty', () async {
    final api = ApiClient(
      storage: _MemoryStorage(),
      httpClient: MockClient(
        (request) async => _json({
          'data': {
            'token': 'tok',
            'user': {
              'id': 1,
              'name': 'Owner',
              'email': 'owner@example.test',
            },
          },
        }),
      ),
    );

    await api.login(email: 'owner@example.test', password: 'secret');

    expect(api.can('boq.edit'), isFalse);
    expect(api.hasRole('administrator'), isFalse);
    expect(api.isPersonalAccount, isTrue);
  });

  test('loadAccess refreshes permissions and roles from /auth/me', () async {
    final api = _accessApi(
      permissions: ['reports.view'],
      roles: ['finance'],
      hasOrganisation: true,
    );

    expect(api.can('reports.view'), isFalse);
    await api.loadAccess();

    expect(api.can('reports.view'), isTrue);
    expect(api.hasRole('finance'), isTrue);
    expect(api.isPersonalAccount, isFalse);
  });

  testWidgets('procurement officer sees no billing and no prices entries', (
    tester,
  ) async {
    final api = _accessApi(
      permissions: ['projects.view', 'boq.view', 'boq.edit', 'boq.upload'],
      roles: ['procurement-officer'],
      hasOrganisation: true,
    );
    await _pumpHome(tester, api);
    await _openDrawer(tester);

    expect(_inDrawer('Manage plan'), findsNothing);
    expect(_inDrawer('Get Prices'), findsNothing);
    expect(_inDrawer('Top Suppliers'), findsNothing);
    // The procurement officer may import BOQs.
    expect(_inDrawer('Import BOQ'), findsOneWidget);
    expect(find.text('Get Prices'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finance sees prices but no billing and no BOQ import', (
    tester,
  ) async {
    final api = _accessApi(
      permissions: [
        'projects.view',
        'boq.view',
        'hardware-prices.view',
        'reports.view',
      ],
      roles: ['finance'],
      hasOrganisation: true,
    );
    await _pumpHome(tester, api);
    await _openDrawer(tester);

    expect(_inDrawer('Manage plan'), findsNothing);
    expect(_inDrawer('Import BOQ'), findsNothing);
    expect(_inDrawer('Get Prices'), findsOneWidget);
    expect(_inDrawer('Top Suppliers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an account owner sees billing, prices and BOQ import', (
    tester,
  ) async {
    final api = _accessApi(
      permissions: [
        'projects.view',
        'boq.view',
        'boq.edit',
        'hardware-prices.view',
        'subscriptions.view',
      ],
      roles: ['user'],
      hasOrganisation: false,
    );
    await _pumpHome(tester, api);
    await _openDrawer(tester);

    expect(api.isPersonalAccount, isTrue);
    expect(_inDrawer('Manage plan'), findsOneWidget);
    expect(_inDrawer('Get Prices'), findsOneWidget);
    expect(_inDrawer('Import BOQ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AccountPage hides Company Profile for a non-admin member', (
    tester,
  ) async {
    final api = _accessApi(
      permissions: ['projects.view'],
      roles: ['procurement-officer'],
      hasOrganisation: true,
    );
    await api.loadAccess();
    await tester.pumpWidget(
      _app(
        AccountPage(
          l10n: AppLocalizationsEn(),
          api: api,
          locale: const Locale('en'),
          onLocaleChanged: (_) {},
          onSignedOut: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Company Profile'), findsNothing);
    expect(find.text('Manage plan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AccountPage shows Company Profile and billing for an admin', (
    tester,
  ) async {
    final api = _accessApi(
      permissions: ['projects.view', 'subscriptions.view'],
      roles: ['administrator'],
      hasOrganisation: true,
    );
    await api.loadAccess();
    await tester.pumpWidget(
      _app(
        AccountPage(
          l10n: AppLocalizationsEn(),
          api: api,
          locale: const Locale('en'),
          onLocaleChanged: (_) {},
          onSignedOut: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Company Profile'), findsOneWidget);
    expect(find.text('Manage plan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Company Profile is read-only for a non-admin member', (
    tester,
  ) async {
    final api = _accessApi(
      permissions: ['projects.view'],
      roles: ['procurement-officer'],
      hasOrganisation: true,
    );
    await api.loadAccess();
    await tester.pumpWidget(_app(CompanyProfilePage(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Save Company Profile'), findsNothing);
    expect(find.text('Choose logo'), findsNothing);
    expect(find.textContaining('organisation administrator'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Company Profile is editable for an organisation admin', (
    tester,
  ) async {
    final api = _accessApi(
      permissions: ['organisations.manage'],
      roles: ['administrator'],
      hasOrganisation: true,
    );
    await api.loadAccess();
    await tester.pumpWidget(_app(CompanyProfilePage(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Save Company Profile'), findsOneWidget);
    expect(find.text('Choose logo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Company Profile is editable for a personal account', (
    tester,
  ) async {
    final api = _accessApi(
      permissions: ['boq.edit'],
      roles: ['user'],
      hasOrganisation: false,
    );
    await api.loadAccess();
    await tester.pumpWidget(_app(CompanyProfilePage(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('Save Company Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
