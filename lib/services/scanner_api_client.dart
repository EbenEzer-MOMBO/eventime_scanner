import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';
import 'offline_storage_service.dart';
import 'scanner_http.dart';

/// Client HTTP scanner avec Bearer Sanctum + gestion 401.
class ScannerApiClient {
  static Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(
    String url,
    Map<String, dynamic> body, {
    BuildContext? context,
    Duration timeout = const Duration(seconds: 15),
    bool handleUnauthorized = true,
  }) async {
    final response = await ScannerHttp.postJson(
      url,
      body,
      headers: await authHeaders(),
      timeout: timeout,
    );

    if (handleUnauthorized && response.statusCode == 401) {
      await clearSession(context: context);
    }

    return response;
  }

  static Future<void> clearSession({BuildContext? context}) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in List<String>.from(prefs.getKeys())) {
      if (OfflineStorageService.isOfflineKey(key)) {
        continue;
      }
      await prefs.remove(key);
    }

    if (context != null && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Connexion()),
        (route) => false,
      );
    }
  }
}
