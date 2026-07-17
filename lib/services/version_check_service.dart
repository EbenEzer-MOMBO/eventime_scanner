import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../config/api_config.dart';

class AppVersionInfo {
  final String versionName;
  final int versionCode;
  final String? changelog;
  final String downloadUrl;

  const AppVersionInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    this.changelog,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      versionName: json['version_name']?.toString() ?? '',
      versionCode: int.tryParse(json['version_code']?.toString() ?? '') ?? 0,
      changelog: json['changelog']?.toString(),
      downloadUrl: json['download_url']?.toString() ?? '',
    );
  }
}

class VersionCheckResult {
  final bool updateRequired;
  final AppVersionInfo? remote;
  final int localBuildNumber;

  const VersionCheckResult({
    required this.updateRequired,
    required this.localBuildNumber,
    this.remote,
  });
}

class VersionCheckService {
  /// Si l'API / le plugin est indisponible : pas de blocage.
  static Future<VersionCheckResult> check() async {
    final localBuild = await _localBuildNumber();

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.appVersion))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return VersionCheckResult(
          updateRequired: false,
          localBuildNumber: localBuild,
        );
      }

      final body = json.decode(response.body);
      if (body['success'] != true || body['data'] == null) {
        return VersionCheckResult(
          updateRequired: false,
          localBuildNumber: localBuild,
        );
      }

      final remote = AppVersionInfo.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );

      final outdated =
          localBuild > 0 &&
          remote.versionCode > 0 &&
          localBuild < remote.versionCode;

      return VersionCheckResult(
        updateRequired: outdated,
        localBuildNumber: localBuild,
        remote: remote,
      );
    } catch (_) {
      return VersionCheckResult(
        updateRequired: false,
        localBuildNumber: localBuild,
      );
    }
  }

  static Future<int> _localBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return int.tryParse(packageInfo.buildNumber) ?? 0;
    } on MissingPluginException {
      // Hot reload après ajout du plugin : rebuild complet requis.
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
