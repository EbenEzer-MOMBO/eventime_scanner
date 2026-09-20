import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache billets slim + file de scans (clés `offline_*`).
class OfflineStorageService {
  static const prefix = 'offline_';
  static const _queueKey = 'offline_scanned_queue';

  static String _ticketsKey(String eventId) => 'offline_tickets_$eventId';
  static String _sinceKey(String eventId) => 'offline_since_$eventId';
  static String _soldCountKey(String eventId) => 'offline_sold_$eventId';
  static String _upcomingKey(String agentId) => 'offline_upcoming_$agentId';
  static String _currentKey(String agentId) => 'offline_current_$agentId';

  static bool isOfflineKey(String key) => key.startsWith(prefix);

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Map<String, dynamic> slimFromParticipant(Map<String, dynamic> p) {
    return {
      'ticket_item_id': p['ticket_item_id'],
      'ticket_number': p['ticket_number']?.toString() ?? '',
      'participant_name': p['participant_name'],
      'participant_lastname': p['participant_lastname'],
      'status': p['status']?.toString() ?? '0',
    };
  }

  static bool isCanceledOrRefunded(String? status) {
    final s = (status ?? '').toLowerCase();
    return s == 'canceled' || s == 'refunded';
  }

  static bool isAlreadyScanned(String? status) {
    final s = (status ?? '').toString();
    return s == '1' || s.toLowerCase() == 'scanned';
  }

  static Future<Map<String, Map<String, dynamic>>> getTickets(
    String eventId,
  ) async {
    final raw = (await _prefs()).getString(_ticketsKey(eventId));
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return {};
    }
    final out = <String, Map<String, dynamic>>{};
    decoded.forEach((key, value) {
      if (value is Map) {
        out[key.toString()] = Map<String, dynamic>.from(value);
      }
    });
    return out;
  }

  static Future<void> saveTickets(
    String eventId,
    Map<String, Map<String, dynamic>> tickets,
  ) async {
    await (await _prefs()).setString(_ticketsKey(eventId), jsonEncode(tickets));
  }

  static Future<void> replaceFromParticipants(
    String eventId,
    List<Map<String, dynamic>> participants,
  ) async {
    final map = <String, Map<String, dynamic>>{};
    for (final p in participants) {
      final slim = slimFromParticipant(p);
      final number = slim['ticket_number'] as String;
      if (number.isEmpty) {
        continue;
      }
      if (isCanceledOrRefunded(slim['status']?.toString())) {
        continue;
      }
      map[number] = slim;
    }
    await saveTickets(eventId, map);
  }

  static Future<void> mergeParticipants(
    String eventId,
    List<Map<String, dynamic>> participants,
  ) async {
    final map = await getTickets(eventId);
    for (final p in participants) {
      final slim = slimFromParticipant(p);
      final number = slim['ticket_number'] as String;
      if (number.isEmpty) {
        continue;
      }
      if (isCanceledOrRefunded(slim['status']?.toString())) {
        map.remove(number);
        continue;
      }
      map[number] = slim;
    }
    await saveTickets(eventId, map);
  }

  static Future<Map<String, dynamic>?> getTicket(
    String eventId,
    String ticketNumber,
  ) async {
    final map = await getTickets(eventId);
    return map[ticketNumber];
  }

  static Future<void> markTicketScanned(String eventId, String ticketNumber) async {
    final map = await getTickets(eventId);
    final existing = map[ticketNumber];
    if (existing == null) {
      return;
    }
    existing['status'] = '1';
    map[ticketNumber] = existing;
    await saveTickets(eventId, map);
  }

  static Future<String?> getUpdatedSince(String eventId) async {
    return (await _prefs()).getString(_sinceKey(eventId));
  }

  static Future<void> setUpdatedSince(String eventId, String iso) async {
    await (await _prefs()).setString(_sinceKey(eventId), iso);
  }

  static Future<void> saveSoldCount(String eventId, int count) async {
    await (await _prefs()).setInt(_soldCountKey(eventId), count);
  }

  static Future<int?> getSoldCount(String eventId) async {
    return (await _prefs()).getInt(_soldCountKey(eventId));
  }

  static Future<List<Map<String, dynamic>>> getQueue() async {
    final raw = (await _prefs()).getString(_queueKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    await (await _prefs()).setString(_queueKey, jsonEncode(queue));
  }

  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    final queue = await getQueue();
    return queue.where((item) => item['synced'] != true).toList();
  }

  static Future<int> unsyncedCount() async {
    return (await getUnsynced()).length;
  }

  static Future<bool> hasPendingFor(String eventId, String ticketNumber) async {
    final pending = await getUnsynced();
    return pending.any(
      (item) =>
          item['event_id']?.toString() == eventId &&
          item['ticket_code']?.toString() == ticketNumber,
    );
  }

  static Future<void> enqueue({
    required String eventId,
    required String ticketCode,
    required String scannedAt,
  }) async {
    if (await hasPendingFor(eventId, ticketCode)) {
      return;
    }
    final queue = await getQueue();
    queue.add({
      'id': '${DateTime.now().microsecondsSinceEpoch}_$ticketCode',
      'event_id': eventId,
      'ticket_code': ticketCode,
      'scanned_at': scannedAt,
      'synced': false,
    });
    await _saveQueue(queue);
  }

  static Future<void> saveUpcomingEvents(
    String agentId,
    List<Map<String, dynamic>> events,
  ) async {
    await (await _prefs()).setString(_upcomingKey(agentId), jsonEncode(events));
  }

  static Future<List<Map<String, dynamic>>> getUpcomingEvents(
    String agentId,
  ) async {
    final raw = (await _prefs()).getString(_upcomingKey(agentId));
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> saveCurrentEvent(
    String agentId,
    Map<String, dynamic>? event,
  ) async {
    final prefs = await _prefs();
    if (event == null) {
      await prefs.remove(_currentKey(agentId));
      return;
    }
    await prefs.setString(_currentKey(agentId), jsonEncode(event));
  }

  static Future<Map<String, dynamic>?> getCurrentEvent(String agentId) async {
    final raw = (await _prefs()).getString(_currentKey(agentId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(decoded);
  }

  static Future<void> ackTicketCodes(List<String> ticketCodes) async {
    if (ticketCodes.isEmpty) {
      return;
    }
    final ack = ticketCodes.toSet();
    final queue = await getQueue();
    final kept = queue.where((item) {
      if (item['synced'] == true) {
        return false;
      }
      return !ack.contains(item['ticket_code']?.toString());
    }).toList();
    await _saveQueue(kept);
  }
}
