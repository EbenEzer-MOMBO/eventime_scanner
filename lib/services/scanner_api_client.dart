import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';

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
  }) async {
    final response = await http
        .post(
          Uri.parse(url),
          headers: await authHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      await clearSession(context: context);
    }

    return response;
  }

  static Future<void> clearSession({BuildContext? context}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context != null && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Connexion()),
        (route) => false,
      );
    }
  }
}
