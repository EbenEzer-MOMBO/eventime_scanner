import 'dart:io';

/// Timeouts HTTP. Pas de [HttpClient.connectionFactory] : il doit renvoyer un
/// [SecureSocket] en HTTPS, sinon nginx répond
/// « The plain HTTP request was sent to HTTPS port ».
class PreferIpv4HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout = const Duration(seconds: 12);
    client.idleTimeout = const Duration(seconds: 15);
    client.userAgent = 'EventimeScan/1.1.1';
    return client;
  }
}
