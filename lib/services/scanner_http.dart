import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Client dart:io (pas Cronet) pour que [HttpOverrides] IPv4 s'applique.
class ScannerHttp {
  ScannerHttp._();

  static http.Client? _client;

  static http.Client get client {
    return _client ??= IOClient(HttpClient());
  }

  static Future<http.Response> postJson(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) {
    return client
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...?headers,
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);
  }

  static Future<http.Response> get(
    String url, {
    Duration timeout = const Duration(seconds: 15),
  }) {
    return client.get(Uri.parse(url)).timeout(timeout);
  }
}
