// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ganda Luganda (`lg`).
class AppLocalizationsLg extends AppLocalizations {
  AppLocalizationsLg([String locale = 'lg']) : super(locale);

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
  String get orgManageFaqs => 'Ddukanya ebibuuzo (omuddukanya omukulu)';

  @override
  String get orgQuestion => 'Ekibuuzo';

  @override
  String get orgAnswer => 'Ekyokuddamu';

  @override
  String get orgSortOrder => 'Ensengeka';

  @override
  String get orgFaqActive => 'Kifulumiziddwa';

  @override
  String get orgSearchExpenses => 'Noonya ennyonnyola oba omuguzi w\'ebintu';

  @override
  String get orgAllProjects => 'Pulojekiti zonna';

  @override
  String get orgAssignments => 'Okugaba pulojekiti';

  @override
  String get orgAssign => 'Wa omukozi pulojekiti';

  @override
  String get orgMember => 'Omukozi';

  @override
  String get orgAssignmentRevokeConfirm =>
      'Ogyawo okugaba pulojekiti eno? Omukozi ajja kufiirwa obuyinza ku pulojekiti eno.';

  @override
  String get orgNoAssignmentOptions =>
      'Pulojekiti n\'omukozi w\'ekitongole byetaagibwa okugaba obuyinza.';

  @override
  String get orgFaqs => 'Ebibuuzo ebibuuzibwa ennyo';

  @override
  String get orgSearchFaqs => 'Noonya ebibuuzo n\'ebyokuddamu';

  @override
  String get orgExtractReceipt =>
      'Soma lisiiti (PDF oba ekifaananyi, okutuuka ku MB 10)';

  @override
  String get orgReviewExtraction => 'Kebera ebisomeddwa nga tonnatereka.';

  @override
  String get orgRetryReceipt =>
      'Ensaasaanya eterekeddwa. Ddamu okuteekako lisiiti';

  @override
  String get orgAddItem => 'Yongerako ekintu ekiguliddwa';

  @override
  String get orgRemoveItem => 'Ggyawo ekintu';

  @override
  String get orgApprovedBoq => 'BOQ ekkiriziddwa';

  @override
  String get orgNoBoqLink => 'Tekigattiddwa ku BOQ';

  @override
  String get orgNoApprovedBoq =>
      'Pulojekiti eno terina BOQ ekkiriziddwa. Ensaasaanya ejja kuwandiikibwa nga tegigattiddwa ku BOQ.';

  @override
  String get orgBoqItem => 'Ekintu kya BOQ';

  @override
  String get orgNoBoqItem => 'Tekigattiddwa ku kintu kya BOQ';

  @override
  String get orgShareToken => 'Gabana akabonero';

  @override
  String get orgExpenses => 'Ensaasaanya ne lisiiti';

  @override
  String get orgInvitations => 'Okuyita abakozi';

  @override
  String get orgAddExpense => 'Wandiika ensaasaanya';

  @override
  String get orgEditExpense => 'Kyusa ensaasaanya';

  @override
  String get orgSave => 'Tereka';

  @override
  String get orgProject => 'Pulojekiti ekuweereddwa';

  @override
  String get orgPurchaseDate => 'Olunaku lw\'okugula';

  @override
  String get orgSupplier => 'Omuguzi w\'ebintu';

  @override
  String get orgDescription => 'Ennyonnyola';

  @override
  String get orgQuantity => 'Obungi';

  @override
  String get orgUnit => 'Ekipimo';

  @override
  String get orgRate => 'Omuwendo';

  @override
  String get orgPaymentMethod => 'Engeri y\'okusasula';

  @override
  String get orgPlanned => 'Okugula okwategekebwa';

  @override
  String get orgExplanation => 'Ensonga y\'okugula okutali mu nteekateeka';

  @override
  String get orgRequired => 'Teekamu omuwendo omutuufu.';

  @override
  String get orgNoProjects =>
      'Tewali pulojekiti ekuweereddwa. Saba omuddukanya akuwe pulojekiti.';

  @override
  String get orgEmpty => 'Tewali biwandiiko.';

  @override
  String get orgPrevious => 'Ebyasooka';

  @override
  String get orgNext => 'Ebiddako';

  @override
  String get orgReceipts => 'Lisiiti';

  @override
  String get orgAddReceipt =>
      'Teekako lisiiti (PDF oba ekifaananyi, okutuuka ku MB 20)';

  @override
  String get orgInvite => 'Yita omukozi';

  @override
  String get orgAccept => 'Kkiriza okuyitibwa';

  @override
  String get orgToken => 'Akabonero k\'okuyitibwa';

  @override
  String get orgRole => 'Obuvunaanyizibwa';

  @override
  String get orgExpiry => 'Kiggwaako';

  @override
  String get orgEdit => 'Kyusa';

