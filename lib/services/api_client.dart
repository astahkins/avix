import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:8000';

  final http.Client _client;

  ApiClient({
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, [
    String? token,
  ]) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(
      _uri(endpoint),
      headers: headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> get(
    String endpoint,
    String token,
  ) async {
    final response = await _client.get(
      _uri(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  Uri _uri(String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';

    return Uri.parse('$baseUrl$normalizedEndpoint');
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decodedBody = <String, dynamic>{};

    if (response.body.isNotEmpty) {
      try {
        decodedBody = jsonDecode(response.body);
      } catch (_) {
        decodedBody = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    if (decodedBody is Map<String, dynamic> &&
        decodedBody.containsKey('detail')) {
      throw ApiException(decodedBody['detail'].toString());
    }

    throw ApiException(
      'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}',
    );
  }
}

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}
