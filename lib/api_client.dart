import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'app_errors.dart';

/// `2026-09-01T00:00:00.000000Z` → `2026-09-01` (API date columns).
String _dateOnly(dynamic value) {
  final raw = (value as String? ?? '').trim();
  return RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(raw)?.group(0) ?? raw;
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0.0;

double? _asDoubleOrNull(dynamic value) =>
    value == null ? null : _asDouble(value);

/// Wraps every request with a timeout and reports expired sessions (HTTP 401).
class _GuardedClient extends http.BaseClient {
  _GuardedClient(this._inner, this._onUnauthorized);

  static const _timeout = Duration(seconds: 30);

  /// Reading a BOQ (AI extraction of PDFs/photos, large spreadsheets) and
  /// pricing run on the server for several minutes.
  static const _longTimeout = Duration(minutes: 5);

  static Duration _timeoutFor(Uri url) {
    final path = url.path;
    return path.endsWith('/process') ||
            path.endsWith('/price-all') ||
            path.endsWith('/pricing-batches') ||
            path.contains('/pricing-jobs')
        ? _longTimeout
        : _timeout;
  }

  final http.Client _inner;
  final void Function() _onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final http.StreamedResponse response;
    try {
      response = await _inner.send(request).timeout(_timeoutFor(request.url));
    } on TimeoutException {
      throw const ApiException(AppErrorMessages.timeout);
    } on ApiException {
      rethrow;
    } on Object catch (error) {
      // SocketException / ClientException / TLS errors: never show raw text.
      throw ApiException(friendlyError(error));
    }

    final isLogin = request.url.path.endsWith('/auth/login');
    if (response.statusCode == 401 && !isLogin) {
      _onUnauthorized();
    }
    return response;
  }

  @override
  void close() => _inner.close();
}

