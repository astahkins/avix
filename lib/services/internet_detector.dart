import 'dart:async';

import 'package:http/http.dart' as http;

class InternetDetector {
  final Uri pingUri;
  final Duration timeout;
  final http.Client _client;

  InternetDetector({
    String pingUrl = 'https://google.com',
    this.timeout = const Duration(seconds: 3),
    http.Client? client,
  })  : pingUri = Uri.parse(pingUrl),
        _client = client ?? http.Client();

  Future<bool> hasInternet() async {
    try {
      await _client.get(pingUri).timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
