import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:eventime_scanner/Scanner/succes_pages.dart';
import 'package:eventime_scanner/config/api_config.dart';

class QRViewExample extends StatefulWidget {
  @override
  _QRViewExampleState createState() => _QRViewExampleState();
  var id_event, evenement, id_agent;
  QRViewExample({super.key, this.id_event, this.evenement, this.id_agent});
}

class _QRViewExampleState extends State<QRViewExample> {
  late MobileScannerController _controller;
  String qrCodeData = "Aucun code QR scanné";
  bool isDataSent = false;
  bool isFlashOn = false; // Variable pour suivre l'état du flash

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(125, 184, 78, 1),
        title: Text(widget.evenement, style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onQRViewCreated,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 250, // Ajustez la largeur selon vos besoins
                      height: 250, // Ajustez la hauteur selon vos besoins
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color.fromRGBO(125, 184, 78, 1),
                          width: 4.0, // Épaisseur de la bordure
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FloatingActionButton(
                        backgroundColor: Color.fromRGBO(125, 184, 78, 1),
                        onPressed: () {
                          // Activer/Désactiver le flash
                          _controller.toggleTorch();
                          setState(() {
                            isFlashOn = !isFlashOn;
                          });
                        },
                        child: Icon(
                          isFlashOn ? Icons.flash_off : Icons.flash_on,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'Code QR scanné : $qrCodeData',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          qrCodeData = code;
        });
        if (qrCodeData != "Aucun code QR scanné" && !isDataSent) {
          // Envoyer les données du code QR via une requête HTTP POST
          sendQRCodeData(qrCodeData);
          isDataSent = true; // Marquer que les données ont été envoyées
        }
      }
    }
  }

  snackbar(text, Color couleur) {
    final snackBar = SnackBar(
      backgroundColor: couleur,
      content: Text(text, style: TextStyle(color: Colors.white)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> sendQRCodeData(numeroTicket) async {
    try {
      // Utiliser le nouvel endpoint API mobile pour le scan de tickets
      final uri = Uri.parse(ApiConfig.scanTicket);
      
      // Préparer les données à envoyer
      final requestData = {
        'ticket_code': numeroTicket.toString(),
        'event_id': int.parse(widget.id_event.toString()),
        'agent_id': widget.id_agent?.toString() ?? '',
      };
      
      // LOG: Afficher les données envoyées
      print('═══════════════════════════════════════');
      print('📤 ENVOI DE LA REQUÊTE');
      print('URL: $uri');
      print('Ticket code: ${requestData['ticket_code']}');
      print('Event ID: ${requestData['event_id']}');
      print('Agent ID: ${requestData['agent_id']}');
      print('Body JSON: ${jsonEncode(requestData)}');
      print('═══════════════════════════════════════');
      
      var reponse = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 15)); // Ajouter un timeout

      // LOG: Afficher le code de statut et la réponse brute
      print('═══════════════════════════════════════');
      print('📥 RÉPONSE REÇUE');
      print('Status Code: ${reponse.statusCode}');
      print('Headers: ${reponse.headers}');
      print('Body brut: ${reponse.body}');
      print('Body length: ${reponse.body.length}');
      print('═══════════════════════════════════════');
      
      if (reponse.statusCode == 200) {
        print('✅ Statut 200 - Succès');
        print('Données envoyées avec succès');
        print('Réponse API: ${reponse.body}');

        // Vérifier si la réponse est vide
        if (reponse.body.trim().isEmpty) {
          print("⚠️ ERREUR: Réponse vide de l'API");
          snackbar("Erreur: Réponse vide du serveur", Colors.redAccent);
          return;
        }

        try {
          // Décoder la réponse JSON
          final data = json.decode(reponse.body);
          
          // LOG: Afficher les données décodées
          print('═══════════════════════════════════════');
          print('📊 DONNÉES DÉCODÉES');
          print('Success: ${data['success']}');
          print('Message: ${data['message']}');
          print('Code: ${data['code']}');
          print('Data: ${data['data']}');
          print('═══════════════════════════════════════');

          // Vérifier si le scan a réussi
          if (data['success'] == true) {
            // Scan réussi
            print('✅ SCAN RÉUSSI');
            final message = data['message'] ?? 'Ticket scanné avec succès';
            snackbar(message, Colors.lightGreen);
            
            bool isDataSentAgain = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => Success(
                      message: message,
                      color: Colors.lightGreen,
                      ticketData: data, // Passer les données du ticket
                    ),
              ),
            );

            setState(() {
              isDataSent = isDataSentAgain;
            });
          } else {
            // Gestion des différents codes d'erreur selon la documentation API
            print('❌ ERREUR DÉTECTÉE');
            final errorCode = data['code'] ?? '';
            String message = data['message'] ?? 'Erreur lors du scan';
            
            print('Code erreur: $errorCode');
            print('Message erreur: $message');
            print('Ticket info: ${data['ticket_info']}');
            print('Errors: ${data['errors']}');
            
            // Messages personnalisés selon le code d'erreur
            switch (errorCode) {
              case 'TICKET_ALREADY_SCANNED':
                message = '⚠️ Ce ticket a déjà été scanné';
                break;
              case 'TICKET_WRONG_EVENT':
                message = '❌ Ce ticket n\'appartient pas à cet événement';
                break;
              case 'AGENT_NOT_AUTHORIZED':
                message = '❌ Vous n\'êtes pas autorisé pour cet événement';
                break;
              case 'TICKET_NOT_FOUND':
                message = '❌ Ticket non trouvé';
                break;
              case 'TICKET_INVALID_STATUS':
                message = '❌ Ce ticket a été annulé ou remboursé';
                break;
              case 'EVENT_NOT_FOUND':
                message = '❌ Événement non trouvé';
                break;
            }
            
            snackbar(message, Colors.redAccent);
            bool isDataSentAgain = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => Success(
                      message: message,
                      color: Colors.redAccent,
                      ticketData: data, // Passer les données du ticket même en cas d'erreur
                    ),
              ),
            );

            setState(() {
              isDataSent = isDataSentAgain;
            });
          }

          setState(() {
            qrCodeData = "Aucun code QR scanné";
          });
        } catch (e) {
          print("═══════════════════════════════════════");
          print("❌ ERREUR DE PARSING JSON");
          print("Erreur: $e");
          print("Body reçu: ${reponse.body}");
          print("═══════════════════════════════════════");
          snackbar("Erreur de format de données", Colors.redAccent);
        }
      } else if (reponse.statusCode == 400) {
        print('═══════════════════════════════════════');
        print('⚠️ ERREUR 400 - BAD REQUEST');
        print('Body: ${reponse.body}');
        
        // Tenter de décoder la réponse pour avoir plus d'infos
        try {
          final errorData = json.decode(reponse.body);
          print('Message: ${errorData['message']}');
          print('Code: ${errorData['code']}');
          print('Détails: $errorData');
          snackbar(errorData['message'] ?? "Requête invalide", Colors.redAccent);
        } catch (e) {
          print('Impossible de décoder l\'erreur 400');
          snackbar("Erreur 400: Requête invalide", Colors.redAccent);
        }
        print('═══════════════════════════════════════');
      } else if (reponse.statusCode == 404) {
        print('❌ ERREUR 404 - NOT FOUND');
        snackbar("Événement ou ticket non trouvé", Colors.redAccent);
      } else if (reponse.statusCode == 403) {
        print('❌ ERREUR 403 - FORBIDDEN');
        snackbar("Accès non autorisé", Colors.redAccent);
      } else if (reponse.statusCode == 422) {
        print('❌ ERREUR 422 - VALIDATION ERROR');
        try {
          final errorData = json.decode(reponse.body);
          print('Erreurs de validation: ${errorData['errors']}');
          snackbar("Données invalides", Colors.redAccent);
        } catch (e) {
          snackbar("Erreur de validation", Colors.redAccent);
        }
      } else {
        print("═══════════════════════════════════════");
        print("❌ ERREUR HTTP: ${reponse.statusCode}");
        print("Body: ${reponse.body}");
        print("═══════════════════════════════════════");
        snackbar("Erreur de connexion au serveur", Colors.redAccent);
      }
    } catch (e) {
      print("═══════════════════════════════════════");
      print("❌ EXCEPTION GÉNÉRALE");
      print("Exception dans sendQRCodeData: $e");
      print("Type d'erreur: ${e.runtimeType}");
      print("═══════════════════════════════════════");
      snackbar("Erreur lors de l'envoi des données", Colors.redAccent);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
