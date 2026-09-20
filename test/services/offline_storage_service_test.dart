import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eventime_scanner/config/media_urls.dart';
import 'package:eventime_scanner/services/offline_storage_service.dart';
import 'package:eventime_scanner/services/offline_sync_ack.dart';
import 'package:eventime_scanner/services/scan_window.dart';
import 'package:eventime_scanner/services/scanner_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('cache slim sans email et retraits canceled', () async {
    await OfflineStorageService.replaceFromParticipants('10', [
      {
        'ticket_item_id': 1,
        'ticket_number': 'TKT-A',
        'participant_name': 'Jean',
        'participant_lastname': 'Test',
        'participant_email': 'secret@test.local',
        'status': '0',
      },
    ]);

    final cached = await OfflineStorageService.getTicket('10', 'TKT-A');
    expect(cached, isNotNull);
    expect(cached!.containsKey('participant_email'), isFalse);
    expect(cached['participant_name'], 'Jean');

    await OfflineStorageService.mergeParticipants('10', [
      {
        'ticket_number': 'TKT-A',
        'status': 'canceled',
        'participant_name': 'Jean',
      },
    ]);
    expect(await OfflineStorageService.getTicket('10', 'TKT-A'), isNull);
  });

  test('file ack ok et already_scanned', () async {
    expect(shouldAckBatchResult('ok'), isTrue);
    expect(shouldAckBatchResult('already_scanned'), isTrue);
    expect(shouldAckBatchResult('not_found'), isFalse);

    await OfflineStorageService.enqueue(
      eventId: '10',
      ticketCode: 'TKT-A',
      scannedAt: '2026-09-19T12:00:00Z',
    );
    expect(await OfflineStorageService.unsyncedCount(), 1);

    await OfflineStorageService.ackTicketCodes(['TKT-A']);
    expect(await OfflineStorageService.unsyncedCount(), 0);
  });

  test('clearSession conserve les clés offline_*', () async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'tok',
      'id_agent': '1',
      'offline_tickets_10': '{"TKT-A":{"status":"0","ticket_number":"TKT-A"}}',
      'offline_scanned_queue': '[]',
    });

    await ScannerApiClient.clearSession();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('access_token'), isNull);
    expect(prefs.getString('id_agent'), isNull);
    expect(prefs.getString('offline_tickets_10'), isNotNull);
    expect(prefs.getString('offline_scanned_queue'), '[]');
  });

  test('fenêtre de scan horloge locale', () {
    final start = DateTime(2026, 9, 19, 18);
    final end = DateTime(2026, 9, 19, 23);
    expect(
      ScanWindow.isOpen(
        start: start,
        end: end,
        scanHours: 1,
        now: DateTime(2026, 9, 19, 16, 59),
      ),
      isFalse,
    );
    expect(
      ScanWindow.isOpen(
        start: start,
        end: end,
        scanHours: 1,
        now: DateTime(2026, 9, 19, 17),
      ),
      isTrue,
    );
    expect(
      ScanWindow.isOpen(
        start: start,
        end: end,
        scanHours: 1,
        now: DateTime(2026, 9, 19, 23),
      ),
      isFalse,
    );
  });

  test('cache événements accueil survit au timeout', () async {
    await OfflineStorageService.saveUpcomingEvents('9', [
      {'event_id': 1, 'title': 'Soirée'},
    ]);
    await OfflineStorageService.saveCurrentEvent('9', {
      'event_id': 2,
      'title': 'Live',
    });

    final upcoming = await OfflineStorageService.getUpcomingEvents('9');
    final current = await OfflineStorageService.getCurrentEvent('9');
    expect(upcoming.single['title'], 'Soirée');
    expect(current?['title'], 'Live');
  });

  test('URLs médias n\'utilisent plus version2.eventime.ga', () {
    expect(
      MediaUrls.eventImage('abc.jpg'),
      contains('eventime.ga/public/storage'),
    );
    expect(MediaUrls.eventImage('abc.jpg'), isNot(contains('version2')));
  });

  test('compteur vendus persisté sans compter la liste', () async {
    await OfflineStorageService.saveSoldCount('10', 42);
    expect(await OfflineStorageService.getSoldCount('10'), 42);
    await OfflineStorageService.replaceFromParticipants('10', [
      {
        'ticket_number': 'A',
        'status': '0',
        'participant_name': 'A',
      },
    ]);
    expect(await OfflineStorageService.getSoldCount('10'), 42);
  });
}
