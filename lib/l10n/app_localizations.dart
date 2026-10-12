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

  /// No description provided for @hwAllPrices.
  ///
  /// In en, this message translates to:
  /// **'All Prices'**
  String get hwAllPrices;

  /// No description provided for @hwCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get hwCategories;

  /// No description provided for @hwMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get hwMoreActions;

  /// No description provided for @hwFetchLatestPrices.
  ///
  /// In en, this message translates to:
  /// **'Fetch Latest Prices'**
  String get hwFetchLatestPrices;

  /// No description provided for @hwSelectedAddMore.
  ///
  /// In en, this message translates to:
  /// **'{count} selected · add one more to compare'**
  String hwSelectedAddMore(int count);

  /// No description provided for @hwItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} items selected'**
  String hwItemsSelected(int count);

  /// No description provided for @hwClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get hwClear;

  /// No description provided for @hwCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get hwCompare;

  /// No description provided for @hwPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {last}'**
  String hwPageOf(int page, int last);

  /// No description provided for @hwPreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get hwPreviousPage;

  /// No description provided for @hwNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get hwNextPage;

  /// No description provided for @hwNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories loaded'**
  String get hwNoCategories;

  /// No description provided for @hwLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Load categories'**
  String get hwLoadCategories;

  /// No description provided for @hwAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get hwAllCategories;

  /// No description provided for @hwItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String hwItemCount(int count);

  /// No description provided for @hwAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get hwAll;

  /// No description provided for @hwSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get hwSupplier;

  /// No description provided for @hwFactory.
  ///
  /// In en, this message translates to:
  /// **'Factory'**
  String get hwFactory;

  /// No description provided for @hwClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get hwClearSearch;

  /// No description provided for @hwCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get hwCategory;

  /// No description provided for @hwRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get hwRegion;

  /// No description provided for @hwNoPrices.
  ///
  /// In en, this message translates to:
  /// **'No hardware prices found'**
  String get hwNoPrices;

  /// No description provided for @hwAdjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get hwAdjustFilters;

  /// No description provided for @hwCompareMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 items for comparison'**
  String get hwCompareMax;

  /// No description provided for @hwAlreadyCompared.
  ///
  /// In en, this message translates to:
  /// **'Already in the comparison'**
  String get hwAlreadyCompared;

  /// No description provided for @hwAddedToComparison.
  ///
  /// In en, this message translates to:
  /// **'Added to comparison ({count}/5)'**
  String hwAddedToComparison(int count);

  /// No description provided for @hwFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'{label} filter'**
  String hwFilterTooltip(String label);

  /// No description provided for @hwMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get hwMoreOptions;

  /// No description provided for @hwVerifiedOn.
  ///
  /// In en, this message translates to:
  /// **'Verified: {date}'**
  String hwVerifiedOn(String date);

  /// No description provided for @hwUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated: {date}'**
  String hwUpdatedOn(String date);

  /// No description provided for @hwSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get hwSource;

  /// No description provided for @hwPriceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price History'**
  String get hwPriceHistory;

  /// No description provided for @hwCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get hwCurrent;

  /// No description provided for @hwLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get hwLowest;

  /// No description provided for @hwHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get hwHighest;

  /// No description provided for @hwAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get hwAverage;

  /// No description provided for @hwChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get hwChange;

  /// No description provided for @hwDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hwDetails;

  /// No description provided for @hwBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get hwBrand;

  /// No description provided for @hwSpec.
  ///
  /// In en, this message translates to:
  /// **'Spec'**
  String get hwSpec;

  /// No description provided for @hwUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get hwUnit;

  /// No description provided for @hwPriceHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'Price History ({count} records)'**
  String hwPriceHistoryCount(int count);

  /// No description provided for @hwNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No history available'**
  String get hwNoHistory;

  /// No description provided for @hwItemPriceHistory.
  ///
  /// In en, this message translates to:
  /// **'{item} - Price History'**
  String hwItemPriceHistory(String item);

  /// No description provided for @hwNoComparison.
  ///
  /// In en, this message translates to:
  /// **'No comparison data'**
  String get hwNoComparison;

  /// No description provided for @hwPricesCompared.
  ///
  /// In en, this message translates to:
  /// **'{count} prices compared'**
  String hwPricesCompared(int count);

  /// No description provided for @hwYouSave.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get hwYouSave;

  /// No description provided for @hwBestChoice.
  ///
  /// In en, this message translates to:
  /// **'Best choice'**
  String get hwBestChoice;

  /// No description provided for @hwSpecification.
  ///
  /// In en, this message translates to:
  /// **'Specification'**
  String get hwSpecification;

  /// No description provided for @hwPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get hwPrice;

  /// No description provided for @hwUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get hwUpdated;

  /// No description provided for @hwVsLowest.
  ///
  /// In en, this message translates to:
  /// **'vs lowest'**
  String get hwVsLowest;

  /// No description provided for @hwTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get hwTrend;

  /// No description provided for @hwRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get hwRecords;

  /// No description provided for @hwRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get hwRating;

  /// No description provided for @hwValueScore.
  ///
  /// In en, this message translates to:
  /// **'Value Score'**
  String get hwValueScore;

  /// No description provided for @hwStability.
  ///
  /// In en, this message translates to:
  /// **'Stability'**
  String get hwStability;

  /// No description provided for @hwFreshness.
  ///
  /// In en, this message translates to:
  /// **'Freshness'**
  String get hwFreshness;

  /// No description provided for @hwNoRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations available'**
  String get hwNoRecommendations;

  /// No description provided for @hwRatingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating}'**
  String hwRatingSemantics(int rating);

  /// No description provided for @hwValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get hwValue;

  /// No description provided for @ratingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get ratingThisWeek;

  /// No description provided for @ratingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get ratingThisMonth;

  /// No description provided for @ratingThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get ratingThisYear;

  /// No description provided for @ratingAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get ratingAllTime;

  /// No description provided for @ratingHardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get ratingHardware;

  /// No description provided for @ratingFactories.
  ///
  /// In en, this message translates to:
  /// **'Factories'**
  String get ratingFactories;

  /// No description provided for @ratingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rating} other{{count} ratings}}'**
  String ratingCount(int count);

  /// No description provided for @ratingRankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get ratingRankings;

  /// No description provided for @ratingCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get ratingCharts;

  /// No description provided for @ratingMyRatings.
  ///
  /// In en, this message translates to:
  /// **'My ratings'**
  String get ratingMyRatings;

  /// No description provided for @ratingRateSupplier.
  ///
  /// In en, this message translates to:
  /// **'Rate a Supplier'**
  String get ratingRateSupplier;

  /// No description provided for @ratingRankingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Ratings of hardware suppliers and factories by users. Rate the ones you buy from to reward good prices and service.'**
  String get ratingRankingsIntro;

  /// No description provided for @ratingLowestRated.
  ///
  /// In en, this message translates to:
  /// **'Lowest rated'**
  String get ratingLowestRated;

  /// No description provided for @ratingHardwareNeedsImprovement.
  ///
  /// In en, this message translates to:
  /// **'Hardware needing improvement'**
  String get ratingHardwareNeedsImprovement;

  /// No description provided for @ratingTopHardware.
  ///
  /// In en, this message translates to:
  /// **'Top 10 Hardware'**
  String get ratingTopHardware;

  /// No description provided for @ratingFactoriesNeedImprovement.
  ///
  /// In en, this message translates to:
  /// **'Factories needing improvement'**
  String get ratingFactoriesNeedImprovement;

  /// No description provided for @ratingTopFactories.
  ///
  /// In en, this message translates to:
  /// **'Top 10 Factories'**
  String get ratingTopFactories;

  /// No description provided for @ratingWeightedNote.
  ///
  /// In en, this message translates to:
  /// **'Rankings use a weighted score: a supplier needs several good ratings to rank above one with many, so a single 5-star rating does not top the list.'**
  String get ratingWeightedNote;

  /// No description provided for @ratingRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratingRatings;

  /// No description provided for @ratingAverage.
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get ratingAverage;

  /// No description provided for @ratingSuppliersRated.
  ///
  /// In en, this message translates to:
  /// **'Suppliers rated'**
  String get ratingSuppliersRated;

  /// No description provided for @ratingTopHardwareChart.
  ///
  /// In en, this message translates to:
  /// **'Top hardware · average rating'**
  String get ratingTopHardwareChart;

  /// No description provided for @ratingLowestHardwareChart.
  ///
  /// In en, this message translates to:
  /// **'Lowest rated hardware · average rating'**
  String get ratingLowestHardwareChart;

  /// No description provided for @ratingTopFactoriesChart.
  ///
  /// In en, this message translates to:
  /// **'Top factories · average rating'**
  String get ratingTopFactoriesChart;

  /// No description provided for @ratingLowestFactoriesChart.
  ///
  /// In en, this message translates to:
  /// **'Lowest rated factories · average rating'**
  String get ratingLowestFactoriesChart;

  /// No description provided for @ratingDistribution.
  ///
  /// In en, this message translates to:
  /// **'Rating distribution'**
  String get ratingDistribution;

  /// No description provided for @ratingByType.
  ///
  /// In en, this message translates to:
  /// **'Ratings by type'**
  String get ratingByType;

  /// No description provided for @ratingScoresByArea.
  ///
  /// In en, this message translates to:
  /// **'Scores by area'**
  String get ratingScoresByArea;

  /// No description provided for @ratingNoScoresPeriod.
  ///
  /// In en, this message translates to:
  /// **'No detailed scores in this period yet.'**
  String get ratingNoScoresPeriod;

  /// No description provided for @ratingMonthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly trend'**
  String get ratingMonthlyTrend;

  /// No description provided for @ratingLast12Months.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get ratingLast12Months;

  /// No description provided for @ratingNoneYet.
  ///
  /// In en, this message translates to:
  /// **'You have not rated any supplier yet.'**
  String get ratingNoneYet;

  /// No description provided for @ratingNoneYetHelp.
  ///
  /// In en, this message translates to:
  /// **'Rate the hardware shops and factories you buy from. You can rate each one again every month.'**
  String get ratingNoneYetHelp;

  /// No description provided for @ratingNonePeriod.
  ///
  /// In en, this message translates to:
  /// **'No ratings in this period yet.'**
  String get ratingNonePeriod;

  /// No description provided for @ratingBeFirst.
  ///
  /// In en, this message translates to:
  /// **'Be the first to rate one.'**
  String get ratingBeFirst;

  /// No description provided for @ratingRank.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank}'**
  String ratingRank(int rank);

  /// No description provided for @ratingOutOfFive.
  ///
  /// In en, this message translates to:
  /// **'{value} out of 5 stars'**
  String ratingOutOfFive(String value);

  /// No description provided for @ratingStars.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String ratingStars(int count);

  /// No description provided for @ratingPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get ratingPrice;

  /// No description provided for @ratingQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get ratingQuality;

  /// No description provided for @ratingDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get ratingDelivery;

  /// No description provided for @ratingService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get ratingService;

  /// No description provided for @ratingRatingsLower.
  ///
  /// In en, this message translates to:
  /// **'ratings'**
  String get ratingRatingsLower;

  /// No description provided for @ratingHardwareAverage.
  ///
  /// In en, this message translates to:
  /// **'Hardware average'**
  String get ratingHardwareAverage;

  /// No description provided for @ratingFactoryAverage.
  ///
  /// In en, this message translates to:
  /// **'Factory average'**
  String get ratingFactoryAverage;

  /// No description provided for @ratingNoneLast12.
  ///
  /// In en, this message translates to:
  /// **'No ratings in the last 12 months.'**
  String get ratingNoneLast12;

  /// No description provided for @ratingPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Ratings per month'**
  String get ratingPerMonth;

  /// No description provided for @ratingWebsiteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the website.'**
  String get ratingWebsiteFailed;

  /// No description provided for @ratingNotRatedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Not rated in this period'**
  String get ratingNotRatedPeriod;

  /// No description provided for @ratingRankOfFactories.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank} of {total} factories'**
  String ratingRankOfFactories(int rank, int total);

  /// No description provided for @ratingRankOfShops.
  ///
  /// In en, this message translates to:
  /// **'Rank {rank} of {total} hardware shops'**
  String ratingRankOfShops(int rank, int total);

  /// No description provided for @ratingRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get ratingRate;

  /// No description provided for @ratingRateAgain.
  ///
  /// In en, this message translates to:
  /// **'Rate again'**
  String get ratingRateAgain;

  /// No description provided for @ratingWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get ratingWebsite;

  /// No description provided for @ratingNoScores.
  ///
  /// In en, this message translates to:
  /// **'No detailed scores yet.'**
  String get ratingNoScores;

  /// No description provided for @ratingRecentReviews.
  ///
  /// In en, this message translates to:
  /// **'Recent reviews'**
  String get ratingRecentReviews;

  /// No description provided for @ratingNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get ratingNoReviews;

  /// No description provided for @ratingVerifiedUser.
  ///
  /// In en, this message translates to:
  /// **'Verified user'**
  String get ratingVerifiedUser;

  /// No description provided for @ratingHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get ratingHidden;

  /// No description provided for @ratingChooseOverall.
  ///
  /// In en, this message translates to:
  /// **'Choose an overall rating from 1 to 5 stars.'**
  String get ratingChooseOverall;

  /// No description provided for @ratingOncePerMonth.
  ///
  /// In en, this message translates to:
  /// **'You can rate each supplier once a month; rating again in the same month updates your rating.'**
  String get ratingOncePerMonth;

  /// No description provided for @ratingHardwareOrFactory.
  ///
  /// In en, this message translates to:
  /// **'Hardware or factory'**
  String get ratingHardwareOrFactory;

  /// No description provided for @ratingSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or location...'**
  String get ratingSearchHint;

  /// No description provided for @ratingNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No active hardware or factory matches your search.'**
  String get ratingNoMatches;

  /// No description provided for @ratingOverallRequired.
  ///
  /// In en, this message translates to:
  /// **'Overall rating *'**
  String get ratingOverallRequired;

  /// No description provided for @ratingScoresOptional.
  ///
  /// In en, this message translates to:
  /// **'Scores by area (optional, tap a chosen star again to clear)'**
  String get ratingScoresOptional;

  /// No description provided for @ratingComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get ratingComment;

  /// No description provided for @ratingCommentHint.
  ///
  /// In en, this message translates to:
  /// **'What was good, and what could be better? (prices, stock, delivery, service)'**
  String get ratingCommentHint;

  /// No description provided for @ratingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Rating'**
  String get ratingUpdate;

  /// No description provided for @ratingSave.
  ///
  /// In en, this message translates to:
  /// **'Save Rating'**
  String get ratingSave;

  /// No description provided for @projNoMatching.
  ///
  /// In en, this message translates to:
  /// **'No matching projects'**
  String get projNoMatching;

  /// No description provided for @projTypeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Project type'**
  String get projTypeSheetTitle;

  /// No description provided for @projProjectType.
  ///
  /// In en, this message translates to:
  /// **'Project Type'**
  String get projProjectType;

  /// No description provided for @projTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose or type a project type'**
  String get projTypeHint;

  /// No description provided for @projChooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose a project type'**
  String get projChooseType;

  /// No description provided for @projStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projStatusCompleted;

  /// No description provided for @projStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projStatusArchived;

  /// No description provided for @projRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get projRequired;

  /// No description provided for @projBasicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic details'**
  String get projBasicDetails;

  /// No description provided for @projNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Project Name *'**
  String get projNameRequired;

  /// No description provided for @projDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projDescription;

  /// No description provided for @projParties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get projParties;

  /// No description provided for @projClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get projClient;

  /// No description provided for @projContractor.
  ///
  /// In en, this message translates to:
  /// **'Contractor'**
  String get projContractor;

  /// No description provided for @projConsultant.
  ///
  /// In en, this message translates to:
  /// **'Consultant'**
  String get projConsultant;

  /// No description provided for @projQuantitySurveyor.
  ///
  /// In en, this message translates to:
  /// **'Quantity Surveyor'**
  String get projQuantitySurveyor;

  /// No description provided for @projProjectManager.
  ///
  /// In en, this message translates to:
  /// **'Project Manager'**
  String get projProjectManager;

  /// No description provided for @projSiteEngineer.
  ///
  /// In en, this message translates to:
  /// **'Site Engineer'**
  String get projSiteEngineer;

  /// No description provided for @projFundingOrganisation.
  ///
  /// In en, this message translates to:
  /// **'Funding Organisation'**
  String get projFundingOrganisation;

  /// No description provided for @projCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get projCountry;

  /// No description provided for @projDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get projDistrict;

  /// No description provided for @projDatesValue.
  ///
  /// In en, this message translates to:
  /// **'Dates & value'**
  String get projDatesValue;

  /// No description provided for @projExpectedCompletionDate.
  ///
  /// In en, this message translates to:
  /// **'Expected Completion Date'**
  String get projExpectedCompletionDate;

  /// No description provided for @projContractValue.
  ///
  /// In en, this message translates to:
  /// **'Contract Value'**
  String get projContractValue;

  /// No description provided for @projLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get projLanguages;

  /// No description provided for @projOriginalLanguage.
  ///
  /// In en, this message translates to:
  /// **'Original Language'**
  String get projOriginalLanguage;

  /// No description provided for @projReportLanguage.
  ///
  /// In en, this message translates to:
  /// **'Report Language'**
  String get projReportLanguage;

  /// No description provided for @pdItemsCreated.
  ///
  /// In en, this message translates to:
  /// **'{count} BOQ items created'**
  String pdItemsCreated(int count);

  /// No description provided for @pdPreparingPrices.
  ///
  /// In en, this message translates to:
  /// **'Preparing to fetch prices...'**
  String get pdPreparingPrices;

  /// No description provided for @pdFetchingProgress.
  ///
  /// In en, this message translates to:
  /// **'Fetching {done}/{total}: {description}'**
  String pdFetchingProgress(int done, int total, String description);

  /// No description provided for @pdGeneratingPrices.
  ///
  /// In en, this message translates to:
  /// **'Generating BOQ prices'**
  String get pdGeneratingPrices;

  /// No description provided for @pdGeneratedAll.
  ///
  /// In en, this message translates to:
  /// **'Generated prices for {count} items'**
  String pdGeneratedAll(int count);

  /// No description provided for @pdGeneratedPartial.
  ///
  /// In en, this message translates to:
  /// **'Generated {priced} of {total} ({failed} failed)'**
  String pdGeneratedPartial(int priced, int total, int failed);

  /// No description provided for @pdTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get pdTitle;

  /// No description provided for @pdActions.
  ///
  /// In en, this message translates to:
  /// **'Project actions'**
  String get pdActions;

  /// No description provided for @pdDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get pdDeleteTitle;

  /// No description provided for @pdDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this project? This action cannot be undone.'**
  String get pdDeleteConfirm;

  /// No description provided for @pdDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pdDelete;

  /// No description provided for @pdDeleted.
  ///
  /// In en, this message translates to:
  /// **'Project deleted'**
  String get pdDeleted;

  /// No description provided for @pdCode.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String pdCode(String code);

  /// No description provided for @pdOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get pdOverview;

  /// No description provided for @pdOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get pdOwner;

  /// No description provided for @pdDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get pdDates;

  /// No description provided for @pdExpectedCompletion.
  ///
  /// In en, this message translates to:
  /// **'Expected Completion'**
  String get pdExpectedCompletion;

  /// No description provided for @pdProjectTotals.
  ///
  /// In en, this message translates to:
  /// **'Project totals'**
  String get pdProjectTotals;

  /// No description provided for @pdNoBoqs.
  ///
  /// In en, this message translates to:
  /// **'No BOQs yet'**
  String get pdNoBoqs;

  /// No description provided for @pdGenerateBoq.
  ///
  /// In en, this message translates to:
  /// **'Generate BOQ'**
  String get pdGenerateBoq;

  /// No description provided for @pdUpdated.
  ///
  /// In en, this message translates to:
  /// **'Project updated'**
  String get pdUpdated;

  /// No description provided for @pdEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get pdEditTitle;

  /// No description provided for @pdLoadingItems.
  ///
  /// In en, this message translates to:
  /// **'Loading BOQ items...'**
  String get pdLoadingItems;

  /// No description provided for @pdNoItemsToPrice.
  ///
  /// In en, this message translates to:
  /// **'No BOQ items found to price'**
  String get pdNoItemsToPrice;

  /// No description provided for @pdLoadItemsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load BOQ items'**
  String get pdLoadItemsFailed;

  /// No description provided for @pdFetchedAll.
  ///
  /// In en, this message translates to:
  /// **'Fetched prices for {count} items'**
  String pdFetchedAll(int count);

  /// No description provided for @pdFetchedPartial.
  ///
  /// In en, this message translates to:
  /// **'Fetched {priced} of {total} items ({failed} failed)'**
  String pdFetchedPartial(int priced, int total, int failed);

  /// No description provided for @pdRetrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying {count} failed items...'**
  String pdRetrying(int count);

  /// No description provided for @pdViewHierarchy.
  ///
  /// In en, this message translates to:
  /// **'View Hierarchy'**
  String get pdViewHierarchy;

  /// No description provided for @pdOverallCost.
  ///
  /// In en, this message translates to:
  /// **'Overall BOQ Cost'**
  String get pdOverallCost;

  /// No description provided for @pdSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get pdSelectLocation;

  /// No description provided for @pdProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {progress}'**
  String pdProgress(String progress);

  /// No description provided for @pdReviewPrices.
  ///
  /// In en, this message translates to:
  /// **'Review prices'**
  String get pdReviewPrices;

  /// No description provided for @pdLocationPrices.
  ///
  /// In en, this message translates to:
  /// **'Location prices'**
  String get pdLocationPrices;

  /// No description provided for @pdItemsNotPriced.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) could not be priced:'**
  String pdItemsNotPriced(int count);

  /// No description provided for @pdRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed items'**
  String get pdRetryFailed;

  /// No description provided for @pdCompareLocations.
  ///
  /// In en, this message translates to:
  /// **'Compare saved locations'**
  String get pdCompareLocations;

  /// No description provided for @pdPricingHistory.
  ///
  /// In en, this message translates to:
  /// **'Pricing History'**
  String get pdPricingHistory;

  /// No description provided for @pdLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Load History'**
  String get pdLoadHistory;

  /// No description provided for @pdNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get pdNotAvailable;

  /// No description provided for @pdPdfShare.
  ///
  /// In en, this message translates to:
  /// **'PDF & Share'**
  String get pdPdfShare;

  /// No description provided for @pdUnknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get pdUnknownLocation;

  /// No description provided for @pdLocationComparison.
  ///
  /// In en, this message translates to:
  /// **'Location Price Comparison'**
  String get pdLocationComparison;

  /// No description provided for @pdNoSavedLocations.
  ///
  /// In en, this message translates to:
  /// **'No saved location prices yet'**
  String get pdNoSavedLocations;

  /// No description provided for @pdSavedPricesByLocation.
  ///
  /// In en, this message translates to:
  /// **'Saved prices by hardware and location'**
  String get pdSavedPricesByLocation;

  /// No description provided for @pdHardwareItem.
  ///
  /// In en, this message translates to:
  /// **'Hardware item'**
  String get pdHardwareItem;

  /// No description provided for @pdLocationHelp.
  ///
  /// In en, this message translates to:
  /// **'Prices depend on the location. Enter the town or district where the project will be built; it is saved to the project.'**
  String get pdLocationHelp;

  /// No description provided for @pdProjectLocation.
  ///
  /// In en, this message translates to:
  /// **'Project location'**
  String get pdProjectLocation;

  /// No description provided for @pdProjectLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kampala, Wakiso'**
  String get pdProjectLocationHint;

  /// No description provided for @pdEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter the project location'**
  String get pdEnterLocation;

  /// No description provided for @orgFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Unable to read this file.'**
  String get orgFileUnreadable;

  /// No description provided for @orgSelect.
  ///
  /// In en, this message translates to:
  /// **'Select...'**
  String get orgSelect;

  /// No description provided for @orgPayCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get orgPayCash;

  /// No description provided for @orgPayMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money'**
  String get orgPayMobileMoney;

  /// No description provided for @orgPayBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get orgPayBankTransfer;

  /// No description provided for @orgPayCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get orgPayCheque;

  /// No description provided for @orgPayCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get orgPayCard;

  /// No description provided for @orgPayCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get orgPayCredit;

  /// No description provided for @orgPayOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get orgPayOther;

  /// No description provided for @orgBoqNumber.
  ///
  /// In en, this message translates to:
  /// **'BOQ #{id}'**
  String orgBoqNumber(int id);

  /// No description provided for @locUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Use {location} prices?'**
  String locUseTitle(String location);

  /// No description provided for @locUseMessage.
  ///
  /// In en, this message translates to:
  /// **'The BOQ\'s suggested prices switch to this location. Approved prices are kept.'**
  String get locUseMessage;

  /// No description provided for @locUsePrices.
  ///
  /// In en, this message translates to:
  /// **'Use these prices'**
  String get locUsePrices;

  /// No description provided for @locSwitched.
  ///
  /// In en, this message translates to:
  /// **'{count} prices switched to {location}'**
  String locSwitched(int count, String location);

  /// No description provided for @locCompareCount.
  ///
  /// In en, this message translates to:
  /// **'Compare {count}'**
  String locCompareCount(int count);

  /// No description provided for @locNone.
  ///
  /// In en, this message translates to:
  /// **'No location prices yet'**
  String get locNone;

  /// No description provided for @locNoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Get prices for a location on the BOQ screen; every location\'s prices are kept here.'**
  String get locNoneHelp;

  /// No description provided for @locTickHint.
  ///
  /// In en, this message translates to:
  /// **'Tick two to four locations to compare them.'**
  String get locTickHint;

  /// No description provided for @locInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get locInUse;

  /// No description provided for @locItemsPriced.
  ///
  /// In en, this message translates to:
  /// **'{priced} of {total} items priced'**
  String locItemsPriced(int priced, int total);

  /// No description provided for @locCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare locations'**
  String get locCompareTitle;

  /// No description provided for @locTotals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get locTotals;

  /// No description provided for @locPricedLabel.
  ///
  /// In en, this message translates to:
  /// **'{location} ({count} priced)'**
  String locPricedLabel(String location, int count);

  /// No description provided for @locLowestHint.
  ///
  /// In en, this message translates to:
  /// **'Lowest price of each item in green.'**
  String get locLowestHint;

  /// No description provided for @locItemsReviewed.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) reviewed'**
  String locItemsReviewed(int count);

  /// No description provided for @locItemsApproved.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) approved'**
  String locItemsApproved(int count);

  /// No description provided for @locItemsRejected.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) rejected'**
  String locItemsRejected(int count);

  /// No description provided for @locSkipped.
  ///
  /// In en, this message translates to:
  /// **'{result}, {count} skipped'**
  String locSkipped(String result, int count);

  /// No description provided for @locSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String locSelected(int count);

  /// No description provided for @locClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get locClearSelection;

  /// No description provided for @locReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get locReview;

  /// No description provided for @locApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get locApprove;

  /// No description provided for @locReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get locReject;

  /// No description provided for @locNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items to review'**
  String get locNoItems;

  /// No description provided for @locSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all (not approved)'**
  String get locSelectAll;

  /// No description provided for @locSuggested.
  ///
  /// In en, this message translates to:
  /// **'{quantity} · suggested {rate}'**
  String locSuggested(String quantity, String rate);

  /// No description provided for @locRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject selected prices'**
  String get locRejectTitle;

  /// No description provided for @locReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get locReason;

  /// No description provided for @locReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rates too high for this location'**
  String get locReasonHint;

  /// No description provided for @locEnterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason'**
  String get locEnterReason;

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
  /// **'Remove this project assignment? The member will lose access to this project.'**
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
  /// **'Remove'**
  String get orgRevoke;

  /// No description provided for @orgRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this invitation? It can no longer be accepted.'**
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
  /// **'Removed'**
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

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @currentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Needed to change your email or password'**
  String get currentPasswordHint;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password to change your email or password.'**
  String get currentPasswordRequired;

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

  /// No description provided for @acctNoActivePlan.
  ///
  /// In en, this message translates to:
  /// **'No active plan'**
  String get acctNoActivePlan;

  /// No description provided for @acctTrialDays.
  ///
  /// In en, this message translates to:
  /// **'{days}-day trial'**
  String acctTrialDays(int days);

  /// No description provided for @acctExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get acctExpiresToday;

  /// No description provided for @acctDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day remaining} other{{count} days remaining}}'**
  String acctDaysRemaining(int count);

  /// No description provided for @acctSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get acctSettings;

  /// No description provided for @acctCompanyProfile.
  ///
  /// In en, this message translates to:
  /// **'Company Profile'**
  String get acctCompanyProfile;

  /// No description provided for @acctCompanyProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Logo and details used on your BOQ PDFs'**
  String get acctCompanyProfileSubtitle;

  /// No description provided for @acctPaymentConfirmedActive.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. Your subscription is now active.'**
  String get acctPaymentConfirmedActive;

  /// No description provided for @acctSubscriptionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Subscription updated successfully.'**
  String get acctSubscriptionUpdated;

  /// No description provided for @acctPlansLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load subscription plans.'**
  String get acctPlansLoadError;

  /// No description provided for @acctNoPlans.
  ///
  /// In en, this message translates to:
  /// **'No plans are currently available.'**
  String get acctNoPlans;

  /// No description provided for @acctPaymentStarted.
  ///
  /// In en, this message translates to:
  /// **'Payment started. Follow the instructions below, then verify the payment.'**
  String get acctPaymentStarted;

  /// No description provided for @acctPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get acctPaymentConfirmed;

  /// No description provided for @acctSubscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has been activated successfully.'**
  String get acctSubscriptionActivated;

  /// No description provided for @acctPaymentUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Payment submitted for review. Your plan will activate after confirmation.'**
  String get acctPaymentUnderReview;

  /// No description provided for @acctPaymentStatusValue.
  ///
  /// In en, this message translates to:
  /// **'Payment status: {status}'**
  String acctPaymentStatusValue(String status);

  /// No description provided for @acctPaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt'**
  String get acctPaymentReceipt;

  /// No description provided for @acctInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get acctInvoice;

  /// No description provided for @acctReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get acctReference;

  /// No description provided for @acctAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get acctAmount;

  /// No description provided for @acctPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get acctPaid;

  /// No description provided for @acctProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get acctProvider;

  /// No description provided for @acctPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get acctPhone;

  /// No description provided for @acctMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get acctMode;

  /// No description provided for @acctInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get acctInstructions;

  /// No description provided for @acctCheckoutUrl.
  ///
  /// In en, this message translates to:
  /// **'Checkout URL'**
  String get acctCheckoutUrl;

  /// No description provided for @acctOpenCheckout.
  ///
  /// In en, this message translates to:
  /// **'Open secure checkout'**
  String get acctOpenCheckout;

  /// No description provided for @acctCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get acctCopy;

  /// No description provided for @acctCheckoutOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open checkout. You can copy the link instead.'**
  String get acctCheckoutOpenFailed;

  /// No description provided for @acctCheckoutCopied.
  ///
  /// In en, this message translates to:
  /// **'Checkout URL copied.'**
  String get acctCheckoutCopied;

  /// No description provided for @acctBankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank details'**
  String get acctBankDetails;

  /// No description provided for @acctPaymentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Payment instructions'**
  String get acctPaymentInstructions;

  /// No description provided for @acctSubscriptionPlan.
  ///
  /// In en, this message translates to:
  /// **'Subscription plan'**
  String get acctSubscriptionPlan;

  /// No description provided for @acctSubscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Subscription status'**
  String get acctSubscriptionStatus;

  /// No description provided for @acctTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get acctTransaction;

  /// No description provided for @acctNotStarted.
  ///
  /// In en, this message translates to:
  /// **'not started'**
  String get acctNotStarted;

  /// No description provided for @acctCompletePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete payment'**
  String get acctCompletePayment;

  /// No description provided for @acctGatewaysLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load payment methods.'**
  String get acctGatewaysLoadError;

  /// No description provided for @acctPaymentActivationNote.
  ///
  /// In en, this message translates to:
  /// **'Your plan is activated only after the server confirms a successful payment. Closing this screen does not delete the pending subscription.'**
  String get acctPaymentActivationNote;

  /// No description provided for @acctNoGateways.
  ///
  /// In en, this message translates to:
  /// **'No payment methods are currently enabled. Please contact the administrator.'**
  String get acctNoGateways;

  /// No description provided for @acctChoosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose payment method'**
  String get acctChoosePaymentMethod;

  /// No description provided for @acctAggregator.
  ///
  /// In en, this message translates to:
  /// **'Aggregator'**
  String get acctAggregator;

  /// No description provided for @acctTestMode.
  ///
  /// In en, this message translates to:
  /// **'Test mode'**
  String get acctTestMode;

  /// No description provided for @acctPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get acctPaymentDetails;

  /// No description provided for @acctMtnNumber.
  ///
  /// In en, this message translates to:
  /// **'MTN MoMo number'**
  String get acctMtnNumber;

  /// No description provided for @acctAirtelNumber.
  ///
  /// In en, this message translates to:
  /// **'Airtel Money number'**
  String get acctAirtelNumber;

  /// No description provided for @acctMobileMoneyNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile money number'**
  String get acctMobileMoneyNumber;

  /// No description provided for @acctPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 0772 123 456'**
  String get acctPhoneHint;

  /// No description provided for @acctPaymentOption.
  ///
  /// In en, this message translates to:
  /// **'Payment option'**
  String get acctPaymentOption;

  /// No description provided for @acctContinueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get acctContinueToPayment;

  /// No description provided for @acctRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get acctRefreshStatus;

  /// No description provided for @acctVerifyPayment.
  ///
  /// In en, this message translates to:
  /// **'Verify payment'**
  String get acctVerifyPayment;

  /// No description provided for @acctAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add profile photo'**
  String get acctAddPhoto;

  /// No description provided for @acctChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get acctChangePhoto;

  /// No description provided for @acctPersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get acctPersonalDetails;

  /// No description provided for @acctSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get acctSecurity;

  /// No description provided for @acctTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get acctTakePhoto;

  /// No description provided for @acctChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get acctChooseGallery;

  /// No description provided for @acctRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get acctRemovePhoto;

  /// No description provided for @acctPhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed'**
  String get acctPhotoRemoved;

  /// No description provided for @acctCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be opened. Allow camera access in Settings.'**
  String get acctCameraDenied;

  /// No description provided for @acctPhotosDenied.
  ///
  /// In en, this message translates to:
  /// **'Your photos could not be opened. Allow photo access in Settings.'**
  String get acctPhotosDenied;

  /// No description provided for @acctPhotoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading profile photo...'**
  String get acctPhotoUploading;

  /// No description provided for @acctPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get acctPhotoUpdated;

  /// No description provided for @acctNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get acctNameRequired;

  /// No description provided for @commonInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get commonInvalidEmail;

  /// No description provided for @authSignInNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Check your connection and try again.'**
  String get authSignInNetworkError;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authAcceptTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Use and Privacy Policy.'**
  String get authAcceptTermsRequired;

  /// No description provided for @authAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully.'**
  String get authAccountCreated;

  /// No description provided for @authRegisterNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create your account. Check your connection and try again.'**
  String get authRegisterNetworkError;

  /// No description provided for @authAgreePrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authAgreePrefix;

  /// No description provided for @authAgreeAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAgreeAnd;

  /// No description provided for @authResetNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the reset link. Check your connection and try again.'**
  String get authResetNetworkError;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get authPasswordRequired;

  /// No description provided for @bioFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get bioFingerprint;

  /// No description provided for @bioFace.
  ///
  /// In en, this message translates to:
  /// **'Face Recognition'**
  String get bioFace;

  /// No description provided for @bioIris.
  ///
  /// In en, this message translates to:
  /// **'Iris Scan'**
  String get bioIris;

  /// No description provided for @bioStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong Biometric'**
  String get bioStrong;

  /// No description provided for @bioWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak Biometric'**
  String get bioWeak;

  /// No description provided for @boqShareBoq.
  ///
  /// In en, this message translates to:
  /// **'Share BOQ'**
  String get boqShareBoq;

  /// No description provided for @boqUploadEstimates.
  ///
  /// In en, this message translates to:
  /// **'Upload estimated prices'**
  String get boqUploadEstimates;

  /// No description provided for @boqTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get boqTemplate;

  /// No description provided for @boqCodeValue.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String boqCodeValue(String code);

  /// No description provided for @boqNoSummaries.
  ///
  /// In en, this message translates to:
  /// **'No summaries yet'**
  String get boqNoSummaries;

  /// No description provided for @boqNoSummariesMessage.
  ///
  /// In en, this message translates to:
  /// **'Totals appear here once the BOQ items have been priced.'**
  String get boqNoSummariesMessage;

  /// No description provided for @boqGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get boqGrandTotal;

  /// No description provided for @boqSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get boqSummary;

  /// No description provided for @boqSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get boqSubtotal;

  /// No description provided for @boqVat18.
  ///
  /// In en, this message translates to:
  /// **'VAT (18%)'**
  String get boqVat18;

  /// No description provided for @boqContingency5.
  ///
  /// In en, this message translates to:
  /// **'Contingency (5%)'**
  String get boqContingency5;

  /// No description provided for @boqBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get boqBreakdown;

  /// No description provided for @boqItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String boqItemsCount(int count);

  /// No description provided for @boqVat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get boqVat;

  /// No description provided for @boqTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get boqTotal;

  /// No description provided for @boqImportMetadata.
  ///
  /// In en, this message translates to:
  /// **'Import Metadata'**
  String get boqImportMetadata;

  /// No description provided for @boqSheets.
  ///
  /// In en, this message translates to:
  /// **'Sheets'**
  String get boqSheets;

  /// No description provided for @boqSheetRows.
  ///
  /// In en, this message translates to:
  /// **'{sheet} ({rows} rows)'**
  String boqSheetRows(String sheet, int rows);

  /// No description provided for @boqTranslations.
  ///
  /// In en, this message translates to:
  /// **'Translations'**
  String get boqTranslations;

  /// No description provided for @boqStructure.
  ///
  /// In en, this message translates to:
  /// **'BOQ Structure'**
  String get boqStructure;

  /// No description provided for @boqNoHierarchy.
  ///
  /// In en, this message translates to:
  /// **'No hierarchy data available'**
  String get boqNoHierarchy;

  /// No description provided for @boqNoHierarchyMessage.
  ///
  /// In en, this message translates to:
  /// **'Process the BOQ to generate structure.'**
  String get boqNoHierarchyMessage;

  /// No description provided for @boqQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get boqQty;

  /// No description provided for @boqRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get boqRate;

  /// No description provided for @boqAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get boqAmount;

  /// No description provided for @boqItemDetails.
  ///
  /// In en, this message translates to:
  /// **'BOQ Item Details'**
  String get boqItemDetails;

  /// No description provided for @boqQuantityAmount.
  ///
  /// In en, this message translates to:
  /// **'Quantity & amount'**
  String get boqQuantityAmount;

  /// No description provided for @boqQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get boqQuantity;

  /// No description provided for @boqPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get boqPricing;

  /// No description provided for @boqOriginalRate.
  ///
  /// In en, this message translates to:
  /// **'Original Rate'**
  String get boqOriginalRate;

  /// No description provided for @boqAiSuggestedRate.
  ///
  /// In en, this message translates to:
  /// **'AI Suggested Rate'**
  String get boqAiSuggestedRate;

  /// No description provided for @boqAiRateValue.
  ///
  /// In en, this message translates to:
  /// **'{rate} (confidence: {confidence}%)'**
  String boqAiRateValue(String rate, String confidence);

  /// No description provided for @boqApprovedRate.
  ///
  /// In en, this message translates to:
  /// **'Approved Rate'**
  String get boqApprovedRate;

  /// No description provided for @boqPricingSource.
  ///
  /// In en, this message translates to:
  /// **'Pricing Source'**
  String get boqPricingSource;

  /// No description provided for @boqPricingDate.
  ///
  /// In en, this message translates to:
  /// **'Pricing Date'**
  String get boqPricingDate;

  /// No description provided for @boqClassification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get boqClassification;

  /// No description provided for @boqWorkCategory.
  ///
  /// In en, this message translates to:
  /// **'Work Category'**
  String get boqWorkCategory;

  /// No description provided for @boqMaterialCategory.
  ///
  /// In en, this message translates to:
  /// **'Material Category'**
  String get boqMaterialCategory;

  /// No description provided for @boqNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get boqNotes;

  /// No description provided for @boqTranslationMeta.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}  |  Confidence: {confidence}%'**
  String boqTranslationMeta(String provider, String confidence);

  /// No description provided for @boqUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get boqUnknown;

  /// No description provided for @boqNoBoqsYet.
  ///
  /// In en, this message translates to:
  /// **'No BOQs yet'**
  String get boqNoBoqsYet;

  /// No description provided for @boqNoMatchingBoqs.
  ///
  /// In en, this message translates to:
  /// **'No matching BOQs'**
  String get boqNoMatchingBoqs;

  /// No description provided for @boqNoBoqsMessage.
  ///
  /// In en, this message translates to:
  /// **'Import a BOQ into one of your projects to see it here.'**
  String get boqNoBoqsMessage;

  /// No description provided for @commonTryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search.'**
  String get commonTryDifferentSearch;

  /// No description provided for @boqSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search BOQs or projects'**
  String get boqSearchHint;

  /// No description provided for @commonClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get commonClearSearch;

  /// No description provided for @boqUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled BOQ'**
  String get boqUntitled;

  /// No description provided for @boqActions.
  ///
  /// In en, this message translates to:
  /// **'BOQ actions'**
  String get boqActions;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @boqUpdated.
  ///
  /// In en, this message translates to:
  /// **'BOQ updated'**
  String get boqUpdated;

  /// No description provided for @boqEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit BOQ'**
  String get boqEditTitle;

  /// No description provided for @boqName.
  ///
  /// In en, this message translates to:
  /// **'BOQ name'**
  String get boqName;

  /// No description provided for @boqEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get boqEnterName;

  /// No description provided for @boqDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get boqDescriptionOptional;

  /// No description provided for @boqProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get boqProject;

  /// No description provided for @boqDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete BOQ?'**
  String get boqDeleteTitle;

  /// No description provided for @boqDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and all its items will be deleted.'**
  String boqDeleteMessage(String name);

  /// No description provided for @boqThisBoq.
  ///
  /// In en, this message translates to:
  /// **'This BOQ'**
  String get boqThisBoq;

  /// No description provided for @boqDeleted.
  ///
  /// In en, this message translates to:
  /// **'BOQ deleted'**
  String get boqDeleted;

  /// No description provided for @boqTotalsLine.
  ///
  /// In en, this message translates to:
  /// **'Estimated {estimated} · Generated {generated}'**
  String boqTotalsLine(String estimated, String generated);

  /// No description provided for @boqTotals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get boqTotals;

  /// No description provided for @boqTotalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Totals appear once BOQ items have been imported.'**
  String get boqTotalsEmpty;

  /// No description provided for @boqEstimatedAmount.
  ///
  /// In en, this message translates to:
  /// **'Estimated amount'**
  String get boqEstimatedAmount;

  /// No description provided for @boqEstimatedOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} items'**
  String boqEstimatedOf(int done, int total);

  /// No description provided for @boqGeneratedTotal.
  ///
  /// In en, this message translates to:
  /// **'Generated total'**
  String get boqGeneratedTotal;

  /// No description provided for @boqPricedOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} priced'**
  String boqPricedOf(int done, int total);

  /// No description provided for @boqAboveEstimate.
  ///
  /// In en, this message translates to:
  /// **'Above estimate'**
  String get boqAboveEstimate;

  /// No description provided for @boqBelowEstimate.
  ///
  /// In en, this message translates to:
  /// **'Below estimate'**
  String get boqBelowEstimate;

  /// No description provided for @commonFilesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Files could not be opened on this device. Try again.'**
  String get commonFilesUnavailable;

  /// No description provided for @commonFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read. Choose it again.'**
  String get commonFileUnreadable;

  /// No description provided for @boqUploadingEstimates.
  ///
  /// In en, this message translates to:
  /// **'Uploading estimated prices...'**
  String get boqUploadingEstimates;

  /// No description provided for @boqEstimatesSubject.
  ///
  /// In en, this message translates to:
  /// **'Estimated prices – {title}'**
  String boqEstimatesSubject(String title);

  /// No description provided for @dashNoRecentProjects.
  ///
  /// In en, this message translates to:
  /// **'No recent projects yet'**
  String get dashNoRecentProjects;

  /// No description provided for @importCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be opened. Allow camera access in Settings and try again.'**
  String get importCameraDenied;

  /// No description provided for @importPhotosDenied.
  ///
  /// In en, this message translates to:
  /// **'Your photos could not be opened. Allow photo access in Settings and try again.'**
  String get importPhotosDenied;

  /// No description provided for @importUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported. Upload Excel, CSV, PDF or a photo.'**
  String get importUnsupportedType;

  /// No description provided for @importTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is larger than 20 MB. Choose a smaller file.'**
  String get importTooLarge;

  /// No description provided for @importCompressing.
  ///
  /// In en, this message translates to:
  /// **'Compressed {sizes}, uploading...'**
  String importCompressing(String sizes);

  /// No description provided for @importItemsImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 BOQ item} other{Imported {count} BOQ items}}'**
  String importItemsImported(int count);

  /// No description provided for @importOpenProjectToRetry.
  ///
  /// In en, this message translates to:
  /// **'{error} (open the project to retry)'**
  String importOpenProjectToRetry(String error);

  /// No description provided for @importChooseProject.
  ///
  /// In en, this message translates to:
  /// **'Choose project'**
  String get importChooseProject;

  /// No description provided for @importCreateProjectFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a project first, then import its BOQ.'**
  String get importCreateProjectFirst;

  /// No description provided for @importAddBoq.
  ///
  /// In en, this message translates to:
  /// **'Add your BOQ'**
  String get importAddBoq;

  /// No description provided for @importChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get importChoosePhoto;

  /// No description provided for @importChoosePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a BOQ photo from your gallery'**
  String get importChoosePhotoSubtitle;

  /// No description provided for @importUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get importUploading;

  /// No description provided for @notifUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notifUnread;

  /// No description provided for @coCompanyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name *'**
  String get coCompanyNameLabel;

  /// No description provided for @coCompanyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Riverside Builders Ltd'**
  String get coCompanyNameHint;

  /// No description provided for @coRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration Number'**
  String get coRegistrationNumber;

  /// No description provided for @coTin.
  ///
  /// In en, this message translates to:
  /// **'TIN (if applicable)'**
  String get coTin;

  /// No description provided for @coCity.
  ///
  /// In en, this message translates to:
  /// **'District/City'**
  String get coCity;

  /// No description provided for @coCityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. city, town or market'**
  String get coCityHint;

  /// No description provided for @coPhysicalAddress.
  ///
  /// In en, this message translates to:
  /// **'Physical Address'**
  String get coPhysicalAddress;

  /// No description provided for @coPhysicalAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Plot 1, Main Street'**
  String get coPhysicalAddressHint;

  /// No description provided for @coPostalAddress.
  ///
  /// In en, this message translates to:
  /// **'Postal Address'**
  String get coPostalAddress;

  /// No description provided for @coPostalAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. P.O. Box 1234'**
  String get coPostalAddressHint;

  /// No description provided for @coTelephone.
  ///
  /// In en, this message translates to:
  /// **'Telephone'**
  String get coTelephone;

  /// No description provided for @coAltTelephone.
  ///
  /// In en, this message translates to:
  /// **'Alternative Telephone'**
  String get coAltTelephone;

  /// No description provided for @coEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get coEmail;

  /// No description provided for @coWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get coWebsite;

  /// No description provided for @coDescription.
  ///
  /// In en, this message translates to:
  /// **'Company Description'**
  String get coDescription;

  /// No description provided for @coDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'A short description of your business'**
  String get coDescriptionHint;

  /// No description provided for @coLogoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The logo must be 2 MB or smaller.'**
  String get coLogoTooLarge;

  /// No description provided for @coPhotoLibraryDenied.
  ///
  /// In en, this message translates to:
  /// **'The photo library could not be opened. Check the app\'s photo permission.'**
  String get coPhotoLibraryDenied;

  /// No description provided for @coSaved.
  ///
  /// In en, this message translates to:
  /// **'Company profile saved. New BOQ exports will use these details.'**
  String get coSaved;

  /// No description provided for @coCompanyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company details'**
  String get coCompanyDetails;

  /// No description provided for @coLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get coLocation;

  /// No description provided for @coContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get coContact;

  /// No description provided for @coPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'PDF letterhead preview'**
  String get coPreviewTitle;

  /// No description provided for @coPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How your details appear on exported BOQs'**
  String get coPreviewSubtitle;

  /// No description provided for @coLogo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get coLogo;

  /// No description provided for @coNoLogo.
  ///
  /// In en, this message translates to:
  /// **'No logo'**
  String get coNoLogo;

  /// No description provided for @coChooseLogo.
  ///
  /// In en, this message translates to:
  /// **'Choose logo'**
  String get coChooseLogo;

  /// No description provided for @coRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get coRemove;

  /// No description provided for @coLogoManaged.
  ///
  /// In en, this message translates to:
  /// **'The logo is managed by your organisation administrator.'**
  String get coLogoManaged;

  /// No description provided for @coSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Company Profile'**
  String get coSaveProfile;

  /// No description provided for @coProfileManaged.
  ///
  /// In en, this message translates to:
  /// **'This company profile is managed by your organisation administrator.'**
  String get coProfileManaged;

  /// No description provided for @coDetailsKept.
  ///
  /// In en, this message translates to:
  /// **'BOQs keep the company details they were first exported with, even if you change this profile later.'**
  String get coDetailsKept;

  /// No description provided for @coNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required.'**
  String get coNameRequired;

  /// No description provided for @coInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number, including the country code.'**
  String get coInvalidPhone;

  /// No description provided for @coCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get coCountry;

  /// No description provided for @coSelect.
  ///
  /// In en, this message translates to:
  /// **'Select...'**
  String get coSelect;

  /// No description provided for @coYourCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Your Company Name'**
  String get coYourCompanyName;

  /// No description provided for @coBillOfQuantities.
  ///
  /// In en, this message translates to:
  /// **'BILL OF\nQUANTITIES'**
  String get coBillOfQuantities;

  /// No description provided for @coPdfPreview.
  ///
  /// In en, this message translates to:
  /// **'PDF preview'**
  String get coPdfPreview;

  /// No description provided for @sharePreviewPdf.
  ///
  /// In en, this message translates to:
  /// **'Preview PDF'**
  String get sharePreviewPdf;

  /// No description provided for @shareDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get shareDownloadPdf;

  /// No description provided for @shareByEmail.
  ///
  /// In en, this message translates to:
  /// **'Share by Email'**
  String get shareByEmail;

  /// No description provided for @shareOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get shareOnWhatsapp;

  /// No description provided for @shareToOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Share PDF to other apps'**
  String get shareToOtherApps;

  /// No description provided for @sharePdfAndSharing.
  ///
  /// In en, this message translates to:
  /// **'PDF & sharing'**
  String get sharePdfAndSharing;

  /// No description provided for @shareOpeningPreview.
  ///
  /// In en, this message translates to:
  /// **'Opening preview...'**
  String get shareOpeningPreview;

  /// No description provided for @sharePreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'The preview could not be opened on this device.'**
  String get sharePreviewFailed;

  /// No description provided for @shareDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading PDF...'**
  String get shareDownloading;

  /// No description provided for @shareSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String shareSaved(String name);

  /// No description provided for @shareOpenSaveTo.
  ///
  /// In en, this message translates to:
  /// **'Open / Save to'**
  String get shareOpenSaveTo;

  /// No description provided for @sharePreparingWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Preparing WhatsApp message...'**
  String get sharePreparingWhatsapp;

  /// No description provided for @sharePreparingPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF...'**
  String get sharePreparingPdf;

  /// No description provided for @shareEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'BOQ – {title}'**
  String shareEmailSubject(String title);

  /// No description provided for @shareRecipientEmail.
  ///
  /// In en, this message translates to:
  /// **'Recipient email'**
  String get shareRecipientEmail;

  /// No description provided for @shareSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get shareSubject;

  /// No description provided for @shareMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get shareMessageOptional;

  /// No description provided for @shareMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Add a short note for the recipient...'**
  String get shareMessageHint;

  /// No description provided for @sharePdfAttached.
  ///
  /// In en, this message translates to:
  /// **'The BOQ PDF is attached automatically.'**
  String get sharePdfAttached;

  /// No description provided for @shareSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get shareSend;

  /// No description provided for @connNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get connNoInternet;

  /// No description provided for @connConnectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please connect to Wi-Fi or mobile data to continue.'**
  String get connConnectPrompt;

  /// No description provided for @connChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get connChecking;

  /// No description provided for @connOpenWifi.
  ///
  /// In en, this message translates to:
  /// **'Open Wi-Fi Settings'**
  String get connOpenWifi;

  /// No description provided for @connOpenMobileData.
  ///
  /// In en, this message translates to:
  /// **'Open Mobile Data Settings'**
  String get connOpenMobileData;

  /// No description provided for @connOpenNetwork.
  ///
  /// In en, this message translates to:
  /// **'Open Network Settings'**
  String get connOpenNetwork;

  /// No description provided for @connAutoContinue.
  ///
  /// In en, this message translates to:
  /// **'The app continues automatically once you are back online.'**
  String get connAutoContinue;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;
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
