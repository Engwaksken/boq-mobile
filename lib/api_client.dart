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