  @override
  String get orgRevoke => 'Gyawo';

  @override
  String get orgRevokeConfirm =>
      'Ogyawo okuyitibwa kuno? Tekujja kuddamu kukkirizibwa.';

  @override
  String get orgPending => 'Kulindirira';

  @override
  String get orgAccepted => 'Kukkiriziddwa';

  @override
  String get orgRevoked => 'Kugiddwawo';

  @override
  String get orgExpired => 'Kuweddeko';

  @override
  String get orgTokenHelp =>
      'Weereza akabonero kano mu ngeri ey\'ekyama eri email eyayitiddwa. Kalagibwa omulundi gumu gwokka.';

  @override
  String get orgCopy => 'Koppa akabonero';

  @override
  String get orgAcceptSuccess =>
      'Okuyitibwa kukkiriziddwa. Obuyinza bwo mu kitongole bukyusiddwa.';

  @override
  String get appTitle => 'BOQ Works';

  @override
  String get home => 'Omwaaka';

  @override
  String get dashboard => 'Ekisengejjero';

  @override
  String get projects => 'Pulojekiti';

  @override
  String get hardwarePrices => 'Ebikwano bya Hardware';

  @override
  String get getPrices => 'Funa Ebbeeyi';

  @override
  String get importBoq => 'Yingiza BOQ';

  @override
  String get account => 'Akawunti';

  @override
  String get goodMorning => 'Wasuze otya';

  @override
  String get overview => 'Laba engeri ebisale bya pulojekiti yo gye biri.';

  @override
  String get totalProjects => 'Pulojekiti zonna';

  @override
  String get activeProjects => 'Pulojekiti ezikola';

  @override
  String get boqsInReview => 'BOQ ezikebererwa';

  @override
  String get estimatedValue => 'Omuwendo ogusuubirwa';

  @override
  String get recentProjects => 'Pulojekiti ezisembyeyo';

  @override
  String get viewAll => 'Laba zonna';

  @override
  String get noProjects => 'Tewali pulojekiti';

  @override
  String get createProject => 'Tonda pulojekiti';

  @override
  String get importTitle => 'Yingiza BOQ yo';

  @override
  String get importDescription =>
      'Teeka Excel oba PDF BOQ, oba sika empapula okuva ku mulimu. Ojja kukebera ensengeka nga tennaterekebwa.';

  @override
  String get uploadDocument => 'Teeka ekiwandiiko';

  @override
  String get scanPages => 'Sika empapula';

  @override
  String get supportedFiles => 'Excel, CSV, PDF n\'ebifaananyi';

  @override
  String get subscription => 'Obwammemba';

  @override
  String get annualProfessional => 'Professional ow\'omwaka';

  @override
  String get active => 'Kikola';

  @override
  String get renewsOn => 'Kiddamu nga 31 Desemba 2026';

  @override
  String get aiCredits => 'AI credits';

  @override
  String get ocrPages => 'Empapula za OCR';

  @override
  String get managePlan => 'Ddukanya pulaani';

  @override
  String get language => 'Olulimi';

  @override
  String get english => 'Lungereza';

  @override
  String get luganda => 'Luganda';

  @override
  String get notifications => 'Obubaka';

  @override
  String get noNotifications => 'Tewali ebibaka';

  @override
  String get markAsRead => 'Kakasa nk\'ebibaka';

  @override
  String get profile => 'Puloofaayiro';

  @override
  String get signOut => 'Fuluma';

  @override
  String get usage => 'Enkozesa';

  @override
  String get viewSubscription => 'Laba obwammemba';

  @override
  String get projectStatusActive => 'Kikola';

  @override
  String get projectStatusPlanning => 'Kitegekebwa';

  @override
  String get signIn => 'Yingira';

  @override
  String get email => 'Endagiriro ya email';

  @override
  String get password => 'Ekigambo ekikuumi';

  @override
  String get signInDescription =>
      'Yingira oddukanye pulojekiti zo ez\'emirimu n\'ama BOQ.';

  @override
  String get signInFailed =>
      'Tesobodde kuyingira. Kebera ebikukwatako oddemu ogezeeko.';

  @override
  String get forgotPassword => 'Oyimiride ekigambo ekikuumi?';

  @override
  String get noAccount => 'Tolina akaawunti?';

  @override
  String get signUp => 'Weeyingize';

  @override
  String get signUpDescription =>
      'Tonda akaawunti otandike okuddukanya pulojekiti zo n\'ama BOQ.';

  @override
  String get organisationName => 'Erinnya ly\'ekibiina (si bya kweetagisa)';

  @override
  String get confirmPassword => 'Kakasa ekigambo ekikuumi';

  @override
  String get passwordTooShort =>
      'Ekigambo ekikuumi kirina okuba n\'ebigambo 8 oba okusukka.';

