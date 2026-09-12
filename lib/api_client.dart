import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? storage})
    : _httpClient = httpClient ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const _tokenKey = 'auth_token';
  final http.Client _httpClient;
  final FlutterSecureStorage _storage;

  Future<bool> hasSession() async =>
      (await _storage.read(key: _tokenKey)) != null;

  Future<void> login({required String email, required String password}) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }

    final token = body['data']?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException('The server did not return an access token.');
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<DashboardSummary> dashboard() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return DashboardSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<UserProfile> profile() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return UserProfile.fromJson(body['data']['user'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> currentSubscription() async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/subscriptions/current'), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data'] as Map<String, dynamic>;
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String email,
    required String locale,
    String? password,
  }) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _headers(),
      body: {
        'name': name,
        'email': email,
        'locale': locale,
        if (password != null && password.isNotEmpty) ...{
          'password': password,
          'password_confirmation': password,
        },
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return UserProfile.fromJson(body['data']['user'] as Map<String, dynamic>);
  }

  Future<List<ProjectSummary>> projects() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/projects'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    final page = body['data'] as Map<String, dynamic>;
    return (page['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProjectSummary.fromJson)
        .toList();
  }

  Future<ProjectDetail> project(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/projects/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return ProjectDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ProjectSummary> createProject({
    required String name,
    String? code,
    required String currency,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/projects'),
      headers: await _headers(),
      body: {
        'name': name,
        if (code != null && code.isNotEmpty) 'code': code,
        'currency': currency,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) {
      throw ApiException(_message(body));
    }
    return ProjectSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ProjectDetail> updateProject({
    required int id,
    String? name,
    String? code,
    String? client,
    String? contractor,
    String? consultant,
    String? quantitySurveyor,
    String? projectManager,
    String? siteEngineer,
    String? fundingOrganisation,
    String? country,
    String? district,
    String? location,
    String? projectType,
    String? startDate,
    String? expectedCompletionDate,
    double? contractValue,
    String? currency,
    String? description,
    String? status,
  }) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl/projects/$id'),
      headers: await _headers(),
      body: {
        if (name != null) 'name': name,
        if (code != null) 'code': code,
        if (client != null) 'client': client,
        if (contractor != null) 'contractor': contractor,
        if (consultant != null) 'consultant': consultant,
        if (quantitySurveyor != null) 'quantity_surveyor': quantitySurveyor,
        if (projectManager != null) 'project_manager': projectManager,
        if (siteEngineer != null) 'site_engineer': siteEngineer,
        if (fundingOrganisation != null) 'funding_organisation': fundingOrganisation,
        if (country != null) 'country': country,
        if (district != null) 'district': district,
        if (location != null) 'location': location,
        if (projectType != null) 'project_type': projectType,
        if (startDate != null) 'start_date': startDate,
        if (expectedCompletionDate != null) 'expected_completion_date': expectedCompletionDate,
        if (contractValue != null) 'contract_value': contractValue,
        if (currency != null) 'currency': currency,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return ProjectDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteProject(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/projects/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
  }

  Future<HardwarePricePaginated> hardwarePrices({
    String? category,
    String? supplier,
    String? location,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? dateFrom,
    String? dateTo,
    String sortBy = 'fetched_at',
    String sortDir = 'desc',
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (supplier != null) queryParams['supplier'] = supplier;
    if (location != null) queryParams['location'] = location;
    if (search != null) queryParams['search'] = search;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (dateFrom != null) queryParams['date_from'] = dateFrom;
    if (dateTo != null) queryParams['date_to'] = dateTo;
    queryParams['sort_by'] = sortBy;
    queryParams['sort_dir'] = sortDir;
    queryParams['page'] = page.toString();
    queryParams['per_page'] = perPage.toString();

    final uri = Uri.parse('$baseUrl/hardware-prices').replace(queryParameters: queryParams);
    final response = await _httpClient.get(uri, headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return HardwarePricePaginated.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<HardwarePrice> hardwarePrice(int id) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/hardware-prices/$id'), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return HardwarePrice.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<HardwarePriceHistory> hardwarePriceHistory(int id, {int page = 1, int perPage = 50}) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/hardware-prices/$id/history').replace(queryParameters: {'page': page.toString(), 'per_page': perPage.toString()}), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return HardwarePriceHistory.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<HardwarePriceStatistics> hardwarePriceStatistics() async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/hardware-prices/statistics'), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return HardwarePriceStatistics.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<HardwarePriceCategory>> hardwarePriceCategories() async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/hardware-prices/categories'), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(HardwarePriceCategory.fromJson).toList();
  }

  Future<List<PriceComparisonItem>> hardwarePriceRecommendations({String? category, String? location, int limit = 10}) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (location != null) queryParams['location'] = location;
    queryParams['limit'] = limit.toString();
    final response = await _httpClient.get(Uri.parse('$baseUrl/hardware-prices/recommendations').replace(queryParameters: queryParams), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>().map(PriceComparisonItem.fromJson).toList();
  }

  Future<PriceComparisonResult> hardwarePriceCompare(List<int> ids) async {
    final response = await _httpClient.post(Uri.parse('$baseUrl/hardware-prices/compare'), headers: await _headers(), body: {'ids': ids});
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return PriceComparisonResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqItemPriceMatch> matchBoqItem(int boqItemId) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/boq-items/$boqItemId/matches'), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqItemPriceMatch.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqItemSummary> applyPriceToBoqItem(int boqItemId, int hardwarePriceId) async {
    final response = await _httpClient.post(Uri.parse('$baseUrl/boq-items/$boqItemId/apply-price'), headers: await _headers(), body: {'hardware_price_id': hardwarePriceId});
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqItemSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> uploadBoq({required int projectId, required String filePath}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/boqs'));
    request.headers.addAll(await _headers());
    request.fields['project_id'] = '$projectId';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) throw ApiException('Upload failed: ${response.statusCode}');
  }

  Future<void> uploadBoqFromBytes({required int projectId, required String fileName, required Uint8List bytes}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/boqs'));
    request.headers.addAll(await _headers());
    request.fields['project_id'] = '$projectId';
    request.fields['name'] = fileName;
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) throw ApiException('Upload failed: ${response.statusCode}');
  }

  Future<int> processBoq(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$id/process'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data']['items_created'] as int? ?? 0;
  }

  Future<List<BoqItemSummary>> boqItems(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data']['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(BoqItemSummary.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> priceItem(int id, String location) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boq-items/$id/price'),
      headers: await _headers(),
      body: {'location': location},
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data'] as Map<String, dynamic>;
  }

  Future<int> priceAll(int boqId, String location) async {
    final response = await _httpClient.post(Uri.parse('$baseUrl/boqs/$boqId/price-all'), headers: await _headers(), body: {'location': location});
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data']['items_priced'] as int? ?? 0;
  }

  Future<List<Map<String, dynamic>>> pricingHistory(int boqId, String location) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/boqs/$boqId/pricing-history/$location'), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>().toList();
  }

  Future<PricingBatch> startPricingBatch(int boqId, String location) async {
    final response = await _httpClient.post(Uri.parse('$baseUrl/boqs/$boqId/pricing-batches'), headers: await _headers(), body: {'location': location});
    final body = _decode(response);
    if (response.statusCode != 202) throw ApiException(_message(body));
    return PricingBatch.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<PricingBatch> pricingBatch(int id) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/pricing-batches/$id'), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return PricingBatch.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<int>> pdf(int boqId) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl/boqs/$boqId/pdf'), headers: await _headers());
    if (response.statusCode != 200) throw const ApiException('Unable to generate the BOQ PDF.');
    return response.bodyBytes;
  }

  Future<void> logout() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      await _httpClient.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _headers(),
      );
    }
    await _storage.delete(key: _tokenKey);
  }

  Future<Map<String, dynamic>> fetchDailyPrices() async {
    final response = await _httpClient.post(Uri.parse('$baseUrl/hardware-prices/fetch'), headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: _tokenKey);
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    }
  }

  String _message(Map<String, dynamic> body) =>
      body['message'] as String? ?? 'Unable to complete the request.';
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalProjects,
    required this.activeProjects,
    required this.boqsAwaitingReview,
    required this.totalEstimatedValue,
    required this.recentProjects,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalProjects: json['total_projects'] as int? ?? 0,
        activeProjects: json['active_projects'] as int? ?? 0,
        boqsAwaitingReview: json['boqs_awaiting_review'] as int? ?? 0,
        totalEstimatedValue:
            (json['total_estimated_value'] as num?)?.toDouble() ?? 0,
        recentProjects: (json['recent_projects'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ProjectSummary.fromJson)
            .toList(),
      );

  final int totalProjects;
  final int activeProjects;
  final int boqsAwaitingReview;
  final double totalEstimatedValue;
  final List<ProjectSummary> recentProjects;
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.locale,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    locale: json['locale'] as String? ?? 'en',
  );

  final String name;
  final String email;
  final String locale;
}

