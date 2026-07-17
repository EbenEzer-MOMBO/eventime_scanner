import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Widget pour l'événement en cours
class CurrentEventCard extends StatelessWidget {
  final String idEvenementEnCours;
  final String nomEvenementEnCours;
  final String imageEvenementEnCours;
  final String descriptionEvenementEnCours;
  final String tkRestant;
  final String participant;
  final VoidCallback onTap;

  const CurrentEventCard({
    super.key,
    required this.idEvenementEnCours,
    required this.nomEvenementEnCours,
    required this.imageEvenementEnCours,
    required this.descriptionEvenementEnCours,
    required this.tkRestant,
    required this.participant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (idEvenementEnCours.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const SizedBox(width: 20),
              Container(width: 10, height: 40, color: Colors.green),
              const SizedBox(width: 20),
              const Text('Événement en cours'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: size.width / 1.1,
            height: size.height * 0.25,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey.shade100, Colors.grey.shade200],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Lottie.asset('assets/noevents.json'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun événement en cours',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'En attente d\'un événement actif',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 20),
              Container(width: 10, height: 40, color: Colors.green),
              const SizedBox(width: 20),
              const Text('Événement en cours 🔴'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: size.width / 1.1,
            height: size.height * 0.25,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Image de fond
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(
                        "https://version2.eventime.ga/public/storage/img-event/$imageEvenementEnCours",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Overlay gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Badge "EN COURS" en haut

                // Titre de l'événement
                Positioned(
                  top: 16,
                  right: 16,
                  left: 16,
                  child: Text(
                    nomEvenementEnCours,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Cards de statistiques
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatsCard(
                        'Non scannés',
                        tkRestant,
                        size,
                        Icons.confirmation_number,
                      ),
                      _buildStatsCard(
                        'Participants',
                        participant,
                        size,
                        Icons.people,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String label, String value, Size size, IconData icon) {
    return Container(
      width: size.width / 2.6,
      height: size.height * 0.12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
