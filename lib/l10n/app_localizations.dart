import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_lg.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('lg'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BOQ Works'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @hardwarePrices.
  ///
  /// In en, this message translates to:
  /// **'Hardware Prices'**
  String get hardwarePrices;

  /// No description provided for @importBoq.
  ///
  /// In en, this message translates to:
  /// **'Import BOQ'**
  String get importBoq;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Here is your project cost overview.'**
  String get overview;

  /// No description provided for @totalProjects.
  ///
  /// In en, this message translates to:
  /// **'Total projects'**
  String get totalProjects;

  /// No description provided for @activeProjects.
  ///
  /// In en, this message translates to:
  /// **'Active projects'**
  String get activeProjects;

  /// No description provided for @boqsInReview.
  ///
  /// In en, this message translates to:
  /// **'BOQs in review'**
  String get boqsInReview;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated value'**
  String get estimatedValue;

  /// No description provided for @recentProjects.
  ///
  /// In en, this message translates to:
  /// **'Recent projects'**
  String get recentProjects;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjects;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get createProject;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring in your BOQ'**
  String get importTitle;

  /// No description provided for @importDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload an Excel or PDF BOQ, or scan pages from site. You will review the extracted structure before it is saved.'**
  String get importDescription;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocument;

  /// No description provided for @scanPages.
  ///
  /// In en, this message translates to:
  /// **'Scan pages'**
  String get scanPages;

  /// No description provided for @supportedFiles.
  ///
  /// In en, this message translates to:
  /// **'XLSX, XLS, CSV, PDF, and images'**
  String get supportedFiles;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @annualProfessional.
  ///
  /// In en, this message translates to:
  /// **'Annual Professional'**
  String get annualProfessional;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @renewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on 31 December 2026'**
  String get renewsOn;

  /// No description provided for @aiCredits.
  ///
  /// In en, this message translates to:
  /// **'AI credits'**
  String get aiCredits;

  /// No description provided for @ocrPages.
  ///
  /// In en, this message translates to:
  /// **'OCR pages'**
  String get ocrPages;

  /// No description provided for @managePlan.
  ///
  /// In en, this message translates to:
  /// **'Manage plan'**
  String get managePlan;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @luganda.
  ///
  /// In en, this message translates to:
  /// **'Luganda'**
  String get luganda;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usage;

  /// No description provided for @viewSubscription.
  ///
  /// In en, this message translates to:
  /// **'View subscription'**
  String get viewSubscription;

  /// No description provided for @projectStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get projectStatusActive;

  /// No description provided for @projectStatusPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get projectStatusPlanning;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signInDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your civil works projects and BOQs.'**
  String get signInDescription;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Check your details and try again.'**
  String get signInFailed;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading your dashboard...'**
  String get loadingDashboard;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep your current password'**
  String get passwordHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @projectCode.
  ///
  /// In en, this message translates to:
  /// **'Project code'**
  String get projectCode;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @projectCreated.
  ///
  /// In en, this message translates to:
  /// **'Project created'**
  String get projectCreated;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @boqs.
  ///
  /// In en, this message translates to:
  /// **'BOQs'**
  String get boqs;

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'BOQ uploaded'**
  String get imported;

  /// No description provided for @priceComparison.
  ///
  /// In en, this message translates to:
  /// **'Price Comparison'**
  String get priceComparison;

  /// No description provided for @bestRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Best Recommendations'**
  String get bestRecommendations;

  /// No description provided for @itemsTracked.
  ///
  /// In en, this message translates to:
  /// **'Items Tracked'**
  String get itemsTracked;

  /// No description provided for @pricesUpdatedToday.
  ///
  /// In en, this message translates to:
  /// **'Prices Updated Today'**
  String get pricesUpdatedToday;

  /// No description provided for @averagePriceChange.
  ///
  /// In en, this message translates to:
  /// **'Avg Price Change'**
  String get averagePriceChange;

  /// No description provided for @suppliersTracked.
  ///
  /// In en, this message translates to:
  /// **'Suppliers Tracked'**
  String get suppliersTracked;

  /// No description provided for @lowestPriceOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Lowest Price Opportunities'**
  String get lowestPriceOpportunities;

  /// No description provided for @boqItemsWithUpdatedPrices.
  ///
  /// In en, this message translates to:
  /// **'BOQ Items with Updated Prices'**
  String get boqItemsWithUpdatedPrices;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'lg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'lg':
      return AppLocalizationsLg();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