class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    _httpClient = _GuardedClient(httpClient ?? http.Client(), _expireSession);
  }

  final StreamController<String> _sessionExpired =
      StreamController<String>.broadcast();

  /// Emits a message when the server rejects the stored token (expired,
  /// revoked or the account was disabled). The app returns to sign-in.
  Stream<String> get sessionExpired => _sessionExpired.stream;

  void _expireSession([
    String message = 'Your session has expired. Please sign in again.',
  ]) {
    unawaited(_storage.delete(key: _tokenKey));
    _sessionExpired.add(message);
  }

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Production is the safe default for installed builds. Override this at
    // run/build time when developing against a local Laravel server.
    defaultValue: 'https://boq.kemmytech.com/api/v1',
  );

  static const _tokenKey = 'auth_token';
  late final http.Client _httpClient;
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

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? organisationName,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: const {'Accept': 'application/json'},
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (organisationName != null && organisationName.trim().isNotEmpty)
          'organisation_name': organisationName.trim(),
      },
    );

    final body = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(_message(body));
    }

    final token = body['data']?['token'] as String?;

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your account was created, but the server did not return an access token.',
      );
    }

    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> forgotPassword({required String email}) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: const {'Accept': 'application/json'},
      body: {'email': email.trim()},
    );

    final body = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw ApiException(_message(body));
    }
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

  /// Uploads a new profile picture (JPEG/PNG/WebP, max 4 MB).
  Future<UserProfile> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/auth/avatar'),
    );
    request.headers.addAll(await _headers());
    request.files.add(
      http.MultipartFile.fromBytes(
        'avatar',
        bytes,
        filename: standardUploadName(fileName),
      ),
    );
    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return UserProfile.fromJson(body['data']['user'] as Map<String, dynamic>);
  }

  Future<UserProfile> deleteAvatar() async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/auth/avatar'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return UserProfile.fromJson(body['data']['user'] as Map<String, dynamic>);
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
    String? phone,
    String? location,
  }) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _headers(),
      body: {
        'name': name,
        'email': email,
        'locale': locale,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (location != null && location.isNotEmpty) 'location': location,
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

  Future<List<ProjectSummary>> projects({
    int page = 1,
    int perPage = 20,
    String? status,
    String? boqStatus,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/projects').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
          'status': ?status,
          'boq_status': ?boqStatus,
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
    String? originalLanguage,
    String? reportLanguage,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/projects'),
      headers: await _headers(),
      body: {
        'name': name,
        if (code != null && code.isNotEmpty) 'code': code,
        'currency': currency,
        'client': ?client,
        'contractor': ?contractor,
        'consultant': ?consultant,
        'quantity_surveyor': ?quantitySurveyor,
        'project_manager': ?projectManager,
        'site_engineer': ?siteEngineer,
        'funding_organisation': ?fundingOrganisation,
        'country': ?country,
        'district': ?district,
        'location': ?location,
        'project_type': ?projectType,
        'start_date': ?startDate,
        'expected_completion_date': ?expectedCompletionDate,
        if (contractValue != null) 'contract_value': contractValue.toString(),
        'description': ?description,
        'status': ?status,
        'original_language': ?originalLanguage,
        'report_language': ?reportLanguage,
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
    String? originalLanguage,
    String? reportLanguage,
  }) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl/projects/$id'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      // Optional text fields are always sent so a cleared field is saved as empty.
      body: jsonEncode({
        'name': ?name,
        'code': code,
        'client': client,
        'contractor': contractor,
        'consultant': consultant,
        'quantity_surveyor': quantitySurveyor,
        'project_manager': projectManager,
        'site_engineer': siteEngineer,
        'funding_organisation': fundingOrganisation,
        'country': country,
        'district': district,
        'location': location,
        'project_type': projectType,
        'start_date': startDate,
        'expected_completion_date': expectedCompletionDate,
        'contract_value': contractValue,
        'currency': ?currency,
        'description': description,
        'status': ?status,
        'original_language': ?originalLanguage,
        'report_language': ?reportLanguage,
      }),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return ProjectDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Sets only the project's location (other fields are left as they are).
  Future<void> updateProjectLocation(int id, String location) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl/projects/$id'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'location': location}),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
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
    String? priceType,
    String? brand,
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
    if (priceType != null) queryParams['price_type'] = priceType;
    if (brand != null) queryParams['brand'] = brand;
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

  /// Selectable categories from the database: project types, BOQ work
  /// sections and material categories (with their items).
  Future<CategoryCatalog> categories() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return CategoryCatalog.fromJson(
      body['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Distinct suppliers and locations for the price list filters.
  Future<({List<String> suppliers, List<String> locations})>
  hardwarePriceFilters() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-prices/filters'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    List<String> names(String key) => (data[key] as List<dynamic>? ?? const [])
        .map((e) => '$e'.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return (suppliers: names('suppliers'), locations: names('locations'));
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
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'ids': ids}),
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

  Future<BoqSummary> uploadBoq({
    required int projectId,
    required String filePath,
    String? name,
  }) async {
    final fileName = name ?? filePath.split(RegExp(r'[\\/]')).last;
    return _uploadBoqFile(
      projectId,
      fileName,
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: standardUploadName(fileName),
      ),
    );
  }

  Future<BoqSummary> uploadBoqFromBytes({
    required int projectId,
    required String fileName,
    required Uint8List bytes,
  }) {
    return _uploadBoqFile(
      projectId,
      fileName,
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: standardUploadName(fileName),
      ),
    );
  }

  /// `Scan 01.JPEG` → `Scan 01.jpg`; photos without an extension become `.jpg`.
  /// The server detects the real format and converts it to a standard one.
  static String standardUploadName(String fileName) {
    final trimmed = fileName.trim().isEmpty ? 'boq' : fileName.trim();
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0 || dot == trimmed.length - 1) return '$trimmed.jpg';
    final base = trimmed.substring(0, dot);
    final extension = switch (trimmed.substring(dot + 1).toLowerCase()) {
      'jpeg' || 'jpe' || 'jfif' => 'jpg',
      'text' => 'txt',
      final other => other,
    };
    return '$base.$extension';
  }

  static String _boqNameFrom(String fileName) {
    var name = fileName.trim();
    // "boq.csv.gz" (compressed by the app) is still named "boq".
    if (name.toLowerCase().endsWith('.gz')) {
      name = name.substring(0, name.length - 3);
    }
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  Future<BoqSummary> _uploadBoqFile(
    int projectId,
    String fileName,
    http.MultipartFile file,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/boqs'));
    request.headers.addAll(await _headers());
    request.fields['project_id'] = '$projectId';
    final name = _boqNameFrom(fileName);
    if (name.isNotEmpty) request.fields['name'] = name;
    request.files.add(file);

    final http.Response response;
    try {
      // Uploads get longer than the usual request timeout.
      final streamed = await request.send().timeout(const Duration(minutes: 3));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(AppErrorMessages.timeout);
    } on Object catch (error) {
      throw ApiException(friendlyError(error));
    }
    if (response.statusCode == 401) _expireSession();

    final body = _decode(response);
    if (response.statusCode != 201) throw ApiException(_message(body));
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('The server did not return the created BOQ.');
    }
    return BoqSummary.fromJson(data);
  }

  Future<int> processBoq(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$id/process'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      if (body['error_code'] == 'FEATURE_TOPUP_REQUIRED') {
        throw ApiException(
          'The BOQ was uploaded, but reading its items needs an active plan '
          'with BOQ imports. Start a trial or choose a plan, then tap '
          '"Generate BOQ" on the project.',
          statusCode: response.statusCode,
        );
      }
      throw ApiException(_message(body), statusCode: response.statusCode);
    }
    final meta = body['meta'];
    if (meta is Map && meta['items_imported'] is int) {
      return meta['items_imported'] as int;
    }
    final data = body['data'];
    if (data is Map && data['items_created'] is int) {
      return data['items_created'] as int;
    }
    return 0;
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
      Uri.parse(
        '$baseUrl/boqs/$id/items',
      ).replace(queryParameters: queryParams),
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

  /// Fetches every BOQ item across all pages of the paginated items endpoint.
  Future<List<BoqItemSummary>> allBoqItems(int id) async {
    final all = <BoqItemSummary>[];
    var page = 1;
    var lastPage = 1;
    do {
      final response = await _httpClient.get(
        Uri.parse(
          '$baseUrl/boqs/$id/items',
        ).replace(queryParameters: {'page': '$page', 'per_page': '100'}),
        headers: await _headers(),
      );
      final body = _decode(response);
      if (response.statusCode != 200) throw ApiException(_message(body));
      final pageData = body['data'];
      if (pageData is! Map<String, dynamic>) break;
      final rows = pageData['data'];
      if (rows is! List) break;
      all.addAll(
        rows.cast<Map<String, dynamic>>().map(BoqItemSummary.fromJson),
      );
      lastPage = pageData['last_page'] as int? ?? page;
      page++;
    } while (page <= lastPage);
    return all;
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
      throw ApiException(
        response.statusCode == 403
            ? AppErrorMessages.forbidden
            : 'The BOQ PDF could not be generated. Please try again.',
        statusCode: response.statusCode,
      );
    }
    return response.bodyBytes;
  }

  /// Email the owner-branded BOQ PDF to a recipient.
  Future<String> shareBoqByEmail(
    int boqId, {
    required String email,
    String? subject,
    String? message,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/share/email'),
      headers: await _headers(),
      body: {
        'email': email,
        if (subject != null && subject.trim().isNotEmpty)
          'subject': subject.trim(),
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body), statusCode: response.statusCode);
    }
    return body['message'] as String? ?? 'BOQ sent.';
  }

  /// Signed download link plus a ready-made message for WhatsApp / device sharing.
  Future<BoqShareLink> boqShareLink(int boqId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/share/link'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body), statusCode: response.statusCode);
    }
    return BoqShareLink.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// ISO code => country name, from the server's managed list (default country first).
  Future<Map<String, String>> countries() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/mobile-config'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body), statusCode: response.statusCode);
    }
    final data = body['data'];
    final list = data is Map ? data['countries_detailed'] : null;
    return {
      if (list is List)
        for (final country in list.whereType<Map>())
          '${country['iso2']}': '${country['name']}',
    };
  }

  Future<CompanyProfile?> companyProfile() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/company-profile'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_message(body), statusCode: response.statusCode);
    }
    final data = body['data'];
    return data is Map<String, dynamic> ? CompanyProfile.fromJson(data) : null;
  }

  /// Create or update the user's company profile; [logoPath] uploads a new logo.
  Future<CompanyProfile> saveCompanyProfile(
    Map<String, String> fields, {
    String? logoPath,
    bool removeLogo = false,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/company-profile'))
          ..headers.addAll(await _headers())
          ..fields.addAll(fields);
    if (removeLogo) request.fields['remove_logo'] = '1';
    if (logoPath != null) {
      request.files.add(await http.MultipartFile.fromPath('logo', logoPath));
    }

    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      final errors = body['errors'];
      final firstError =
          errors is Map &&
              errors.values.isNotEmpty &&
              errors.values.first is List
          ? (errors.values.first as List).firstOrNull?.toString()
          : null;
      throw ApiException(
        firstError ?? _message(body),
        statusCode: response.statusCode,
      );
    }
    return CompanyProfile.fromJson(body['data'] as Map<String, dynamic>);
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

  Future<List<NotificationItem>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/notifications').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      ),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    final pageData = body['data'] as Map<String, dynamic>;
    return (pageData['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
  }

  Future<void> markNotificationAsRead(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
  }

  /// BOQs the user can see, newest first.
  Future<({List<BoqListItem> items, int lastPage})> boqs({
    String? search,
    int? projectId,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs').replace(
        queryParameters: {
          'page': '$page',
          'per_page': '$perPage',
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (projectId != null) 'project_id': '$projectId',
        },
      ),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    final pageData = body['data'] as Map<String, dynamic>? ?? const {};
    final rows = pageData['data'] as List<dynamic>? ?? const [];
    return (
      items: rows
          .whereType<Map<String, dynamic>>()
          .map(BoqListItem.fromJson)
          .toList(),
      lastPage: _asInt(pageData['last_page'] ?? 1),
    );
  }

  /// Renames a BOQ, changes its description or moves it to another project.
  Future<BoqListItem> updateBoq(
    int id, {
    required String name,
    String? description,
    int? projectId,
  }) async {
    final response = await _httpClient.patch(
      Uri.parse('$baseUrl/boqs/$id'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'project_id': ?projectId,
      }),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqListItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// CSV of the BOQ's items with an "Estimated Rate" column to fill in.
  Future<Uint8List> boqEstimatesTemplate(int boqId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/estimates/template'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw ApiException(_message(_decode(response)));
    }
    return response.bodyBytes;
  }

  /// Uploads a file of estimated rates; returns the server's summary message.
  Future<({String message, BoqTotals totals, List<String> unmatched})>
  uploadBoqEstimates(
    int boqId, {
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/boqs/$boqId/estimates'),
    );
    request.headers.addAll(await _headers());
    request.files.add(
      filePath != null
          ? await http.MultipartFile.fromPath(
              'file',
              filePath,
              filename: standardUploadName(fileName),
            )
          : http.MultipartFile.fromBytes(
              'file',
              bytes!,
              filename: standardUploadName(fileName),
            ),
    );

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await request.send().timeout(const Duration(minutes: 2)),
      );
    } on TimeoutException {
      throw const ApiException(AppErrorMessages.timeout);
    } on Object catch (error) {
      throw ApiException(friendlyError(error));
    }
    if (response.statusCode == 401) _expireSession();
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    final data = body['data'] as Map<String, dynamic>? ?? const {};
    return (
      message: '${body['message'] ?? 'Estimated prices updated.'}',
      totals: BoqTotals.fromJson(data['totals']),
      unmatched: (data['unmatched'] as List<dynamic>? ?? const [])
          .map((e) => '$e')
          .toList(),
    );
  }

  Future<void> deleteBoq(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/boqs/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
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

  // Proxy subscription API methods.

  Future<List<BeneficiaryUser>> searchBeneficiaries(String query) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$baseUrl/proxy-subscriptions/beneficiaries/search',
      ).replace(queryParameters: {'q': query}),
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
      Uri.parse(
        '$baseUrl/proxy-subscriptions/$proxySubscriptionId/initiate-payment',
      ),
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
      Uri.parse(
        '$baseUrl/proxy-subscriptions/$proxySubscriptionId/verify-payment',
      ),
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

  // BOQ pricing job API methods.

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

  Future<BoqPricingJobProgress> getPricingJobProgress(
    int boqId,
    int jobId,
  ) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs/$jobId/progress'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    return BoqPricingJobProgress.fromJson(body['data'] as Map<String, dynamic>);
  }

  // AI provider admin API methods.

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

  // Hardware category admin API methods.

  Future<List<HardwareCategory>> hardwareCategoriesAdmin() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-categories'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
    final raw = body['data'];
    final list = raw is List
        ? raw
        : raw is Map && raw['data'] is List
        ? raw['data'] as List
        : <dynamic>[];
    return list
        .cast<Map<String, dynamic>>()
        .map(HardwareCategory.fromJson)
        .toList();
  }

  Future<HardwareCategory> createHardwareCategory({
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/hardware-categories'),
      headers: await _headers(),
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
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
    String? description,
    bool? isActive,
  }) async {
    final body = <String, String>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (isActive != null) body['is_active'] = isActive.toString();

    final response = await _httpClient.put(
      Uri.parse('$baseUrl/hardware-categories/$id'),
      headers: await _headers(),
      body: body,
    );
    final responseBody = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(responseBody));
    return HardwareCategory.fromJson(
      responseBody['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteHardwareCategory(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/hardware-categories/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(body));
  }

  Future<HardwareCategory> toggleHardwareCategory(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/hardware-categories/$id/toggle-active'),
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
    final status = response.statusCode;
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      // HTML error page from the server or a proxy: explain by status instead.
      if (status >= 400) {
        throw ApiException(friendlyStatusMessage(status), statusCode: status);
      }
      throw const ApiException(AppErrorMessages.invalidResponse);
    }

    if (status >= 400) {
      final serverMessage = body['message'];
      final keepServerMessage =
          serverMessage is String &&
          serverMessage.trim().isNotEmpty &&
          // Never pass through generic framework/server wording for 5xx.
          (status < 500 || status == 503);
      body = {
        ...body,
        'message': keepServerMessage
            ? serverMessage
            : friendlyStatusMessage(status),
      };
    }

    if (response.statusCode == 403 &&
        body['error_code'] == 'ACCOUNT_DISABLED') {
      _expireSession(
        body['message'] as String? ??
            'Your account has been disabled. Contact your administrator.',
      );
    }
    return body;
  }

  /// The first validation error when there is one (it says what to fix),
  /// otherwise the server message.
  String _message(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        final first = value is List ? value.firstOrNull : value;
        if (first is String && first.trim().isNotEmpty) return first;
      }
    }
    final message = body['message'];
    return message is String && message.trim().isNotEmpty
        ? message
        : 'Unable to complete the request.';
  }
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
    this.phone,
    this.location,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    locale: json['locale'] as String? ?? 'en',
    phone: json['phone'] as String?,
    location: json['location'] as String?,
    avatarUrl: (json['avatar_url'] as String?)?.trim().isEmpty ?? true
        ? null
        : json['avatar_url'] as String,
  );

  final String name;
  final String email;
  final String locale;
  final String? phone;
  final String? location;

  /// Profile picture URL, or null when none was uploaded.
  final String? avatarUrl;

  /// Up to two initials for the avatar placeholder.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.readAt,
    required this.createdAt,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: _asInt(json['id']),
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: json['type'] as String? ?? 'info',
        readAt: json['read_at'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        data: json['data'] as Map<String, dynamic>?,
      );

  final int id;
  final String title;
  final String message;
  final String type;
  final String? readAt;
  final String createdAt;
  final Map<String, dynamic>? data;

  bool get isRead => readAt != null;
}

