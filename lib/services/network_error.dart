import 'dart:async';
import 'dart:io';

String networkErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Connexion trop lente. Réessayez.';
  }
  if (error is HandshakeException) {
    return 'HTTPS refusé (certificat). Vérifiez SSL sur eventime.ga.';
  }
  if (error is SocketException) {
    final detail = error.osError?.message ?? error.message;
    if (detail.trim().isEmpty) {
      return 'Impossible de joindre le serveur';
    }
    return 'Réseau injoignable : $detail';
  }
  return 'Impossible de joindre le serveur';
}
