import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0.0;

class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? storage})
    : _httpClient = httpClient ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Production is the safe default for installed builds. Override this at
    // run/build time when developing against a local Laravel server.
    defaultValue: 'https://boq.kemmytech.com/api/v1',
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
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/subscriptions/current'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> plans() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/plans'),
      headers: const {'Accept': 'application/json'},
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<Map<String, dynamic>> createSubscription(int planId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/subscriptions'),
      headers: await _headers(),
      body: {'plan_id': '$planId'},
    );
    final body = _decode(response);
    if (response.statusCode != 201) {
      throw ApiException(_message(body));
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> paymentGateways() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/payment-gateways'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return (body['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<Map<String, dynamic>> initiatePayment({
    required int subscriptionId,
    required String gatewayCode,
    required String idempotencyKey,
    String? paymentMethod,
    String? phoneNumber,
    String? network,
  }) async {
    final headers = await _headers();
    headers['Idempotency-Key'] = idempotencyKey;
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/subscriptions/$subscriptionId/payments'),
      headers: headers,
      body: {
        'gateway_code': gatewayCode,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'payment_method': paymentMethod,
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phone_number': phoneNumber.trim(),
        if (network != null && network.trim().isNotEmpty)
          'network': network.trim(),
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) {
      throw ApiException(_message(body));
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> transaction(int transactionId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/transactions/$transactionId'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> paymentReceipt(int transactionId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/transactions/$transactionId/receipt'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyPayment(
    int transactionId, {
    String? gatewayTransactionId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/transactions/$transactionId/verify'),
      headers: await _headers(),
      body: {
        if (gatewayTransactionId != null && gatewayTransactionId.isNotEmpty)
          'gateway_transaction_id': gatewayTransactionId,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> subscriptions() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/subscriptions'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return (body['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
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

  Future<List<ProjectSummary>> projects({int page = 1, int perPage = 20}) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/projects').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      ),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    final pageData = body['data'] as Map<String, dynamic>;
    return (pageData['data'] as List<dynamic>)
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
    String? description,
    String? status,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/projects'),
      headers: await _headers(),
      body: {
        'name': name,
        if (code != null && code.isNotEmpty) 'code': code,
        'currency': currency,
        if (client != null) 'client': client,
        if (contractor != null) 'contractor': contractor,
        if (consultant != null) 'consultant': consultant,
        if (quantitySurveyor != null) 'quantity_surveyor': quantitySurveyor,
        if (projectManager != null) 'project_manager': projectManager,
        if (siteEngineer != null) 'site_engineer': siteEngineer,
        if (fundingOrganisation != null)
          'funding_organisation': fundingOrganisation,
        if (country != null) 'country': country,
        if (district != null) 'district': district,
        if (location != null) 'location': location,
        if (projectType != null) 'project_type': projectType,
        if (startDate != null) 'start_date': startDate,
        if (expectedCompletionDate != null)
          'expected_completion_date': expectedCompletionDate,
        if (contractValue != null) 'contract_value': contractValue.toString(),
        if (description != null) 'description': description,
        if (status != null) 'status': status,
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
        if (fundingOrganisation != null)
          'funding_organisation': fundingOrganisation,
        if (country != null) 'country': country,
        if (district != null) 'district': district,
        if (location != null) 'location': location,
        if (projectType != null) 'project_type': projectType,
        if (startDate != null) 'start_date': startDate,
        if (expectedCompletionDate != null)
          'expected_completion_date': expectedCompletionDate,
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

    final uri = Uri.parse(
      '$baseUrl/hardware-prices',
    ).replace(queryParameters: queryParams);
    final response = await _httpClient.get(uri, headers: await _headers());
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return HardwarePricePaginated.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  Future<HardwarePrice> hardwarePrice(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-prices/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return HardwarePrice.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<HardwarePriceHistory> hardwarePriceHistory(
    int id, {
    int page = 1,
    int perPage = 50,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-prices/$id/history').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      ),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return HardwarePriceHistory.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<HardwarePriceStatistics> hardwarePriceStatistics() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-prices/statistics'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return HardwarePriceStatistics.fromJson(
      body['data'] as Map<String, dynamic>,
    );
  }

  Future<List<HardwarePriceCategory>> hardwarePriceCategories() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-prices/categories'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(HardwarePriceCategory.fromJson)
        .toList();
  }

  Future<List<PriceComparisonItem>> hardwarePriceRecommendations({
    String? category,
    String? location,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (location != null) queryParams['location'] = location;
    queryParams['limit'] = limit.toString();
    final response = await _httpClient.get(
      Uri.parse(
        '$baseUrl/hardware-prices/recommendations',
      ).replace(queryParameters: queryParams),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PriceComparisonItem.fromJson)
        .toList();
  }

  Future<PriceComparisonResult> hardwarePriceCompare(List<int> ids) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/hardware-prices/compare'),
      headers: await _headers(),
      body: {'ids': ids},
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return PriceComparisonResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqItemPriceMatch> matchBoqItem(int boqItemId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boq-items/$boqItemId/matches'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqItemPriceMatch.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqItemSummary> applyPriceToBoqItem(
    int boqItemId,
    int hardwarePriceId,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boq-items/$boqItemId/apply-price'),
      headers: await _headers(),
      body: {'hardware_price_id': hardwarePriceId},
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqItemSummary.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqDetail> boqDetail(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqItemDetail> boqItemDetail(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boq-items/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqItemDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> uploadBoq({
    required int projectId,
    required String filePath,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/boqs'));
    request.headers.addAll(await _headers());
    request.fields['project_id'] = '$projectId';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send().timeout(const Duration(seconds: 120));
final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw ApiException('Upload failed: ${response.statusCode}');
    }
  }

  Future<void> uploadBoqFromBytes({
    required int projectId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/boqs'));
    request.headers.addAll(await _headers());
    request.fields['project_id'] = '$projectId';
    request.fields['name'] = fileName;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw ApiException('Upload failed: ${response.statusCode}');
    }
  }

  Future<int> processBoq(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$id/process'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return body['data']['items_created'] as int? ?? 0;
  }

  Future<List<BoqItemSummary>> boqItems(
    int id, {
    String? search,
    String? status,
    String? pricingStatus,
    String? facility,
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (pricingStatus != null && pricingStatus.isNotEmpty) {
      queryParams['pricing_status'] = pricingStatus;
    }
    if (facility != null && facility.isNotEmpty) {
      queryParams['facility'] = facility;
    }

    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$id/items').replace(queryParameters: queryParams),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    final pageData = body['data'] as Map<String, dynamic>;
    return (pageData['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(BoqItemSummary.fromJson)
        .toList();
  }

  List<BoqItemSummary> _flattenBoqItems(BoqDetail boq) {
    final items = <BoqItemSummary>[];
    for (final facility in boq.facilities) {
      for (final bill in facility.bills) {
        for (final element in bill.elements) {
          items.addAll(element.items);
          for (final subElement in element.subElements) {
            items.addAll(subElement.items);
          }
        }
      }
    }
    return items;
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
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/price-all'),
      headers: await _headers(),
      body: {'location': location},
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data']['items_priced'] as int? ?? 0;
  }

  Future<List<Map<String, dynamic>>> pricingHistory(
    int boqId,
    String location,
  ) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-history/$location'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> allPricingHistory(int boqId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-history'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<PricingBatch> startPricingBatch(int boqId, String location) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-batches'),
      headers: await _headers(),
      body: {'location': location},
    );
    final body = _decode(response);
    if (response.statusCode != 202) throw ApiException(_message(body));
    return PricingBatch.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<PricingBatch> pricingBatch(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/pricing-batches/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body));
    }
    return PricingBatch.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<int>> pdf(int boqId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/pdf'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw const ApiException('Unable to generate the BOQ PDF.');
    }
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
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/hardware-prices/fetch'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data'] as Map<String, dynamic>;
  }

  /// ============================================================================
  /// PROXY SUBSCRIPTION API METHODS
  /// ============================================================================

  Future<List<BeneficiaryUser>> searchBeneficiaries(String query) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/proxy-subscriptions/beneficiaries/search').replace(
        queryParameters: {'q': query},
      ),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BeneficiaryUser.fromJson)
        .toList();
  }

  Future<ProxySubscription> createProxySubscription({
    required int planId,
    required int beneficiaryId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/proxy-subscriptions'),
      headers: await _headers(),
      body: {
        'plan_id': planId.toString(),
        'beneficiary_id': beneficiaryId.toString(),
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) throw ApiException(_message(body));
    return ProxySubscription.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> initiateProxyPayment({
    required int proxySubscriptionId,
    required String gatewayCode,
    String? paymentMethod,
    String? phoneNumber,
    String? network,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/proxy-subscriptions/$proxySubscriptionId/initiate-payment'),
      headers: await _headers(),
      body: {
        'gateway_code': gatewayCode,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'payment_method': paymentMethod,
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phone_number': phoneNumber.trim(),
        if (network != null && network.trim().isNotEmpty)
          'network': network.trim(),
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) throw ApiException(_message(body));
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyProxyPayment(
    int proxySubscriptionId, {
    String? gatewayTransactionId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/proxy-subscriptions/$proxySubscriptionId/verify-payment'),
      headers: await _headers(),
      body: {
        if (gatewayTransactionId != null && gatewayTransactionId.isNotEmpty)
          'gateway_transaction_id': gatewayTransactionId,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<ProxySubscription>> listProxySubscriptions() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/proxy-subscriptions'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(ProxySubscription.fromJson)
        .toList();
  }

  Future<ProxySubscription> getProxySubscription(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/proxy-subscriptions/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return ProxySubscription.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> cancelProxySubscription(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/proxy-subscriptions/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
  }

  /// ============================================================================
  /// BOQ PRICING JOB API METHODS (replaces PricingBatch)
  /// ============================================================================

  Future<BoqPricingJob> startPricingJob(int boqId, {int batchSize = 25}) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs'),
      headers: await _headers(),
      body: {'batch_size': batchSize.toString()},
    );
    final body = _decode(response);
    if (response.statusCode != 201) throw ApiException(_message(body));
    return BoqPricingJob.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqPricingJob> getPricingJob(int boqId, int jobId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs/$jobId'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqPricingJob.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqPricingJob> startPricingJobProcessing(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs/$jobId/start'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqPricingJob.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqPricingJobProgress> processNextBatch(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs/$jobId/next-batch'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqPricingJobProgress.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqPricingJob> pausePricingJob(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs/$jobId/pause'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqPricingJob.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqPricingJob> resumePricingJob(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs/$jobId/resume'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqPricingJob.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqPricingJob> cancelPricingJob(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs/$jobId/cancel'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqPricingJob.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqPricingJob> retryFailedItems(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs/$jobId/retry-failed'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqPricingJob.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<BoqPricingJobProgress> getPricingJobProgress(int boqId, int jobId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs/$jobId/progress'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqPricingJobProgress.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// ============================================================================
  /// AI PROVIDER ADMIN API METHODS
  /// ============================================================================

  Future<List<AiProvider>> aiProviders() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/admin/ai-providers'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(AiProvider.fromJson)
        .toList();
  }

  Future<AiProvider> createAiProvider({
    required String name,
    required String code,
    required String apiKey,
    Map<String, dynamic>? config,
    bool isDefault = false,
    bool isEnabled = true,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/admin/ai-providers'),
      headers: await _headers(),
      body: {
        'name': name,
        'code': code,
        'api_key': apiKey,
        if (config != null) 'config': jsonEncode(config),
        'is_default': isDefault.toString(),
        'is_enabled': isEnabled.toString(),
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) throw ApiException(_message(body));
    return AiProvider.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<AiProvider> updateAiProvider(
    int id, {
    String? name,
    String? apiKey,
    Map<String, dynamic>? config,
    bool? isDefault,
    bool? isEnabled,
  }) async {
    final body = <String, String>{};
    if (name != null) body['name'] = name;
    if (apiKey != null) body['api_key'] = apiKey;
    if (config != null) body['config'] = jsonEncode(config);
    if (isDefault != null) body['is_default'] = isDefault.toString();
    if (isEnabled != null) body['is_enabled'] = isEnabled.toString();

    final response = await _httpClient.put(
      Uri.parse('$baseUrl/admin/ai-providers/$id'),
      headers: await _headers(),
      body: body,
    );
    final responseBody = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(responseBody));
    return AiProvider.fromJson(responseBody['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAiProvider(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/admin/ai-providers/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
  }

  Future<Map<String, dynamic>> testAiProvider(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/admin/ai-providers/$id/test'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return body['data'] as Map<String, dynamic>;
  }

  Future<AiProvider> setDefaultAiProvider(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/admin/ai-providers/$id/set-default'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return AiProvider.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// ============================================================================
  /// HARDWARE CATEGORY ADMIN API METHODS
  /// ============================================================================

  Future<List<HardwareCategory>> hardwareCategoriesAdmin() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/admin/hardware-categories'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(HardwareCategory.fromJson)
        .toList();
  }

  Future<HardwareCategory> createHardwareCategory({
    required String name,
    required String code,
    String? description,
    bool isActive = true,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/admin/hardware-categories'),
      headers: await _headers(),
      body: {
        'name': name,
        'code': code,
        if (description != null && description.isNotEmpty) 'description': description,
        'is_active': isActive.toString(),
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) throw ApiException(_message(body));
    return HardwareCategory.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<HardwareCategory> updateHardwareCategory(
    int id, {
    String? name,
    String? code,
    String? description,
    bool? isActive,
  }) async {
    final body = <String, String>{};
    if (name != null) body['name'] = name;
    if (code != null) body['code'] = code;
    if (description != null) body['description'] = description;
    if (isActive != null) body['is_active'] = isActive.toString();

    final response = await _httpClient.put(
      Uri.parse('$baseUrl/admin/hardware-categories/$id'),
      headers: await _headers(),
      body: body,
    );
    final responseBody = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(responseBody));
    return HardwareCategory.fromJson(responseBody['data'] as Map<String, dynamic>);
  }

  Future<void> deleteHardwareCategory(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/admin/hardware-categories/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
  }

  Future<HardwareCategory> toggleHardwareCategory(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/admin/hardware-categories/$id/toggle-active'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return HardwareCategory.fromJson(body['data'] as Map<String, dynamic>);
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
        totalProjects: _asInt(json['total_projects']),
        activeProjects: _asInt(json['active_projects']),
        boqsAwaitingReview: _asInt(json['boqs_awaiting_review']),
        totalEstimatedValue: _asDouble(json['total_estimated_value']),
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
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    status: json['status'] as String? ?? 'draft',
    boqCount: _asInt(json['boqs_count']),
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
    id: _asInt(json['id']),
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
    contractValue: _asDouble(json['contract_value']),
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
    id: _asInt(json['id']),
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
    currentRate:
        '${json['ai_suggested_rate'] ?? json['approved_rate'] ?? json['original_rate'] ?? 0}',
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
  const PricingBatch({
    required this.id,
    required this.status,
    required this.total,
    required this.processed,
    required this.failed,
  });
  factory PricingBatch.fromJson(Map<String, dynamic> json) => PricingBatch(
    id: _asInt(json['id']),
    status: json['status'] as String? ?? 'unknown',
    total: _asInt(json['total_items']),
    processed: _asInt(json['processed_items']),
    failed: _asInt(json['failed_items']),
  );
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
    id: _asInt(json['id']),
    itemName: json['item_name'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    category: json['category'] as String? ?? '',
    specification: json['specification'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    price: _asDouble(json['price']),
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
    id: _asInt(json['id']),
    price: _asDouble(json['price']),
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
  factory HardwarePriceStatistics.fromJson(Map<String, dynamic> json) =>
      HardwarePriceStatistics(
        itemsTracked: json['items_tracked'] as int? ?? 0,
        pricesUpdatedToday: json['prices_updated_today'] as int? ?? 0,
        averagePriceChange:
            (json['average_price_change'] as num?)?.toDouble() ?? 0.0,
        suppliersTracked: json['suppliers_tracked'] as int? ?? 0,
        lowestPriceOpportunities:
            json['lowest_price_opportunities'] as int? ?? 0,
        boqItemsWithUpdatedPrices:
            json['boq_items_with_updated_prices'] as int? ?? 0,
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
  factory PriceComparisonItem.fromJson(Map<String, dynamic> json) =>
      PriceComparisonItem(
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
        matchReasons: (json['match_reasons'] as List<dynamic>? ?? [])
            .cast<String>(),
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
  factory PriceHistorySummary.fromJson(Map<String, dynamic> json) =>
      PriceHistorySummary(
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
    factors: (json['factors'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as String),
    ),
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
  const BoqItemPriceMatch({required this.boqItem, required this.matches});
  factory BoqItemPriceMatch.fromJson(Map<String, dynamic> json) =>
      BoqItemPriceMatch(
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
  factory BoqItemMatchInfo.fromJson(Map<String, dynamic> json) =>
      BoqItemMatchInfo(
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
  factory HardwarePricePaginated.fromJson(Map<String, dynamic> json) =>
      HardwarePricePaginated(
        data: (json['data'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(HardwarePrice.fromJson)
            .toList(),
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
  factory HardwarePriceHistory.fromJson(Map<String, dynamic> json) =>
      HardwarePriceHistory(
        item: HardwarePrice.fromJson(
          (json['item'] as Map<String, dynamic>?) ?? {},
        ),
        summary: PriceHistorySummary.fromJson(
          (json['summary'] as Map<String, dynamic>?) ?? {},
        ),
        history:
            ((json['history'] as Map<String, dynamic>?)?['data']
                        as List<dynamic>? ??
                    [])
                .cast<Map<String, dynamic>>()
                .map(PriceHistory.fromJson)
                .toList(),
      );
  final HardwarePrice item;
  final PriceHistorySummary summary;
  final List<PriceHistory> history;
}

class HardwarePriceCategory {
  const HardwarePriceCategory({required this.name, required this.count});
  factory HardwarePriceCategory.fromJson(Map<String, dynamic> json) =>
      HardwarePriceCategory(
        name: json['name'] as String? ?? '',
        count: json['count'] as int? ?? 0,
      );
  final String name;
  final int count;
}

class PriceComparisonResult {
  const PriceComparisonResult({required this.items, required this.summary});
  factory PriceComparisonResult.fromJson(Map<String, dynamic> json) =>
      PriceComparisonResult(
        items: (json['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(PriceComparisonItem.fromJson)
            .toList(),
        summary: json['summary'] as Map<String, dynamic>? ?? {},
      );
  final List<PriceComparisonItem> items;
  final Map<String, dynamic> summary;
}

class BoqDetail {
  const BoqDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.currency,
    required this.status,
    required this.version,
    required this.metadata,
    required this.facilities,
    required this.summaries,
  });
  factory BoqDetail.fromJson(Map<String, dynamic> json) => BoqDetail(
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    description: json['description'] as String? ?? '',
    currency: json['currency'] as String? ?? 'UGX',
    status: json['status'] as String? ?? 'draft',
    version: json['version'] as String? ?? '1.0',
    metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    facilities: (json['facilities'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Facility.fromJson)
        .toList(),
    summaries: (json['summaries'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BoqCostSummary.fromJson)
        .toList(),
  );
  final int id;
  final String name;
  final String code;
  final String description;
  final String currency;
  final String status;
  final String version;
  final Map<String, dynamic> metadata;
  final List<Facility> facilities;
  final List<BoqCostSummary> summaries;
}

class Facility {
  const Facility({
    required this.id,
    required this.name,
    this.nameTranslations,
    this.description,
    required this.displayOrder,
    required this.bills,
    required this.summaries,
  });
  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    nameTranslations: json['name_translations'] != null
        ? (json['name_translations'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as String))
        : null,
    description: json['description'] as String?,
    displayOrder: _asInt(json['display_order']),
    bills: (json['bills'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Bill.fromJson)
        .toList(),
    summaries: (json['summaries'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BoqCostSummary.fromJson)
        .toList(),
  );
  final int id;
  final String name;
  final Map<String, String>? nameTranslations;
  final String? description;
  final int displayOrder;
  final List<Bill> bills;
  final List<BoqCostSummary> summaries;
}

class Bill {
  const Bill({
    required this.id,
    required this.name,
    this.nameTranslations,
    this.description,
    required this.displayOrder,
    required this.elements,
    required this.summaries,
  });
  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    nameTranslations: json['name_translations'] != null
        ? (json['name_translations'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as String))
        : null,
    description: json['description'] as String?,
    displayOrder: _asInt(json['display_order']),
    elements: (json['elements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Element.fromJson)
        .toList(),
    summaries: (json['summaries'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BoqCostSummary.fromJson)
        .toList(),
  );
  final int id;
  final String name;
  final Map<String, String>? nameTranslations;
  final String? description;
  final int displayOrder;
  final List<Element> elements;
  final List<BoqCostSummary> summaries;
}

class Element {
  const Element({
    required this.id,
    required this.name,
    this.nameTranslations,
    this.description,
    required this.displayOrder,
    required this.subElements,
    required this.items,
  });
  factory Element.fromJson(Map<String, dynamic> json) => Element(
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    nameTranslations: json['name_translations'] != null
        ? (json['name_translations'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as String))
        : null,
    description: json['description'] as String?,
    displayOrder: _asInt(json['display_order']),
    subElements: (json['sub_elements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(SubElement.fromJson)
        .toList(),
    items: (json['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BoqItemSummary.fromJson)
        .toList(),
  );
  final int id;
  final String name;
  final Map<String, String>? nameTranslations;
  final String? description;
  final int displayOrder;
  final List<SubElement> subElements;
  final List<BoqItemSummary> items;
}

class SubElement {
  const SubElement({
    required this.id,
    required this.name,
    this.nameTranslations,
    this.description,
    required this.displayOrder,
    required this.items,
  });
  factory SubElement.fromJson(Map<String, dynamic> json) => SubElement(
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    nameTranslations: json['name_translations'] != null
        ? (json['name_translations'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as String))
        : null,
    description: json['description'] as String?,
    displayOrder: _asInt(json['display_order']),
    items: (json['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BoqItemSummary.fromJson)
        .toList(),
  );
  final int id;
  final String name;
  final Map<String, String>? nameTranslations;
  final String? description;
  final int displayOrder;
  final List<BoqItemSummary> items;
}

class BoqCostSummary {
  const BoqCostSummary({
    required this.id,
    required this.summaryType,
    this.name,
    required this.subtotal,
    required this.vat,
    required this.contingency,
    required this.grandTotal,
    this.metadata,
  });
  factory BoqCostSummary.fromJson(Map<String, dynamic> json) => BoqCostSummary(
    id: _asInt(json['id']),
    summaryType: json['summary_type'] as String? ?? 'grand',
    name: json['name'] as String?,
    subtotal: _asDouble(json['subtotal']),
    vat: _asDouble(json['vat']),
    contingency: _asDouble(json['contingency']),
    grandTotal: _asDouble(json['grand_total']),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
  final int id;
  final String summaryType;
  final String? name;
  final double subtotal;
  final double vat;
  final double contingency;
  final double grandTotal;
  final Map<String, dynamic>? metadata;
}

class BoqItemDetail extends BoqItemSummary {
  const BoqItemDetail({
    required super.id,
    required super.code,
    required super.description,
    required super.quantity,
    required super.unit,
    required super.amount,
    required super.currentRate,
    required super.aiRate,
    required this.facilityId,
    required this.billId,
    required this.elementId,
    required this.subElementId,
    this.originalRate,
    this.approvedRate,
    this.aiSuggestedRate,
    this.currency,
    this.workCategory,
    this.materialCategory,
    this.location,
    this.pricingSource,
    this.pricingDate,
    this.aiConfidence,
    this.translationConfidence,
    this.notes,
    this.status,
    this.translations = const [],
  });
  factory BoqItemDetail.fromJson(Map<String, dynamic> json) => BoqItemDetail(
    id: json['id'] as int,
    code: json['item_code'] as String? ?? '',
    description: json['description'] as String? ?? '',
    quantity: '${json['quantity'] ?? 0}',
    unit: json['unit'] as String? ?? '',
    amount: '${json['amount'] ?? 0}',
    currentRate:
        '${json['ai_suggested_rate'] ?? json['approved_rate'] ?? json['original_rate'] ?? 0}',
    aiRate: '${json['ai_suggested_rate'] ?? 0}',
    facilityId: json['facility_id'] as int?,
    billId: json['bill_id'] as int?,
    elementId: json['element_id'] as int?,
    subElementId: json['sub_element_id'] as int?,
    originalRate: (json['original_rate'] as num?)?.toDouble(),
    approvedRate: (json['approved_rate'] as num?)?.toDouble(),
    aiSuggestedRate: (json['ai_suggested_rate'] as num?)?.toDouble(),
    currency: json['currency'] as String? ?? 'UGX',
    workCategory: json['work_category'] as String?,
    materialCategory: json['material_category'] as String?,
    location: json['location'] as String?,
    pricingSource: json['pricing_source'] as String?,
    pricingDate: json['pricing_date'] as String?,
    aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
    translationConfidence: (json['translation_confidence'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
    status: json['status'] as String? ?? 'pending',
    translations: (json['translations'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(BoqItemTranslation.fromJson)
        .toList(),
  );
  final int? facilityId;
  final int? billId;
  final int? elementId;
  final int? subElementId;
  final double? originalRate;
  final double? approvedRate;
  final double? aiSuggestedRate;
  final String? currency;
  final String? workCategory;
  final String? materialCategory;
  final String? location;
  final String? pricingSource;
  final String? pricingDate;
  final double? aiConfidence;
  final double? translationConfidence;
  final String? notes;
  final String? status;
  final List<BoqItemTranslation> translations;
}

class BoqItemTranslation {
  const BoqItemTranslation({
    required this.id,
    required this.locale,
    required this.translatedDescription,
    this.provider,
    this.confidence,
    this.status,
    this.reviewedAt,
  });
  factory BoqItemTranslation.fromJson(Map<String, dynamic> json) => BoqItemTranslation(
    id: _asInt(json['id']),
    locale: json['locale'] as String? ?? '',
    translatedDescription: json['translated_description'] as String? ?? '',
    provider: json['provider'] as String?,
    confidence: (json['confidence'] as num?)?.toDouble(),
    status: json['status'] as String? ?? 'pending_review',
    reviewedAt: json['reviewed_at'] as String?,
  );
  final int id;
  final String locale;
  final String translatedDescription;
  final String? provider;
  final double? confidence;
  final String? status;
  final String? reviewedAt;
}

/// ============================================================================
/// PROXY SUBSCRIPTION MODELS
/// ============================================================================

class ProxySubscription {
  const ProxySubscription({
    required this.id,
    required this.beneficiaryId,
    required this.beneficiaryName,
    required this.beneficiaryEmail,
    required this.payerId,
    required this.payerName,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.paymentStatus,
    required this.transactionId,
    required this.createdAt,
  });

  factory ProxySubscription.fromJson(Map<String, dynamic> json) => ProxySubscription(
    id: _asInt(json['id']),
    beneficiaryId: _asInt(json['beneficiary_id']),
    beneficiaryName: json['beneficiary_name'] as String? ?? '',
    beneficiaryEmail: json['beneficiary_email'] as String? ?? '',
    payerId: _asInt(json['payer_id']),
    payerName: json['payer_name'] as String? ?? '',
    planId: _asInt(json['plan_id']),
    planName: json['plan_name'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    startDate: json['start_date'] as String? ?? '',
    endDate: json['end_date'] as String? ?? '',
    paymentStatus: json['payment_status'] as String? ?? 'pending',
    transactionId: json['transaction_id'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
  );

  final int id;
  final int beneficiaryId;
  final String beneficiaryName;
  final String beneficiaryEmail;
  final int payerId;
  final String payerName;
  final int planId;
  final String planName;
  final String status;
  final String startDate;
  final String endDate;
  final String paymentStatus;
  final String transactionId;
  final String createdAt;
}

class BeneficiaryUser {
  const BeneficiaryUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory BeneficiaryUser.fromJson(Map<String, dynamic> json) => BeneficiaryUser(
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
  );

  final int id;
  final String name;
  final String email;
}

/// ============================================================================
/// BOQ PRICING JOB MODELS (replaces PricingBatch)
/// ============================================================================

class BoqPricingJob {
  const BoqPricingJob({
    required this.id,
    required this.boqId,
    required this.status,
    required this.currentBatch,
    required this.totalBatches,
    required this.batchSize,
    required this.totalItems,
    required this.processedItems,
    required this.failedItems,
    this.lockedAt,
    this.lockedBy,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  factory BoqPricingJob.fromJson(Map<String, dynamic> json) => BoqPricingJob(
    id: _asInt(json['id']),
    boqId: _asInt(json['boq_id']),
    status: json['status'] as String? ?? 'pending',
    currentBatch: _asInt(json['current_batch']),
    totalBatches: _asInt(json['total_batches']),
    batchSize: _asInt(json['batch_size']),
    totalItems: _asInt(json['total_items']),
    processedItems: _asInt(json['processed_items']),
    failedItems: _asInt(json['failed_items']),
    lockedAt: json['locked_at'] as String?,
    lockedBy: json['locked_by'] as int?,
    startedAt: json['started_at'] as String?,
    completedAt: json['completed_at'] as String?,
    createdAt: json['created_at'] as String? ?? '',
  );

  final int id;
  final int boqId;
  final String status;
  final int currentBatch;
  final int totalBatches;
  final int batchSize;
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final String? lockedAt;
  final int? lockedBy;
  final String? startedAt;
  final String? completedAt;
  final String createdAt;
}

class BoqPricingJobProgress {
  const BoqPricingJobProgress({
    required this.jobId,
    required this.percentage,
    required this.currentBatch,
    required this.totalBatches,
    required this.itemsPricedThisBatch,
    required this.totalPriced,
    required this.remaining,
    required this.failedItems,
    required this.status,
  });

  factory BoqPricingJobProgress.fromJson(Map<String, dynamic> json) => BoqPricingJobProgress(
    jobId: _asInt(json['job_id']),
    percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    currentBatch: _asInt(json['current_batch']),
    totalBatches: _asInt(json['total_batches']),
    itemsPricedThisBatch: _asInt(json['items_priced_this_batch']),
    totalPriced: _asInt(json['total_priced']),
    remaining: _asInt(json['remaining']),
    failedItems: _asInt(json['failed_items']),
    status: json['status'] as String? ?? 'unknown',
  );

  final int jobId;
  final double percentage;
  final int currentBatch;
  final int totalBatches;
  final int itemsPricedThisBatch;
  final int totalPriced;
  final int remaining;
  final int failedItems;
  final String status;
}

/// ============================================================================
/// AI PROVIDER & HARDWARE CATEGORY MODELS
/// ============================================================================

class AiProvider {
  const AiProvider({
    required this.id,
    required this.name,
    required this.code,
    required this.apiKeyEncrypted,
    required this.isDefault,
    required this.isEnabled,
    required this.config,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiProvider.fromJson(Map<String, dynamic> json) => AiProvider(
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    apiKeyEncrypted: json['api_key_encrypted'] as String? ?? '',
    isDefault: json['is_default'] as bool? ?? false,
    isEnabled: json['is_enabled'] as bool? ?? true,
    config: json['config'] as Map<String, dynamic>? ?? {},
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
  );

  final int id;
  final String name;
  final String code;
  final String apiKeyEncrypted;
  final bool isDefault;
  final bool isEnabled;
  final Map<String, dynamic> config;
  final String createdAt;
  final String updatedAt;
}

class HardwareCategory {
  const HardwareCategory({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HardwareCategory.fromJson(Map<String, dynamic> json) => HardwareCategory(
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    description: json['description'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
  );

  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
}
