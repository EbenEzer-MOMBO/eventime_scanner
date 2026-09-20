import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../config/api_config.dart';
import 'offline_storage_service.dart';
import 'offline_sync_ack.dart';
import 'scanner_api_client.dart';

class ParticipantsPullResult {
  final List<Map<String, dynamic>> items;
  final int? count;
  final bool delta;

  ParticipantsPullResult({
    required this.items,
    required this.count,
    required this.delta,
  });
}

class OfflineSyncService with WidgetsBindingObserver {
  OfflineSyncService._();
  static final OfflineSyncService instance = OfflineSyncService._();

  final ValueNotifier<int> unsyncedCount = ValueNotifier<int>(0);

  Timer? _timer;
  bool _flushing = false;
  bool _started = false;
  int _backoffSeconds = 8;

  Future<void> start() async {
    if (_started) {
      await refreshCount();
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(flushQueue());
    });
    await refreshCount();
    unawaited(flushQueue());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(flushQueue());
    }
  }

  Future<void> refreshCount() async {
    unsyncedCount.value = await OfflineStorageService.unsyncedCount();
  }

  Future<void> flushQueue() async {
    if (_flushing) {
      return;
    }
    _flushing = true;
    try {
      final pending = await OfflineStorageService.getUnsynced();
      unsyncedCount.value = pending.length;
      if (pending.isEmpty) {
        _backoffSeconds = 8;
        return;
      }

      final byEvent = <String, List<Map<String, dynamic>>>{};
      for (final item in pending) {
        final eventId = item['event_id']?.toString() ?? '';
        byEvent.putIfAbsent(eventId, () => []).add(item);
      }

      for (final entry in byEvent.entries) {
        final eventId = int.tryParse(entry.key);
        if (eventId == null) {
          continue;
        }
        final scans = entry.value;
        for (var i = 0; i < scans.length; i += 100) {
          final chunk = scans.sublist(
            i,
            i + 100 > scans.length ? scans.length : i + 100,
          );
          final ok = await _sendChunk(eventId, chunk);
          if (!ok) {
            return;
          }
        }
      }
      _backoffSeconds = 8;
    } finally {
      _flushing = false;
      await refreshCount();
    }
  }

  Future<bool> _sendChunk(
    int eventId,
    List<Map<String, dynamic>> chunk,
  ) async {
    try {
      final response = await ScannerApiClient.post(
        ApiConfig.scanTicketBatch,
        {
          'event_id': eventId,
          'scans': chunk
              .map(
                (item) => {
                  'ticket_code': item['ticket_code'],
                  'scanned_at': item['scanned_at'],
                },
              )
              .toList(),
        },
        timeout: Duration(seconds: _backoffSeconds.clamp(8, 30)),
        handleUnauthorized: false,
      );

      if (response.statusCode == 401) {
        return false;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _backoffSeconds = (_backoffSeconds * 2).clamp(8, 30);
        return false;
      }

      final body = jsonDecode(response.body);
      final results = body is Map ? body['results'] : null;
      final acked = <String>[];
      if (results is List) {
        for (final row in results) {
          if (row is! Map) {
            continue;
          }
          final code = row['ticket_code']?.toString();
          final result = row['result']?.toString() ?? '';
          if (code != null && shouldAckBatchResult(result)) {
            acked.add(code);
          }
        }
      }
      await OfflineStorageService.ackTicketCodes(acked);
      return true;
    } catch (_) {
      _backoffSeconds = (_backoffSeconds * 2).clamp(8, 30);
      return false;
    }
  }

  static Future<ParticipantsPullResult?> pullParticipants(
    String eventId, {
    bool full = false,
  }) async {
    final body = <String, dynamic>{'event_id': eventId};
    if (!full) {
      final since = await OfflineStorageService.getUpdatedSince(eventId);
      if (since != null && since.isNotEmpty) {
        body['updated_since'] = since;
      }
    }

    try {
      final response = await ScannerApiClient.post(
        ApiConfig.participantsList,
        body,
        timeout: const Duration(seconds: 15),
      );
      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        return null;
      }
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is! Map || jsonResponse['success'] != true) {
        return null;
      }
      final data = jsonResponse['data'];
      if (data is! List) {
        return null;
      }
      final list = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final isDelta = jsonResponse['delta'] == true;
      if (isDelta && !full) {
        await OfflineStorageService.mergeParticipants(eventId, list);
      } else {
        await OfflineStorageService.replaceFromParticipants(eventId, list);
      }
      final serverTime = jsonResponse['server_time']?.toString();
      if (serverTime != null && serverTime.isNotEmpty) {
        await OfflineStorageService.setUpdatedSince(eventId, serverTime);
      }
      final apiCount = jsonResponse['count'];
      final count = apiCount is int
          ? apiCount
          : int.tryParse(apiCount?.toString() ?? '');
      if (count != null) {
        await OfflineStorageService.saveSoldCount(eventId, count);
      }
      return ParticipantsPullResult(
        items: list,
        count: count,
        delta: isDelta && !full,
      );
    } catch (_) {
      return null;
    }
  }
}