class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    required this.boqCount,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) => ProjectSummary(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    status: json['status'] as String? ?? 'draft',
    boqCount: json['boqs_count'] as int? ?? 0,
  );

  final String name;
  final int id;
  final String code;
  final String status;
  final int boqCount;
}

class ProjectDetail {
  const ProjectDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.client,
    required this.contractor,
    required this.consultant,
    required this.quantitySurveyor,
    required this.projectManager,
    required this.siteEngineer,
    required this.fundingOrganisation,
    required this.country,
    required this.district,
    required this.location,
    required this.projectType,
    required this.startDate,
    required this.expectedCompletionDate,
    required this.contractValue,
    required this.currency,
    required this.description,
    required this.status,
    required this.ownerName,
    required this.boqs,
  });
  factory ProjectDetail.fromJson(Map<String, dynamic> json) => ProjectDetail(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    client: json['client'] as String? ?? '',
    contractor: json['contractor'] as String? ?? '',
    consultant: json['consultant'] as String? ?? '',
    quantitySurveyor: json['quantity_surveyor'] as String? ?? '',
    projectManager: json['project_manager'] as String? ?? '',
    siteEngineer: json['site_engineer'] as String? ?? '',
    fundingOrganisation: json['funding_organisation'] as String? ?? '',
    country: json['country'] as String? ?? '',
    district: json['district'] as String? ?? '',
    location: json['location'] as String? ?? '',
    projectType: json['project_type'] as String? ?? '',
    startDate: json['start_date'] as String? ?? '',
    expectedCompletionDate: json['expected_completion_date'] as String? ?? '',
    contractValue: (json['contract_value'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'UGX',
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? 'draft',
    ownerName: json['user']?['name'] as String? ?? '',
    boqs: (json['boqs'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BoqSummary.fromJson)
        .toList(),
  );
  final int id;
  final String name;
  final String code;
  final String client;
  final String contractor;
  final String consultant;
  final String quantitySurveyor;
  final String projectManager;
  final String siteEngineer;
  final String fundingOrganisation;
  final String country;
  final String district;
  final String location;
  final String projectType;
  final String startDate;
  final String expectedCompletionDate;
  final double contractValue;
  final String currency;
  final String description;
  final String status;
  final String ownerName;
  final List<BoqSummary> boqs;
}

class BoqSummary {
  const BoqSummary({
    required this.id,
    required this.name,
    required this.status,
  });
  factory BoqSummary.fromJson(Map<String, dynamic> json) => BoqSummary(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    status: json['status'] as String? ?? 'draft',
  );
  final int id;
  final String name;
  final String status;
}

class BoqItemSummary {
  const BoqItemSummary({
    required this.id,
    required this.code,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.amount,
    required this.currentRate,
    required this.aiRate,
  });
  factory BoqItemSummary.fromJson(Map<String, dynamic> json) => BoqItemSummary(
    id: json['id'] as int,
    code: json['item_code'] as String? ?? '',
    description: json['description'] as String? ?? '',
    quantity: '${json['quantity'] ?? 0}',
    unit: json['unit'] as String? ?? '',
    amount: '${json['amount'] ?? 0}',
    currentRate: '${json['ai_suggested_rate'] ?? json['approved_rate'] ?? json['original_rate'] ?? 0}',
    aiRate: '${json['ai_suggested_rate'] ?? 0}',
  );
  final int id;
  final String code;
  final String description;
  final String quantity;
  final String unit;
  final String amount;
  final String currentRate;
  final String aiRate;
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
}

class PricingBatch {
  const PricingBatch({required this.id, required this.status, required this.total, required this.processed, required this.failed});
  factory PricingBatch.fromJson(Map<String, dynamic> json) => PricingBatch(id: json['id'] as int, status: json['status'] as String, total: json['total_items'] as int, processed: json['processed_items'] as int, failed: json['failed_items'] as int);
  final int id;
  final String status;
  final int total;
  final int processed;
  final int failed;
}

class HardwarePrice {
  const HardwarePrice({
    required this.id,
    required this.itemName,
    required this.brand,
    required this.category,
    required this.specification,
    required this.unit,
    required this.price,
    required this.currency,
    required this.supplier,
    required this.location,
    required this.sourceReference,
    required this.fetchedAt,
    required this.isActive,
    this.priceHistory = const [],
  });
  factory HardwarePrice.fromJson(Map<String, dynamic> json) => HardwarePrice(
    id: json['id'] as int,
    itemName: json['item_name'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    category: json['category'] as String? ?? '',
    specification: json['specification'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'UGX',
    supplier: json['supplier'] as String? ?? '',
    location: json['location'] as String? ?? '',
    sourceReference: json['source_reference'] as String? ?? '',
    fetchedAt: json['fetched_at'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    priceHistory: json['price_histories'] != null
        ? (json['price_histories'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(PriceHistory.fromJson)
            .toList()
        : [],
  );
  final int id;
  final String itemName;
  final String brand;
  final String category;
  final String specification;
  final String unit;
  final double price;
  final String currency;
  final String supplier;
  final String location;
  final String sourceReference;
  final String fetchedAt;
  final bool isActive;
  final List<PriceHistory> priceHistory;
}

class PriceHistory {
  const PriceHistory({
    required this.id,
    required this.price,
    required this.currency,
    required this.supplier,
    required this.location,
    required this.recordedAt,
  });
  factory PriceHistory.fromJson(Map<String, dynamic> json) => PriceHistory(
    id: json['id'] as int,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'UGX',
    supplier: json['supplier'] as String? ?? '',
    location: json['location'] as String? ?? '',
    recordedAt: json['recorded_at'] as String? ?? '',
  );
  final int id;
  final double price;
  final String currency;
  final String supplier;
  final String location;
  final String recordedAt;
}

class HardwarePriceStatistics {
  const HardwarePriceStatistics({
    required this.itemsTracked,
    required this.pricesUpdatedToday,
    required this.averagePriceChange,
    required this.suppliersTracked,
    required this.lowestPriceOpportunities,
    required this.boqItemsWithUpdatedPrices,
  });
  factory HardwarePriceStatistics.fromJson(Map<String, dynamic> json) => HardwarePriceStatistics(
    itemsTracked: json['items_tracked'] as int? ?? 0,
    pricesUpdatedToday: json['prices_updated_today'] as int? ?? 0,
    averagePriceChange: (json['average_price_change'] as num?)?.toDouble() ?? 0.0,
    suppliersTracked: json['suppliers_tracked'] as int? ?? 0,
    lowestPriceOpportunities: json['lowest_price_opportunities'] as int? ?? 0,
    boqItemsWithUpdatedPrices: json['boq_items_with_updated_prices'] as int? ?? 0,
  );
  final int itemsTracked;
  final int pricesUpdatedToday;
  final double averagePriceChange;
  final int suppliersTracked;
  final int lowestPriceOpportunities;
  final int boqItemsWithUpdatedPrices;
}

class PriceComparisonItem {
  const PriceComparisonItem({
    required this.id,
    required this.itemName,
    required this.brand,
    required this.category,
    required this.specification,
    required this.unit,
    required this.price,
    required this.currency,
    required this.supplier,
    required this.location,
    required this.sourceReference,
    required this.fetchedAt,
    required this.similarityScore,
    required this.matchReasons,
    required this.variancePercent,
    required this.priceHistory,
    required this.rating,
    this.badges = const [],
  });
  factory PriceComparisonItem.fromJson(Map<String, dynamic> json) => PriceComparisonItem(
    id: json['id'] as int,
    itemName: json['item_name'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    category: json['category'] as String? ?? '',
    specification: json['specification'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'UGX',
    supplier: json['supplier'] as String? ?? '',
    location: json['location'] as String? ?? '',
    sourceReference: json['source_reference'] as String? ?? '',
    fetchedAt: json['fetched_at'] as String? ?? '',
    similarityScore: json['similarity_score'] as int? ?? 0,
    matchReasons: (json['match_reasons'] as List<dynamic>? ?? []).cast<String>(),
    variancePercent: (json['variance_percent'] as num?)?.toDouble(),
    priceHistory: PriceHistorySummary.fromJson(json['price_history'] ?? {}),
    rating: PriceRating.fromJson(json['rating'] ?? {}),
    badges: (json['badges'] as List<dynamic>? ?? []).cast<String>(),
  );
  final int id;
  final String itemName;
  final String brand;
  final String category;
  final String specification;
  final String unit;
  final double price;
  final String currency;
  final String supplier;
  final String location;
  final String sourceReference;
  final String fetchedAt;
  final int similarityScore;
  final List<String> matchReasons;
  final double? variancePercent;
  final PriceHistorySummary priceHistory;
  final PriceRating rating;
  final List<String> badges;
}

class PriceHistorySummary {
  const PriceHistorySummary({
    required this.records,
    required this.lowest,
    required this.highest,
    required this.average,
    required this.change,
    required this.changePercent,
    required this.trend,
  });
  factory PriceHistorySummary.fromJson(Map<String, dynamic> json) => PriceHistorySummary(
    records: json['records'] as int? ?? 0,
    lowest: (json['lowest'] as num?)?.toDouble() ?? 0.0,
    highest: (json['highest'] as num?)?.toDouble() ?? 0.0,
    average: (json['average'] as num?)?.toDouble() ?? 0.0,
    change: (json['change'] as num?)?.toDouble() ?? 0.0,
    changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0.0,
    trend: json['trend'] as String? ?? 'stable',
  );
  final int records;
  final double lowest;
  final double highest;
  final double average;
  final double change;
  final double changePercent;
  final String trend;
}

class PriceRating {
  const PriceRating({
    required this.overall,
    required this.valueScore,
    required this.stabilityScore,
    required this.freshnessScore,
    required this.supplierScore,
    required this.availabilityScore,
    required this.factors,
  });
  factory PriceRating.fromJson(Map<String, dynamic> json) => PriceRating(
    overall: json['overall'] as int? ?? 0,
    valueScore: json['value_score'] as int? ?? 0,
    stabilityScore: json['stability_score'] as int? ?? 0,
    freshnessScore: json['freshness_score'] as int? ?? 0,
    supplierScore: json['supplier_score'] as int? ?? 0,
    availabilityScore: json['availability_score'] as int? ?? 0,
    factors: (json['factors'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as String)),
  );
  final int overall;
  final int valueScore;
  final int stabilityScore;
  final int freshnessScore;
  final int supplierScore;
  final int availabilityScore;
  final Map<String, String> factors;
}

class BoqItemPriceMatch {
  const BoqItemPriceMatch({
    required this.boqItem,
    required this.matches,
  });
  factory BoqItemPriceMatch.fromJson(Map<String, dynamic> json) => BoqItemPriceMatch(
    boqItem: BoqItemMatchInfo.fromJson(json['boq_item'] ?? {}),
    matches: (json['matches'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(PriceComparisonItem.fromJson)
        .toList(),
  );
  final BoqItemMatchInfo boqItem;
  final List<PriceComparisonItem> matches;
}

class BoqItemMatchInfo {
  const BoqItemMatchInfo({
    required this.description,
    required this.quantity,
    required this.unit,
    required this.currentRate,
    required this.currency,
    required this.currentAmount,
  });
  factory BoqItemMatchInfo.fromJson(Map<String, dynamic> json) => BoqItemMatchInfo(
    description: json['description'] as String? ?? '',
    quantity: json['quantity'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    currentRate: (json['current_rate'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'UGX',
    currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
  );
  final String description;
  final String quantity;
  final String unit;
  final double currentRate;
  final String currency;
  final double currentAmount;
}

class HardwarePricePaginated {
  const HardwarePricePaginated({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });
  factory HardwarePricePaginated.fromJson(Map<String, dynamic> json) => HardwarePricePaginated(
    data: (json['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>().map(HardwarePrice.fromJson).toList(),
    currentPage: json['current_page'] as int? ?? 1,
    lastPage: json['last_page'] as int? ?? 1,
    perPage: json['per_page'] as int? ?? 20,
    total: json['total'] as int? ?? 0,
  );
  final List<HardwarePrice> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
}

class HardwarePriceHistory {
  const HardwarePriceHistory({
    required this.item,
    required this.summary,
    required this.history,
  });
  factory HardwarePriceHistory.fromJson(Map<String, dynamic> json) => HardwarePriceHistory(
    item: HardwarePrice.fromJson((json['item'] as Map<String, dynamic>?) ?? {}),
    summary: PriceHistorySummary.fromJson((json['summary'] as Map<String, dynamic>?) ?? {}),
    history: ((json['history'] as Map<String, dynamic>?)?['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>().map(PriceHistory.fromJson).toList(),
  );
  final HardwarePrice item;
  final PriceHistorySummary summary;
  final List<PriceHistory> history;
}

class HardwarePriceCategory {
  const HardwarePriceCategory({required this.name, required this.count});
  factory HardwarePriceCategory.fromJson(Map<String, dynamic> json) => HardwarePriceCategory(name: json['name'] as String? ?? '', count: json['count'] as int? ?? 0);
  final String name;
  final int count;
}

class PriceComparisonResult {
  const PriceComparisonResult({required this.items, required this.summary});
  factory PriceComparisonResult.fromJson(Map<String, dynamic> json) => PriceComparisonResult(
    items: (json['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>().map(PriceComparisonItem.fromJson).toList(),
    summary: json['summary'] as Map<String, dynamic>? ?? {},
  );
  final List<PriceComparisonItem> items;
  final Map<String, dynamic> summary;
}