  @override
  String get passwordMismatch => 'Ebigambo ebikuumi tebikwatagana.';

  @override
  String get createAccount => 'Tonda akaawunti';

  @override
  String get resetPasswordDescription =>
      'Wandika endagiriro ya email yo, tuunikuggyeza olukusa lw\'okuddizaawo ekigambo ekikuumi.';

  @override
  String get resetEmailSent =>
      'Bwe waba nga waliwo akaawunti eyo, tumyeerezza olukusa lw\'okuddizaawo ekigambo ekikuumi. Kebera email yo.';

  @override
  String get sendResetLink => 'Tumya olukusa';

  @override
  String get backToSignIn => 'Dda ku kuyingira';

  @override
  String get privacyPolicy => 'Empisa za Kyaama';

  @override
  String get termsOfUse => 'Empisa z\'Eby\'Okukozesa';

  @override
  String get loadingDashboard => 'Ekisengejjero kyo kitikkibwa...';

  @override
  String get editProfile => 'Terereza puloofaayiro';

  @override
  String get fullName => 'Erinnya erijjuvu';

  @override
  String get phoneNumber => 'Nambala ya simu';

  @override
  String get location => 'Ekiwaaliro';

  @override
  String get newPassword => 'Ekigambo ekikuumi ekipya';

  @override
  String get passwordHint => 'Kirekeere awo okusigaza ekigambo ekikuumi ekyo';

  @override
  String get saveChanges => 'Tereka enkyukakyuka';

  @override
  String get profileUpdated => 'Puloofaayiro eterezeddwa';

  @override
  String get projectCode => 'Koodi ya pulojekiti';

  @override
  String get currency => 'Ssente';

  @override
  String get projectCreated => 'Pulojekiti etondeddwa';

  @override
  String get draft => 'Kiwandiikiddwa';

  @override
  String get boqs => 'BOQ';

  @override
  String get imported => 'BOQ etikkiddwa';

  @override
  String get priceComparison => 'Ekihinga eky\'Ebikwano';

  @override
  String get bestRecommendations => 'Ebisuubizo eby\'Abaka';

  @override
  String get itemsTracked => 'Ebintu eby\'Ekitegyekeko';

  @override
  String get pricesUpdatedToday => 'Ebikwano eby\'Okugeza Lero';

  @override
  String get averagePriceChange => 'Enkyukakyuka y\'Omuwendo';

  @override
  String get suppliersTracked => 'Abazimisa ab\'Obugayima';

  @override
  String get lowestPriceOpportunities => 'Eby\'Olugero lw\'Omutono';

  @override
  String get boqItemsWithUpdatedPrices => 'Ebikwano bya BOQ eby\'Okugeza';

  @override
  String get proxySubscriptions => 'Obwammemba bwa Proxy';

  @override
  String get beneficiary => 'Omugenzebwa';

  @override
  String get beneficiaryEmail => 'Email ya Omugenzebwa';

  @override
  String get payer => 'Omukwata';

  @override
  String get plan => 'Pulaani';

  @override
  String get status => 'Obwenyini';

  @override
  String get paymentStatus => 'Obwenyini bwa Kwesha';

  @override
  String get startDate => 'Lunaku lwa Kweteka';

  @override
  String get endDate => 'Lunaku lwa Mwisho';

  @override
  String get createdAt => 'Lunaku lwa Kwetondeka';

  @override
  String get transactionId => 'Koodi ya Transakishoni';

  @override
  String get search => 'Ssaka';

  @override
  String get refresh => 'Ganzeza';

  @override
  String get retry => 'Ganzeza';

  @override
  String get allStatuses => 'Obwenyini Bwonna';

  @override
  String get statusActive => 'Kikola';

  @override
  String get statusPending => 'Kitegereke';

  @override
  String get statusCancelled => 'Gwako';

  @override
  String get statusExpired => 'Mwisho';

  @override
  String get noProxySubscriptions => 'Tewali obwammemba bwa proxy';

  @override
  String get noProxySubscriptionsDescription =>
      'Tewali obwammemba bwa proxy bunaakulaba.';

  @override
  String get proxySubscriptionDetails => 'Ebikwata ku Obwammemba bwa Proxy';

  @override
  String get adminAccessRequired => 'Obugagga bwa Admin Bwebulidde';

  @override
  String get adminAccessDescription =>
      'Olusomesa luno lulabibwa abakulu abakulu tu.';

  @override
  String get useBiometricToLogin => 'Yingira n\'Obulamu';

  @override
  String get biometricPromptTitle => 'Kolesa Obuyita Obulamu';

  @override
  String get biometricPromptMessage =>
      'Omulabe okuwulira obuyita obulamu bwo kuyingira nga bwe kibi?';

  @override
  String get biometricPromptEnable => 'Kolesa';

