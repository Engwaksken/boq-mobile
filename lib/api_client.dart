import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'app_errors.dart';
import 'json_utils.dart';

part 'organisation_api.dart';

/// `2026-09-01T00:00:00.000000Z` → `2026-09-01` (API date columns).
String _dateOnly(dynamic value) {
  final raw = jsonString(value).trim();
  return RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(raw)?.group(0) ?? raw;
}

/// A list of non-empty, trimmed strings from an API/JSON value.
List<String> _stringList(dynamic value) =>
    (value is List ? value : const <dynamic>[])
        .map((e) => '$e'.trim())
        .where((e) => e.isNotEmpty)
        .toList();

/// A list of strings persisted as JSON, tolerating missing/corrupt values.
List<String> _storedStringList(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    return _stringList(jsonDecode(raw));
  } on FormatException {
    return const [];
  }
}

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
            path.endsWith('/expenses/extract') ||
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
    unawaited(_clearAccess());
    _sessionExpired.add(message);
  }

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Production is the safe default for installed builds. Override this at
    // run/build time when developing against a local Laravel server.
    defaultValue: 'https://boq.kemmytech.com/api/v1',
  );

  static const _tokenKey = 'auth_token';
  static const _permissionsKey = 'auth_permissions';
  static const _rolesKey = 'auth_roles';
  static const _organisationKey = 'auth_has_organisation';

  late final http.Client _httpClient;
  final FlutterSecureStorage _storage;

  /// Access control cached for the signed-in user (permissions, role slugs
  /// and whether the account belongs to an organisation).
  Set<String> _permissions = <String>{};
  Set<String> _roles = <String>{};
  bool _hasOrganisation = false;

  /// True when a permission/role payload has been seen for this session.
  bool _accessLoaded = false;

  /// Whether the signed-in user holds [permission] (e.g. `boq.edit`).
  /// Unknown or omitted permissions are treated as not granted.
  bool can(String permission) => _permissions.contains(permission.trim());

  /// Whether the signed-in user has the role [slug] (e.g. `administrator`).
  bool hasRole(String slug) => _roles.contains(slug.trim());

  /// A personal account: the user was never attached to an organisation.
  bool get isPersonalAccount => _accessLoaded && !_hasOrganisation;

  /// Organisation owners/admins and personal accounts may edit the company
  /// profile. The customer/owner role (`user`) is included because organisations
  /// are created with that role; invited operational roles (project-manager,
  /// procurement-officer, finance) are excluded.
  bool get canManageCompanyProfile =>
      isPersonalAccount ||
      hasRole('user') ||
      hasRole('administrator') ||
      hasRole('super-admin');

  Future<bool> hasSession() async =>
      (await _storage.read(key: _tokenKey)) != null;

  /// Restores the cached permissions/roles and, when the server can be
  /// reached, refreshes them from `/auth/me`. Returns false only when the
  /// stored session is missing or the server rejects it (401/403).
  Future<bool> loadAccess() async {
    await _loadStoredAccess();
    try {
      await profile();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) return false;
      return true;
    } on Object {
      // Offline or unexpected error: keep the cached values.
      return true;
    }
  }

  void _applyAccess({
    required Iterable<String> permissions,
    required Iterable<String> roles,
    required bool hasOrganisation,
  }) {
    _permissions = permissions
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet();
    _roles = roles.map((r) => r.trim()).where((r) => r.isNotEmpty).toSet();
    _hasOrganisation = hasOrganisation;
    _accessLoaded = true;
  }

  /// Reads permissions, role slugs and the organisation flag from an
  /// auth payload (`data` of login/register/me) and persists them.
  Future<void> _storeAccessFromData(Map<String, dynamic>? data) async {
    if (data == null) return;
    final user = data['user'] is Map<String, dynamic>
        ? jsonMap(data['user'])
        : const <String, dynamic>{};
    final roles = (user['roles'] is List ? jsonList(user['roles']) : const [])
        .whereType<Map>()
        .map((role) => '${role['slug'] ?? ''}');
    final organisation = user['organisation'];
    final hasOrganisation = organisation is Map && organisation['id'] != null;
    _applyAccess(
      permissions: _stringList(data['permissions']),
      roles: roles,
      hasOrganisation: hasOrganisation,
    );
    await _persistAccess();
  }

  Future<void> _persistAccess() async {
    await _storage.write(
      key: _permissionsKey,
      value: jsonEncode(_permissions.toList()),
    );
    await _storage.write(key: _rolesKey, value: jsonEncode(_roles.toList()));
    await _storage.write(
      key: _organisationKey,
      value: _hasOrganisation ? 'true' : 'false',
    );
  }

  Future<void> _loadStoredAccess() async {
    final permissions = await _storage.read(key: _permissionsKey);
    final roles = await _storage.read(key: _rolesKey);
    final organisation = await _storage.read(key: _organisationKey);
    _applyAccess(
      permissions: _storedStringList(permissions),
      roles: _storedStringList(roles),
      hasOrganisation: organisation == 'true',
    );
  }

  Future<void> _clearAccess() async {
    _applyAccess(
      permissions: const [],
      roles: const [],
      hasOrganisation: false,
    );
    _accessLoaded = false;
    await _storage.delete(key: _permissionsKey);
    await _storage.delete(key: _rolesKey);
    await _storage.delete(key: _organisationKey);
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
    }

    final token = jsonStringOrNull(jsonMap(body['data'])['token']);
    if (token == null || token.isEmpty) {
      throw const ApiException('The server did not return an access token.');
    }
    await _storage.write(key: _tokenKey, value: token);
    await _storeAccessFromData(jsonMapOrNull(body['data']));
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
      throw _apiError(response, body);
    }

    final token = jsonStringOrNull(jsonMap(body['data'])['token']);

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your account was created, but the server did not return an access token.',
      );
    }

    await _storage.write(key: _tokenKey, value: token);
    await _storeAccessFromData(jsonMapOrNull(body['data']));
  }

  Future<void> forgotPassword({required String email}) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: const {'Accept': 'application/json'},
      body: {'email': email.trim()},
    );

    final body = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw _apiError(response, body);
    }
  }

  Future<DashboardSummary> dashboard() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
    }
    return DashboardSummary.fromJson(jsonMap(body['data']));
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return UserProfile.fromJson(jsonMap(jsonMap(body['data'])['user']));
  }

  Future<UserProfile> deleteAvatar() async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/auth/avatar'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return UserProfile.fromJson(jsonMap(jsonMap(body['data'])['user']));
  }

  Future<UserProfile> profile() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
    }
    final data = body['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    if (map['user'] is Map<String, dynamic>) {
      await _storeAccessFromData(map);
    }
    return UserProfile.fromJson(jsonMap(map['user']));
  }

  Future<Map<String, dynamic>> currentSubscription() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/subscriptions/current'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return jsonMap(body['data']);
  }

  Future<List<Map<String, dynamic>>> plans() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/plans'),
      headers: const {'Accept': 'application/json'},
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(body['data'])).whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createSubscription(int planId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/subscriptions'),
      headers: await _headers(),
      body: {'plan_id': '$planId'},
    );
    final body = _decode(response);
    if (response.statusCode != 201) {
      throw _apiError(response, body);
    }
    return jsonMap(body['data']);
  }

  Future<List<Map<String, dynamic>>> paymentGateways() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/payment-gateways'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
    }
    return (jsonList(body['data'])).whereType<Map<String, dynamic>>().toList();
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
      throw _apiError(response, body);
    }
    return jsonMap(body['data']);
  }

  Future<Map<String, dynamic>> transaction(int transactionId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/transactions/$transactionId'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
    }
    return jsonMap(body['data']);
  }

  Future<Map<String, dynamic>> paymentReceipt(int transactionId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/transactions/$transactionId/receipt'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
    }
    return jsonMap(body['data']);
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
      throw _apiError(response, body);
    }
    return jsonMap(body['data']);
  }

  Future<List<Map<String, dynamic>>> subscriptions() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/subscriptions'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
    }
    return (jsonList(body['data'])).whereType<Map<String, dynamic>>().toList();
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
      throw _apiError(response, body);
    }
    return UserProfile.fromJson(jsonMap(jsonMap(body['data'])['user']));
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
      throw _apiError(response, body);
    }
    final pageData = jsonMap(body['data']);
    return (jsonList(
      pageData['data'],
    )).whereType<Map<String, dynamic>>().map(ProjectSummary.fromJson).toList();
  }

  Future<ProjectDetail> project(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/projects/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return ProjectDetail.fromJson(jsonMap(body['data']));
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
      throw _apiError(response, body);
    }
    return ProjectSummary.fromJson(jsonMap(body['data']));
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return ProjectDetail.fromJson(jsonMap(body['data']));
  }

  /// Sets only the project's location (other fields are left as they are).
  Future<void> updateProjectLocation(int id, String location) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl/projects/$id'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'location': location}),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
  }

  Future<void> deleteProject(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/projects/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
  }

  Future<HardwarePricePaginated> hardwarePrices({
    String? priceType,
    String? brand,
    String? category,
    String? supplier,
    String? location,
    String? region,
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
    if (region != null) queryParams['region'] = region;
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return HardwarePricePaginated.fromJson(jsonMap(body['data']));
  }

  Future<HardwarePrice> hardwarePrice(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-prices/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return HardwarePrice.fromJson(jsonMap(body['data']));
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return HardwarePriceHistory.fromJson(jsonMap(body['data']));
  }

  Future<HardwarePriceStatistics> hardwarePriceStatistics() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-prices/statistics'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return HardwarePriceStatistics.fromJson(jsonMap(body['data']));
  }

  Future<List<HardwarePriceCategory>> hardwarePriceCategories() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-prices/categories'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(body['data']))
        .whereType<Map<String, dynamic>>()
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return CategoryCatalog.fromJson(jsonMap(body['data']));
  }

  /// Distinct suppliers, locations and regions for the price list filters.
  Future<
    ({List<String> suppliers, List<String> locations, List<String> regions})
  >
  hardwarePriceFilters() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-prices/filters'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    final data = jsonMap(body['data']);
    List<String> names(String key) => (jsonList(
      data[key],
    )).map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
    return (
      suppliers: names('suppliers'),
      locations: names('locations'),
      regions: names('regions'),
    );
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(body['data']))
        .whereType<Map<String, dynamic>>()
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return PriceComparisonResult.fromJson(jsonMap(body['data']));
  }

  Future<BoqItemPriceMatch> matchBoqItem(int boqItemId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boq-items/$boqItemId/matches'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqItemPriceMatch.fromJson(jsonMap(body['data']));
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqItemSummary.fromJson(jsonMap(body['data']));
  }

  Future<BoqDetail> boqDetail(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqDetail.fromJson(jsonMap(body['data']));
  }

  Future<BoqItemDetail> boqItemDetail(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boq-items/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqItemDetail.fromJson(jsonMap(body['data']));
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
    if (response.statusCode != 201) throw _apiError(response, body);
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
          errorCode: 'FEATURE_TOPUP_REQUIRED',
        );
      }
      throw _apiError(response, body);
    }
    final meta = body['meta'];
    if (meta is Map && jsonIntOrNull(meta['items_imported']) != null) {
      return jsonInt(meta['items_imported']);
    }
    final data = body['data'];
    if (data is Map && jsonIntOrNull(data['items_created']) != null) {
      return jsonInt(data['items_created']);
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
      throw _apiError(response, body);
    }
    final pageData = jsonMap(body['data']);
    return (jsonList(
      pageData['data'],
    )).whereType<Map<String, dynamic>>().map(BoqItemSummary.fromJson).toList();
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
      if (response.statusCode != 200) throw _apiError(response, body);
      final pageData = body['data'];
      if (pageData is! Map<String, dynamic>) break;
      final rows = pageData['data'];
      if (rows is! List) break;
      all.addAll(
        rows.whereType<Map<String, dynamic>>().map(BoqItemSummary.fromJson),
      );
      lastPage = jsonIntOrNull(pageData['last_page']) ?? page;
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return jsonMap(body['data']);
  }

  Future<int> priceAll(int boqId, String location) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/price-all'),
      headers: await _headers(),
      body: {'location': location},
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return jsonIntOrNull(jsonMap(body['data'])['items_priced']) ?? 0;
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(body['data'])).whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> allPricingHistory(int boqId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-history'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(body['data'])).whereType<Map<String, dynamic>>().toList();
  }

  Future<PricingBatch> startPricingBatch(int boqId, String location) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-batches'),
      headers: await _headers(),
      body: {'location': location},
    );
    final body = _decode(response);
    if (response.statusCode != 202) throw _apiError(response, body);
    return PricingBatch.fromJson(jsonMap(body['data']));
  }

  Future<PricingBatch> pricingBatch(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/pricing-batches/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
    }
    return PricingBatch.fromJson(jsonMap(body['data']));
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
      throw _apiError(response, body);
    }
    return jsonStringOrNull(body['message']) ?? 'BOQ sent.';
  }

  /// Signed download link plus a ready-made message for WhatsApp / device sharing.
  Future<BoqShareLink> boqShareLink(int boqId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/share/link'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
    }
    return BoqShareLink.fromJson(jsonMap(body['data']));
  }

  /// ISO code => country name, from the server's managed list (default country first).
  Future<Map<String, String>> countries() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/mobile-config'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw _apiError(response, body);
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
      throw _apiError(response, body);
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
          ? jsonList(errors.values.first).firstOrNull?.toString()
          : null;
      final code = body['error_code'] ?? body['code'];
      throw ApiException(
        firstError ?? _message(body),
        statusCode: response.statusCode,
        errorCode: code is String && code.trim().isNotEmpty ? code : null,
      );
    }
    return CompanyProfile.fromJson(jsonMap(body['data']));
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
    await _clearAccess();
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
    if (response.statusCode != 200) throw _apiError(response, body);
    final pageData = jsonMap(body['data']);
    return (jsonList(pageData['data']))
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
  }

  Future<void> markNotificationAsRead(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
  }

  /// BOQs the user can see, newest first.
  Future<({List<BoqListItem> items, int lastPage})> boqs({
    String? search,
    int? projectId,
    String? status,
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
          if (status != null && status.trim().isNotEmpty)
            'status': status.trim(),
        },
      ),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    final pageData = jsonMap(body['data']);
    final rows = jsonList(pageData['data']);
    return (
      items: rows
          .whereType<Map<String, dynamic>>()
          .map(BoqListItem.fromJson)
          .toList(),
      lastPage: jsonInt(pageData['last_page'] ?? 1),
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
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqListItem.fromJson(jsonMap(body['data']));
  }

  /// CSV of the BOQ's items with an "Estimated Rate" column to fill in.
  Future<Uint8List> boqEstimatesTemplate(int boqId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/estimates/template'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw _apiError(response, _decode(response));
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
    if (response.statusCode != 200) throw _apiError(response, body);
    final data = jsonMap(body['data']);
    return (
      message: '${body['message'] ?? 'Estimated prices updated.'}',
      totals: BoqTotals.fromJson(data['totals']),
      unmatched: (jsonList(data['unmatched'])).map((e) => '$e').toList(),
    );
  }

  /// Locations this BOQ has prices for, with totals.
  Future<List<BoqLocation>> boqLocations(int boqId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/locations'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(
      body['data'],
    )).whereType<Map<String, dynamic>>().map(BoqLocation.fromJson).toList();
  }

  /// Item rates side by side for 2 to 4 location keys.
  Future<LocationComparison> compareBoqLocations(
    int boqId,
    List<String> keys,
  ) async {
    final query = keys
        .map((k) => 'locations[]=${Uri.encodeQueryComponent(k)}')
        .join('&');
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/boqs/$boqId/locations/compare?$query'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return LocationComparison.fromJson(jsonMap(body['data']));
  }

  /// Switches the BOQ to one location's saved prices. Returns items changed.
  Future<int> useBoqLocation(int boqId, String location) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/locations/use'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'location': location}),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return jsonInt(jsonMap(body['data'])['applied']);
  }

  /// action: accept (use suggested as reviewed) | approve | reject (reason).
  Future<({int done, int skipped})> bulkReviewItems(
    int boqId, {
    required String action,
    required List<int> itemIds,
    String? reason,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/items/bulk-review'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': action,
        'item_ids': itemIds,
        'reason': ?reason,
      }),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (
      done: jsonInt(jsonMap(body['data'])['done']),
      skipped: jsonInt(jsonMap(body['data'])['skipped']),
    );
  }

  Future<void> deleteBoq(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/boqs/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
  }

  /// Starts fetching the latest prices on the server. The server answers at
  /// once (202) and fetches in the background; the returned message says so.
  Future<({String status, String message})> fetchDailyPrices() async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/hardware-prices/fetch'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200 && response.statusCode != 202) {
      throw _apiError(response, body);
    }
    final data = body['data'] is Map<String, dynamic>
        ? jsonMap(body['data'])
        : const <String, dynamic>{};
    final status = '${body['status'] ?? data['status'] ?? 'started'}';
    final message = body['message'] is String && '${body['message']}'.isNotEmpty
        ? jsonString(body['message'])
        : status == 'running'
        ? 'Prices are already being fetched.'
        : 'Fetching the latest prices. New prices appear in a few minutes.';
    return (status: status, message: message);
  }

  // Proxy subscription API methods.

  Future<List<BeneficiaryUser>> searchBeneficiaries(String query) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$baseUrl/subscriptions/proxy/beneficiaries',
      ).replace(queryParameters: {'query': query}),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(
      body['data'],
    )).whereType<Map<String, dynamic>>().map(BeneficiaryUser.fromJson).toList();
  }

  Future<ProxySubscription> createProxySubscription({
    required int planId,
    required int beneficiaryId,
    required int paymentGatewayId,
    String? paymentMethod,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/subscriptions/proxy'),
      headers: await _headers(),
      body: {
        'plan_id': planId.toString(),
        'beneficiary_id': beneficiaryId.toString(),
        'payment_gateway_id': paymentGatewayId.toString(),
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'payment_method': paymentMethod,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) throw _apiError(response, body);
    return ProxySubscription.fromJson(jsonMap(body['data']));
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
        '$baseUrl/subscriptions/proxy/$proxySubscriptionId/payments',
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
    if (response.statusCode != 201) throw _apiError(response, body);
    return jsonMap(body['data']);
  }

  /// Verifies a proxy payment by its transaction id (not the subscription id).
  Future<Map<String, dynamic>> verifyProxyPayment(
    int transactionId, {
    String? gatewayTransactionId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse(
        '$baseUrl/transactions/proxy/$transactionId/verify',
      ),
      headers: await _headers(),
      body: {
        if (gatewayTransactionId != null && gatewayTransactionId.isNotEmpty)
          'gateway_transaction_id': gatewayTransactionId,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return jsonMap(body['data']);
  }

  Future<List<ProxySubscription>> listProxySubscriptions() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/subscriptions/proxy'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(body['data']))
        .whereType<Map<String, dynamic>>()
        .map(ProxySubscription.fromJson)
        .toList();
  }

  Future<ProxySubscription> getProxySubscription(int id) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/subscriptions/proxy/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return ProxySubscription.fromJson(jsonMap(body['data']));
  }

  Future<void> cancelProxySubscription(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/subscriptions/proxy/$id/cancel'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
  }

  // BOQ pricing job API methods.

  Future<BoqPricingJob> startPricingJob(int boqId, {int batchSize = 25}) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/boqs/$boqId/pricing-jobs'),
      headers: await _headers(),
      body: {'batch_size': batchSize.toString()},
    );
    final body = _decode(response);
    if (response.statusCode != 201) throw _apiError(response, body);
    return BoqPricingJob.fromJson(jsonMap(body['data']));
  }

  Future<BoqPricingJob> getPricingJob(int boqId, int jobId) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/pricing-jobs/$jobId'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqPricingJob.fromJson(jsonMap(body['data']));
  }

  Future<BoqPricingJob> startPricingJobProcessing(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/pricing-jobs/$jobId/start'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqPricingJob.fromJson(jsonMap(body['data']));
  }

  Future<BoqPricingJobProgress> processNextBatch(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/pricing-jobs/$jobId/next-batch'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqPricingJobProgress.fromJson(jsonMap(body['data']));
  }

  Future<BoqPricingJob> pausePricingJob(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/pricing-jobs/$jobId/pause'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqPricingJob.fromJson(jsonMap(body['data']));
  }

  Future<BoqPricingJob> resumePricingJob(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/pricing-jobs/$jobId/resume'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqPricingJob.fromJson(jsonMap(body['data']));
  }

  Future<BoqPricingJob> cancelPricingJob(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/pricing-jobs/$jobId/cancel'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqPricingJob.fromJson(jsonMap(body['data']));
  }

  Future<BoqPricingJob> retryFailedItems(int boqId, int jobId) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/pricing-jobs/$jobId/retry-failed'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqPricingJob.fromJson(jsonMap(body['data']));
  }

  Future<BoqPricingJobProgress> getPricingJobProgress(
    int boqId,
    int jobId,
  ) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/pricing-jobs/$jobId/progress'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return BoqPricingJobProgress.fromJson(jsonMap(body['data']));
  }

  // AI provider admin API methods.

  Future<List<AiProvider>> aiProviders() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/ai-providers'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(
      body['data'],
    )).whereType<Map<String, dynamic>>().map(AiProvider.fromJson).toList();
  }

  Future<AiProvider> createAiProvider({
    required String name,
    required String code,
    required String apiKey,
    required String providerType,
    required String defaultModel,
    Map<String, dynamic>? config,
    bool isDefault = false,
    bool isEnabled = true,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/ai-providers'),
      headers: await _headers(),
      body: {
        'name': name,
        'key': code,
        'api_key': apiKey,
        'provider_type': providerType,
        'default_model': defaultModel,
        ..._settingsFields(config),
        'is_default': isDefault ? '1' : '0',
        'is_enabled': isEnabled ? '1' : '0',
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) throw _apiError(response, body);
    return AiProvider.fromJson(jsonMap(body['data']));
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
    body.addAll(_settingsFields(config));
    if (isDefault != null) body['is_default'] = isDefault ? '1' : '0';
    if (isEnabled != null) body['is_enabled'] = isEnabled ? '1' : '0';

    final response = await _httpClient.put(
      Uri.parse('$baseUrl/ai-providers/$id'),
      headers: await _headers(),
      body: body,
    );
    final responseBody = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, responseBody);
    return AiProvider.fromJson(jsonMap(responseBody['data']));
  }

  /// Provider settings as form fields (`settings[timeout]=30`), the shape
  /// the API validates as an array.
  static Map<String, String> _settingsFields(Map<String, dynamic>? config) => {
    for (final entry in (config ?? const <String, dynamic>{}).entries)
      if (entry.value != null && entry.value is! Map && entry.value is! List)
        'settings[${entry.key}]': '${entry.value}',
  };

  Future<void> deleteAiProvider(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/ai-providers/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
  }

  Future<Map<String, dynamic>> testAiProvider(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/ai-providers/$id/test'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return jsonMap(body['data']);
  }

  Future<AiProvider> setDefaultAiProvider(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/ai-providers/$id/set-default'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return AiProvider.fromJson(jsonMap(body['data']));
  }

  // Hardware category admin API methods.

  Future<List<HardwareCategory>> hardwareCategoriesAdmin() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/hardware-categories'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    final raw = body['data'];
    final list = raw is List
        ? raw
        : raw is Map && raw['data'] is List
        ? jsonList(raw['data'])
        : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
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
    if (response.statusCode != 201) throw _apiError(response, body);
    return HardwareCategory.fromJson(jsonMap(body['data']));
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
    if (response.statusCode != 200) throw _apiError(response, responseBody);
    return HardwareCategory.fromJson(jsonMap(responseBody['data']));
  }

  Future<void> deleteHardwareCategory(int id) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/hardware-categories/$id'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
  }

  Future<HardwareCategory> toggleHardwareCategory(int id) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/hardware-categories/$id/toggle-active'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return HardwareCategory.fromJson(jsonMap(body['data']));
  }

  // Supplier and factory ratings ("Top Suppliers").

  /// Top rated (or [lowest] rated) suppliers of a [type] (`supplier` =
  /// hardware, `factory`) in a [period]: `week`, `month`, `year` or `all`.
  Future<SupplierLeaderboard> supplierLeaderboard({
    String period = 'month',
    String type = 'supplier',
    int limit = 10,
    bool lowest = false,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/supplier-ratings/leaderboard').replace(
        queryParameters: {
          'period': period,
          'type': type,
          'limit': '$limit',
          'order': lowest ? 'lowest' : 'top',
        },
      ),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return SupplierLeaderboard.fromJson(jsonMap(body['data']));
  }

  /// Totals, distribution, by type, scores by area and 12-month trends.
  Future<SupplierRatingSummary> supplierRatingSummary({
    String period = 'month',
  }) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$baseUrl/supplier-ratings/summary',
      ).replace(queryParameters: {'period': period}),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return SupplierRatingSummary.fromJson(jsonMap(body['data']));
  }

  /// Active suppliers and factories to pick one to rate.
  Future<List<RatedSupplier>> ratableSuppliers({
    String search = '',
    String? type,
    int limit = 20,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/supplier-ratings/suppliers').replace(
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          'type': ?type,
          'limit': '$limit',
        },
      ),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(
      body['data'],
    )).whereType<Map<String, dynamic>>().map(RatedSupplier.fromJson).toList();
  }

  /// One supplier's performance and the user's rating this month.
  Future<SupplierPerformance> supplierPerformance(
    int supplierId, {
    String period = 'month',
  }) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$baseUrl/supplier-ratings/suppliers/$supplierId',
      ).replace(queryParameters: {'period': period}),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return SupplierPerformance.fromJson(jsonMap(body['data']));
  }

  /// Rates a supplier (1 to 5 stars). A second rating in the same month
  /// updates the first. Returns the server's message and the saved rating.
  Future<({String message, SupplierRatingEntry rating})> rateSupplier(
    int supplierId, {
    required int rating,
    int? priceRating,
    int? qualityRating,
    int? deliveryRating,
    int? serviceRating,
    String? comment,
  }) async {
    final text = comment?.trim() ?? '';
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/supplier-ratings/suppliers/$supplierId'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'rating': rating,
        'price_rating': priceRating,
        'quality_rating': qualityRating,
        'delivery_rating': deliveryRating,
        'service_rating': serviceRating,
        'comment': text.isEmpty ? null : text,
      }),
    );
    final body = _decode(response);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _apiError(response, body);
    }
    return (
      message: '${body['message'] ?? 'Your rating was saved.'}',
      rating: SupplierRatingEntry.fromJson(jsonMap(body['data'])),
    );
  }

  /// The user's latest supplier ratings.
  Future<List<SupplierRatingEntry>> mySupplierRatings() async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl/supplier-ratings/mine'),
      headers: await _headers(),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return (jsonList(body['data']))
        .whereType<Map<String, dynamic>>()
        .map(SupplierRatingEntry.fromJson)
        .toList();
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
        jsonStringOrNull(body['message']) ??
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

  ApiException _apiError(http.Response response, Map<String, dynamic> body) {
    final code = body['error_code'] ?? body['code'];
    return ApiException(
      _message(body),
      statusCode: response.statusCode,
      errorCode: code is String && code.trim().isNotEmpty ? code : null,
    );
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
        totalProjects: jsonInt(json['total_projects']),
        activeProjects: jsonInt(json['active_projects']),
        boqsAwaitingReview: jsonInt(json['boqs_awaiting_review']),
        totalEstimatedValue: jsonDouble(json['total_estimated_value']),
        recentProjects: (jsonList(json['recent_projects']))
            .whereType<Map<String, dynamic>>()
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
    name: jsonStringOrNull(json['name']) ?? '',
    email: jsonStringOrNull(json['email']) ?? '',
    locale: jsonStringOrNull(json['locale']) ?? 'en',
    phone: jsonStringOrNull(json['phone']),
    location: jsonStringOrNull(json['location']),
    avatarUrl: (jsonStringOrNull(json['avatar_url']))?.trim().isEmpty ?? true
        ? null
        : jsonString(json['avatar_url']),
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
        id: jsonInt(json['id']),
        title: jsonStringOrNull(json['title']) ?? '',
        message: jsonStringOrNull(json['message']) ?? '',
        type: jsonStringOrNull(json['type']) ?? 'info',
        readAt: jsonStringOrNull(json['read_at']),
        createdAt: jsonStringOrNull(json['created_at']) ?? '',
        data: jsonMapOrNull(json['data']),
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

/// A location a BOQ has been priced for.
class BoqLocation {
  const BoqLocation({
    required this.key,
    required this.location,
    required this.pricedItems,
    required this.totalItems,
    required this.total,
    this.current = false,
    this.pricedAt,
  });

  factory BoqLocation.fromJson(Map<String, dynamic> json) => BoqLocation(
    key: '${json['key'] ?? ''}',
    location: '${json['location'] ?? ''}',
    pricedItems: jsonInt(json['priced_items']),
    totalItems: jsonInt(json['total_items']),
    total: jsonDouble(json['total']),
    current: json['current'] == true,
    pricedAt: jsonStringOrNull(json['priced_at']),
  );

  final String key;
  final String location;
  final int pricedItems;
  final int totalItems;
  final double total;
  final bool current;
  final String? pricedAt;
}

class LocationComparison {
  const LocationComparison({required this.locations, required this.rows});

  factory LocationComparison.fromJson(Map<String, dynamic> json) =>
      LocationComparison(
        locations: (jsonList(
          json['locations'],
        )).whereType<Map<String, dynamic>>().map(BoqLocation.fromJson).toList(),
        rows: (jsonList(json['rows']))
            .whereType<Map<String, dynamic>>()
            .map(LocationComparisonRow.fromJson)
            .toList(),
      );

  final List<BoqLocation> locations;
  final List<LocationComparisonRow> rows;
}

class LocationComparisonRow {
  const LocationComparisonRow({
    required this.itemId,
    required this.code,
    required this.description,
    required this.quantity,
    required this.rates,
    this.lowest,
  });

  factory LocationComparisonRow.fromJson(Map<String, dynamic> json) {
    final raw = json['rates'];
    return LocationComparisonRow(
      itemId: jsonInt(json['item_id']),
      code: '${json['item_code'] ?? ''}',
      description: '${json['description'] ?? ''}',
      quantity: jsonDouble(json['quantity']),
      rates: {
        if (raw is Map)
          for (final entry in raw.entries)
            '${entry.key}': entry.value == null
                ? null
                : jsonDouble(entry.value),
      },
      lowest: jsonStringOrNull(json['lowest']),
    );
  }

  final int itemId;
  final String code;
  final String description;
  final double quantity;
  final Map<String, double?> rates;
  final String? lowest;
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
          (json['materials'] is List ? jsonList(json['materials']) : const [])
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
      items: jsonInt(json['items']),
      estimatedItems: jsonInt(json['estimated_items']),
      pricedItems: jsonInt(json['priced_items']),
      estimatedAmount: jsonDouble(json['estimated_amount']),
      generatedTotal: jsonDouble(json['generated_total']),
      boqs: jsonInt(json['boqs']),
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
    currency: jsonStringOrNull(json['currency']) ?? 'UGX',
    totals: BoqTotals.fromJson(json['totals']),
    id: jsonInt(json['id']),
    name: jsonStringOrNull(json['name']) ?? '',
    code: jsonStringOrNull(json['code']) ?? '',
    status: jsonStringOrNull(json['status']) ?? 'draft',
    boqCount: jsonInt(json['boqs_count']),
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
    id: jsonInt(json['id']),
    name: jsonStringOrNull(json['name']) ?? '',
    code: jsonStringOrNull(json['code']) ?? '',
    client: jsonStringOrNull(json['client']) ?? '',
    contractor: jsonStringOrNull(json['contractor']) ?? '',
    consultant: jsonStringOrNull(json['consultant']) ?? '',
    quantitySurveyor: jsonStringOrNull(json['quantity_surveyor']) ?? '',
    projectManager: jsonStringOrNull(json['project_manager']) ?? '',
    siteEngineer: jsonStringOrNull(json['site_engineer']) ?? '',
    fundingOrganisation: jsonStringOrNull(json['funding_organisation']) ?? '',
    country: jsonStringOrNull(json['country']) ?? '',
    district: jsonStringOrNull(json['district']) ?? '',
    location: jsonStringOrNull(json['location']) ?? '',
    projectType: jsonStringOrNull(json['project_type']) ?? '',
    startDate: _dateOnly(json['start_date']),
    expectedCompletionDate: _dateOnly(json['expected_completion_date']),
    contractValue: jsonDouble(json['contract_value']),
    currency: jsonStringOrNull(json['currency']) ?? 'UGX',
    description: jsonStringOrNull(json['description']) ?? '',
    status: jsonStringOrNull(json['status']) ?? 'draft',
    ownerName: jsonStringOrNull(jsonMap(json['user'])['name']) ?? '',
    originalLanguage: jsonStringOrNull(json['original_language']) ?? '',
    reportLanguage: jsonStringOrNull(json['report_language']) ?? '',
    boqs: (jsonList(
      json['boqs'],
    )).whereType<Map<String, dynamic>>().map(BoqSummary.fromJson).toList(),
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
    id: jsonInt(json['id']),
    name: jsonStringOrNull(json['name']) ?? '',
    status: jsonStringOrNull(json['status']) ?? 'draft',
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
      id: jsonInt(json['id']),
      name: jsonStringOrNull(json['name']) ?? '',
      status: jsonStringOrNull(json['status']) ?? 'draft',
      description: jsonStringOrNull(json['description']) ?? '',
      projectId: jsonInt(json['project_id']),
      projectName: project is Map ? '${project['name'] ?? ''}' : '',
      itemsCount: jsonInt(json['items_count']),
      createdAt: _dateOnly(json['created_at']),
      currency: jsonStringOrNull(json['currency']) ?? 'UGX',
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
    this.reviewStatus = 'pending',
  });
  factory BoqItemSummary.fromJson(Map<String, dynamic> json) => BoqItemSummary(
    reviewStatus: jsonStringOrNull(json['status']) ?? 'pending',
    id: jsonInt(json['id']),
    code: jsonStringOrNull(json['item_code']) ?? '',
    description: jsonStringOrNull(json['description']) ?? '',
    quantity: '${json['quantity'] ?? 0}',
    unit: jsonStringOrNull(json['unit']) ?? '',
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

  /// pending | reviewed | approved | rejected
  final String reviewStatus;
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errorCode});
  final String message;
  final int? statusCode;

  /// Machine-readable code from the server (`error_code` or `code`), if any.
  final String? errorCode;

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
    id: jsonInt(json['id']),
    status: jsonStringOrNull(json['status']) ?? 'unknown',
    total: jsonInt(json['total_items']),
    processed: jsonInt(json['processed_items']),
    failed: jsonInt(json['failed_items']),
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
    id: jsonInt(json['id']),
    itemName: jsonStringOrNull(json['item_name']) ?? '',
    brand: jsonStringOrNull(json['brand']) ?? '',
    category: jsonStringOrNull(json['category']) ?? '',
    specification: jsonStringOrNull(json['specification']) ?? '',
    unit: jsonStringOrNull(json['unit']) ?? '',
    price: jsonDouble(json['price']),
    currency: jsonStringOrNull(json['currency']) ?? 'UGX',
    supplier: jsonStringOrNull(json['supplier']) ?? '',
    location: jsonStringOrNull(json['location']) ?? '',
    sourceReference: jsonStringOrNull(json['source_reference']) ?? '',
    fetchedAt: jsonStringOrNull(json['fetched_at']) ?? '',
    isActive: json['is_active'] == true || json['is_active'] == 1,
    priceType: jsonStringOrNull(json['price_type']) ?? 'hardware',
    sourceUrl: jsonStringOrNull(json['source_url']) ?? '',
    lastVerifiedAt: jsonStringOrNull(json['last_verified_at']) ?? '',
    priceHistory: json['price_histories'] != null
        ? (jsonList(json['price_histories']))
              .whereType<Map<String, dynamic>>()
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
    url: jsonStringOrNull(json['url']) ?? '',
    message: jsonStringOrNull(json['message']) ?? '',
    whatsappUrl: jsonStringOrNull(json['whatsapp_url']) ?? '',
    filename: jsonStringOrNull(json['filename']) ?? 'boq.pdf',
    expiresInDays: jsonInt(json['expires_in_days']),
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
    logoUrl: jsonStringOrNull(json['logo_url']),
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
    id: jsonInt(json['id']),
    price: jsonDouble(json['price']),
    currency: jsonStringOrNull(json['currency']) ?? 'UGX',
    supplier: jsonStringOrNull(json['supplier']) ?? '',
    location: jsonStringOrNull(json['location']) ?? '',
    recordedAt: jsonStringOrNull(json['recorded_at']) ?? '',
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
        itemsTracked: jsonIntOrNull(json['items_tracked']) ?? 0,
        pricesUpdatedToday: jsonIntOrNull(json['prices_updated_today']) ?? 0,
        averagePriceChange:
            (jsonDoubleOrNull(json['average_price_change']))?.toDouble() ?? 0.0,
        suppliersTracked: jsonIntOrNull(json['suppliers_tracked']) ?? 0,
        lowestPriceOpportunities:
            jsonIntOrNull(json['lowest_price_opportunities']) ?? 0,
        boqItemsWithUpdatedPrices:
            jsonIntOrNull(json['boq_items_with_updated_prices']) ?? 0,
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
        id: jsonInt(json['id']),
        itemName: jsonStringOrNull(json['item_name']) ?? '',
        brand: jsonStringOrNull(json['brand']) ?? '',
        category: jsonStringOrNull(json['category']) ?? '',
        specification: jsonStringOrNull(json['specification']) ?? '',
        unit: jsonStringOrNull(json['unit']) ?? '',
        price: jsonDouble(json['price']),
        currency: jsonStringOrNull(json['currency']) ?? 'UGX',
        supplier: jsonStringOrNull(json['supplier']) ?? '',
        location: jsonStringOrNull(json['location']) ?? '',
        sourceReference: jsonStringOrNull(json['source_reference']) ?? '',
        fetchedAt: '${json['fetched_at'] ?? ''}',
        similarityScore: jsonInt(json['similarity_score']),
        matchReasons: (jsonList(
          json['match_reasons'],
        )).map((e) => '$e').toList(),
        variancePercent: jsonDoubleOrNull(json['variance_percent']),
        priceHistory: PriceHistorySummary.fromJson(
          json['price_history'] is Map<String, dynamic>
              ? jsonMap(json['price_history'])
              : const {},
        ),
        rating: PriceRating.fromJson(
          json['rating'] is Map<String, dynamic>
              ? jsonMap(json['rating'])
              : const {},
        ),
        badges: (jsonList(json['badges'])).map((e) => '$e').toList(),
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
        records: jsonInt(json['records']),
        lowest: jsonDouble(json['lowest']),
        highest: jsonDouble(json['highest']),
        average: jsonDouble(json['average']),
        change: jsonDouble(json['change']),
        changePercent: jsonDouble(json['change_percent']),
        trend: jsonStringOrNull(json['trend']) ?? 'stable',
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
    overall: jsonInt(json['overall']),
    valueScore: jsonInt(json['value_score']),
    stabilityScore: jsonInt(json['stability_score']),
    freshnessScore: jsonInt(json['freshness_score']),
    supplierScore: jsonInt(json['supplier_score']),
    availabilityScore: jsonInt(json['availability_score']),
    factors: (json['factors'] is Map ? jsonMap(json['factors']) : const {}).map(
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
        boqItem: BoqItemMatchInfo.fromJson(jsonMap(json['boq_item'])),
        matches: (jsonList(json['matches']))
            .whereType<Map<String, dynamic>>()
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
        description: jsonStringOrNull(json['description']) ?? '',
        quantity: jsonStringOrNull(json['quantity']) ?? '',
        unit: jsonStringOrNull(json['unit']) ?? '',
        currentRate: jsonDouble(json['current_rate']),
        currency: jsonStringOrNull(json['currency']) ?? 'UGX',
        currentAmount: jsonDouble(json['current_amount']),
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
        data: (jsonList(json['data']))
            .whereType<Map<String, dynamic>>()
            .map(HardwarePrice.fromJson)
            .toList(),
        currentPage: jsonIntOrNull(json['current_page']) ?? 1,
        lastPage: jsonIntOrNull(json['last_page']) ?? 1,
        perPage: jsonIntOrNull(json['per_page']) ?? 20,
        total: jsonInt(json['total']),
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
        item: HardwarePrice.fromJson((jsonMapOrNull(json['item'])) ?? {}),
        summary: PriceHistorySummary.fromJson(
          (jsonMapOrNull(json['summary'])) ?? {},
        ),
        history: jsonMaps(
          jsonMap(json['history'])['data'],
        ).map(PriceHistory.fromJson).toList(),
      );
  final HardwarePrice item;
  final PriceHistorySummary summary;
  final List<PriceHistory> history;
}

