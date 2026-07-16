import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Login/login.dart';
import 'Events/page_acceuil.dart';

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
      home:
          isLoggedIn
              ? page_acceuil(
                id_organisateur: id_org!,
                nom_agent: nom_agent!,
                matricule_agent: matricule_agent!,
                id_agent: id_agent!,
              )
              : const Connexion(),
    );
  }
}
