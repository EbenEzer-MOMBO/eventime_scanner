import 'dart:convert';
import '../config/api_config.dart';
import '../config/branding.dart';
import 'scanner_http.dart';

class BrandingAssets {
  final String logoDark;
  final String logoLight;

  const BrandingAssets({
    required this.logoDark,
    required this.logoLight,
  });
}

class BrandingService {
  /// Charge les logos depuis l'API ; fallback si indisponible.
  static Future<BrandingAssets> fetch() async {
    try {
      final response = await ScannerHttp.get(
        ApiConfig.branding,
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          final dark = data['logo_dark']?.toString();
          final light = data['logo_light']?.toString();
          return BrandingAssets(
            logoDark:
                (dark != null && dark.isNotEmpty)
                    ? dark
                    : Branding.fallbackLogoDark,
            logoLight:
                (light != null && light.isNotEmpty)
                    ? light
                    : Branding.fallbackLogoLight,
          );
        }
      }
    } catch (_) {}

    return const BrandingAssets(
      logoDark: Branding.fallbackLogoDark,
      logoLight: Branding.fallbackLogoLight,
    );
  }
}
