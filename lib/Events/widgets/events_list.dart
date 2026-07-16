import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'event_card.dart';

// Widget pour la liste des événements
class EventsList extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final VoidCallback onRefresh;
  final String? idAgent;

  const EventsList({
    super.key,
    required this.events,
    required this.onRefresh,
    this.idAgent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 20),
            Container(width: 10, height: 40, color: Colors.green),
            const SizedBox(width: 20),
            const Text('Événements à venir 📅'),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child:
              events.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Lottie.asset('assets/noevents.json'),
                        ),
                        const Text(
                          'Aucun événement disponible',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: onRefresh,
                          child: const Text('Actualiser'),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.only(left: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: EventCard(
                          event: events[index],
                          idAgent: idAgent,
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
