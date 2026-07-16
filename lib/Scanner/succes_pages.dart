import 'package:flutter/material.dart';

class Success extends StatefulWidget {
  final String message;
  final Color color;
  final Map<String, dynamic>? ticketData;

  const Success({super.key, required this.message, required this.color, this.ticketData});

  @override
  State<Success> createState() => _SuccessState();
}

class _SuccessState extends State<Success> {
  // Méthode pour construire les informations du ticket
  Widget _buildTicketInfo(Map<String, dynamic> data) {
    return Container(
      width: MediaQuery.of(context).size.width / 1.3,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.confirmation_number,
            'Ticket',
            data['ticketNumber'] ?? 'N/A',
          ),
          const Divider(height: 8, thickness: 0.5),
          _buildInfoRow(
            Icons.person,
            'Participant',
            '${data['civility_participant'] ?? ''} ${data['participantName'] ?? ''} ${data['participantLastname'] ?? ''}',
          ),
          const Divider(height: 8, thickness: 0.5),
          _buildInfoRow(
            Icons.email,
            'Email',
            data['participantEmailAddress'] ?? 'N/A',
          ),
          if (data['status'] != null) ...[
            const Divider(height: 8, thickness: 0.5),
            _buildInfoRow(
              data['status'] == 1 ? Icons.check_circle : Icons.pending,
              'Statut',
              data['status'] == 1 ? 'Validé' : 'En attente',
              iconColor: data['status'] == 1 ? Colors.green : Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  // Méthode pour construire une ligne d'information
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                // Hauteur dynamique en fonction de la présence des données du ticket
                height:
                    widget.ticketData != null &&
                            widget.ticketData!.containsKey('data')
                        ? MediaQuery.of(context).size.height / 2
                        : MediaQuery.of(context).size.height / 2.5,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/icone_eventime_light.png'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    // Afficher les informations du ticket si disponibles
                    if (widget.ticketData != null &&
                        widget.ticketData!.containsKey('data'))
                      _buildTicketInfo(widget.ticketData!['data']),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            false,
                          ); // Passer la valeur false comme résultat
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                            125,
                            184,
                            78,
                            1,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text(
                          'Continuer à scanner',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            child: Positioned(
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
          ),
        ],
      ),
    );
  }
}
