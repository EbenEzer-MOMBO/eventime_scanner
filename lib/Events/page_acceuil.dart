import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';
import '../config/api_config.dart';

import 'details_pages.dart';
import 'widgets/user_header.dart';
import 'widgets/current_event_card.dart';
import 'widgets/events_list.dart';

class page_acceuil extends StatefulWidget {
  var id_organisateur, nom_agent, matricule_agent, id_agent;

  page_acceuil({super.key, 
    required this.id_organisateur,
    required this.nom_agent,
    required this.matricule_agent,
    required this.id_agent,
  });

  @override
  State<page_acceuil> createState() => _page_acceuilState();
}

class _page_acceuilState extends State<page_acceuil> {
  String id_evenement_en_cours = "";
  String nom_evenement_en_cours = "";
  String image_evenement_en_cours = "";
  String description_evenement_en_cours = "";
  String participant = "0";
  String tk_restant = "0";

  // Variables d'état
  List<Map<String, dynamic>> upcomingEvents = []; // Liste des événements

  @override
  void initState() {
    super.initState();
    // Chargement initial des données
    fetchData();
    Evenements_en_cours(widget.id_agent.toString());
  }

  void _logout() async {
    // Supprimer les données sauvegardées
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Supprime toutes les données stockées

    // Navigate to login page and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Connexion()),
      (Route<dynamic> route) => false,
    );
  }

  Future<List<Map<String, dynamic>>> fetchEvents(String idAgent) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.eventsAvenir),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_agent': idAgent.toString()}),
      );

      if (response.statusCode == 200) {
        // Vérifier si la réponse est vide
        if (response.body.trim().isEmpty) {
          return [];
        }

        try {
          // Décoder la réponse JSON
          Map<String, dynamic> jsonResponse = json.decode(response.body);

          // Vérifier le statut de succès
          if (jsonResponse['success'] == true) {
            var data = jsonResponse['data'];

            if (data is List) {
              List<Map<String, dynamic>> events = [];

              // Traiter chaque événement
              for (var item in data) {
                if (item is Map<String, dynamic>) {
                  events.add(item);
                }
              }

              return events;
            } else {
              return [];
            }
          } else {
            return [];
          }
        } catch (e) {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  void Evenements_en_cours(String idAgent) async {
    final uri = Uri.parse(ApiConfig.eventsEnCours);

    try {
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_agent': idAgent}),
      );

      if (response.statusCode == 200) {
        String responseBody = response.body.trim();
        if (responseBody.isEmpty) {
          return;
        }

        try {
          Map<String, dynamic> jsonResponse = json.decode(responseBody);

          if (jsonResponse['success'] == true) {
            var data = jsonResponse['data'];

            if (data is List && data.isNotEmpty) {
              var eventData = data[0];

              bool newEvent =
                  id_evenement_en_cours != eventData['event_id'].toString();

              setState(() {
                id_evenement_en_cours = eventData['event_id'].toString();
                image_evenement_en_cours = eventData['image'].toString();
                nom_evenement_en_cours = eventData['title'].toString();
                description_evenement_en_cours =
                    eventData['description'] ?? "Aucune description disponible";
              });

              if (newEvent) {
                fetchEventStats(id_evenement_en_cours);
                snackbar("Événement en cours: $nom_evenement_en_cours");
              }
            } else {
              setState(() {
                id_evenement_en_cours = "";
              });
            }
          } else {
            setState(() {
              id_evenement_en_cours = "";
            });
          }
        } catch (e) {
          snackbar("Erreur de format de données: $e");
        }
      } else {
        snackbar("Erreur: ${response.statusCode}");
      }
    } catch (e) {
      snackbar("Erreur: $e");
    }
  }

  /// Stats alignées dashboard : participants = vendus, remaining = non scannés.
  Future<void> fetchEventStats(idEvent) async {
    try {
      final uri = Uri.parse(ApiConfig.eventStats);
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'event_id': idEvent.toString()}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            participant = data['data']['participants']?.toString() ?? '0';
            tk_restant = data['data']['remaining']?.toString() ?? '0';
          });
          return;
        }
      }
      setState(() {
        participant = '0';
        tk_restant = '0';
      });
    } catch (e) {
      setState(() {
        participant = '0';
        tk_restant = '0';
      });
    }
  }

  Future<void> fetchData() async {
    try {
      // Utiliser fetchEvents pour récupérer les événements
      List<Map<String, dynamic>> events = await fetchEvents(
        widget.id_agent.toString(),
      );

      // Mettre à jour la liste des événements
      setState(() {
        upcomingEvents = events;
      });
    } catch (e) {
      // Afficher un message d'erreur à l'utilisateur
      snackbar("Impossible de charger les événements");
    }
  }

  snackbar(text) {
    final snackBar = SnackBar(
      backgroundColor: Colors.redAccent,
      content: Text(text, style: const TextStyle(color: Colors.white)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    // Les données sont mises à jour manuellement via le bouton de rafraîchissement

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _refreshAllData,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: UserHeader(
              nomAgent: widget.nom_agent,
              matriculeAgent: widget.matricule_agent,
              onLogout: _logout,
            ),
          ),
          const SizedBox(height: 10),
          CurrentEventCard(
            idEvenementEnCours: id_evenement_en_cours,
            nomEvenementEnCours: nom_evenement_en_cours,
            imageEvenementEnCours: image_evenement_en_cours,
            descriptionEvenementEnCours: description_evenement_en_cours,
            tkRestant: tk_restant,
            participant: participant,
            onTap: () => _navigateToEventDetails(),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: EventsList(
              events: upcomingEvents,
              onRefresh: _refreshEvents,
              idAgent: widget.id_agent.toString(),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEventDetails() {
    // Chercher l'événement dans la liste pour obtenir toutes ses données
    Map<String, dynamic>? currentEvent;
    for (var event in upcomingEvents) {
      if (event['event_id'].toString() == id_evenement_en_cours) {
        currentEvent = event;
        break;
      }
    }

    Map<String, dynamic> eventDetails = {
      'event_id': id_evenement_en_cours, // Garder comme String pour l'API
      'title': nom_evenement_en_cours,
      'image': image_evenement_en_cours,
      'description':
          description_evenement_en_cours.isNotEmpty
              ? description_evenement_en_cours
              : (currentEvent?['description'] ??
                  'Aucune description disponible'),
      'start_date': currentEvent?['start_date'] ?? DateTime.now().toString(),
      'end_date':
          currentEvent?['end_date'] ??
          DateTime.now().add(const Duration(days: 1)).toString(),
      'scan_date': currentEvent?['scan_date']?.toString() ?? '1',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Details(
          Plus: eventDetails,
          id_agent: widget.id_agent,
        ),
      ),
    );
  }

  void _refreshEvents() {
    fetchData();
  }

  void _refreshAllData() {
    // Afficher un indicateur de chargement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text(
          'Actualisation des données en cours...',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 1),
      ),
    );

    // Actualiser les événements à venir
    fetchData();

    // Vérifier l'événement en cours
    Evenements_en_cours(widget.id_agent.toString());

    if (id_evenement_en_cours.isNotEmpty) {
      fetchEventStats(id_evenement_en_cours);
    }
  }
}
