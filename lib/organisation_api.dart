part of 'api_client.dart';

/// Resource collections use Laravel's top-level data/meta envelope.
class ResourcePage {
  ResourcePage.fromJson(Map<String, dynamic> json)
    : items = jsonMaps(json['data']),
      page = jsonInt(jsonMap(json['meta'])['current_page']).clamp(1, 100000),
      lastPage = jsonInt(jsonMap(json['meta'])['last_page']).clamp(1, 100000),
      totals = jsonMaps(json['totals']);

  final List<Map<String, dynamic>> items;
  final int page;
  final int lastPage;
  final List<Map<String, dynamic>> totals;
  bool get hasNext => page < lastPage;
}

extension OrganisationApi on ApiClient {
  Future<Map<String, dynamic>> _resourceRequest(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    final request = http.Request(
      method,
      Uri.parse('${ApiClient.baseUrl}/$path'),
    );
    request.headers.addAll(await _headers());
    if (data != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(data);
    }
    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    if (response.statusCode == 204) return {};
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiError(response, body);
    }
    return body;
  }

  Future<ResourcePage> expenses({
    int page = 1,
    String search = '',
    int? projectId,
  }) async => ResourcePage.fromJson(
    await _resourceRequest(
      'GET',
      'expenses?page=$page&search=${Uri.encodeQueryComponent(search.trim())}${projectId == null ? '' : '&project_id=$projectId'}',
    ),
  );

  Future<List<Map<String, dynamic>>> expenseProjects() async {
    final projects = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final body = await _resourceRequest(
        'GET',
        'expenses/projects?page=$page',
      );
      projects.addAll(jsonMaps(body['data']));
      final lastPage = jsonInt(jsonMap(body['meta'])['last_page']);
      if (page >= lastPage.clamp(1, 100000)) break;
      page++;
    }
    return projects;
  }

  Future<Map<String, dynamic>> expense(int id) async =>
      jsonMap((await _resourceRequest('GET', 'expenses/$id'))['data']);

  Future<Map<String, dynamic>> saveExpense(
    Map<String, dynamic> data, {
    int? id,
  }) async => jsonMap(
    (await _resourceRequest(
      id == null ? 'POST' : 'PUT',
      id == null ? 'expenses' : 'expenses/$id',
      data,
    ))['data'],
  );

  Future<void> uploadExpenseReceipt(
    int expenseId,
    Uint8List bytes,
    String fileName,
  ) async {
    if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
      throw const ApiException('Choose a receipt smaller than 20 MB.');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/expenses/$expenseId/receipts'),
    );
    request.headers.addAll(await _headers());
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: ApiClient.standardUploadName(fileName),
      ),
    );
    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    final body = _decode(response);
    if (response.statusCode != 201) throw _apiError(response, body);
  }

  /// Download by ID on our API origin; never send credentials to a resource URL.
  Future<Uint8List> downloadExpenseReceipt(int id) async {
    final response = await _httpClient.get(
      Uri.parse('${ApiClient.baseUrl}/expense-receipts/$id/download'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw _apiError(response, _decode(response));
    }
    return response.bodyBytes;
  }

  Future<ResourcePage> invitations({int page = 1}) async =>
      ResourcePage.fromJson(
        await _resourceRequest('GET', 'invitations?page=$page'),
      );

  Future<List<Map<String, dynamic>>> invitationRoles() async =>
      jsonMaps((await _resourceRequest('GET', 'invitations/roles'))['data']);

  /// The raw single-use token is returned only on creation.
  Future<String> createInvitation(Map<String, dynamic> data) async =>
      jsonString(
        (await _resourceRequest('POST', 'invitations', data))['token'],
      );

  Future<void> updateInvitation(int id, Map<String, dynamic> data) async {
    await _resourceRequest('PUT', 'invitations/$id', data);
  }

  Future<void> revokeInvitation(int id) async {
    await _resourceRequest('DELETE', 'invitations/$id');
  }

  Future<void> acceptInvitation(String token) async {
    await _resourceRequest('POST', 'invitations/accept', {
      'token': token.trim(),
    });
  }

  Future<Map<String, dynamic>> extractExpenseReceipt(
    Uint8List bytes,
    String fileName,
  ) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const ApiException('Choose a receipt no larger than 10 MB.');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/expenses/extract'),
    );
    request.headers.addAll(await _headers());
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: ApiClient.standardUploadName(fileName),
      ),
    );
    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    final body = _decode(response);
    if (response.statusCode != 200) throw _apiError(response, body);
    return jsonMap(body['data']);
  }

  Future<ResourcePage> projectAssignments({int page = 1}) async =>
      ResourcePage.fromJson(
        await _resourceRequest('GET', 'project-assignments?page=$page'),
      );

  Future<Map<String, dynamic>> assignmentOptions() async => jsonMap(
    (await _resourceRequest('GET', 'project-assignments/options'))['data'],
  );

  Future<void> saveProjectAssignment(
    int projectId,
    int userId,
    String role,
  ) async {
    await _resourceRequest('POST', 'project-assignments', {
      'project_id': projectId,
      'user_id': userId,
      'role': role,
    });
  }

  Future<void> revokeProjectAssignment(int id) async {
    await _resourceRequest('DELETE', 'project-assignments/$id');
  }

  Future<ResourcePage> faqs({int page = 1, String search = ''}) async =>
      ResourcePage.fromJson(
        await _resourceRequest(
          'GET',
          'faqs?page=$page&search=${Uri.encodeQueryComponent(search.trim())}',
        ),
      );

  Future<ResourcePage> adminFaqs({int page = 1}) async => ResourcePage.fromJson(
    await _resourceRequest('GET', 'admin/faqs?page=$page'),
  );

  Future<void> saveFaq(Map<String, dynamic> data, {int? id}) async {
    await _resourceRequest(
      id == null ? 'POST' : 'PUT',
      id == null ? 'admin/faqs' : 'admin/faqs/$id',
      data,
    );
  }
}
