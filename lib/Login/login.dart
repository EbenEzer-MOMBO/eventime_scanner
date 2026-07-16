import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Events/page_acceuil.dart';

class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

TextEditingController email = TextEditingController();
TextEditingController passe = TextEditingController();

class _ConnexionState extends State<Connexion> {
  bool chargement = false;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');

    if (savedEmail != null && savedPassword != null) {
      // Pré-remplir les champs avec les données sauvegardées
      email.text = savedEmail;
      passe.text = savedPassword;
      // Se connecter automatiquement seulement si les données sont présentes
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
      // Utiliser HTTPS au lieu de HTTP pour la compatibilité avec le mode release
      final uri = Uri.parse('https://eventime.ga/api/spb_index.php');

      var reponse = await http
          .post(
            uri,
            body: {'clic': 'con', 'matricule': email, 'code': password},
          )
          .timeout(const Duration(seconds: 15)); // Ajouter un timeout

      print('Réponse du serveur: ${reponse.body}');

      if (email == '' || password == '') {
        snackbar('Les champs sont vide');
        setState(() {
          chargement = false;
        });
      } else {
        if (reponse.body == 'non') {
          snackbar('Compte inconnu');
          print('Compte inconnu');
        } else if (reponse.body.contains(',')) {
          print('Connexion réussie');
          final datas = reponse.body.split(',');

          if (datas.length >= 4) {
            // Vérifier que nous avons assez de données
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            prefs.setString('id_agent', datas[0]);
            prefs.setString('matricule_agent', datas[1]);
            prefs.setString('id_org', datas[2]);
            prefs.setString('nom_agent', datas[3]);

            // Save login credentials
            await _saveCredentials(email, password);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => page_acceuil(
                      id_organisateur: datas[2],
                      nom_agent: datas[3],
                      matricule_agent: datas[1],
                      id_agent: datas[0],
                    ),
              ),
            );
          } else {
            snackbar('Format de réponse invalide');
            print('Format de réponse invalide: ${reponse.body}');
          }
        } else {
          snackbar('Erreur de connexion');
          print('Réponse inattendue: ${reponse.body}');
        }
        setState(() {
          chargement = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la connexion: $e');
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
                    Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/logo-eventime-noel-alt.png'),
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
                        ), // Bordure personnalisée
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 19),
                        child: TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'votre matricule',
                            hintStyle: TextStyle(color: Colors.grey),
                            border:
                                InputBorder
                                    .none, // Retire la bordure décorative du TextField
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
                        ), // Bordure personnalisée
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
                            border:
                                InputBorder
                                    .none, // Retire la bordure décorative du TextField
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
                          ), // Bordure personnalisée
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
            left: 150,
            right: 150,
            top: MediaQuery.of(context).size.height / 1.2,
            bottom: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: AssetImage('assets/icone_eventime_light.png'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
