import 'package:boq_mobile/api_client.dart';
import 'package:boq_mobile/l10n/app_localizations.dart';
import 'package:boq_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the localized Luganda sign-in screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('lg'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          BoqMaterialLocalizationsDelegate(),
          BoqCupertinoLocalizationsDelegate(),
        ],
        home: LoginPage(api: ApiClient(), onSignedIn: () {}),
      ),
    );

    expect(find.text('Yingira'), findsOneWidget);
    expect(find.text('Endagiriro ya email'), findsWidgets);
  });
}
