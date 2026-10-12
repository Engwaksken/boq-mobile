// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hwAllPrices => 'All Prices';

  @override
  String get hwCategories => 'Categories';

  @override
  String get hwMoreActions => 'More actions';

  @override
  String get hwFetchLatestPrices => 'Fetch Latest Prices';

  @override
  String hwSelectedAddMore(int count) {
    return '$count selected · add one more to compare';
  }

  @override
  String hwItemsSelected(int count) {
    return '$count items selected';
  }

  @override
  String get hwClear => 'Clear';

  @override
  String get hwCompare => 'Compare';

  @override
  String hwPageOf(int page, int last) {
    return 'Page $page of $last';
  }

  @override
  String get hwPreviousPage => 'Previous page';

  @override
  String get hwNextPage => 'Next page';

  @override
  String get hwNoCategories => 'No categories loaded';

  @override
  String get hwLoadCategories => 'Load categories';

  @override
  String get hwAllCategories => 'All categories';

  @override
  String hwItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get hwAll => 'All';

  @override
  String get hwSupplier => 'Supplier';

  @override
  String get hwFactory => 'Factory';

  @override
  String get hwClearSearch => 'Clear search';

  @override
  String get hwCategory => 'Category';

  @override
  String get hwRegion => 'Region';

  @override
  String get hwNoPrices => 'No hardware prices found';

  @override
  String get hwAdjustFilters => 'Try adjusting your filters';

  @override
  String get hwCompareMax => 'Maximum 5 items for comparison';

  @override
  String get hwAlreadyCompared => 'Already in the comparison';

  @override
  String hwAddedToComparison(int count) {
    return 'Added to comparison ($count/5)';
  }

  @override
  String hwFilterTooltip(String label) {
    return '$label filter';
  }

  @override
  String get hwMoreOptions => 'More options';

  @override
  String hwVerifiedOn(String date) {
    return 'Verified: $date';
  }

  @override
  String hwUpdatedOn(String date) {
    return 'Updated: $date';
  }

  @override
  String get hwSource => 'Source';

  @override
  String get hwPriceHistory => 'Price History';

  @override
  String get hwCurrent => 'Current';

  @override
  String get hwLowest => 'Lowest';

  @override
  String get hwHighest => 'Highest';

  @override
  String get hwAverage => 'Average';

  @override
  String get hwChange => 'Change';

  @override
  String get hwDetails => 'Details';

  @override
  String get hwBrand => 'Brand';

  @override
  String get hwSpec => 'Spec';

  @override
  String get hwUnit => 'Unit';

  @override
  String hwPriceHistoryCount(int count) {
    return 'Price History ($count records)';
  }

  @override
  String get hwNoHistory => 'No history available';

  @override
  String hwItemPriceHistory(String item) {
    return '$item - Price History';
  }

  @override
  String get hwNoComparison => 'No comparison data';

  @override
  String hwPricesCompared(int count) {
    return '$count prices compared';
  }

  @override
  String get hwYouSave => 'You save';

  @override
  String get hwBestChoice => 'Best choice';

  @override
  String get hwSpecification => 'Specification';

  @override
  String get hwPrice => 'Price';

  @override
  String get hwUpdated => 'Updated';

  @override
  String get hwVsLowest => 'vs lowest';

  @override
  String get hwTrend => 'Trend';

  @override
  String get hwRecords => 'Records';

  @override
  String get hwRating => 'Rating';

  @override
  String get hwValueScore => 'Value Score';

  @override
  String get hwStability => 'Stability';

  @override
  String get hwFreshness => 'Freshness';

  @override
  String get hwNoRecommendations => 'No recommendations available';

  @override
  String hwRatingSemantics(int rating) {
    return 'Rating $rating';
  }

  @override
  String get hwValue => 'Value';

  @override
  String get ratingThisWeek => 'This week';

  @override
  String get ratingThisMonth => 'This month';

  @override
  String get ratingThisYear => 'This year';

  @override
  String get ratingAllTime => 'All time';

  @override
  String get ratingHardware => 'Hardware';

  @override
  String get ratingFactories => 'Factories';

  @override
  String ratingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
    );
    return '$_temp0';
  }

  @override
  String get ratingRankings => 'Rankings';

  @override
  String get ratingCharts => 'Charts';

  @override
  String get ratingMyRatings => 'My ratings';

  @override
  String get ratingRateSupplier => 'Rate a Supplier';

  @override
  String get ratingRankingsIntro =>
      'Ratings of hardware suppliers and factories by users. Rate the ones you buy from to reward good prices and service.';

  @override
  String get ratingLowestRated => 'Lowest rated';

  @override
  String get ratingHardwareNeedsImprovement => 'Hardware needing improvement';

  @override
  String get ratingTopHardware => 'Top 10 Hardware';

  @override
  String get ratingFactoriesNeedImprovement => 'Factories needing improvement';

  @override
  String get ratingTopFactories => 'Top 10 Factories';

  @override
  String get ratingWeightedNote =>
      'Rankings use a weighted score: a supplier needs several good ratings to rank above one with many, so a single 5-star rating does not top the list.';

  @override
  String get ratingRatings => 'Ratings';

  @override
  String get ratingAverage => 'Average rating';

  @override
  String get ratingSuppliersRated => 'Suppliers rated';

  @override
  String get ratingTopHardwareChart => 'Top hardware · average rating';

  @override
  String get ratingLowestHardwareChart =>
      'Lowest rated hardware · average rating';

  @override
  String get ratingTopFactoriesChart => 'Top factories · average rating';

  @override
  String get ratingLowestFactoriesChart =>
      'Lowest rated factories · average rating';

  @override
  String get ratingDistribution => 'Rating distribution';

  @override
  String get ratingByType => 'Ratings by type';

  @override
  String get ratingScoresByArea => 'Scores by area';

  @override
  String get ratingNoScoresPeriod => 'No detailed scores in this period yet.';

  @override
  String get ratingMonthlyTrend => 'Monthly trend';

  @override
  String get ratingLast12Months => 'Last 12 months';

  @override
  String get ratingNoneYet => 'You have not rated any supplier yet.';

  @override
  String get ratingNoneYetHelp =>
      'Rate the hardware shops and factories you buy from. You can rate each one again every month.';

  @override
  String get ratingNonePeriod => 'No ratings in this period yet.';

  @override
  String get ratingBeFirst => 'Be the first to rate one.';

  @override
  String ratingRank(int rank) {
    return 'Rank $rank';
  }

  @override
  String ratingOutOfFive(String value) {
    return '$value out of 5 stars';
  }

  @override
  String ratingStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get ratingPrice => 'Price';

  @override
  String get ratingQuality => 'Quality';

  @override
  String get ratingDelivery => 'Delivery';

  @override
  String get ratingService => 'Service';

  @override
  String get ratingRatingsLower => 'ratings';

  @override
  String get ratingHardwareAverage => 'Hardware average';

  @override
  String get ratingFactoryAverage => 'Factory average';

  @override
  String get ratingNoneLast12 => 'No ratings in the last 12 months.';

  @override
  String get ratingPerMonth => 'Ratings per month';

  @override
  String get ratingWebsiteFailed => 'Could not open the website.';

  @override
  String get ratingNotRatedPeriod => 'Not rated in this period';

  @override
  String ratingRankOfFactories(int rank, int total) {
    return 'Rank $rank of $total factories';
  }

  @override
  String ratingRankOfShops(int rank, int total) {
    return 'Rank $rank of $total hardware shops';
  }

  @override
  String get ratingRate => 'Rate';

  @override
  String get ratingRateAgain => 'Rate again';

  @override
  String get ratingWebsite => 'Website';

  @override
  String get ratingNoScores => 'No detailed scores yet.';

  @override
  String get ratingRecentReviews => 'Recent reviews';

  @override
  String get ratingNoReviews => 'No reviews yet.';

  @override
  String get ratingVerifiedUser => 'Verified user';

  @override
  String get ratingHidden => 'Hidden';

  @override
  String get ratingChooseOverall =>
      'Choose an overall rating from 1 to 5 stars.';

  @override
  String get ratingOncePerMonth =>
      'You can rate each supplier once a month; rating again in the same month updates your rating.';

  @override
  String get ratingHardwareOrFactory => 'Hardware or factory';

  @override
  String get ratingSearchHint => 'Search by name or location...';

  @override
  String get ratingNoMatches =>
      'No active hardware or factory matches your search.';

  @override
  String get ratingOverallRequired => 'Overall rating *';

  @override
  String get ratingScoresOptional =>
      'Scores by area (optional, tap a chosen star again to clear)';

  @override
  String get ratingComment => 'Comment';

  @override
  String get ratingCommentHint =>
      'What was good, and what could be better? (prices, stock, delivery, service)';

  @override
  String get ratingUpdate => 'Update Rating';

  @override
  String get ratingSave => 'Save Rating';

  @override
  String get projNoMatching => 'No matching projects';

  @override
  String get projTypeSheetTitle => 'Project type';

  @override
  String get projProjectType => 'Project Type';

  @override
  String get projTypeHint => 'Choose or type a project type';

  @override
  String get projChooseType => 'Choose a project type';

  @override
  String get projStatusCompleted => 'Completed';

  @override
  String get projStatusArchived => 'Archived';

  @override
  String get projRequired => 'Required';

  @override
  String get projBasicDetails => 'Basic details';

  @override
  String get projNameRequired => 'Project Name *';

  @override
  String get projDescription => 'Description';

  @override
  String get projParties => 'Parties';

  @override
  String get projClient => 'Client';

  @override
  String get projContractor => 'Contractor';

  @override
  String get projConsultant => 'Consultant';

  @override
  String get projQuantitySurveyor => 'Quantity Surveyor';

  @override
  String get projProjectManager => 'Project Manager';

  @override
  String get projSiteEngineer => 'Site Engineer';

  @override
  String get projFundingOrganisation => 'Funding Organisation';

  @override
  String get projCountry => 'Country';

  @override
  String get projDistrict => 'District';

  @override
  String get projDatesValue => 'Dates & value';

  @override
  String get projExpectedCompletionDate => 'Expected Completion Date';

  @override
  String get projContractValue => 'Contract Value';

  @override
  String get projLanguages => 'Languages';

  @override
  String get projOriginalLanguage => 'Original Language';

  @override
  String get projReportLanguage => 'Report Language';

  @override
  String pdItemsCreated(int count) {
    return '$count BOQ items created';
  }

  @override
  String get pdPreparingPrices => 'Preparing to fetch prices...';

  @override
  String pdFetchingProgress(int done, int total, String description) {
    return 'Fetching $done/$total: $description';
  }

  @override
  String get pdGeneratingPrices => 'Generating BOQ prices';

  @override
  String pdGeneratedAll(int count) {
    return 'Generated prices for $count items';
  }

  @override
  String pdGeneratedPartial(int priced, int total, int failed) {
    return 'Generated $priced of $total ($failed failed)';
  }

  @override
  String get pdTitle => 'Project Details';

  @override
  String get pdActions => 'Project actions';

  @override
  String get pdDeleteTitle => 'Delete Project';

  @override
  String get pdDeleteConfirm =>
      'Are you sure you want to delete this project? This action cannot be undone.';

  @override
  String get pdDelete => 'Delete';

  @override
  String get pdDeleted => 'Project deleted';

  @override
  String pdCode(String code) {
    return 'Code: $code';
  }

  @override
  String get pdOverview => 'Overview';

  @override
  String get pdOwner => 'Owner';

  @override
  String get pdDates => 'Dates';

  @override
  String get pdExpectedCompletion => 'Expected Completion';

  @override
  String get pdProjectTotals => 'Project totals';

  @override
  String get pdNoBoqs => 'No BOQs yet';

  @override
  String get pdGenerateBoq => 'Generate BOQ';

  @override
  String get pdUpdated => 'Project updated';

  @override
  String get pdEditTitle => 'Edit Project';

  @override
  String get pdLoadingItems => 'Loading BOQ items...';

  @override
  String get pdNoItemsToPrice => 'No BOQ items found to price';

  @override
  String get pdLoadItemsFailed => 'Failed to load BOQ items';

  @override
  String pdFetchedAll(int count) {
    return 'Fetched prices for $count items';
  }

  @override
  String pdFetchedPartial(int priced, int total, int failed) {
    return 'Fetched $priced of $total items ($failed failed)';
  }

  @override
  String pdRetrying(int count) {
    return 'Retrying $count failed items...';
  }

  @override
  String get pdViewHierarchy => 'View Hierarchy';

  @override
  String get pdOverallCost => 'Overall BOQ Cost';

  @override
  String get pdSelectLocation => 'Select location';

  @override
  String pdProgress(String progress) {
    return 'Progress: $progress';
  }

  @override
  String get pdReviewPrices => 'Review prices';

  @override
  String get pdLocationPrices => 'Location prices';

  @override
  String pdItemsNotPriced(int count) {
    return '$count item(s) could not be priced:';
  }

  @override
  String get pdRetryFailed => 'Retry failed items';

  @override
  String get pdCompareLocations => 'Compare saved locations';

  @override
  String get pdPricingHistory => 'Pricing History';

  @override
  String get pdLoadHistory => 'Load History';

  @override
  String get pdNotAvailable => 'N/A';

  @override
  String get pdPdfShare => 'PDF & Share';

  @override
  String get pdUnknownLocation => 'Unknown location';

  @override
  String get pdLocationComparison => 'Location Price Comparison';

  @override
  String get pdNoSavedLocations => 'No saved location prices yet';

  @override
  String get pdSavedPricesByLocation => 'Saved prices by hardware and location';

  @override
  String get pdHardwareItem => 'Hardware item';

  @override
  String get pdLocationHelp =>
      'Prices depend on the location. Enter the town or district where the project will be built; it is saved to the project.';

  @override
  String get pdProjectLocation => 'Project location';

  @override
  String get pdProjectLocationHint => 'e.g. Kampala, Wakiso';

  @override
  String get pdEnterLocation => 'Enter the project location';

  @override
  String get orgFileUnreadable => 'Unable to read this file.';

  @override
  String get orgSelect => 'Select...';

  @override
  String get orgPayCash => 'Cash';

  @override
  String get orgPayMobileMoney => 'Mobile Money';

  @override
  String get orgPayBankTransfer => 'Bank Transfer';

  @override
  String get orgPayCheque => 'Cheque';

  @override
  String get orgPayCard => 'Card';

  @override
  String get orgPayCredit => 'Credit';

  @override
  String get orgPayOther => 'Other';

  @override
  String orgBoqNumber(int id) {
    return 'BOQ #$id';
  }

  @override
  String locUseTitle(String location) {
    return 'Use $location prices?';
  }

  @override
  String get locUseMessage =>
      'The BOQ\'s suggested prices switch to this location. Approved prices are kept.';

  @override
  String get locUsePrices => 'Use these prices';

  @override
  String locSwitched(int count, String location) {
    return '$count prices switched to $location';
  }

  @override
  String locCompareCount(int count) {
    return 'Compare $count';
  }

  @override
  String get locNone => 'No location prices yet';

  @override
  String get locNoneHelp =>
      'Get prices for a location on the BOQ screen; every location\'s prices are kept here.';

  @override
  String get locTickHint => 'Tick two to four locations to compare them.';

  @override
  String get locInUse => 'In use';

  @override
  String locItemsPriced(int priced, int total) {
    return '$priced of $total items priced';
  }

  @override
  String get locCompareTitle => 'Compare locations';

  @override
  String get locTotals => 'Totals';

  @override
  String locPricedLabel(String location, int count) {
    return '$location ($count priced)';
  }

  @override
  String get locLowestHint => 'Lowest price of each item in green.';

  @override
  String locItemsReviewed(int count) {
    return '$count item(s) reviewed';
  }

  @override
  String locItemsApproved(int count) {
    return '$count item(s) approved';
  }

  @override
  String locItemsRejected(int count) {
    return '$count item(s) rejected';
  }

  @override
  String locSkipped(String result, int count) {
    return '$result, $count skipped';
  }

  @override
  String locSelected(int count) {
    return '$count selected';
  }

  @override
  String get locClearSelection => 'Clear selection';

  @override
  String get locReview => 'Review';

  @override
  String get locApprove => 'Approve';

  @override
  String get locReject => 'Reject';

  @override
  String get locNoItems => 'No items to review';

  @override
  String get locSelectAll => 'Select all (not approved)';

  @override
  String locSuggested(String quantity, String rate) {
    return '$quantity · suggested $rate';
  }

  @override
  String get locRejectTitle => 'Reject selected prices';

  @override
  String get locReason => 'Reason';

  @override
  String get locReasonHint => 'e.g. Rates too high for this location';

  @override
  String get locEnterReason => 'Enter a reason';

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
  String get currentPassword => 'Current password';

  @override
  String get currentPasswordHint => 'Needed to change your email or password';

  @override
  String get currentPasswordRequired =>
      'Enter your current password to change your email or password.';

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

  @override
  String get acctNoActivePlan => 'No active plan';

  @override
  String acctTrialDays(int days) {
    return '$days-day trial';
  }

  @override
  String get acctExpiresToday => 'Expires today';

  @override
  String acctDaysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days remaining',
      one: '1 day remaining',
    );
    return '$_temp0';
  }

  @override
  String get acctSettings => 'Settings';

  @override
  String get acctCompanyProfile => 'Company Profile';

  @override
  String get acctCompanyProfileSubtitle =>
      'Logo and details used on your BOQ PDFs';

  @override
  String get acctPaymentConfirmedActive =>
      'Payment confirmed. Your subscription is now active.';

  @override
  String get acctSubscriptionUpdated => 'Subscription updated successfully.';

  @override
  String get acctPlansLoadError => 'Unable to load subscription plans.';

  @override
  String get acctNoPlans => 'No plans are currently available.';

  @override
  String get acctPaymentStarted =>
      'Payment started. Follow the instructions below, then verify the payment.';

  @override
  String get acctPaymentConfirmed => 'Payment confirmed';

  @override
  String get acctSubscriptionActivated =>
      'Your subscription has been activated successfully.';

  @override
  String get acctPaymentUnderReview =>
      'Payment submitted for review. Your plan will activate after confirmation.';

  @override
  String acctPaymentStatusValue(String status) {
    return 'Payment status: $status';
  }

  @override
  String get acctPaymentReceipt => 'Payment receipt';

  @override
  String get acctInvoice => 'Invoice';

  @override
  String get acctReference => 'Reference';

  @override
  String get acctAmount => 'Amount';

  @override
  String get acctPaid => 'Paid';

  @override
  String get acctProvider => 'Provider';

  @override
  String get acctPhone => 'Phone';

  @override
  String get acctMode => 'Mode';

  @override
  String get acctInstructions => 'Instructions';

  @override
  String get acctCheckoutUrl => 'Checkout URL';

  @override
  String get acctOpenCheckout => 'Open secure checkout';

  @override
  String get acctCopy => 'Copy';

  @override
  String get acctCheckoutOpenFailed =>
      'Unable to open checkout. You can copy the link instead.';

  @override
  String get acctCheckoutCopied => 'Checkout URL copied.';

  @override
  String get acctBankDetails => 'Bank details';

  @override
  String get acctPaymentInstructions => 'Payment instructions';

  @override
  String get acctSubscriptionPlan => 'Subscription plan';

  @override
  String get acctSubscriptionStatus => 'Subscription status';

  @override
  String get acctTransaction => 'Transaction';

  @override
  String get acctNotStarted => 'not started';

  @override
  String get acctCompletePayment => 'Complete payment';

  @override
  String get acctGatewaysLoadError => 'Unable to load payment methods.';

  @override
  String get acctPaymentActivationNote =>
      'Your plan is activated only after the server confirms a successful payment. Closing this screen does not delete the pending subscription.';

  @override
  String get acctNoGateways =>
      'No payment methods are currently enabled. Please contact the administrator.';

  @override
  String get acctChoosePaymentMethod => 'Choose payment method';

  @override
  String get acctAggregator => 'Aggregator';

  @override
  String get acctTestMode => 'Test mode';

  @override
  String get acctPaymentDetails => 'Payment details';

  @override
  String get acctMtnNumber => 'MTN MoMo number';

  @override
  String get acctAirtelNumber => 'Airtel Money number';

  @override
  String get acctMobileMoneyNumber => 'Mobile money number';

  @override
  String get acctPhoneHint => 'e.g. 0772 123 456';

  @override
  String get acctPaymentOption => 'Payment option';

  @override
  String get acctContinueToPayment => 'Continue to payment';

  @override
  String get acctRefreshStatus => 'Refresh status';

  @override
  String get acctVerifyPayment => 'Verify payment';

  @override
  String get acctAddPhoto => 'Add profile photo';

  @override
  String get acctChangePhoto => 'Change profile photo';

  @override
  String get acctPersonalDetails => 'Personal details';

  @override
  String get acctSecurity => 'Security';

  @override
  String get acctTakePhoto => 'Take photo';

  @override
  String get acctChooseGallery => 'Choose from gallery';

  @override
  String get acctRemovePhoto => 'Remove photo';

  @override
  String get acctPhotoRemoved => 'Profile photo removed';

  @override
  String get acctCameraDenied =>
      'The camera could not be opened. Allow camera access in Settings.';

  @override
  String get acctPhotosDenied =>
      'Your photos could not be opened. Allow photo access in Settings.';

  @override
  String get acctPhotoUploading => 'Uploading profile photo...';

  @override
  String get acctPhotoUpdated => 'Profile photo updated';

  @override
  String get acctNameRequired => 'Enter your full name.';

  @override
  String get commonInvalidEmail => 'Enter a valid email address.';

  @override
  String get authSignInNetworkError =>
      'Unable to sign in. Check your connection and try again.';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authAcceptTermsRequired =>
      'Please accept the Terms of Use and Privacy Policy.';

  @override
  String get authAccountCreated => 'Account created successfully.';

  @override
  String get authRegisterNetworkError =>
      'Unable to create your account. Check your connection and try again.';

  @override
  String get authAgreePrefix => 'I agree to the ';

  @override
  String get authAgreeAnd => ' and ';

  @override
  String get authResetNetworkError =>
      'Unable to send the reset link. Check your connection and try again.';

  @override
  String get authPasswordRequired => 'Enter your password.';

  @override
  String get bioFingerprint => 'Fingerprint';

  @override
  String get bioFace => 'Face Recognition';

  @override
  String get bioIris => 'Iris Scan';

  @override
  String get bioStrong => 'Strong Biometric';

  @override
  String get bioWeak => 'Weak Biometric';

  @override
  String get boqShareBoq => 'Share BOQ';

  @override
  String get boqUploadEstimates => 'Upload estimated prices';

  @override
  String get boqTemplate => 'Template';

  @override
  String boqCodeValue(String code) {
    return 'Code: $code';
  }

  @override
  String get boqNoSummaries => 'No summaries yet';

  @override
  String get boqNoSummariesMessage =>
      'Totals appear here once the BOQ items have been priced.';

  @override
  String get boqGrandTotal => 'Grand Total';

  @override
  String get boqSummary => 'Summary';

  @override
  String get boqSubtotal => 'Subtotal';

  @override
  String get boqVat18 => 'VAT (18%)';

  @override
  String get boqContingency5 => 'Contingency (5%)';

  @override
  String get boqBreakdown => 'Breakdown';

  @override
  String boqItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get boqVat => 'VAT';

  @override
  String get boqTotal => 'Total';

  @override
  String get boqImportMetadata => 'Import Metadata';

  @override
  String get boqSheets => 'Sheets';

  @override
  String boqSheetRows(String sheet, int rows) {
    return '$sheet ($rows rows)';
  }

  @override
  String get boqTranslations => 'Translations';

  @override
  String get boqStructure => 'BOQ Structure';

  @override
  String get boqNoHierarchy => 'No hierarchy data available';

  @override
  String get boqNoHierarchyMessage => 'Process the BOQ to generate structure.';

  @override
  String get boqQty => 'Qty';

  @override
  String get boqRate => 'Rate';

  @override
  String get boqAmount => 'Amount';

  @override
  String get boqItemDetails => 'BOQ Item Details';

  @override
  String get boqQuantityAmount => 'Quantity & amount';

  @override
  String get boqQuantity => 'Quantity';

  @override
  String get boqPricing => 'Pricing';

  @override
  String get boqOriginalRate => 'Original Rate';

  @override
  String get boqAiSuggestedRate => 'AI Suggested Rate';

  @override
  String boqAiRateValue(String rate, String confidence) {
    return '$rate (confidence: $confidence%)';
  }

  @override
  String get boqApprovedRate => 'Approved Rate';

  @override
  String get boqPricingSource => 'Pricing Source';

  @override
  String get boqPricingDate => 'Pricing Date';

  @override
  String get boqClassification => 'Classification';

  @override
  String get boqWorkCategory => 'Work Category';

  @override
  String get boqMaterialCategory => 'Material Category';

  @override
  String get boqNotes => 'Notes';

  @override
  String boqTranslationMeta(String provider, String confidence) {
    return 'Provider: $provider  |  Confidence: $confidence%';
  }

  @override
  String get boqUnknown => 'unknown';

  @override
  String get boqNoBoqsYet => 'No BOQs yet';

  @override
  String get boqNoMatchingBoqs => 'No matching BOQs';

  @override
  String get boqNoBoqsMessage =>
      'Import a BOQ into one of your projects to see it here.';

  @override
  String get commonTryDifferentSearch => 'Try a different search.';

  @override
  String get boqSearchHint => 'Search BOQs or projects';

  @override
  String get commonClearSearch => 'Clear search';

  @override
  String get boqUntitled => 'Untitled BOQ';

  @override
  String get boqActions => 'BOQ actions';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get boqUpdated => 'BOQ updated';

  @override
  String get boqEditTitle => 'Edit BOQ';

  @override
  String get boqName => 'BOQ name';

  @override
  String get boqEnterName => 'Enter a name';

  @override
  String get boqDescriptionOptional => 'Description (optional)';

  @override
  String get boqProject => 'Project';

  @override
  String get boqDeleteTitle => 'Delete BOQ?';

  @override
  String boqDeleteMessage(String name) {
    return '\"$name\" and all its items will be deleted.';
  }

  @override
  String get boqThisBoq => 'This BOQ';

  @override
  String get boqDeleted => 'BOQ deleted';

  @override
  String boqTotalsLine(String estimated, String generated) {
    return 'Estimated $estimated · Generated $generated';
  }

  @override
  String get boqTotals => 'Totals';

  @override
  String get boqTotalsEmpty =>
      'Totals appear once BOQ items have been imported.';

  @override
  String get boqEstimatedAmount => 'Estimated amount';

  @override
  String boqEstimatedOf(int done, int total) {
    return '$done of $total items';
  }

  @override
  String get boqGeneratedTotal => 'Generated total';

  @override
  String boqPricedOf(int done, int total) {
    return '$done of $total priced';
  }

  @override
  String get boqAboveEstimate => 'Above estimate';

  @override
  String get boqBelowEstimate => 'Below estimate';

  @override
  String get commonFilesUnavailable =>
      'Files could not be opened on this device. Try again.';

  @override
  String get commonFileUnreadable =>
      'The file could not be read. Choose it again.';

  @override
  String get boqUploadingEstimates => 'Uploading estimated prices...';

  @override
  String boqEstimatesSubject(String title) {
    return 'Estimated prices – $title';
  }

  @override
  String get dashNoRecentProjects => 'No recent projects yet';

  @override
  String get importCameraDenied =>
      'The camera could not be opened. Allow camera access in Settings and try again.';

  @override
  String get importPhotosDenied =>
      'Your photos could not be opened. Allow photo access in Settings and try again.';

  @override
  String get importUnsupportedType =>
      'This file type is not supported. Upload Excel, CSV, PDF or a photo.';

  @override
  String get importTooLarge =>
      'The file is larger than 20 MB. Choose a smaller file.';

  @override
  String importCompressing(String sizes) {
    return 'Compressed $sizes, uploading...';
  }

  @override
  String importItemsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count BOQ items',
      one: 'Imported 1 BOQ item',
    );
    return '$_temp0';
  }

  @override
  String importOpenProjectToRetry(String error) {
    return '$error (open the project to retry)';
  }

  @override
  String get importChooseProject => 'Choose project';

  @override
  String get importCreateProjectFirst =>
      'Create a project first, then import its BOQ.';

  @override
  String get importAddBoq => 'Add your BOQ';

  @override
  String get importChoosePhoto => 'Choose photo';

  @override
  String get importChoosePhotoSubtitle => 'Pick a BOQ photo from your gallery';

  @override
  String get importUploading => 'Uploading';

  @override
  String get notifUnread => 'Unread';

  @override
  String get coCompanyNameLabel => 'Company Name *';

  @override
  String get coCompanyNameHint => 'e.g. Riverside Builders Ltd';

  @override
  String get coRegistrationNumber => 'Registration Number';

  @override
  String get coTin => 'TIN (if applicable)';

  @override
  String get coCity => 'District/City';

  @override
  String get coCityHint => 'e.g. city, town or market';

  @override
  String get coPhysicalAddress => 'Physical Address';

  @override
  String get coPhysicalAddressHint => 'e.g. Plot 1, Main Street';

  @override
  String get coPostalAddress => 'Postal Address';

  @override
  String get coPostalAddressHint => 'e.g. P.O. Box 1234';

  @override
  String get coTelephone => 'Telephone';

  @override
  String get coAltTelephone => 'Alternative Telephone';

  @override
  String get coEmail => 'Email';

  @override
  String get coWebsite => 'Website';

  @override
  String get coDescription => 'Company Description';

  @override
  String get coDescriptionHint => 'A short description of your business';

  @override
  String get coLogoTooLarge => 'The logo must be 2 MB or smaller.';

  @override
  String get coPhotoLibraryDenied =>
      'The photo library could not be opened. Check the app\'s photo permission.';

  @override
  String get coSaved =>
      'Company profile saved. New BOQ exports will use these details.';

  @override
  String get coCompanyDetails => 'Company details';

  @override
  String get coLocation => 'Location';

  @override
  String get coContact => 'Contact';

  @override
  String get coPreviewTitle => 'PDF letterhead preview';

  @override
  String get coPreviewSubtitle => 'How your details appear on exported BOQs';

  @override
  String get coLogo => 'Logo';

  @override
  String get coNoLogo => 'No logo';

  @override
  String get coChooseLogo => 'Choose logo';

  @override
  String get coRemove => 'Remove';

  @override
  String get coLogoManaged =>
      'The logo is managed by your organisation administrator.';

  @override
  String get coSaveProfile => 'Save Company Profile';

  @override
  String get coProfileManaged =>
      'This company profile is managed by your organisation administrator.';

  @override
  String get coDetailsKept =>
      'BOQs keep the company details they were first exported with, even if you change this profile later.';

  @override
  String get coNameRequired => 'Company name is required.';

  @override
  String get coInvalidPhone =>
      'Enter a valid phone number, including the country code.';

  @override
  String get coCountry => 'Country';

  @override
  String get coSelect => 'Select...';

  @override
  String get coYourCompanyName => 'Your Company Name';

  @override
  String get coBillOfQuantities => 'BILL OF\nQUANTITIES';

  @override
  String get coPdfPreview => 'PDF preview';

  @override
  String get sharePreviewPdf => 'Preview PDF';

  @override
  String get shareDownloadPdf => 'Download PDF';

  @override
  String get shareByEmail => 'Share by Email';

  @override
  String get shareOnWhatsapp => 'Share on WhatsApp';

  @override
  String get shareToOtherApps => 'Share PDF to other apps';

  @override
  String get sharePdfAndSharing => 'PDF & sharing';

  @override
  String get shareOpeningPreview => 'Opening preview...';

  @override
  String get sharePreviewFailed =>
      'The preview could not be opened on this device.';

  @override
  String get shareDownloading => 'Downloading PDF...';

  @override
  String shareSaved(String name) {
    return 'Saved $name';
  }

  @override
  String get shareOpenSaveTo => 'Open / Save to';

  @override
  String get sharePreparingWhatsapp => 'Preparing WhatsApp message...';

  @override
  String get sharePreparingPdf => 'Preparing PDF...';

  @override
  String shareEmailSubject(String title) {
    return 'BOQ – $title';
  }

  @override
  String get shareRecipientEmail => 'Recipient email';

  @override
  String get shareSubject => 'Subject';

  @override
  String get shareMessageOptional => 'Message (optional)';

  @override
  String get shareMessageHint => 'Add a short note for the recipient...';

  @override
  String get sharePdfAttached => 'The BOQ PDF is attached automatically.';

  @override
  String get shareSend => 'Send';

  @override
  String get connNoInternet => 'No Internet Connection';

  @override
  String get connConnectPrompt =>
      'Please connect to Wi-Fi or mobile data to continue.';

  @override
  String get connChecking => 'Checking...';

  @override
  String get connOpenWifi => 'Open Wi-Fi Settings';

  @override
  String get connOpenMobileData => 'Open Mobile Data Settings';

  @override
  String get connOpenNetwork => 'Open Network Settings';

  @override
  String get connAutoContinue =>
      'The app continues automatically once you are back online.';

  @override
  String get commonLoading => 'Loading';
}
