import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/version_check_service.dart';

class ForceUpdateDialog extends StatelessWidget {
  final AppVersionInfo versionInfo;

  const ForceUpdateDialog({super.key, required this.versionInfo});

  Future<void> _openDownload() async {
    final uri = Uri.parse(versionInfo.downloadUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Mise à jour requise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Une nouvelle version (${versionInfo.versionName}) est disponible. '
              'Vous devez mettre à jour l\'application pour continuer.',
            ),
            if (versionInfo.changelog != null &&
                versionInfo.changelog!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Nouveautés',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(versionInfo.changelog!),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(125, 184, 78, 1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _openDownload,
              child: const Text(
                'Télécharger la mise à jour',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue bloquant (non dismissible).
  static Future<void> show(BuildContext context, AppVersionInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ForceUpdateDialog(versionInfo: info),
    );
  }
}
