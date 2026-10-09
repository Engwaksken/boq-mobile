// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get orgManageFaqs => 'Manage FAQs (super admin)';

  @override
  String get orgQuestion => 'Question';

  @override
  String get orgAnswer => 'Answer';

  @override
  String get orgSortOrder => 'Sort order';

  @override
  String get orgFaqActive => 'Published';

  @override
  String get orgSearchExpenses => 'Search description or supplier';

  @override
  String get orgAllProjects => 'All projects';

  @override
  String get orgAssignments => 'Project assignments';

  @override
  String get orgAssign => 'Assign team member';

  @override
  String get orgMember => 'Team member';

  @override
  String get orgAssignmentRevokeConfirm =>
      'Remove this project assignment? The member will lose access to this project.';

  @override
  String get orgNoAssignmentOptions =>
      'A project and an organisation member are needed before assigning access.';

  @override
  String get orgFaqs => 'Frequently asked questions';

  @override
  String get orgSearchFaqs => 'Search questions and answers';

  @override
  String get orgExtractReceipt => 'Read receipt (PDF or image, up to 10 MB)';

  @override
  String get orgReviewExtraction =>
      'Review the extracted details before saving.';

  @override
  String get orgRetryReceipt => 'Expense saved. Retry attaching receipt';

  @override
  String get orgAddItem => 'Add expense item';

  @override
  String get orgRemoveItem => 'Remove item';

  @override
  String get orgApprovedBoq => 'Approved BOQ';

  @override
  String get orgNoBoqLink => 'Not linked to a BOQ';

  @override
  String get orgNoApprovedBoq =>
      'This project has no approved BOQ. The expense will be recorded without a BOQ link.';

  @override
  String get orgBoqItem => 'BOQ item';

  @override
  String get orgNoBoqItem => 'Not linked to a BOQ item';

  @override
  String get orgShareToken => 'Share token';

  @override
  String get orgExpenses => 'Expenses & receipts';

  @override
  String get orgInvitations => 'Team invitations';

  @override
  String get orgAddExpense => 'Record expense';

  @override
  String get orgEditExpense => 'Edit expense';

  @override
  String get orgSave => 'Save';

  @override
  String get orgProject => 'Assigned project';

  @override
  String get orgPurchaseDate => 'Purchase date';

  @override
  String get orgSupplier => 'Supplier';

  @override
  String get orgDescription => 'Description';

  @override
  String get orgQuantity => 'Quantity';

  @override
  String get orgUnit => 'Unit';

  @override
  String get orgRate => 'Rate';

  @override
  String get orgPaymentMethod => 'Payment method';

  @override
  String get orgPlanned => 'Planned purchase';

  @override
  String get orgExplanation => 'Reason for unplanned purchase';

  @override
  String get orgRequired => 'Enter a valid value.';

  @override
  String get orgNoProjects =>
      'No assigned projects are available. Ask your administrator for a project assignment.';

  @override
  String get orgEmpty => 'No records found.';

  @override
  String get orgPrevious => 'Previous';

  @override
  String get orgNext => 'Next';

  @override
  String get orgReceipts => 'Receipts';

  @override
  String get orgAddReceipt => 'Attach receipt (PDF or image, up to 20 MB)';

  @override
  String get orgInvite => 'Invite team member';

  @override
  String get orgAccept => 'Accept invitation';

  @override
  String get orgToken => 'Invitation token';

  @override
  String get orgRole => 'Role';

  @override
  String get orgExpiry => 'Expires at';

  @override
  String get orgEdit => 'Edit';

  @override
  String get orgRevoke => 'Remove';

  @override
  String get orgRevokeConfirm =>
      'Remove this invitation? It can no longer be accepted.';

  @override
  String get orgPending => 'Pending';

  @override
  String get orgAccepted => 'Accepted';

  @override
  String get orgRevoked => 'Removed';

  @override
  String get orgExpired => 'Expired';

  @override
  String get orgTokenHelp =>
      'Share this token securely with the invited email address. It is shown only once.';

  @override
  String get orgCopy => 'Copy token';

  @override
  String get orgAcceptSuccess =>
      'Invitation accepted. Your organisation access has been updated.';

  @override
  String get appTitle => 'BOQ Works';

  @override
  String get home => 'Home';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get projects => 'Projects';

  @override
  String get hardwarePrices => 'Hardware Prices';

  @override
  String get getPrices => 'Get Prices';

  @override
  String get importBoq => 'Import BOQ';

  @override
  String get account => 'Account';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get overview => 'Here is your project cost overview.';

  @override
  String get totalProjects => 'Total projects';

  @override
  String get activeProjects => 'Active projects';

  @override
  String get boqsInReview => 'BOQs in review';

  @override
  String get estimatedValue => 'Estimated value';

  @override
  String get recentProjects => 'Recent projects';

  @override
  String get viewAll => 'View all';

  @override
  String get noProjects => 'No projects yet';

  @override
  String get createProject => 'Create project';

  @override
  String get importTitle => 'Bring in your BOQ';

  @override
  String get importDescription =>
      'Upload an Excel or PDF BOQ, or scan pages from site. You will review the extracted structure before it is saved.';

  @override
  String get uploadDocument => 'Upload document';

  @override
  String get scanPages => 'Scan pages';

  @override
  String get supportedFiles =>
      'Excel, CSV, PDF and photos, converted automatically';

  @override
  String get subscription => 'Subscription';

  @override
  String get annualProfessional => 'Annual Professional';

  @override
  String get active => 'Active';

  @override
  String get renewsOn => 'Renews on 31 December 2026';

  @override
  String get aiCredits => 'AI credits';

  @override
  String get ocrPages => 'OCR pages';

  @override
  String get managePlan => 'Manage plan';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get luganda => 'Luganda';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get profile => 'Profile';

  @override
  String get signOut => 'Sign out';

  @override
  String get usage => 'Usage';

  @override
  String get viewSubscription => 'View subscription';

  @override
  String get projectStatusActive => 'Active';

  @override
  String get projectStatusPlanning => 'Planning';

  @override
  String get signIn => 'Sign in';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get signInDescription =>
      'Sign in to manage your civil works projects and BOQs.';

  @override
  String get signInFailed =>
      'Unable to sign in. Check your details and try again.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get signUpDescription =>
      'Create an account to start managing your projects and BOQs.';

  @override
  String get organisationName => 'Organisation name (optional)';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters.';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get createAccount => 'Create account';

  @override
  String get resetPasswordDescription =>
      'Enter your email address and we will send you a link to reset your password.';

  @override
  String get resetEmailSent =>
      'If an account exists for that email, a password reset link has been sent. Check your inbox.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get loadingDashboard => 'Loading your dashboard...';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get fullName => 'Full name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get location => 'Location';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordHint => 'Leave blank to keep your current password';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get projectCode => 'Project code';

  @override
  String get currency => 'Currency';

  @override
  String get projectCreated => 'Project created';

  @override
  String get draft => 'Draft';

  @override
  String get boqs => 'BOQs';

  @override
  String get imported => 'BOQ uploaded';

  @override
  String get priceComparison => 'Price Comparison';

  @override
  String get bestRecommendations => 'Best Recommendations';

  @override
  String get itemsTracked => 'Items Tracked';

  @override
  String get pricesUpdatedToday => 'Prices Updated Today';

  @override
  String get averagePriceChange => 'Avg Price Change';

  @override
  String get suppliersTracked => 'Suppliers Tracked';

  @override
  String get lowestPriceOpportunities => 'Lowest Price Opportunities';

  @override
  String get boqItemsWithUpdatedPrices => 'BOQ Items with Updated Prices';

  @override
  String get proxySubscriptions => 'Proxy Subscriptions';

  @override
  String get beneficiary => 'Beneficiary';

  @override
  String get beneficiaryEmail => 'Beneficiary Email';

  @override
  String get payer => 'Payer';

  @override
  String get plan => 'Plan';

  @override
  String get status => 'Status';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get createdAt => 'Created At';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get search => 'Search';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get statusActive => 'Active';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusExpired => 'Expired';

  @override
  String get noProxySubscriptions => 'No proxy subscriptions found';

  @override
  String get noProxySubscriptionsDescription =>
      'There are no proxy subscriptions matching your filters.';

  @override
  String get proxySubscriptionDetails => 'Proxy Subscription Details';

  @override
  String get adminAccessRequired => 'Admin Access Required';

  @override
  String get adminAccessDescription =>
      'This page is only accessible to administrators.';

  @override
  String get useBiometricToLogin => 'Login with Biometric';

  @override
  String get biometricPromptTitle => 'Enable Biometric Login';

  @override
  String get biometricPromptMessage =>
      'Would you like to enable biometric login for faster access?';

  @override
  String get biometricPromptEnable => 'Enable';

  @override
  String get biometricPromptCancel => 'Cancel';

  @override
  String get enableBiometricLogin => 'Enable Biometric Login';

  @override
  String get biometricLoginDescription =>
      'Use fingerprint or face recognition to sign in quickly';

  @override
  String get biometricNotAvailable =>
      'Biometric authentication is not available on this device';

  @override
  String get biometricEnabled => 'Biometric login enabled';

  @override
  String get biometricDisabled => 'Biometric login disabled';

  @override
  String get biometricError =>
      'Biometric authentication failed. Please try again.';

  @override
  String get biometricAvailable => 'Biometric available';

  @override
  String get biometricTypes => 'Available: ';

  @override
  String get deleteBoq => 'Delete BOQ';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String get selectBoqs => 'Select BOQs';

  @override
  String get selectedCount => 'selected';

  @override
  String get locationHistory => 'Location History';

  @override
  String get recentLocations => 'Recent Locations';

  @override
  String get topSuppliers => 'Top Suppliers';

  @override
  String get oneTimeSubtitle => 'For occasional BOQ preparation';

  @override
  String get oneTimeBadge => 'One-Time';

  @override
  String get buyOneTimeAccess => 'Buy One-Time Access';

  @override
  String get selectPlan => 'Select plan';

  @override
  String validityHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String validityDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String maxProjectsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projects',
      one: '1 project',
    );
    return '$_temp0';
  }

  @override
  String maxBoqsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count BOQs',
      one: '1 BOQ',
    );
    return '$_temp0';
  }

  @override
  String maxAiCreditsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count AI credits',
      one: '1 AI credit',
    );
    return '$_temp0';
  }

  @override
  String get featureHardwareFactoryPrices =>
      'Current Hardware & Factory prices';

  @override
  String get featureLimitedAiCredits => 'Limited AI credits';

  @override
  String get featurePdfExcelExport => 'PDF & Excel export';

  @override
  String get featureCompanyBranding => 'Company branding';

  @override
  String get noRecurringPayment => 'No recurring payment';

  @override
  String get renewsAutomatically => 'Renews automatically';

  @override
  String get confirmPurchaseTitle => 'Confirm purchase';

  @override
  String confirmPurchaseMessage(String planName) {
    return 'Create a pending subscription for $planName? Your plan becomes active only after payment is confirmed.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get continueAction => 'Continue';

  @override
  String get buyAnotherOneTimeAccess => 'Buy Another One-Time Access';

  @override
  String get renewAccess => 'Renew Access';

  @override
  String get upgradeToSubscription => 'Upgrade to a Subscription';

  @override
  String get errorOneTimeProjectLimit =>
      'You have reached the project limit of your One-Time Access. Buy another One-Time Access or upgrade to a subscription.';

  @override
  String get errorOneTimeBoqLimit =>
      'You have reached the BOQ limit of your One-Time Access. Buy another One-Time Access or upgrade to a subscription.';

  @override
  String get errorAiCreditsExhausted =>
      'Your AI credits are exhausted. Buy another One-Time Access or upgrade to a subscription.';

  @override
  String get errorOcrLimitReached =>
      'You have reached the OCR page limit of your One-Time Access. Buy another One-Time Access or upgrade to a subscription.';

  @override
  String get errorOneTimeAccessExpired =>
      'Your One-Time Access has expired. Renew access or upgrade to a subscription.';
}
