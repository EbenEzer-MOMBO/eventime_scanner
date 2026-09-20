import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/network_error.dart';
import '../services/offline_storage_service.dart';
import '../services/offline_sync_service.dart';
import '../services/scanner_api_client.dart';

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
  List<Map<String, dynamic>> upcomingEvents = [];
  Map<String, dynamic>? _currentEventPayload; // Liste des événements

  @override
  void initState() {
    super.initState();
    _loadFromCacheThenNetwork();
  }

  Future<void> _loadFromCacheThenNetwork() async {
    await _hydrateFromCache();
    await fetchData();
    await Evenements_en_cours(widget.id_agent.toString());
    await OfflineSyncService.instance.start();
  }

  Future<void> _hydrateFromCache() async {
    final agentId = widget.id_agent.toString();
    final upcoming = await OfflineStorageService.getUpcomingEvents(agentId);
    final current = await OfflineStorageService.getCurrentEvent(agentId);
    if (!mounted) {
      return;
    }
    setState(() {
      upcomingEvents = upcoming;
      _currentEventPayload = current;
      if (current != null) {
        id_evenement_en_cours = current['event_id']?.toString() ?? '';
        image_evenement_en_cours = current['image']?.toString() ?? '';
        nom_evenement_en_cours = current['title']?.toString() ?? '';
        description_evenement_en_cours =
            current['description']?.toString() ??
            'Aucune description disponible';
      }
    });
  }

  void _logout() async {
    try {
      await ScannerApiClient.post(ApiConfig.logout, {});
    } catch (_) {}
    await ScannerApiClient.clearSession(context: context);
  }

  Future<List<Map<String, dynamic>>?> fetchEvents(String idAgent) async {
    try {
      final response = await ScannerApiClient.post(
        ApiConfig.eventsAvenir,
        {'id_agent': idAgent.toString()},
        timeout: const Duration(seconds: 25),
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
      return null;
    }
  }

  Future<void> Evenements_en_cours(String idAgent) async {
    try {
      var response = await ScannerApiClient.post(
        ApiConfig.eventsEnCours,
        {'id_agent': idAgent},
        timeout: const Duration(seconds: 25),
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

              if (!mounted) {
                return;
              }
              setState(() {
                id_evenement_en_cours = eventData['event_id'].toString();
                image_evenement_en_cours = eventData['image'].toString();
                nom_evenement_en_cours = eventData['title'].toString();
                description_evenement_en_cours =
                    eventData['description'] ?? "Aucune description disponible";
                _currentEventPayload = Map<String, dynamic>.from(eventData);
              });

              if (newEvent) {
                fetchEventStats(id_evenement_en_cours);
              }
              await OfflineStorageService.saveCurrentEvent(idAgent, {
                'event_id': id_evenement_en_cours,
                'image': image_evenement_en_cours,
                'title': nom_evenement_en_cours,
                'description': description_evenement_en_cours,
                'start_date': eventData['start_date'],
                'end_date': eventData['end_date'],
                'scan_date': eventData['scan_date'],
              });
            } else {
              setState(() {
                id_evenement_en_cours = "";
              });
              await OfflineStorageService.saveCurrentEvent(idAgent, null);
            }
          } else {
            setState(() {
              id_evenement_en_cours = "";
            });
          }
        } catch (e) {
          snackbar("Erreur de format de données");
        }
      } else {
        snackbar("Impossible de charger l'événement en cours");
      }
    } catch (e) {
      if (id_evenement_en_cours.isEmpty) {
        snackbar(networkErrorMessage(e));
      }
    }
  }

  /// Stats alignées dashboard : participants = vendus, remaining = non scannés.
  Future<void> fetchEventStats(idEvent) async {
    try {
      var response = await ScannerApiClient.post(
        ApiConfig.eventStats,
        {'event_id': idEvent.toString()},
        context: context,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final sold = data['data']['participants'];
          final soldInt =
              sold is int ? sold : int.tryParse(sold?.toString() ?? '') ?? 0;
          await OfflineStorageService.saveSoldCount(
            idEvent.toString(),
            soldInt,
          );
          if (!mounted) {
            return;
          }
          setState(() {
            participant = soldInt.toString();
            tk_restant = data['data']['remaining']?.toString() ?? '0';
          });
          return;
        }
      }
      final cached = await OfflineStorageService.getSoldCount(
        idEvent.toString(),
      );
      if (!mounted) {
        return;
      }
      if (cached != null) {
        setState(() {
          participant = cached.toString();
        });
      }
    } catch (e) {
      final cached = await OfflineStorageService.getSoldCount(
        idEvent.toString(),
      );
      if (!mounted) {
        return;
      }
      if (cached != null) {
        setState(() {
          participant = cached.toString();
        });
      }
    }
  }

  Future<void> fetchData() async {
    try {
      final events = await fetchEvents(widget.id_agent.toString());
      if (events == null) {
        if (upcomingEvents.isEmpty) {
          snackbar('Connexion trop lente. Réessayez.');
        }
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        upcomingEvents = events;
      });
      await OfflineStorageService.saveUpcomingEvents(
        widget.id_agent.toString(),
        events,
      );
    } catch (e) {
      if (upcomingEvents.isEmpty) {
        snackbar(networkErrorMessage(e));
      }
    }
  }

  snackbar(text) {
    if (!mounted) {
      return;
    }
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
    final currentEvent = _currentEventPayload;

    Map<String, dynamic> eventDetails = {
      'event_id': id_evenement_en_cours,
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