class HardwarePriceCategory {
  const HardwarePriceCategory({required this.name, required this.count});
  factory HardwarePriceCategory.fromJson(Map<String, dynamic> json) =>
      HardwarePriceCategory(
        name: jsonStringOrNull(json['name']) ?? '',
        count: jsonInt(json['count']),
      );
  final String name;
  final int count;
}

class PriceComparisonResult {
  const PriceComparisonResult({required this.items, required this.summary});
  factory PriceComparisonResult.fromJson(Map<String, dynamic> json) =>
      PriceComparisonResult(
        items: (jsonList(json['items']))
            .whereType<Map<String, dynamic>>()
            .map(PriceComparisonItem.fromJson)
            .toList(),
        summary: jsonMap(json['summary']),
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
    id: jsonInt(json['id']),
    projectId: jsonInt(json['project_id']),
    name: jsonStringOrNull(json['name']) ?? '',
    code: jsonStringOrNull(json['code']) ?? '',
    description: jsonStringOrNull(json['description']) ?? '',
    currency: jsonStringOrNull(json['currency']) ?? 'UGX',
    status: jsonStringOrNull(json['status']) ?? 'draft',
    version: jsonStringOrNull(json['version']) ?? '1.0',
    metadata: jsonMap(json['metadata']),
    facilities: (jsonList(
      json['facilities'],
    )).whereType<Map<String, dynamic>>().map(Facility.fromJson).toList(),
    summaries: (jsonList(
      json['summaries'],
    )).whereType<Map<String, dynamic>>().map(BoqCostSummary.fromJson).toList(),
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
    id: jsonInt(json['id']),
    name: jsonStringOrNull(json['name']) ?? '',
    nameTranslations: json['name_translations'] != null
        ? (jsonMap(
            json['name_translations'],
          )).map((k, v) => MapEntry(k, jsonString(v)))
        : null,
    description: jsonStringOrNull(json['description']),
    displayOrder: jsonInt(json['display_order']),
    bills: (jsonList(
      json['bills'],
    )).whereType<Map<String, dynamic>>().map(Bill.fromJson).toList(),
    summaries: (jsonList(
      json['summaries'],
    )).whereType<Map<String, dynamic>>().map(BoqCostSummary.fromJson).toList(),
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
    id: jsonInt(json['id']),
    name: jsonStringOrNull(json['name']) ?? '',
    nameTranslations: json['name_translations'] != null
        ? (jsonMap(
            json['name_translations'],
          )).map((k, v) => MapEntry(k, jsonString(v)))
        : null,
    description: jsonStringOrNull(json['description']),
    displayOrder: jsonInt(json['display_order']),
    elements: (jsonList(
      json['elements'],
    )).whereType<Map<String, dynamic>>().map(Element.fromJson).toList(),
    summaries: (jsonList(
      json['summaries'],
    )).whereType<Map<String, dynamic>>().map(BoqCostSummary.fromJson).toList(),
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
    id: jsonInt(json['id']),
    name: jsonStringOrNull(json['name']) ?? '',
    nameTranslations: json['name_translations'] != null
        ? (jsonMap(
            json['name_translations'],
          )).map((k, v) => MapEntry(k, jsonString(v)))
        : null,
    description: jsonStringOrNull(json['description']),
    displayOrder: jsonInt(json['display_order']),
    subElements: (jsonList(
      json['sub_elements'],
    )).whereType<Map<String, dynamic>>().map(SubElement.fromJson).toList(),
    items: (jsonList(
      json['items'],
    )).whereType<Map<String, dynamic>>().map(BoqItemSummary.fromJson).toList(),
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
    id: jsonInt(json['id']),
    name: jsonStringOrNull(json['name']) ?? '',
    nameTranslations: json['name_translations'] != null
        ? (jsonMap(
            json['name_translations'],
          )).map((k, v) => MapEntry(k, jsonString(v)))
        : null,
    description: jsonStringOrNull(json['description']),
    displayOrder: jsonInt(json['display_order']),
    items: (jsonList(
      json['items'],
    )).whereType<Map<String, dynamic>>().map(BoqItemSummary.fromJson).toList(),
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
    id: jsonInt(json['id']),
    summaryType: jsonStringOrNull(json['summary_type']) ?? 'grand',
    name: jsonStringOrNull(json['name']),
    subtotal: jsonDouble(json['subtotal']),
    vat: jsonDouble(json['vat']),
    contingency: jsonDouble(json['contingency']),
    grandTotal: jsonDouble(json['grand_total']),
    metadata: jsonMapOrNull(json['metadata']),
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
    id: jsonInt(json['id']),
    code: jsonStringOrNull(json['item_code']) ?? '',
    description: jsonStringOrNull(json['description']) ?? '',
    quantity: '${json['quantity'] ?? 0}',
    unit: jsonStringOrNull(json['unit']) ?? '',
    amount: '${json['amount'] ?? 0}',
    currentRate:
        '${json['ai_suggested_rate'] ?? json['approved_rate'] ?? json['original_rate'] ?? 0}',
    aiRate: '${json['ai_suggested_rate'] ?? 0}',
    facilityId: jsonIntOrNull(json['facility_id']),
    billId: jsonIntOrNull(json['bill_id']),
    elementId: jsonIntOrNull(json['element_id']),
    subElementId: jsonIntOrNull(json['sub_element_id']),
    originalRate: jsonDoubleOrNull(json['original_rate']),
    approvedRate: jsonDoubleOrNull(json['approved_rate']),
    aiSuggestedRate: jsonDoubleOrNull(json['ai_suggested_rate']),
    currency: jsonStringOrNull(json['currency']) ?? 'UGX',
    workCategory: jsonStringOrNull(json['work_category']),
    materialCategory: jsonStringOrNull(json['material_category']),
    location: jsonStringOrNull(json['location']),
    pricingSource: jsonStringOrNull(json['pricing_source']),
    pricingDate: jsonStringOrNull(json['pricing_date']),
    aiConfidence: jsonDoubleOrNull(json['ai_confidence']),
    translationConfidence: jsonDoubleOrNull(json['translation_confidence']),
    notes: jsonStringOrNull(json['notes']),
    status: jsonStringOrNull(json['status']) ?? 'pending',
    translations: (jsonList(json['translations']))
        .whereType<Map<String, dynamic>>()
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
        id: jsonInt(json['id']),
        locale: jsonStringOrNull(json['locale']) ?? '',
        translatedDescription:
            jsonStringOrNull(json['translated_description']) ?? '',
        provider: jsonStringOrNull(json['provider']),
        confidence: (jsonDoubleOrNull(json['confidence']))?.toDouble(),
        status: jsonStringOrNull(json['status']) ?? 'pending_review',
        reviewedAt: jsonStringOrNull(json['reviewed_at']),
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

  /// ProxySubscriptionResource nests `beneficiary`, `payer`, `plan` and
  /// `transactions`; flat `*_id`/`*_name` keys are accepted as a fallback.
  factory ProxySubscription.fromJson(Map<String, dynamic> json) {
    final beneficiary = jsonMap(json['beneficiary']);
    final payer = jsonMap(json['payer']);
    final plan = jsonMap(json['plan']);
    final transactions = jsonMaps(json['transactions']);
    final latest = transactions.isEmpty ? null : transactions.last;
    return ProxySubscription(
      id: jsonInt(json['id']),
      beneficiaryId: jsonInt(beneficiary['id'] ?? json['beneficiary_id']),
      beneficiaryName: jsonString(
        beneficiary['name'] ?? json['beneficiary_name'],
      ),
      beneficiaryEmail: jsonString(
        beneficiary['email'] ?? json['beneficiary_email'],
      ),
      payerId: jsonInt(payer['id'] ?? json['payer_id']),
      payerName: jsonString(payer['name'] ?? json['payer_name']),
      planId: jsonInt(plan['id'] ?? json['plan_id']),
      planName: jsonString(plan['name'] ?? json['plan_name']),
      status: jsonString(json['status'], 'pending'),
      startDate: jsonString(json['start_date']),
      endDate: jsonString(json['end_date']),
      paymentStatus: jsonString(json['payment_status'], 'pending'),
      transactionId: jsonString(
        latest?['reference'] ?? latest?['id'] ?? json['transaction_id'],
      ),
      createdAt: jsonString(json['created_at']),
    );
  }

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
        id: jsonInt(json['id']),
        name: jsonStringOrNull(json['name']) ?? '',
        email: jsonStringOrNull(json['email']) ?? '',
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
    id: jsonInt(json['id']),
    boqId: jsonInt(json['boq_id']),
    status: jsonStringOrNull(json['status']) ?? 'pending',
    currentBatch: jsonInt(json['current_batch']),
    totalBatches: jsonInt(json['total_batches']),
    batchSize: jsonInt(json['batch_size']),
    totalItems: jsonInt(json['total_items']),
    processedItems: jsonInt(json['processed_items']),
    failedItems: jsonInt(json['failed_items']),
    lockedAt: jsonStringOrNull(json['locked_at']),
    lockedBy: jsonIntOrNull(json['locked_by']),
    startedAt: jsonStringOrNull(json['started_at']),
    completedAt: jsonStringOrNull(json['completed_at']),
    createdAt: jsonStringOrNull(json['created_at']) ?? '',
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
        jobId: jsonInt(json['job_id'] ?? json['id']),
        percentage: jsonDouble(
          json['progress_percentage'] ?? json['percentage'],
        ),
        currentBatch: jsonInt(json['current_batch']),
        totalBatches: jsonInt(json['total_batches']),
        itemsPricedThisBatch: jsonInt(json['items_priced_this_batch']),
        totalPriced: jsonInt(json['processed_items'] ?? json['total_priced']),
        remaining: jsonInt(json['remaining_items'] ?? json['remaining']),
        failedItems: jsonInt(json['failed_items']),
        status: jsonStringOrNull(json['status']) ?? 'unknown',
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
    id: jsonInt(json['id']),
    name: jsonStringOrNull(json['name']) ?? '',
    code: jsonString(json['key'] ?? json['code']),
    apiKeyEncrypted: jsonStringOrNull(json['api_key_encrypted']) ?? '',
    isDefault: jsonBoolOrNull(json['is_default']) ?? false,
    isEnabled: jsonBoolOrNull(json['is_enabled']) ?? true,
    config: jsonMap(json['config']),
    createdAt: jsonStringOrNull(json['created_at']) ?? '',
    updatedAt: jsonStringOrNull(json['updated_at']) ?? '',
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
        id: jsonInt(json['id']),
        name: jsonStringOrNull(json['name']) ?? '',
        code: jsonStringOrNull(json['code']) ?? '',
        description: jsonStringOrNull(json['description']),
        isActive: jsonBoolOrNull(json['is_active']) ?? true,
        createdAt: jsonStringOrNull(json['created_at']) ?? '',
        updatedAt: jsonStringOrNull(json['updated_at']) ?? '',
      );

  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
}

