import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../Scanner/Scanne_pages.dart';
import '../config/api_config.dart';

class Details extends StatefulWidget {
  var Plus;
  var id_agent;
  Details({super.key, required this.Plus, this.id_agent});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> with SingleTickerProviderStateMixin {
  var participant = "0";

  late TabController _tabController;
  List<Map<String, dynamic>> participantsList = [];
  List<Map<String, dynamic>> filteredParticipantsList = [];
  int participantsCount = 0; // vendus = initial - remaining (API count)
  bool isLoadingParticipants = false;
  TextEditingController searchController = TextEditingController();
  Timer? _softFetchTimer;

  Future<void> fetchEventStats(String idEvent) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.eventStats),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'event_id': idEvent}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            participant = data['data']['participants']?.toString() ?? '0';
          });
          return;
        }
      }
      setState(() {
        participant = '0';
      });
    } catch (_) {
      setState(() {
        participant = '0';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    String eventId = widget.Plus['event_id'].toString();
    fetchEventStats(eventId);
    fetchParticipants(eventId);

    searchController.addListener(_filterParticipants);

    _softFetchTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      fetchParticipants(eventId, soft: true);
      fetchEventStats(eventId);
    });
  }

  @override
  void dispose() {
    _softFetchTimer?.cancel();
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _filterParticipants() {
    String query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredParticipantsList = participantsList;
      } else {
        filteredParticipantsList =
            participantsList.where((participant) {
              String fullName =
                  '${participant['participant_name'] ?? ''} ${participant['participant_lastname'] ?? ''}'
                      .toLowerCase();
              String email =
                  (participant['participant_email'] ?? '').toLowerCase();
              String ticketNumber =
                  (participant['ticket_number'] ?? '').toLowerCase();
              return fullName.contains(query) ||
                  email.contains(query) ||
                  ticketNumber.contains(query);
            }).toList();
      }
    });
  }

  Future<void> fetchParticipants(String eventId, {bool soft = false}) async {
    if (!soft || participantsList.isEmpty) {
      setState(() {
        isLoadingParticipants = true;
      });
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.participantsList),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'event_id': eventId}),
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isNotEmpty) {
          Map<String, dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse['success'] == true) {
            var data = jsonResponse['data'];
            if (data is List) {
              final list = List<Map<String, dynamic>>.from(data);
              final apiCount = jsonResponse['count'];
              setState(() {
                participantsList = list;
                participantsCount =
                    apiCount is int
                        ? apiCount
                        : int.tryParse(apiCount?.toString() ?? '') ??
                            list.length;
                isLoadingParticipants = false;
              });
              _filterParticipants();
              return;
            }
          }
        }
      }
    } catch (e) {
      print("Erreur lors du chargement des participants: $e");
    }

    if (!soft) {
      setState(() {
        participantsList = [];
        filteredParticipantsList = [];
        participantsCount = 0;
        isLoadingParticipants = false;
      });
    } else {
      setState(() {
        isLoadingParticipants = false;
      });
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
    var size = MediaQuery.of(context).size;

    double dureeEnHeures = double.parse(widget.Plus['scan_date'].toString());
    DateTime heureSpecifique = DateTime.parse(
      widget.Plus['start_date'].toString(),
    );
    DateTime dateFin = DateTime.parse(widget.Plus['end_date'].toString());
    DateTime finScan = heureSpecifique.add(const Duration(hours: 1));
    DateTime maintenant = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header avec titre et bouton retour
          Stack(
            children: [
              // Image de l'événement
              Container(
                height: size.height * 0.25,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://version2.eventime.ga/public/storage/img-event/${widget.Plus['image']}',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Gradient overlay
              Container(
                height: size.height * 0.25,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
              ),
              // Header content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.Plus['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(
                        width: 48,
                      ), // Pour équilibrer le bouton retour
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xFF8BC34A),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: const [Tab(text: "Description"), Tab(text: "Participants")],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                DescriptionContent(
                  description: widget.Plus['description'],
                  startDate: heureSpecifique,
                  endDate: dateFin,
                  location: widget.Plus['location'] ?? 'Non spécifié',
                  scanAvailable: condition(heureSpecifique, dureeEnHeures),
                  scanHours: dureeEnHeures,
                ),
                ParticipantsContent(
                  participantsList: filteredParticipantsList,
                  isLoading: isLoadingParticipants,
                  searchController: searchController,
                  totalCount: participantsCount,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (condition(heureSpecifique, dureeEnHeures)) {
            if (finScan.isBefore(maintenant)) {
              snackbar('Les validations sont clôturées');
            } else {
              participant != '0'
                  ? Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => QRViewExample(
                            id_event: widget.Plus['event_id'].toString(),
                            evenement: widget.Plus['title'].toString(),
                            id_agent: widget.id_agent,
                          ),
                    ),
                  )
                  : snackbar('Il n\'y a encore aucun participant');
            }
          } else {
            snackbar(
              "L'heure de la validation des tickets n'est pas encore venue !",
            );
          }
        },
        backgroundColor: const Color(0xFF8BC34A),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text(
          'Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Fonction qui vérifie la condition
  bool condition(heureSpecifique, dureeEnHeures) {
    DateTime heureActuelle = DateTime.now();
    int minutes = (dureeEnHeures * 60).toInt();
    DateTime heureLimite = heureSpecifique.subtract(
      Duration(minutes: minutes),
    );
    return heureActuelle.isAfter(heureLimite) ||
        heureActuelle.isAtSameMomentAs(heureLimite);
  }
}

