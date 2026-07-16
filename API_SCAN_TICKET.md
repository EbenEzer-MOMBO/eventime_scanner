# API Scan de Ticket - Documentation

## Vue d'ensemble

Cette API permet de scanner les tickets QR des participants lors d'un événement. Elle vérifie que le ticket est valide et appartient bien à l'événement en cours avant de l'enregistrer comme scanné.

## Endpoint

```
POST /api/mobile/scan-ticket
```

## Authentification

L'agent doit être assigné à l'événement pour pouvoir scanner les tickets.

## Paramètres de la requête

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| `ticket_code` | string | ✅ | Le code du ticket (numéro de ticket QR) |
| `event_id` | integer | ✅ | L'ID de l'événement en cours |
| `agent_id` | string | ✅ | L'ID de l'agent qui effectue le scan |

### Exemple de requête

```json
POST /api/mobile/scan-ticket
Content-Type: application/json

{
  "ticket_code": "TKT-2026-ABC123456",
  "event_id": 1234,
  "agent_id": "agent-xyz-789"
}
```

## Réponses de l'API

### ✅ Succès (200 OK)

Le ticket a été scanné avec succès.

```json
{
  "success": true,
  "message": "Ticket scanné avec succès",
  "code": "SCAN_SUCCESS",
  "data": {
    "ticket_number": "TKT-2026-ABC123456",
    "participant_name": "Jean Dupont",
    "participant_email": "jean.dupont@email.com",
    "buyer_name": "Marie Dupont",
    "event_title": "Concert Jazz Festival 2026",
    "scan_time": "2026-02-13 14:30:00"
  }
}
```

### ❌ Erreurs possibles

#### 1. Événement non trouvé (404)

```json
{
  "success": false,
  "message": "Événement non trouvé",
  "code": "EVENT_NOT_FOUND"
}
```

#### 2. Agent non autorisé (403)

L'agent n'est pas assigné à cet événement.

```json
{
  "success": false,
  "message": "Agent non autorisé pour cet événement",
  "code": "AGENT_NOT_AUTHORIZED"
}
```

#### 3. Ticket non trouvé (404)

Le code du ticket n'existe pas dans la base de données.

```json
{
  "success": false,
  "message": "Ticket non trouvé",
  "code": "TICKET_NOT_FOUND"
}
```

#### 4. Ticket ne correspond pas à l'événement (400)

Le ticket existe mais appartient à un autre événement.

```json
{
  "success": false,
  "message": "Ce ticket n'appartient pas à cet événement",
  "code": "TICKET_WRONG_EVENT",
  "ticket_info": {
    "ticket_event_id": 5678,
    "current_event_id": 1234
  }
}
```

**Action recommandée**: Afficher un message clair à l'utilisateur et proposer de vérifier l'événement associé au ticket.

#### 5. Ticket déjà scanné (400)

Le ticket a déjà été scanné précédemment.

```json
{
  "success": false,
  "message": "Ce ticket a déjà été scanné",
  "code": "TICKET_ALREADY_SCANNED",
  "ticket_info": {
    "ticket_number": "TKT-2026-ABC123456",
    "participant_name": "Jean Dupont",
    "participant_email": "jean.dupont@email.com",
    "buyer_name": "Marie Dupont",
    "scanned_at": "2026-02-13 14:30:00"
  }
}
```

**Action recommandée**: Afficher les informations du participant pour permettre à l'agent de vérifier visuellement l'identité.

#### 6. Ticket annulé ou remboursé (400)

Le ticket a été annulé ou remboursé et n'est plus valide.

```json
{
  "success": false,
  "message": "Ce ticket a été annulé ou remboursé",
  "code": "TICKET_INVALID_STATUS",
  "ticket_info": {
    "status": "canceled"
  }
}
```

#### 7. Erreur de validation (422)

Les paramètres de la requête sont invalides ou manquants.

```json
{
  "success": false,
  "message": "Données de validation invalides",
  "code": "VALIDATION_ERROR",
  "errors": {
    "ticket_code": ["Le champ ticket code est requis."],
    "event_id": ["Le champ event id est requis."]
  }
}
```

#### 8. Erreur serveur (500)

Une erreur interne s'est produite.

```json
{
  "success": false,
  "message": "Une erreur est survenue lors du scan du ticket",
  "code": "SCAN_ERROR",
  "error": "Message d'erreur détaillé"
}
```

## Logique de validation

L'API effectue les vérifications suivantes dans cet ordre :

