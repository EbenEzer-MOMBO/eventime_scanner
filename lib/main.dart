import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Login/login.dart';
import 'Events/page_acceuil.dart';
import 'services/version_check_service.dart';
import 'widgets/force_update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final idAgent = prefs.getString('id_agent');
  final nomAgent = prefs.getString('nom_agent');
  final matriculeAgent = prefs.getString('matricule_agent');
  final idOrg = prefs.getString('id_org');

  runApp(
    MyApp(
      isLoggedIn: idAgent != null,
      id_agent: idAgent,
      nom_agent: nomAgent,
      matricule_agent: matriculeAgent,
      id_org: idOrg,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? id_agent;
  final String? nom_agent;
  final String? matricule_agent;
  final String? id_org;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.id_agent,
    this.nom_agent,
    this.matricule_agent,
    this.id_org,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventime scan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AppBootstrap(
        isLoggedIn: isLoggedIn,
        id_agent: id_agent,
        nom_agent: nom_agent,
        matricule_agent: matricule_agent,
        id_org: id_org,
      ),
    );
  }
}

/// Gate de démarrage : vérifie la version avant d'ouvrir login/home.
class AppBootstrap extends StatefulWidget {
  final bool isLoggedIn;
  final String? id_agent;
  final String? nom_agent;
  final String? matricule_agent;
  final String? id_org;

  const AppBootstrap({
    super.key,
    required this.isLoggedIn,
    this.id_agent,
    this.nom_agent,
    this.matricule_agent,
    this.id_org,
  });

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _checking = true;
  bool _blocked = false;
  AppVersionInfo? _remoteVersion;

  @override
  void initState() {
    super.initState();
    _runVersionCheck();
  }

  Future<void> _runVersionCheck() async {
    final result = await VersionCheckService.check();
    if (!mounted) return;

    if (result.updateRequired && result.remote != null) {
      setState(() {
        _checking = false;
        _blocked = true;
        _remoteVersion = result.remote;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _remoteVersion == null) return;
        ForceUpdateDialog.show(context, _remoteVersion!);
      });
      return;
    }

    setState(() {
      _checking = false;
      _blocked = false;
    });
  }

  Widget _homeScreen() {
    if (widget.isLoggedIn) {
      return page_acceuil(
        id_organisateur: widget.id_org!,
        nom_agent: widget.nom_agent!,
        matricule_agent: widget.matricule_agent!,
        id_agent: widget.id_agent!,
      );
    }
    return const Connexion();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color.fromRGBO(125, 184, 78, 1),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_blocked) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(125, 184, 78, 1),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Mise à jour requise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _remoteVersion != null
                      ? 'Version ${_remoteVersion!.versionName} disponible'
                      : 'Une nouvelle version est disponible',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color.fromRGBO(125, 184, 78, 1),
                  ),
                  onPressed: () {
                    if (_remoteVersion != null) {
                      ForceUpdateDialog.show(context, _remoteVersion!);
                    }
                  },
                  child: const Text('Voir la mise à jour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _homeScreen();
  }
}
