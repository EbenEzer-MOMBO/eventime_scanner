import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Events/page_acceuil.dart';
import '../config/api_config.dart';
import '../config/branding.dart';
import '../services/branding_service.dart';

class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

TextEditingController email = TextEditingController();
TextEditingController passe = TextEditingController();

class _ConnexionState extends State<Connexion> {
  bool chargement = false;
  String logoDark = Branding.fallbackLogoDark;
  String logoLight = Branding.fallbackLogoLight;

  @override
  void initState() {
    super.initState();
    _loadBranding();
    _checkSavedCredentials();
  }

  Future<void> _loadBranding() async {
    final assets = await BrandingService.fetch();
    if (!mounted) return;
    setState(() {
      logoDark = assets.logoDark;
      logoLight = assets.logoLight;
    });
  }

  Future<void> _checkSavedCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');

    if (savedEmail != null && savedPassword != null) {
      email.text = savedEmail;
      passe.text = savedPassword;
      _autoLogin(savedEmail, savedPassword);
    }
  }

  Future<void> _autoLogin(String email, String password) async {
    setState(() {
      chargement = true;
    });
    await connexion(email, password);
    setState(() {
      chargement = false;
    });
  }

  Future<void> _saveCredentials(String email, String password) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('saved_email', email);
    prefs.setString('saved_password', password);
  }

  snackbar(text) {
    final snackBar = SnackBar(
      backgroundColor: Colors.redAccent,
      content: Text(text, style: const TextStyle(color: Colors.white)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> connexion(String email, String password) async {
    setState(() {
      chargement = true;
    });

    try {
      if (email == '' || password == '') {
        snackbar('Les champs sont vide');
        setState(() {
          chargement = false;
        });
        return;
      }

      final uri = Uri.parse(ApiConfig.login);

      var reponse = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'matricule': email, 'code': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (reponse.statusCode == 200) {
        final data = json.decode(reponse.body);
        if (data['success'] == true && data['data'] != null) {
          final agent = data['data'] as Map<String, dynamic>;
          final idAgent = agent['id_agent']?.toString() ?? '';
          final matriculeAgent = agent['matricule']?.toString() ?? '';
          final idOrg = agent['id_org']?.toString() ?? '';
          final nomAgent = agent['nom_agent']?.toString() ?? '';

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('id_agent', idAgent);
          prefs.setString('matricule_agent', matriculeAgent);
          prefs.setString('id_org', idOrg);
          prefs.setString('nom_agent', nomAgent);

          await _saveCredentials(email, password);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => page_acceuil(
                    id_organisateur: idOrg,
                    nom_agent: nomAgent,
                    matricule_agent: matriculeAgent,
                    id_agent: idAgent,
                  ),
            ),
          );
        } else {
          snackbar(data['message']?.toString() ?? 'Compte inconnu');
        }
      } else if (reponse.statusCode == 401) {
        snackbar('Compte inconnu');
      } else {
        snackbar('Erreur de connexion');
      }
      setState(() {
        chargement = false;
      });
    } catch (e) {
      snackbar('Erreur de connexion: vérifiez votre connexion internet');
      setState(() {
        chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(125, 184, 78, 1),
            ),
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width / 1.1,
                height: MediaQuery.of(context).size.height / 2,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.3,
                      height: 56,
                      child: Image.network(
                        logoDark,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color.fromRGBO(125, 184, 78, 1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 19),
                        child: TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'votre matricule',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color.fromRGBO(125, 184, 78, 1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 19),
                        child: TextField(
                          controller: passe,
                          obscureText: true,
                          keyboardType: TextInputType.visiblePassword,
                          decoration: const InputDecoration(
                            hintText: 'votre mot de passe',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        connexion(email.text, passe.text);
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width / 1.3,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(125, 184, 78, 1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color.fromRGBO(125, 184, 78, 1),
                          ),
                        ),
                        child: Center(
                          child:
                              chargement == false
                                  ? const Text(
                                    'Connexion',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 80,
            right: 80,
            top: MediaQuery.of(context).size.height / 1.2,
            bottom: 16,
            child: Center(
              child: Image.network(
                logoLight,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
