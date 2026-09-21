import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_store.dart';
import 'api_config.dart' as config;
import 'api_exception.dart';

class ApiClient {
  ApiClient({String? apiBaseUrl, TokenStore? tokenStore, http.Client? client})
    : baseUrl = apiBaseUrl ?? config.baseUrl,
      tokenStore = tokenStore ?? TokenStore(),
      client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokenStore;
  final http.Client client;

  Future<dynamic> get(String path) => _request('GET', path);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _request('POST', path, body);

  Future<dynamic> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = await tokenStore.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = method == 'GET'
          ? await client.get(uri, headers: headers)
          : await client.post(
              uri,
              headers: headers,
              body: jsonEncode(body ?? <String, dynamic>{}),
            );
      final decoded = _decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw ApiException(response.statusCode, _message(decoded));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(0, 'Unable to connect to the server');
    } on http.ClientException {
      throw const ApiException(0, 'Unable to connect to the server');
    } on FormatException {
      throw const ApiException(0, 'Unable to read the server response');
    }
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(body);
  }

  String _message(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.join(', ');
    }
    return 'Request failed';
  }

  void dispose() => client.close();
}
