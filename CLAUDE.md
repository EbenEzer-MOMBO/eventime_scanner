# Eventime Scanner — application mobile Flutter

Application Android/iOS des agents de contrôle : connexion par matricule, liste des événements assignés, scan des billets QR, **fonctionnement hors-ligne** avec synchronisation différée. Carte de l'écosystème et contrats inter-repos : `../CLAUDE.md`.

## Stack
- Flutter / Dart `^3.7.2` ; `mobile_scanner`, `http`, `shared_preferences`, `package_info_plus`.
- Commandes : `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --release`.
- Version dans `pubspec.yaml` (`version: x.y.z+build`) : à incrémenter à chaque release.

## Organisation
- `lib/Login/`, `lib/Events/`, `lib/Scanner/` : écrans.
- `lib/services/` : `scanner_api_client.dart` / `scanner_http.dart` (appels API + Bearer), `offline_storage_service.dart` / `offline_sync_service.dart` / `offline_sync_ack.dart` (file de scans hors-ligne), `version_check_service.dart` (force update), `prefer_ipv4_http_overrides.dart` (contournement IPv6, cf. `DEBUG_SCANNER_API_IPV6.md` côté Eventime).
- `lib/config/` : `api_config.dart` (`https://eventime.ga/api/scanner`), `branding.dart`, `media_urls.dart`.

## Dépendance à l'API Eventime (`../eventime_repo`)
- Source de vérité : `routes/api/masters.php` (préfixe `scanner`) + `MobileAppController.php`, docs `README_SCANNER_API_V2.md`, `README_SCANNER_OFFLINE.md`, `README_SCANNER_FORCE_UPDATE.md`.
- ⚠️ `API_SCAN_TICKET.md` à la racine de ce repo décrit l'ancien endpoint `/api/mobile/scan-ticket` : **obsolète**, ne pas s'y fier.
- Token Sanctum en Bearer ; sur 401 → `clearSession()` et retour au login.
- **Les APK installés ne se mettent pas à jour tout seuls** : toute rupture de contrat côté Laravel doit être rétrocompatible, sinon publier une nouvelle version et la déclarer obligatoire dans l'admin Eventime (`scanner_app_versions`).

## Release
1. Incrémenter `version` dans `pubspec.yaml`.
2. `flutter build apk --release`.
3. Uploader l'APK et déclarer la version dans l'admin Eventime (`/admin/scanner-versions`), en cochant « obligatoire » si le contrat API a changé.

## Parité avec le scanner web
Pendant web : `../eventime_scan_web`. Toute évolution fonctionnelle ici doit être évaluée pour la PWA (mêmes codes d'erreur, mêmes messages).

## Conventions
- Français (UI, commits, docs). Branche `master`, remote GitHub `origin`.