// Supplier and factory ratings.

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

String? _asTextOrNull(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

/// A hardware supplier or factory as the ratings API returns it.
class RatedSupplier {
  const RatedSupplier({
    required this.id,
    required this.name,
    required this.type,
    this.location,
    this.region,
    this.country,
    this.websiteUrl,
    this.rating = 0,
    this.ratingsCount = 0,
  });

  factory RatedSupplier.fromJson(Map<String, dynamic> json) => RatedSupplier(
    id: jsonInt(json['id']),
    name: '${json['name'] ?? ''}',
    type: '${json['type'] ?? 'supplier'}',
    location: _asTextOrNull(json['location']),
    region: _asTextOrNull(json['region']),
    country: _asTextOrNull(json['country']),
    websiteUrl: _asTextOrNull(json['website_url']),
    rating: jsonDouble(json['rating']),
    ratingsCount: jsonInt(json['ratings_count']),
  );

  final int id;
  final String name;

  /// `supplier` (hardware shop) or `factory`.
  final String type;
  final String? location;
  final String? region;
  final String? country;
  final String? websiteUrl;

  /// All-time average (each user's latest rating) and number of raters.
  final double rating;
  final int ratingsCount;

  bool get isFactory => type == 'factory';

  /// `Kampala, Central`: location and region, without repeats.
  String get place => {location, region}.whereType<String>().join(', ');
}

/// Average score in each area (1 to 5, null when nobody scored that area).
class RatingCriteria {
  const RatingCriteria({this.price, this.quality, this.delivery, this.service});

  factory RatingCriteria.fromJson(dynamic json) {
    final map = _asMap(json);
    return RatingCriteria(
      price: jsonDoubleOrNull(map['price']),
      quality: jsonDoubleOrNull(map['quality']),
      delivery: jsonDoubleOrNull(map['delivery']),
      service: jsonDoubleOrNull(map['service']),
    );
  }

  final double? price;
  final double? quality;
  final double? delivery;
  final double? service;

  /// Label and score of each area, in display order.
  List<(String, double?)> get entries => [
    ('Price', price),
    ('Quality', quality),
    ('Delivery', delivery),
    ('Service', service),
  ];

  bool get isEmpty => entries.every((e) => e.$2 == null);
}

/// One row of a top 10 ranking.
class SupplierLeaderboardEntry {
  const SupplierLeaderboardEntry({
    required this.rank,
    required this.supplier,
    required this.average,
    required this.score,
    required this.count,
    required this.criteria,
  });

  factory SupplierLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      SupplierLeaderboardEntry(
        rank: jsonInt(json['rank']),
        supplier: RatedSupplier.fromJson(_asMap(json['supplier'])),
        average: jsonDouble(json['average']),
        score: jsonDouble(json['score']),
        count: jsonInt(json['count']),
        criteria: RatingCriteria.fromJson(json['criteria']),
      );

  final int rank;
  final RatedSupplier supplier;

  /// Average stars in the period.
  final double average;

  /// Weighted score used for the order.
  final double score;

  /// Ratings in the period.
  final int count;
  final RatingCriteria criteria;
}

class SupplierLeaderboard {
  const SupplierLeaderboard({
    required this.period,
    required this.periodLabel,
    required this.type,
    required this.items,
  });

  factory SupplierLeaderboard.fromJson(Map<String, dynamic> json) =>
      SupplierLeaderboard(
        period: '${json['period'] ?? 'month'}',
        periodLabel: '${json['period_label'] ?? ''}',
        type: '${json['type'] ?? 'supplier'}',
        items: jsonMaps(
          json['items'],
        ).map(SupplierLeaderboardEntry.fromJson).toList(),
      );

  final String period;
  final String periodLabel;
  final String type;
  final List<SupplierLeaderboardEntry> items;
}

/// Number of ratings with [stars] stars.
class RatingBucket {
  const RatingBucket({required this.stars, required this.count});

  factory RatingBucket.fromJson(Map<String, dynamic> json) => RatingBucket(
    stars: jsonInt(json['stars']),
    count: jsonInt(json['count']),
  );

  final int stars;
  final int count;

  /// 5 down to 1, filling in missing star values with 0.
  static List<RatingBucket> listFrom(dynamic json) {
    final counts = {
      for (final row in jsonMaps(json).map(RatingBucket.fromJson))
        row.stars: row.count,
    };
    return [
      for (var stars = 5; stars >= 1; stars--)
        RatingBucket(stars: stars, count: counts[stars] ?? 0),
    ];
  }
}

/// One month of a ratings trend.
class RatingTrendPoint {
  const RatingTrendPoint({
    required this.period,
    required this.label,
    required this.count,
    this.average,
  });

  factory RatingTrendPoint.fromJson(Map<String, dynamic> json) =>
      RatingTrendPoint(
        period: '${json['period'] ?? ''}',
        label: '${json['label'] ?? json['period'] ?? ''}',
        average: jsonDoubleOrNull(json['average']),
        count: jsonInt(json['count']),
      );

  /// `YYYY-MM`.
  final String period;

  /// `Sep 2026`.
  final String label;
  final double? average;
  final int count;

  static List<RatingTrendPoint> listFrom(dynamic json) =>
      jsonMaps(json).map(RatingTrendPoint.fromJson).toList();
}

class RatingTypeStat {
  const RatingTypeStat({this.count = 0, this.average});

  factory RatingTypeStat.fromJson(dynamic json) {
    final map = _asMap(json);
    return RatingTypeStat(
      count: jsonInt(map['count']),
      average: jsonDoubleOrNull(map['average']),
    );
  }

  final int count;
  final double? average;
}

/// Figures for the charts on the Top Suppliers screen.
class SupplierRatingSummary {
  const SupplierRatingSummary({
    required this.period,
    required this.periodLabel,
    required this.total,
    required this.suppliers,
    required this.distribution,
    required this.hardware,
    required this.factories,
    required this.criteria,
    required this.trend,
    required this.hardwareTrend,
    required this.factoryTrend,
    this.average,
  });

  factory SupplierRatingSummary.fromJson(Map<String, dynamic> json) {
    final byType = _asMap(json['by_type']);
    final trendByType = _asMap(json['trend_by_type']);
    return SupplierRatingSummary(
      period: '${json['period'] ?? 'month'}',
      periodLabel: '${json['period_label'] ?? ''}',
      total: jsonInt(json['total']),
      suppliers: jsonInt(json['suppliers']),
      average: jsonDoubleOrNull(json['average']),
      distribution: RatingBucket.listFrom(json['distribution']),
      hardware: RatingTypeStat.fromJson(byType['supplier']),
      factories: RatingTypeStat.fromJson(byType['factory']),
      criteria: RatingCriteria.fromJson(json['criteria']),
      trend: RatingTrendPoint.listFrom(json['trend']),
      hardwareTrend: RatingTrendPoint.listFrom(trendByType['supplier']),
      factoryTrend: RatingTrendPoint.listFrom(trendByType['factory']),
    );
  }

  final String period;
  final String periodLabel;

  /// Ratings in the period.
  final int total;

  /// Suppliers and factories rated in the period.
  final int suppliers;
  final double? average;

  /// 5 stars down to 1 star.
  final List<RatingBucket> distribution;
  final RatingTypeStat hardware;
  final RatingTypeStat factories;
  final RatingCriteria criteria;

  /// Last 12 months, oldest first.
  final List<RatingTrendPoint> trend;
  final List<RatingTrendPoint> hardwareTrend;
  final List<RatingTrendPoint> factoryTrend;
}

/// A rating shown in a supplier's recent reviews.
class SupplierReview {
  const SupplierReview({
    required this.id,
    required this.rating,
    this.comment,
    this.author,
    this.isHidden = false,
    this.ratedAt,
  });

  factory SupplierReview.fromJson(Map<String, dynamic> json) => SupplierReview(
    id: jsonInt(json['id']),
    rating: jsonInt(json['rating']),
    comment: _asTextOrNull(json['comment']),
    author: _asTextOrNull(json['author']),
    isHidden: json['is_hidden'] == true || json['is_hidden'] == 1,
    ratedAt: jsonStringOrNull(json['rated_at']),
  );

  final int id;
  final int rating;
  final String? comment;

  /// Only sent to administrators.
  final String? author;
  final bool isHidden;
  final String? ratedAt;
}

/// A rating the user gave (their rating this month, or one of "My ratings").
class SupplierRatingEntry {
  const SupplierRatingEntry({
    required this.rating,
    this.id,
    this.supplierId,
    this.priceRating,
    this.qualityRating,
    this.deliveryRating,
    this.serviceRating,
    this.comment,
    this.period,
    this.ratedAt,
    this.supplier,
  });

  factory SupplierRatingEntry.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'];
    return SupplierRatingEntry(
      id: jsonIntOrNull(json['id']),
      supplierId: jsonIntOrNull(json['supplier_id']),
      rating: jsonInt(json['rating']),
      priceRating: jsonIntOrNull(json['price_rating']),
      qualityRating: jsonIntOrNull(json['quality_rating']),
      deliveryRating: jsonIntOrNull(json['delivery_rating']),
      serviceRating: jsonIntOrNull(json['service_rating']),
      comment: _asTextOrNull(json['comment']),
      period: jsonStringOrNull(json['period']),
      ratedAt: jsonStringOrNull(json['rated_at']),
      supplier: supplier is Map<String, dynamic>
          ? RatedSupplier.fromJson(supplier)
          : null,
    );
  }

  final int? id;
  final int? supplierId;
  final int rating;
  final int? priceRating;
  final int? qualityRating;
  final int? deliveryRating;
  final int? serviceRating;
  final String? comment;

  /// Month rated, `YYYY-MM`.
  final String? period;
  final String? ratedAt;
  final RatedSupplier? supplier;
}