/// Categories managed in the database (never hard-coded in the app).
class CategoryCatalog {
  const CategoryCatalog({
    this.projectTypes = const [],
    this.workSections = const [],
    this.materials = const [],
  });

  factory CategoryCatalog.fromJson(Map<String, dynamic> json) {
    List<String> names(dynamic list) => (list is List ? list : const [])
        .map((e) => '$e'.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return CategoryCatalog(
      projectTypes: names(json['project_types']),
      workSections: names(json['work_sections']),
      materials:
          (json['materials'] is List ? json['materials'] as List : const [])
              .whereType<Map>()
              .map(
                (m) => MaterialCategory(
                  name: '${m['name'] ?? ''}',
                  description: '${m['description'] ?? ''}',
                  items: names(m['items']),
                ),
              )
              .where((m) => m.name.isNotEmpty)
              .toList(),
    );
  }

  final List<String> projectTypes;
  final List<String> workSections;
  final List<MaterialCategory> materials;
}

class MaterialCategory {
  const MaterialCategory({
    required this.name,
    this.description = '',
    this.items = const [],
  });

  final String name;
  final String description;
  final List<String> items;
}

/// Estimated vs generated amounts for a BOQ or a whole project.
class BoqTotals {
  const BoqTotals({
    this.items = 0,
    this.estimatedItems = 0,
    this.pricedItems = 0,
    this.estimatedAmount = 0,
    this.generatedTotal = 0,
    this.boqs = 0,
  });

