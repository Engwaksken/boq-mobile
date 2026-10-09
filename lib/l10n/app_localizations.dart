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

  /// No description provided for @orgManageFaqs.
  ///
  /// In en, this message translates to:
  /// **'Manage FAQs (super admin)'**
  String get orgManageFaqs;

  /// No description provided for @orgQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get orgQuestion;

  /// No description provided for @orgAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get orgAnswer;

  /// No description provided for @orgSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get orgSortOrder;

  /// No description provided for @orgFaqActive.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get orgFaqActive;

  /// No description provided for @orgSearchExpenses.
  ///
  /// In en, this message translates to:
  /// **'Search description or supplier'**
  String get orgSearchExpenses;

  /// No description provided for @orgAllProjects.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get orgAllProjects;

  /// No description provided for @orgAssignments.
  ///
  /// In en, this message translates to:
  /// **'Project assignments'**
  String get orgAssignments;

  /// No description provided for @orgAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign team member'**
  String get orgAssign;

  /// No description provided for @orgMember.
  ///
  /// In en, this message translates to:
  /// **'Team member'**
  String get orgMember;

  /// No description provided for @orgAssignmentRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke this project assignment? The member will lose access to this project.'**
  String get orgAssignmentRevokeConfirm;

  /// No description provided for @orgNoAssignmentOptions.
  ///
  /// In en, this message translates to:
  /// **'A project and an organisation member are needed before assigning access.'**
  String get orgNoAssignmentOptions;

  /// No description provided for @orgFaqs.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get orgFaqs;

  /// No description provided for @orgSearchFaqs.
  ///
  /// In en, this message translates to:
  /// **'Search questions and answers'**
  String get orgSearchFaqs;

  /// No description provided for @orgExtractReceipt.
  ///
  /// In en, this message translates to:
  /// **'Read receipt (PDF or image, up to 10 MB)'**
  String get orgExtractReceipt;

  /// No description provided for @orgReviewExtraction.
  ///
  /// In en, this message translates to:
  /// **'Review the extracted details before saving.'**
  String get orgReviewExtraction;

  /// No description provided for @orgRetryReceipt.
  ///
  /// In en, this message translates to:
  /// **'Expense saved. Retry attaching receipt'**
  String get orgRetryReceipt;

  /// No description provided for @orgAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add expense item'**
  String get orgAddItem;

  /// No description provided for @orgRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get orgRemoveItem;

  /// No description provided for @orgApprovedBoq.
  ///
  /// In en, this message translates to:
  /// **'Approved BOQ'**
  String get orgApprovedBoq;

  /// No description provided for @orgNoBoqLink.
  ///
  /// In en, this message translates to:
  /// **'Not linked to a BOQ'**
  String get orgNoBoqLink;

  /// No description provided for @orgNoApprovedBoq.
  ///
  /// In en, this message translates to:
  /// **'This project has no approved BOQ. The expense will be recorded without a BOQ link.'**
  String get orgNoApprovedBoq;

  /// No description provided for @orgBoqItem.
  ///
  /// In en, this message translates to:
  /// **'BOQ item'**
  String get orgBoqItem;

  /// No description provided for @orgNoBoqItem.
  ///
  /// In en, this message translates to:
  /// **'Not linked to a BOQ item'**
  String get orgNoBoqItem;

  /// No description provided for @orgShareToken.
  ///
  /// In en, this message translates to:
  /// **'Share token'**
  String get orgShareToken;

  /// No description provided for @orgExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses & receipts'**
  String get orgExpenses;

  /// No description provided for @orgInvitations.
  ///
  /// In en, this message translates to:
  /// **'Team invitations'**
  String get orgInvitations;

  /// No description provided for @orgAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Record expense'**
  String get orgAddExpense;

  /// No description provided for @orgEditExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get orgEditExpense;

  /// No description provided for @orgSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get orgSave;

  /// No description provided for @orgProject.
  ///
  /// In en, this message translates to:
  /// **'Assigned project'**
  String get orgProject;

  /// No description provided for @orgPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get orgPurchaseDate;

  /// No description provided for @orgSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get orgSupplier;

  /// No description provided for @orgDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get orgDescription;

  /// No description provided for @orgQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get orgQuantity;

  /// No description provided for @orgUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get orgUnit;

  /// No description provided for @orgRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get orgRate;

  /// No description provided for @orgPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get orgPaymentMethod;

  /// No description provided for @orgPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned purchase'**
  String get orgPlanned;

  /// No description provided for @orgExplanation.
  ///
  /// In en, this message translates to:
  /// **'Reason for unplanned purchase'**
  String get orgExplanation;

  /// No description provided for @orgRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value.'**
  String get orgRequired;

  /// No description provided for @orgNoProjects.
  ///
  /// In en, this message translates to:
  /// **'No assigned projects are available. Ask your administrator for a project assignment.'**
  String get orgNoProjects;

  /// No description provided for @orgEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records found.'**
  String get orgEmpty;

  /// No description provided for @orgPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get orgPrevious;

  /// No description provided for @orgNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get orgNext;

  /// No description provided for @orgReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get orgReceipts;

  /// No description provided for @orgAddReceipt.
  ///
  /// In en, this message translates to:
  /// **'Attach receipt (PDF or image, up to 20 MB)'**
  String get orgAddReceipt;

  /// No description provided for @orgInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite team member'**
  String get orgInvite;

  /// No description provided for @orgAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get orgAccept;

  /// No description provided for @orgToken.
  ///
  /// In en, this message translates to:
  /// **'Invitation token'**
  String get orgToken;

  /// No description provided for @orgRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get orgRole;

  /// No description provided for @orgExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expires at'**
  String get orgExpiry;

  /// No description provided for @orgEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get orgEdit;

  /// No description provided for @orgRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get orgRevoke;

  /// No description provided for @orgRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Revoke this invitation? It can no longer be accepted.'**
  String get orgRevokeConfirm;

  /// No description provided for @orgPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orgPending;

  /// No description provided for @orgAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get orgAccepted;

  /// No description provided for @orgRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get orgRevoked;

  /// No description provided for @orgExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get orgExpired;

  /// No description provided for @orgTokenHelp.
  ///
  /// In en, this message translates to:
  /// **'Share this token securely with the invited email address. It is shown only once.'**
  String get orgTokenHelp;

  /// No description provided for @orgCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy token'**
  String get orgCopy;

  /// No description provided for @orgAcceptSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted. Your organisation access has been updated.'**
  String get orgAcceptSuccess;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BOQ Works'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

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

  /// No description provided for @getPrices.
  ///
  /// In en, this message translates to:
  /// **'Get Prices'**
  String get getPrices;

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
  /// **'Excel, CSV, PDF and photos, converted automatically'**
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

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

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

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @signUpDescription.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start managing your projects and BOQs.'**
  String get signUpDescription;

  /// No description provided for @organisationName.
  ///
  /// In en, this message translates to:
  /// **'Organisation name (optional)'**
  String get organisationName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @resetPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you a link to reset your password.'**
  String get resetPasswordDescription;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, a password reset link has been sent. Check your inbox.'**
  String get resetEmailSent;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

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

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

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

  /// No description provided for @proxySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Proxy Subscriptions'**
  String get proxySubscriptions;

  /// No description provided for @beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get beneficiary;

  /// No description provided for @beneficiaryEmail.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary Email'**
  String get beneficiaryEmail;

  /// No description provided for @payer.
  ///
  /// In en, this message translates to:
  /// **'Payer'**
  String get payer;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @noProxySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No proxy subscriptions found'**
  String get noProxySubscriptions;

  /// No description provided for @noProxySubscriptionsDescription.
  ///
  /// In en, this message translates to:
  /// **'There are no proxy subscriptions matching your filters.'**
  String get noProxySubscriptionsDescription;

  /// No description provided for @proxySubscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Proxy Subscription Details'**
  String get proxySubscriptionDetails;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin Access Required'**
  String get adminAccessRequired;

  /// No description provided for @adminAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'This page is only accessible to administrators.'**
  String get adminAccessDescription;

  /// No description provided for @useBiometricToLogin.
  ///
  /// In en, this message translates to:
  /// **'Login with Biometric'**
  String get useBiometricToLogin;

  /// No description provided for @biometricPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Login'**
  String get biometricPromptTitle;

  /// No description provided for @biometricPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Would you like to enable biometric login for faster access?'**
  String get biometricPromptMessage;

  /// No description provided for @biometricPromptEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get biometricPromptEnable;

  /// No description provided for @biometricPromptCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get biometricPromptCancel;

  /// No description provided for @enableBiometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Login'**
  String get enableBiometricLogin;

  /// No description provided for @biometricLoginDescription.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face recognition to sign in quickly'**
  String get biometricLoginDescription;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device'**
  String get biometricNotAvailable;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login disabled'**
  String get biometricDisabled;

  /// No description provided for @biometricError.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed. Please try again.'**
  String get biometricError;

  /// No description provided for @biometricAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric available'**
  String get biometricAvailable;

  /// No description provided for @biometricTypes.
  ///
  /// In en, this message translates to:
  /// **'Available: '**
  String get biometricTypes;

  /// No description provided for @deleteBoq.
  ///
  /// In en, this message translates to:
  /// **'Delete BOQ'**
  String get deleteBoq;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelected;

  /// No description provided for @selectBoqs.
  ///
  /// In en, this message translates to:
  /// **'Select BOQs'**
  String get selectBoqs;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selectedCount;

  /// No description provided for @locationHistory.
  ///
  /// In en, this message translates to:
  /// **'Location History'**
  String get locationHistory;

  /// No description provided for @recentLocations.
  ///
  /// In en, this message translates to:
  /// **'Recent Locations'**
  String get recentLocations;

  /// No description provided for @topSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Top Suppliers'**
  String get topSuppliers;

  /// No description provided for @oneTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For occasional BOQ preparation'**
  String get oneTimeSubtitle;

  /// No description provided for @oneTimeBadge.
  ///
  /// In en, this message translates to:
  /// **'One-Time'**
  String get oneTimeBadge;

  /// No description provided for @buyOneTimeAccess.
  ///
  /// In en, this message translates to:
  /// **'Buy One-Time Access'**
  String get buyOneTimeAccess;

  /// No description provided for @selectPlan.
  ///
  /// In en, this message translates to:
  /// **'Select plan'**
  String get selectPlan;

  /// No description provided for @validityHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String validityHours(int hours);

  /// No description provided for @validityDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String validityDays(int days);

  /// No description provided for @maxProjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 project} other{{count} projects}}'**
  String maxProjectsLabel(int count);

  /// No description provided for @maxBoqsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 BOQ} other{{count} BOQs}}'**
  String maxBoqsLabel(int count);

  /// No description provided for @maxAiCreditsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 AI credit} other{{count} AI credits}}'**
  String maxAiCreditsLabel(int count);

  /// No description provided for @featureHardwareFactoryPrices.
  ///
  /// In en, this message translates to:
  /// **'Current Hardware & Factory prices'**
  String get featureHardwareFactoryPrices;

  /// No description provided for @featureLimitedAiCredits.
  ///
  /// In en, this message translates to:
  /// **'Limited AI credits'**
  String get featureLimitedAiCredits;

  /// No description provided for @featurePdfExcelExport.
  ///
  /// In en, this message translates to:
  /// **'PDF & Excel export'**
  String get featurePdfExcelExport;

  /// No description provided for @featureCompanyBranding.
  ///
  /// In en, this message translates to:
  /// **'Company branding'**
  String get featureCompanyBranding;

  /// No description provided for @noRecurringPayment.
  ///
  /// In en, this message translates to:
  /// **'No recurring payment'**
  String get noRecurringPayment;

  /// No description provided for @renewsAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically'**
  String get renewsAutomatically;

  /// No description provided for @confirmPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm purchase'**
  String get confirmPurchaseTitle;

  /// No description provided for @confirmPurchaseMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a pending subscription for {planName}? Your plan becomes active only after payment is confirmed.'**
  String confirmPurchaseMessage(String planName);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @buyAnotherOneTimeAccess.
  ///
  /// In en, this message translates to:
  /// **'Buy Another One-Time Access'**
  String get buyAnotherOneTimeAccess;

  /// No description provided for @renewAccess.
  ///
  /// In en, this message translates to:
  /// **'Renew Access'**
  String get renewAccess;

  /// No description provided for @upgradeToSubscription.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to a Subscription'**
  String get upgradeToSubscription;

  /// No description provided for @errorOneTimeProjectLimit.
  ///
  /// In en, this message translates to:
  /// **'You have reached the project limit of your One-Time Access. Buy another One-Time Access or upgrade to a subscription.'**
  String get errorOneTimeProjectLimit;

  /// No description provided for @errorOneTimeBoqLimit.
  ///
  /// In en, this message translates to:
  /// **'You have reached the BOQ limit of your One-Time Access. Buy another One-Time Access or upgrade to a subscription.'**
  String get errorOneTimeBoqLimit;

  /// No description provided for @errorAiCreditsExhausted.
  ///
  /// In en, this message translates to:
  /// **'Your AI credits are exhausted. Buy another One-Time Access or upgrade to a subscription.'**
  String get errorAiCreditsExhausted;

  /// No description provided for @errorOcrLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached the OCR page limit of your One-Time Access. Buy another One-Time Access or upgrade to a subscription.'**
  String get errorOcrLimitReached;

  /// No description provided for @errorOneTimeAccessExpired.
  ///
  /// In en, this message translates to:
  /// **'Your One-Time Access has expired. Renew access or upgrade to a subscription.'**
  String get errorOneTimeAccessExpired;
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