// ==================== WIDGETS ====================

class DescriptionContent extends StatelessWidget {
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final bool scanAvailable;
  final double scanHours;

  const DescriptionContent({
    super.key,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.scanAvailable,
    required this.scanHours,
  });

  String _formatDate(DateTime date) {
    // Format: "11 décembre 2025 à 17:00"
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    String day = date.day.toString().padLeft(2, '0');
    String month = months[date.month - 1];
    String year = date.year.toString();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year à $hour:$minute';
  }

  String _getScanAvailabilityText() {
    // Calculer quand le scan devient disponible
    int minutes = (scanHours * 60).toInt();
    DateTime scanStartTime = startDate.subtract(Duration(minutes: minutes));
    DateTime now = DateTime.now();

    if (now.isAfter(scanStartTime)) {
      // Le scan est déjà disponible
      return 'Scan disponible maintenant';
    } else {
      // Calculer le temps restant
      Duration timeRemaining = scanStartTime.difference(now);

      if (timeRemaining.inDays > 0) {
        return 'Scan disponible dans ${timeRemaining.inDays}j ${timeRemaining.inHours % 24}h';
      } else if (timeRemaining.inHours > 0) {
        return 'Scan disponible dans ${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}min';
      } else {
        return 'Scan disponible dans ${timeRemaining.inMinutes}min';
      }
    }
  }

