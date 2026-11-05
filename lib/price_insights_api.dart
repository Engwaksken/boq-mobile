part of 'api_client.dart';

// Price history and comparison endpoints: monthly market history, recent price
// changes, a BOQ's rates against today's market, BOQ item rate history and plan
// price changes. Each uses the same server logic as the matching web page.

extension PriceInsightsApi on ApiClient {
  Future<Map<String, dynamic>> _getJson(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    final response = await _httpClient.get(
      Uri.parse(
        '${ApiClient.baseUrl}/$path',
      ).replace(queryParameters: query.isEmpty ? null : query),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return body;
  }

  /// A price summarised per month, newest month first ([months]: 6, 12 or 24).
  Future<MonthlyPriceHistory> hardwarePriceMonthly(
    int id, {
    int months = 12,
  }) async => MonthlyPriceHistory.fromJson(
    jsonMap(
      (await _getJson('hardware-prices/$id/monthly', {
        'months': '$months',
      }))['data'],
    ),
  );

  /// The latest change of every visible price, with counts for the filters.
  Future<PriceChangesResult> hardwarePriceChanges({
    String period = '30',
    String direction = '',
    String category = '',
    String source = '',
    String sort = 'recent',
    String search = '',
    int page = 1,
    int perPage = 20,
  }) async => PriceChangesResult.fromJson(
    await _getJson('hardware-prices/changes', {
      'period': period,
      if (direction.isNotEmpty) 'direction': direction,
      if (category.isNotEmpty) 'category': category,
      if (source.isNotEmpty) 'source': source,
      'sort': sort,
      if (search.trim().isNotEmpty) 'search': search.trim(),
      'page': '$page',
      'per_page': '$perPage',
    }),
  );

  /// Each matched BOQ item's rate against today's market price.
  Future<BoqPriceCheck> boqPriceCheck(
    int boqId, {
    String filter = 'all',
  }) async => BoqPriceCheck.fromJson(
    jsonMap(
      (await _getJson('boqs/$boqId/price-check', {'filter': filter}))['data'],
    ),
  );

  /// Changes to one BOQ item's original, suggested, reviewed or approved rate.
  Future<List<BoqItemRateChange>> boqItemRateHistory(int boqItemId) async {
    final data = jsonMap(
      (await _getJson('boq-items/$boqItemId/price-history', {
        'per_page': '100',
      }))['data'],
    );
    return jsonMaps(data['data']).map(BoqItemRateChange.fromJson).toList();
  }

  /// Plan price changes: [scope] "mine" (plans I subscribe to) or "all".
  Future<PlanPriceChangesResult> planPriceHistory({
    String scope = 'mine',
    int page = 1,
  }) async => PlanPriceChangesResult.fromJson(
    await _getJson('plans/price-history', {'scope': scope, 'page': '$page'}),
  );
}

class MonthlyPriceHistory {
  const MonthlyPriceHistory({required this.item, required this.months});

  factory MonthlyPriceHistory.fromJson(Map<String, dynamic> json) =>
      MonthlyPriceHistory(
        item: HardwarePrice.fromJson(jsonMap(json['item'])),
        months: jsonMaps(json['months']).map(MonthlyPrice.fromJson).toList(),
      );

  final HardwarePrice item;

  /// Newest month first; months without recordings have [MonthlyPrice.records] 0.
  final List<MonthlyPrice> months;

  /// Months with recordings, oldest first (for the trend chart).
  List<MonthlyPrice> get trend =>
      months.where((m) => m.average != null).toList().reversed.toList();

  /// The newest month with recordings and a change from the month before.
  MonthlyPrice? get latestChange =>
      months.where((m) => m.average != null && m.change != null).firstOrNull;
}

class MonthlyPrice {
  const MonthlyPrice({
    required this.month,
    required this.records,
    this.low,
    this.high,
    this.average,
    this.closing,
    this.change,
    this.changePercent,
  });

  factory MonthlyPrice.fromJson(Map<String, dynamic> json) => MonthlyPrice(
    month: jsonStringOrNull(json['month']) ?? '',
    records: jsonIntOrNull(json['records']) ?? 0,
    low: jsonDoubleOrNull(json['low']),
    high: jsonDoubleOrNull(json['high']),
    average: jsonDoubleOrNull(json['average']),
    closing: jsonDoubleOrNull(json['closing']),
    change: jsonDoubleOrNull(json['change']),
    changePercent: jsonDoubleOrNull(json['change_percent']),
  );

  /// "YYYY-MM".
  final String month;
  final int records;
  final double? low;
  final double? high;
  final double? average;

  /// The last price recorded in the month.
  final double? closing;

  /// Change of the average against the previous month with recordings.
  final double? change;
  final double? changePercent;

