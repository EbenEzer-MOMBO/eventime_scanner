import 'package:flutter/material.dart';

// Widget pour l'en-tête de l'utilisateur
class UserHeader extends StatelessWidget {
  final String nomAgent;
  final String matriculeAgent;
  final VoidCallback onLogout;

  const UserHeader({
    super.key,
    required this.nomAgent,
    required this.matriculeAgent,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        nomAgent.isNotEmpty ? nomAgent[0] : 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(nomAgent, style: const TextStyle(fontSize: 15)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: TextButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}
