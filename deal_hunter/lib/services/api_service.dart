import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> get _authHeaders {
    final token = StorageService.getToken();
    return {
      ..._baseHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    bool auth = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: queryParams);
    final response =
        await http.get(uri, headers: auth ? _authHeaders : _baseHeaders);
    return _handle(response);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
    bool formData = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final http.Response response;

    if (formData) {
      final formHeaders = {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (auth && StorageService.getToken() != null)
          'Authorization': 'Bearer ${StorageService.getToken()}',
      };
      response = await http.post(uri,
          headers: formHeaders,
          body: body?.map((k, v) => MapEntry(k, v.toString())));
    } else {
      response = await http.post(
        uri,
        headers: auth ? _authHeaders : _baseHeaders,
        body: body != null ? jsonEncode(body) : null,
      );
    }
    return _handle(response);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.patch(
      uri,
      headers: auth ? _authHeaders : _baseHeaders,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Future<dynamic> delete(String path, {bool auth = false}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response =
        await http.delete(uri, headers: auth ? _authHeaders : _baseHeaders);
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    // Token expired or invalid — clear it so the app redirects to login
    if (response.statusCode == 401) {
      StorageService.clearToken();
      throw ApiException(401, 'Session expired. Please sign in again.');
    }

    String message = 'Something went wrong.';
    try {
      final err = jsonDecode(response.body);
      message = (err['detail'] as String?) ?? message;
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }
}