  DateTime? get date => DateTime.tryParse('$month-01');
}

class PriceChangeStats {
  const PriceChangeStats({
    required this.total,
    required this.up,
    required this.down,
    this.average,
  });

  factory PriceChangeStats.fromJson(Map<String, dynamic> json) =>
      PriceChangeStats(
        total: jsonIntOrNull(json['total']) ?? 0,
        up: jsonIntOrNull(json['up']) ?? 0,
        down: jsonIntOrNull(json['down']) ?? 0,
        average: jsonDoubleOrNull(json['average']),
      );

  final int total;
  final int up;
  final int down;

  /// Average change in percent.
  final double? average;
}

class PriceChangesResult {
  const PriceChangesResult({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.stats,
    required this.categories,
  });

  factory PriceChangesResult.fromJson(Map<String, dynamic> json) {
    final data = jsonMap(json['data']);
    final meta = jsonMap(json['meta']);
    return PriceChangesResult(
      items: jsonMaps(data['data']).map(HardwarePrice.fromJson).toList(),
      page: jsonIntOrNull(data['current_page']) ?? 1,
      lastPage: jsonIntOrNull(data['last_page']) ?? 1,
      stats: PriceChangeStats.fromJson(jsonMap(meta['stats'])),
      categories: jsonList(
        meta['categories'],
      ).map((c) => '$c').where((c) => c.isNotEmpty).toList(),
    );
  }

  final List<HardwarePrice> items;
  final int page;
  final int lastPage;
  final PriceChangeStats stats;
  final List<String> categories;

  bool get hasNext => page < lastPage;
}

class BoqPriceCheck {
  const BoqPriceCheck({
    required this.currency,
    required this.summary,
    required this.rows,
  });

  factory BoqPriceCheck.fromJson(Map<String, dynamic> json) => BoqPriceCheck(
    currency: jsonStringOrNull(json['currency']) ?? 'UGX',
    summary: BoqPriceCheckSummary.fromJson(jsonMap(json['summary'])),
    rows: jsonMaps(json['rows']).map(BoqPriceCheckRow.fromJson).toList(),
  );

  final String currency;
  final BoqPriceCheckSummary summary;
  final List<BoqPriceCheckRow> rows;
}

class BoqPriceCheckSummary {
  const BoqPriceCheckSummary({
    required this.matched,
    required this.unmatched,
    required this.above,
    required this.below,
    required this.changed,
    required this.totalOurs,
    required this.totalMarket,
    required this.totalDifference,
    this.totalPercent,
  });

  factory BoqPriceCheckSummary.fromJson(Map<String, dynamic> json) =>
      BoqPriceCheckSummary(
        matched: jsonIntOrNull(json['matched']) ?? 0,
        unmatched: jsonIntOrNull(json['unmatched']) ?? 0,
        above: jsonIntOrNull(json['above']) ?? 0,
        below: jsonIntOrNull(json['below']) ?? 0,
        changed: jsonIntOrNull(json['changed']) ?? 0,
        totalOurs: jsonDoubleOrNull(json['total_ours']) ?? 0,
        totalMarket: jsonDoubleOrNull(json['total_market']) ?? 0,
        totalDifference: jsonDoubleOrNull(json['total_difference']) ?? 0,
        totalPercent: jsonDoubleOrNull(json['total_percent']),
      );

  final int matched;
  final int unmatched;

  /// Items whose rate is above today's market.
  final int above;

  /// Items whose rate is below today's market.
  final int below;

  /// Items whose market price moved since they were matched.
  final int changed;
  final double totalOurs;
  final double totalMarket;

  /// Market total minus our total (positive: the market is now higher).
  final double totalDifference;
  final double? totalPercent;
}

class BoqPriceCheckRow {
  const BoqPriceCheckRow({
    required this.boqItemId,
    required this.itemCode,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.currency,
    required this.comparable,
    required this.marketId,
    required this.marketName,
    required this.marketPrice,
    required this.marketCurrency,
    required this.marketUnit,
    required this.marketSupplier,
    required this.marketFetchedAt,
    this.rate,
    this.rateField,
    this.difference,
    this.percent,
    this.sinceMatch,
  });