1. **Validation des paramètres** - Vérifie que tous les champs requis sont présents
2. **Vérification de l'événement** - S'assure que l'événement existe
3. **Vérification de l'agent** - Confirme que l'agent est autorisé pour cet événement
4. **Vérification du ticket** - Vérifie que le ticket existe
5. **Vérification d'appartenance** - Confirme que le ticket appartient à l'événement en cours
6. **Vérification du statut** - S'assure que le ticket n'a pas déjà été scanné, annulé ou remboursé
7. **Mise à jour** - Marque le ticket comme "scanned" avec timestamp
8. **Historique** - Enregistre le scan dans la table d'historique (si disponible)

## Codes de statut HTTP

| Code | Signification |
|------|---------------|
| 200 | Scan réussi |
| 400 | Requête invalide (ticket déjà scanné, mauvais événement, etc.) |
| 403 | Agent non autorisé |
| 404 | Ressource non trouvée (événement ou ticket) |
| 422 | Erreur de validation |
| 500 | Erreur serveur |

## Exemple d'implémentation (JavaScript/React Native)

```javascript
async function scanTicket(ticketCode, eventId, agentId) {
  try {
    const response = await fetch('https://votre-domaine.com/api/mobile/scan-ticket', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        ticket_code: ticketCode,
        event_id: eventId,
        agent_id: agentId
      })
    });

    const data = await response.json();

    if (data.success) {
      // Scan réussi
      console.log('✅ Ticket scanné:', data.data.participant_name);
      showSuccessAlert(data.message, data.data);
    } else {
      // Gestion des erreurs
      switch (data.code) {
        case 'TICKET_ALREADY_SCANNED':
          showWarningAlert('Ticket déjà scanné', data.ticket_info);
          break;
        case 'TICKET_WRONG_EVENT':
          showErrorAlert('Mauvais événement', 'Ce ticket est pour un autre événement');
          break;
        case 'AGENT_NOT_AUTHORIZED':
          showErrorAlert('Non autorisé', 'Vous n\'êtes pas autorisé pour cet événement');
          break;
        default:
          showErrorAlert('Erreur', data.message);
      }
    }
  } catch (error) {
    console.error('Erreur réseau:', error);
    showErrorAlert('Erreur', 'Impossible de se connecter au serveur');
  }
}
```

## Exemple d'implémentation (Dart/Flutter)

```dart
Future<void> scanTicket(String ticketCode, int eventId, String agentId) async {
  try {
    final response = await http.post(
      Uri.parse('https://votre-domaine.com/api/mobile/scan-ticket'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ticket_code': ticketCode,
        'event_id': eventId,
        'agent_id': agentId,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['success']) {
      // Scan réussi
      print('✅ Ticket scanné: ${data['data']['participant_name']}');
      showSuccessDialog(data['message'], data['data']);
    } else {
      // Gestion des erreurs
      switch (data['code']) {
        case 'TICKET_ALREADY_SCANNED':
          showWarningDialog('Ticket déjà scanné', data['ticket_info']);
          break;
        case 'TICKET_WRONG_EVENT':
          showErrorDialog('Mauvais événement', 'Ce ticket est pour un autre événement');
          break;
        case 'AGENT_NOT_AUTHORIZED':
          showErrorDialog('Non autorisé', 'Vous n\'êtes pas autorisé pour cet événement');
          break;
        default:
          showErrorDialog('Erreur', data['message']);
      }
    }
  } catch (e) {
    print('Erreur réseau: $e');
    showErrorDialog('Erreur', 'Impossible de se connecter au serveur');
  }
}
```

## Bonnes pratiques

1. **Feedback visuel immédiat** - Afficher une indication visuelle (couleur, son, vibration) lors d'un scan réussi ou échoué
2. **Gestion du mode hors-ligne** - Prévoir un système de cache pour scanner des tickets sans connexion (à synchroniser plus tard)
3. **Logs locaux** - Conserver un historique local des scans pour référence
4. **Retry automatique** - En cas d'erreur réseau, proposer de réessayer automatiquement
5. **Vérification visuelle** - Afficher les informations du participant après chaque scan pour permettre une vérification d'identité
6. **Statistiques en temps réel** - Afficher le nombre de tickets scannés vs total attendu

## Table d'historique (optionnelle)

Si vous souhaitez activer l'historique complet des scans, créez la table suivante :

```sql
CREATE TABLE ticket_scan_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_item_id INT NOT NULL,
    event_id INT NOT NULL,
    agent_id VARCHAR(255) NOT NULL,
    scan_date DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_item_id) REFERENCES ticket_item(ticket_item_id),
    FOREIGN KEY (event_id) REFERENCES events(event_id)
);
```

## Support

Pour toute question ou problème, veuillez contacter l'équipe technique Eventime.

---

**Version**: 1.0  
**Dernière mise à jour**: 13 février 2026  
**Contrôleur**: `App\Http\Controllers\MobileAppController::scanTicket`