  @override
  String get biometricPromptCancel => 'Gana';

  @override
  String get enableBiometricLogin => 'Kolesa Obuyita Obulamu';

  @override
  String get biometricLoginDescription =>
      'Kozesa ekigere oba ennyo y\'omuntu okuyingira nga bwe kibi';

  @override
  String get biometricNotAvailable =>
      'Obuyita obulamu tebwaliwo ku kifaananyi kino';

  @override
  String get biometricEnabled => 'Obuyita obulamu bwakolesedde';

  @override
  String get biometricDisabled => 'Obuyita obulamu bwekkedde';

  @override
  String get biometricError => 'Obuyita obulamu bweleke. Mwongeze omulabe.';

  @override
  String get biometricAvailable => 'Obuyita obulamu buliwo';

  @override
  String get biometricTypes => 'Ebikozesebwa: ';

  @override
  String get deleteBoq => 'Futa BOQ';

  @override
  String get deleteSelected => 'Futa ebyakusanyibwa';

  @override
  String get selectBoqs => 'Kusanya BOQ';

  @override
  String get selectedCount => 'ebyakusanyibwa';

  @override
  String get locationHistory => 'Enkuluze ya Ekiwaaliro';

  @override
  String get recentLocations => 'Eby\'Ekiwaaliro eby\'Olugendo';

  @override
  String get topSuppliers => 'Abatunzi Abasinga';

  @override
  String get oneTimeSubtitle => 'Ku kutegeka BOQ akaseera konna';

  @override
  String get oneTimeBadge => 'Lumu';

  @override
  String get buyOneTimeAccess => 'Gula Obukwakkulizo bwa Lumu';

  @override
  String get selectPlan => 'Londa pulaani';

  @override
  String validityHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'essaawa $hours',
      one: 'essaawa 1',
    );
    return '$_temp0';
  }

  @override
  String validityDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ennaku $days',
      one: 'olunaku 1',
    );
    return '$_temp0';
  }

  @override
  String maxProjectsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pulojekiti $count',
      one: 'pulojekiti 1',
    );
    return '$_temp0';
  }

  @override
  String maxBoqsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'BOQ $count',
      one: 'BOQ 1',
    );
    return '$_temp0';
  }

  @override
  String maxAiCreditsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'AI credits $count',
      one: 'AI credit 1',
    );
    return '$_temp0';
  }

  @override
  String get featureHardwareFactoryPrices =>
      'Ebbeeyi za Hardware ne Fekitoli ez\'akati';

  @override
  String get featureLimitedAiCredits => 'AI credits entono';

  @override
  String get featurePdfExcelExport => 'Okufulumya PDF ne Excel';

  @override
  String get featureCompanyBranding => 'Ekifaananyi ky\'ekibiina';

  @override
  String get noRecurringPayment => 'Tewali kusasula buli mwezi';

  @override
  String get renewsAutomatically => 'Kiddamu mu bwesona';

  @override
  String get confirmPurchaseTitle => 'Kakasa okugula';

  @override
  String confirmPurchaseMessage(String planName) {
    return 'Tonda obwammemba butannatuukiriziddwa bwa $planName? Pulaani yo etandika okukola nga ssente zikakasiddwa.';
  }

  @override
  String get cancel => 'Gana';

  @override
  String get continueAction => 'Weyongereyo';

  @override
  String get buyAnotherOneTimeAccess => 'Gula Obukwakkulizo bwa Lumu obulala';

  @override
  String get renewAccess => 'Ddaabiriza Obukwakkulizo';

  @override
  String get upgradeToSubscription => 'Kyusa ku Bwammemba';

  @override
  String get errorOneTimeProjectLimit =>
      'Otuuse ku kkomo lya pulojekiti mu Bukwakkulizo bwo obwa Lumu. Gula obukwakkulizo obulala obwa Lumu oba okwongeza ku bwammemba.';

  @override
  String get errorOneTimeBoqLimit =>
      'Otuuse ku kkomo lya BOQ mu Bukwakkulizo bwo obwa Lumu. Gula obukwakkulizo obulala obwa Lumu oba okwongeza ku bwammemba.';

  @override
  String get errorAiCreditsExhausted =>
      'AI credits zo ziwedde. Gula obukwakkulizo obulala obwa Lumu oba okwongeza ku bwammemba.';

  @override
  String get errorOcrLimitReached =>
      'Otuuse ku kkomo lya mpapula za OCR mu Bukwakkulizo bwo obwa Lumu. Gula obukwakkulizo obulala obwa Lumu oba okwongeza ku bwammemba.';

  @override
  String get errorOneTimeAccessExpired =>
      'Obukwakkulizo bwo obwa Lumu buwedde. Ddaabiriza obukwakkulizo oba okwongeza ku bwammemba.';

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