  factory BoqPriceCheckRow.fromJson(Map<String, dynamic> json) {
    final market = jsonMap(json['market']);
    return BoqPriceCheckRow(
      boqItemId: jsonInt(json['boq_item_id']),
      itemCode: jsonStringOrNull(json['item_code']) ?? '',
      description: jsonStringOrNull(json['description']) ?? '',
      quantity: jsonDoubleOrNull(json['quantity']) ?? 0,
      unit: jsonStringOrNull(json['unit']) ?? '',
      currency: jsonStringOrNull(json['currency']) ?? 'UGX',
      comparable: json['comparable'] == true,
      rate: jsonDoubleOrNull(json['rate']),
      rateField: jsonStringOrNull(json['rate_field']),
      difference: jsonDoubleOrNull(json['difference']),
      percent: jsonDoubleOrNull(json['percent']),
      sinceMatch: jsonDoubleOrNull(json['since_match']),
      marketId: jsonInt(market['id']),
      marketName: jsonStringOrNull(market['item_name']) ?? '',
      marketPrice: jsonDoubleOrNull(market['price']) ?? 0,
      marketCurrency: jsonStringOrNull(market['currency']) ?? 'UGX',
      marketUnit: jsonStringOrNull(market['unit']) ?? '',
      marketSupplier: jsonStringOrNull(market['supplier']) ?? '',
      marketFetchedAt: jsonStringOrNull(market['fetched_at']) ?? '',
    );
  }

  final int boqItemId;
  final String itemCode;
  final String description;
  final double quantity;
  final String unit;
  final String currency;

  /// False when there is no rate yet or the currencies differ.
  final bool comparable;
  final double? rate;

  /// approved_rate, reviewed_rate, ai_suggested_rate or original_rate.
  final String? rateField;

  /// Market price minus our rate.
  final double? difference;
  final double? percent;

  /// How much the market moved since the item was matched.
  final double? sinceMatch;
  final int marketId;
  final String marketName;
  final double marketPrice;
  final String marketCurrency;
  final String marketUnit;
  final String marketSupplier;
  final String marketFetchedAt;
}

class BoqItemRateChange {
  const BoqItemRateChange({
    required this.id,
    required this.field,
    required this.currency,
    required this.changedAt,
    required this.userName,
    this.oldValue,
    this.newValue,
  });

  factory BoqItemRateChange.fromJson(Map<String, dynamic> json) =>
      BoqItemRateChange(
        id: jsonInt(json['id']),
        field: jsonStringOrNull(json['field']) ?? '',
        currency: jsonStringOrNull(json['currency']) ?? 'UGX',
        changedAt: jsonStringOrNull(json['changed_at']) ?? '',
        userName: jsonStringOrNull(jsonMap(json['user'])['name']) ?? '',
        oldValue: jsonDoubleOrNull(json['old_value']),
        newValue: jsonDoubleOrNull(json['new_value']),
      );

  final int id;

  /// original_rate, ai_suggested_rate, reviewed_rate or approved_rate.
  final String field;
  final String currency;
  final String changedAt;

  /// Who made the change; empty for system changes.
  final String userName;
  final double? oldValue;
  final double? newValue;

  double? get change =>
      oldValue != null && newValue != null ? newValue! - oldValue! : null;
}

class PlanPriceChange {
  const PlanPriceChange({
    required this.id,
    required this.planName,
    required this.planType,
    required this.newPrice,
    required this.newCurrency,
    required this.changedAt,
    required this.isMyPlan,
    this.oldPrice,
    this.oldCurrency,
    this.difference,
    this.percentChange,
  });

  factory PlanPriceChange.fromJson(Map<String, dynamic> json) {
    final plan = jsonMap(json['plan']);
    return PlanPriceChange(
      id: jsonInt(json['id']),
      planName: jsonStringOrNull(plan['name']) ?? '',
      planType: jsonStringOrNull(plan['type']) ?? '',
      oldPrice: jsonDoubleOrNull(json['old_price']),
      newPrice: jsonDoubleOrNull(json['new_price']) ?? 0,
      oldCurrency: jsonStringOrNull(json['old_currency']),
      newCurrency: jsonStringOrNull(json['new_currency']) ?? 'UGX',
      difference: jsonDoubleOrNull(json['difference']),
      percentChange: jsonDoubleOrNull(json['percent_change']),
      changedAt: jsonStringOrNull(json['changed_at']) ?? '',
      isMyPlan: json['is_my_plan'] == true,
    );
  }

  final int id;
  final String planName;
  final String planType;

  /// Null for a plan's first (initial) price.
  final double? oldPrice;
  final double newPrice;
  final String? oldCurrency;
  final String newCurrency;
  final double? difference;
  final double? percentChange;
  final String changedAt;
  final bool isMyPlan;
}

class PlanPriceChangesResult {
  const PlanPriceChangesResult({
    required this.items,
    required this.page,
    required this.lastPage,
  });

  factory PlanPriceChangesResult.fromJson(Map<String, dynamic> json) {
    final data = jsonMap(json['data']);
    return PlanPriceChangesResult(
      items: jsonMaps(data['data']).map(PlanPriceChange.fromJson).toList(),
      page: jsonIntOrNull(data['current_page']) ?? 1,
      lastPage: jsonIntOrNull(data['last_page']) ?? 1,
    );
  }

  final List<PlanPriceChange> items;
  final int page;
  final int lastPage;

  bool get hasNext => page < lastPage;
}