  factory BoqTotals.fromJson(dynamic json) {
    if (json is! Map) return empty;
    return BoqTotals(
      items: _asInt(json['items']),
      estimatedItems: _asInt(json['estimated_items']),
      pricedItems: _asInt(json['priced_items']),
      estimatedAmount: _asDouble(json['estimated_amount']),
      generatedTotal: _asDouble(json['generated_total']),
      boqs: _asInt(json['boqs']),
    );
  }

  static const empty = BoqTotals();

  final int items;
  final int estimatedItems;
  final int pricedItems;
  final double estimatedAmount;
  final double generatedTotal;
  final int boqs;

  double get difference => generatedTotal - estimatedAmount;
  bool get hasEstimate => estimatedItems > 0;
  bool get hasGenerated => pricedItems > 0;
}

class ProjectSummary {
  /// Estimated amount and generated total from the BOQ items.
  final BoqTotals totals;

  const ProjectSummary({
    this.totals = BoqTotals.empty,
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    required this.boqCount,
    this.currency = 'UGX',
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) => ProjectSummary(
    currency: json['currency'] as String? ?? 'UGX',
    totals: BoqTotals.fromJson(json['totals']),
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
  final String currency;
}

class ProjectDetail {
  /// Estimated amount and generated total from the BOQ items.
  final BoqTotals totals;

  const ProjectDetail({
    this.totals = BoqTotals.empty,
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
    required this.originalLanguage,
    required this.reportLanguage,
    required this.boqs,
  });
  factory ProjectDetail.fromJson(Map<String, dynamic> json) => ProjectDetail(
    totals: BoqTotals.fromJson(json['totals']),
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
    startDate: _dateOnly(json['start_date']),
    expectedCompletionDate: _dateOnly(json['expected_completion_date']),
    contractValue: _asDouble(json['contract_value']),
    currency: json['currency'] as String? ?? 'UGX',
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? 'draft',
    ownerName: json['user']?['name'] as String? ?? '',
    originalLanguage: json['original_language'] as String? ?? '',
    reportLanguage: json['report_language'] as String? ?? '',
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
  final String originalLanguage;
  final String reportLanguage;
  final List<BoqSummary> boqs;
}

class BoqSummary {
  /// Estimated amount and generated total from the BOQ items.
  final BoqTotals totals;

  const BoqSummary({
    this.totals = BoqTotals.empty,
    required this.id,
    required this.name,
    required this.status,
  });
  factory BoqSummary.fromJson(Map<String, dynamic> json) => BoqSummary(
    totals: BoqTotals.fromJson(json['totals']),
    id: _asInt(json['id']),
    name: json['name'] as String? ?? '',
    status: json['status'] as String? ?? 'draft',
  );
  final int id;
  final String name;
  final String status;
}

/// A BOQ row in the BOQs list.
class BoqListItem {
  /// Estimated amount and generated total from the BOQ items.
  final BoqTotals totals;

  const BoqListItem({
    this.totals = BoqTotals.empty,
    required this.id,
    required this.name,
    required this.status,
    required this.description,
    required this.projectId,
    required this.projectName,
    required this.itemsCount,
    required this.createdAt,
    this.currency = 'UGX',
  });

  factory BoqListItem.fromJson(Map<String, dynamic> json) {
    final project = json['project'];
    return BoqListItem(
      totals: BoqTotals.fromJson(json['totals']),
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      description: json['description'] as String? ?? '',
      projectId: _asInt(json['project_id']),
      projectName: project is Map ? '${project['name'] ?? ''}' : '',
      itemsCount: _asInt(json['items_count']),
      createdAt: _dateOnly(json['created_at']),
      currency: json['currency'] as String? ?? 'UGX',
    );
  }

  final String currency;

  final int id;
  final String name;
  final String status;
  final String description;
  final int projectId;
  final String projectName;
  final int itemsCount;
  final String createdAt;
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
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
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
    this.priceType = 'hardware',
    this.sourceUrl = '',
    this.lastVerifiedAt = '',
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
    isActive: json['is_active'] == true || json['is_active'] == 1,
    priceType: json['price_type'] as String? ?? 'hardware',
    sourceUrl: json['source_url'] as String? ?? '',
    lastVerifiedAt: json['last_verified_at'] as String? ?? '',
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
  final String priceType;
  final String sourceUrl;
  final String lastVerifiedAt;
  final List<PriceHistory> priceHistory;

  bool get isFactory => priceType == 'factory';

  /// When the price was last confirmed (verification, else fetch).
  String get updatedAt =>
      lastVerifiedAt.isNotEmpty ? lastVerifiedAt : fetchedAt;
}

class BoqShareLink {
  const BoqShareLink({
    required this.url,
    required this.message,
    required this.whatsappUrl,
    required this.filename,
    required this.expiresInDays,
  });

  factory BoqShareLink.fromJson(Map<String, dynamic> json) => BoqShareLink(
    url: json['url'] as String? ?? '',
    message: json['message'] as String? ?? '',
    whatsappUrl: json['whatsapp_url'] as String? ?? '',
    filename: json['filename'] as String? ?? 'boq.pdf',
    expiresInDays: _asInt(json['expires_in_days']),
  );

  final String url;
  final String message;
  final String whatsappUrl;
  final String filename;
  final int expiresInDays;
}

class CompanyProfile {
  const CompanyProfile({required this.fields, this.logoUrl});

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
    fields: {for (final key in keys) key: json[key]?.toString() ?? ''},
    logoUrl: json['logo_url'] as String?,
  );

  /// Field names shared with the Laravel API.
  static const keys = [
    'company_name',
    'registration_number',
    'tin',
    'country',
    'city',
    'physical_address',
    'postal_address',
    'telephone',
    'alt_telephone',
    'email',
    'website',
    'description',
  ];

  final Map<String, String> fields;
  final String? logoUrl;

  String get companyName => fields['company_name'] ?? '';
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
        fetchedAt: '${json['fetched_at'] ?? ''}',
        similarityScore: _asInt(json['similarity_score']),
        matchReasons: (json['match_reasons'] as List<dynamic>? ?? [])
            .map((e) => '$e')
            .toList(),
        variancePercent: _asDoubleOrNull(json['variance_percent']),
        priceHistory: PriceHistorySummary.fromJson(
          json['price_history'] is Map<String, dynamic>
              ? json['price_history'] as Map<String, dynamic>
              : const {},
        ),
        rating: PriceRating.fromJson(
          json['rating'] is Map<String, dynamic>
              ? json['rating'] as Map<String, dynamic>
              : const {},
        ),
        badges: (json['badges'] as List<dynamic>? ?? [])
            .map((e) => '$e')
            .toList(),
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
        records: _asInt(json['records']),
        lowest: _asDouble(json['lowest']),
        highest: _asDouble(json['highest']),
        average: _asDouble(json['average']),
        change: _asDouble(json['change']),
        changePercent: _asDouble(json['change_percent']),
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
    overall: _asInt(json['overall']),
    valueScore: _asInt(json['value_score']),
    stabilityScore: _asInt(json['stability_score']),
    freshnessScore: _asInt(json['freshness_score']),
    supplierScore: _asInt(json['supplier_score']),
    availabilityScore: _asInt(json['availability_score']),
    factors: (json['factors'] is Map ? json['factors'] as Map : const {}).map(
      (k, v) => MapEntry('$k', '$v'),
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
        currentRate: _asDouble(json['current_rate']),
        currency: json['currency'] as String? ?? 'UGX',
        currentAmount: _asDouble(json['current_amount']),
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
        total: _asInt(json['total']),
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
        count: _asInt(json['count']),
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
  /// Estimated amount and generated total from the BOQ items.
  final BoqTotals totals;

  const BoqDetail({
    this.totals = BoqTotals.empty,
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
    this.projectId = 0,
  });
  factory BoqDetail.fromJson(Map<String, dynamic> json) => BoqDetail(
    totals: BoqTotals.fromJson(json['totals']),
    id: _asInt(json['id']),
    projectId: _asInt(json['project_id']),
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
  final int projectId;
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
            (k, v) => MapEntry(k, v as String),
          )
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
            (k, v) => MapEntry(k, v as String),
          )
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
            (k, v) => MapEntry(k, v as String),
          )
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
            (k, v) => MapEntry(k, v as String),
          )
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
    originalRate: _asDoubleOrNull(json['original_rate']),
    approvedRate: _asDoubleOrNull(json['approved_rate']),
    aiSuggestedRate: _asDoubleOrNull(json['ai_suggested_rate']),
    currency: json['currency'] as String? ?? 'UGX',
    workCategory: json['work_category'] as String?,
    materialCategory: json['material_category'] as String?,
    location: json['location'] as String?,
    pricingSource: json['pricing_source'] as String?,
    pricingDate: json['pricing_date'] as String?,
    aiConfidence: _asDoubleOrNull(json['ai_confidence']),
    translationConfidence: _asDoubleOrNull(json['translation_confidence']),
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
  factory BoqItemTranslation.fromJson(Map<String, dynamic> json) =>
      BoqItemTranslation(
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

// Proxy subscription models.

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

  factory ProxySubscription.fromJson(Map<String, dynamic> json) =>
      ProxySubscription(
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

  factory BeneficiaryUser.fromJson(Map<String, dynamic> json) =>
      BeneficiaryUser(
        id: _asInt(json['id']),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  final int id;
  final String name;
  final String email;
}

// BOQ pricing job models.

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

  factory BoqPricingJobProgress.fromJson(Map<String, dynamic> json) =>
      BoqPricingJobProgress(
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

// AI provider and hardware category models.

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
    this.code = '',
    this.description,
    required this.isActive,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory HardwareCategory.fromJson(Map<String, dynamic> json) =>
      HardwareCategory(
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