  String _getScanAvailabilitySubtext() {
    int minutes = (scanHours * 60).toInt();
    DateTime scanStartTime = startDate.subtract(Duration(minutes: minutes));
    DateTime now = DateTime.now();

    if (now.isAfter(scanStartTime)) {
      return 'Scan autorisé jusqu\'à 1h après le début de l\'événement';
    } else {
      // Afficher en heures ou minutes selon la valeur
      if (scanHours >= 1) {
        return 'Scan autorisé ${scanHours}h avant le début de l\'événement';
      } else {
        return 'Scan autorisé ${minutes}min avant le début de l\'événement';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          const Center(
            child: Text(
              'DESCRIPTION',
              style: TextStyle(
                color: Color(0xFF8BC34A),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Description text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ),

          const SizedBox(height: 24),

          // Date de début
          _buildInfoCard(
            icon: Icons.calendar_today,
            iconColor: const Color(0xFFE57373),
            title: 'Date de début:',
            subtitle: _formatDate(startDate),
          ),

          const SizedBox(height: 12),

          // Date de fin
          _buildInfoCard(
            icon: Icons.flag_outlined,
            iconColor: Colors.black87,
            title: 'Date de fin:',
            subtitle: _formatDate(endDate),
          ),

          const SizedBox(height: 12),

          // Lieu
          _buildInfoCard(
            icon: Icons.location_on,
            iconColor: const Color(0xFFFFB74D),
            title: 'Lieu:',
            subtitle: location,
          ),

          const SizedBox(height: 16),

          // Disponibilité du scan
          Builder(
            builder: (context) {
              int minutes = (scanHours * 60).toInt();
              DateTime scanStartTime = startDate.subtract(
                Duration(minutes: minutes),
              );
              DateTime now = DateTime.now();
              bool isScanAvailable = now.isAfter(scanStartTime);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isScanAvailable
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isScanAvailable
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFFEB3B),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isScanAvailable ? Icons.check_circle : Icons.alarm,
                        color:
                            isScanAvailable
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disponibilité du scan:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  isScanAvailable
                                      ? Colors.green[900]
                                      : Colors.orange[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getScanAvailabilityText(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getScanAvailabilitySubtext(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

class ParticipantsContent extends StatelessWidget {
  final List<Map<String, dynamic>> participantsList;
  final bool isLoading;
  final TextEditingController searchController;
  final int totalCount;

  const ParticipantsContent({
    super.key,
    required this.participantsList,
    required this.isLoading,
    required this.searchController,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8BC34A)),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un participant...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8BC34A)),
                suffixIcon:
                    searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => searchController.clear(),
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ),

        // Participants count header
        if (totalCount > 0)
          ParticipantsHeader(
            count: participantsList.length,
            totalCount: totalCount,
          ),

        // Participants list
        if (participantsList.isEmpty && !isLoading)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    searchController.text.isNotEmpty
                        ? Icons.search_off
                        : Icons.people_outline,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    searchController.text.isNotEmpty
                        ? 'Aucun participant trouvé'
                        : 'Aucun participant pour le moment',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // Scroll infini : boucle sur la liste actuelle
              itemBuilder: (context, index) {
                final item =
                    participantsList[index % participantsList.length];
                return ParticipantCard(participant: item);
              },
            ),
          ),
      ],
    );
  }
}

class ParticipantsHeader extends StatelessWidget {
  final int count;
  final int? totalCount;

  const ParticipantsHeader({super.key, required this.count, this.totalCount});

  @override
  Widget build(BuildContext context) {
    bool isFiltered = totalCount != null && count != totalCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8BC34A), Color(0xFF7CB342)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  isFiltered
                      ? '$count / $totalCount'
                      : '${totalCount ?? count}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isFiltered
                      ? 'Résultats trouvés'
                      : ((totalCount ?? count) > 1
                          ? 'Participants'
                          : 'Participant'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isFiltered ? Icons.filter_list : Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticipantCard extends StatelessWidget {
  final Map<String, dynamic> participant;

  const ParticipantCard({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    final status = participant['status']?.toString();
    final bool isValidated = status == '1' || status == 'scanned';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color:
              isValidated
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar avec effet brillant
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isValidated ? Colors.green : Colors.orange)
                        .withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: isValidated ? Colors.green : Colors.orange,
                child: Text(
                  participant['participant_name']?.substring(0, 1) ?? 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Informations principales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom avec icône
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${participant['participant_name'] ?? 'Prénom'} ${participant['participant_lastname'] ?? 'Nom'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Billet avec icône
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          participant['ticket_number'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Email avec icône
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          participant['participant_email'] ??
                              'Email non fourni',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Acheteur avec icône
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          participant['buyer_name'] ?? 'Acheteur inconnu',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Badge de statut amélioré
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isValidated
                          ? [Colors.green, Colors.green.shade600]
                          : [Colors.orange, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isValidated ? Colors.green : Colors.orange)
                        .withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isValidated ? Icons.check_circle : Icons.schedule,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