/// One supplier's performance: rank, figures, reviews and the user's rating.
class SupplierPerformance {
  const SupplierPerformance({
    required this.supplier,
    required this.period,
    required this.periodTotal,
    required this.total,
    required this.distribution,
    required this.criteria,
    required this.trend,
    required this.reviews,
    this.rank,
    this.rankOf,
    this.periodAverage,
    this.average,
    this.mine,
  });

  factory SupplierPerformance.fromJson(Map<String, dynamic> json) {
    final rank = json['rank'];
    final mine = json['mine'];
    return SupplierPerformance(
      supplier: RatedSupplier.fromJson(_asMap(json['supplier'])),
      period: '${json['period'] ?? 'month'}',
      rank: rank is Map ? jsonIntOrNull(rank['rank']) : null,
      rankOf: rank is Map ? jsonIntOrNull(rank['of']) : null,
      periodTotal: jsonInt(json['period_total']),
      periodAverage: jsonDoubleOrNull(json['period_average']),
      total: jsonInt(json['total']),
      average: jsonDoubleOrNull(json['average']),
      distribution: RatingBucket.listFrom(json['distribution']),
      criteria: RatingCriteria.fromJson(json['criteria']),
      trend: RatingTrendPoint.listFrom(json['trend']),
      reviews: jsonMaps(json['reviews']).map(SupplierReview.fromJson).toList(),
      mine: mine is Map<String, dynamic>
          ? SupplierRatingEntry.fromJson(mine)
          : null,
    );
  }

  final RatedSupplier supplier;
  final String period;

  /// Position among suppliers of the same type in the period (null = not
  /// rated in the period) and how many were ranked.
  final int? rank;
  final int? rankOf;
  final int periodTotal;
  final double? periodAverage;

  /// All-time figures.
  final int total;
  final double? average;
  final List<RatingBucket> distribution;
  final RatingCriteria criteria;
  final List<RatingTrendPoint> trend;
  final List<SupplierReview> reviews;

  /// The user's rating this month (pre-fills "Rate again").
  final SupplierRatingEntry? mine;
}
