import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:eventime_scanner/Scanner/succes_pages.dart';
import 'package:eventime_scanner/config/api_config.dart';
import 'package:eventime_scanner/services/offline_storage_service.dart';
import 'package:eventime_scanner/services/offline_sync_service.dart';
import 'package:eventime_scanner/services/scan_window.dart';
import 'package:eventime_scanner/services/scanner_api_client.dart';
import 'package:eventime_scanner/widgets/sync_queue_badge.dart';

class QRViewExample extends StatefulWidget {
  @override
  _QRViewExampleState createState() => _QRViewExampleState();
  var id_event, evenement, id_agent;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? scanHours;

  QRViewExample({
    super.key,
    this.id_event,
    this.evenement,
    this.id_agent,
    this.startDate,
    this.endDate,
    this.scanHours,
  });
}

class _QRViewExampleState extends State<QRViewExample>
    with WidgetsBindingObserver {
  late MobileScannerController _controller;
  String qrCodeData = "Aucun code QR scanné";
  bool isDataSent = false;
  bool isFlashOn = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController();
    unawaited(OfflineSyncService.instance.start());
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(
        OfflineSyncService.pullParticipants(
          widget.id_event.toString(),
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(OfflineSyncService.instance.flushQueue());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(125, 184, 78, 1),
        title: Text(widget.evenement, style: TextStyle(color: Colors.white)),
        actions: const [SyncQueueBadge()],
      ),
      body: Column(
        children: [
          Expanded(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onQRViewCreated,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color.fromRGBO(125, 184, 78, 1),
                          width: 4.0,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FloatingActionButton(
                        backgroundColor: Color.fromRGBO(125, 184, 78, 1),
                        onPressed: () {
                          _controller.toggleTorch();
                          setState(() {
                            isFlashOn = !isFlashOn;
                          });
                        },
                        child: Icon(
                          isFlashOn ? Icons.flash_off : Icons.flash_on,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'Code QR scanné : $qrCodeData',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          qrCodeData = code;
        });
        if (qrCodeData != "Aucun code QR scanné" && !isDataSent) {
          sendQRCodeData(qrCodeData);
          isDataSent = true;
        }
      }
    }
  }

  snackbar(text, Color couleur) {
    final snackBar = SnackBar(
      backgroundColor: couleur,
      content: Text(text, style: TextStyle(color: Colors.white)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  bool _windowOk() {
    if (widget.startDate == null ||
        widget.endDate == null ||
        widget.scanHours == null) {
      return true;
    }
    return ScanWindow.isOpen(
      start: widget.startDate!,
      end: widget.endDate!,
      scanHours: widget.scanHours!,
    );
  }

  Future<void> sendQRCodeData(numeroTicket) async {
    final ticketCode = numeroTicket.toString();
    final eventId = widget.id_event.toString();
    final scannedAt = DateTime.now().toUtc().toIso8601String();

    if (!_windowOk()) {
      final message = ScanWindow.refusalMessage(
            start: widget.startDate!,
            end: widget.endDate!,
            scanHours: widget.scanHours!,
          ) ??
          'Scan non autorisé';
      await _showOutcome(
        success: false,
        message: message,
        ticketData: {'success': false, 'message': message},
      );
      return;
    }

    try {
      final cached = await OfflineStorageService.getTicket(eventId, ticketCode);
      if (cached != null) {
        await _handleCachedTicket(cached, ticketCode, eventId, scannedAt);
        return;
      }

      await _handleOnlineFallback(ticketCode, eventId, scannedAt);
    } catch (e) {
      snackbar("Erreur lors de l'envoi des données", Colors.redAccent);
      setState(() {
        isDataSent = false;
        qrCodeData = "Aucun code QR scanné";
      });
    }
  }

  Future<void> _handleCachedTicket(
    Map<String, dynamic> cached,
    String ticketCode,
    String eventId,
    String scannedAt,
  ) async {
    final status = cached['status']?.toString();
    final name =
        '${cached['participant_name'] ?? ''} ${cached['participant_lastname'] ?? ''}'
            .trim();

    if (OfflineStorageService.isCanceledOrRefunded(status)) {
      await _showOutcome(
        success: false,
        message: 'Ce ticket a été annulé ou remboursé',
        ticketData: {
          'success': false,
          'code': 'TICKET_INVALID_STATUS',
          'message': 'Ce ticket a été annulé ou remboursé',
        },
      );
      return;
    }

    if (OfflineStorageService.isAlreadyScanned(status) ||
        await OfflineStorageService.hasPendingFor(eventId, ticketCode)) {
      await _showOutcome(
        success: false,
        message: '⚠️ Ce ticket a déjà été scanné',
        ticketData: {
          'success': false,
          'code': 'TICKET_ALREADY_SCANNED',
          'message': 'Ce ticket a déjà été scanné',
          'ticket_info': {
            'ticket_number': ticketCode,
            'participant_name': name,
          },
        },
      );
      return;
    }

    await OfflineStorageService.markTicketScanned(eventId, ticketCode);
    await OfflineStorageService.enqueue(
      eventId: eventId,
      ticketCode: ticketCode,
      scannedAt: scannedAt,
    );
    unawaited(OfflineSyncService.instance.flushQueue());

    await _showOutcome(
      success: true,
      message: 'Ticket scanné avec succès',
      ticketData: {
        'success': true,
        'code': 'SCAN_SUCCESS',
        'message': 'Ticket scanné avec succès',
        'data': {
          'ticket_number': ticketCode,
          'participant_name': name,
          'scan_time': scannedAt,
        },
      },
    );
  }

  Future<void> _handleOnlineFallback(
    String ticketCode,
    String eventId,
    String scannedAt,
  ) async {
    try {
      final reponse = await ScannerApiClient.post(
        ApiConfig.scanTicket,
        {
          'ticket_code': ticketCode,
          'event_id': int.parse(eventId),
          'agent_id': widget.id_agent?.toString() ?? '',
          'scanned_at': scannedAt,
        },
        context: context,
        timeout: const Duration(seconds: 3),
      );

      if (reponse.statusCode == 200 && reponse.body.trim().isNotEmpty) {
        final data = json.decode(reponse.body);
        if (data['success'] == true) {
          await OfflineStorageService.mergeParticipants(eventId, [
            {
              'ticket_number': ticketCode,
              'participant_name': data['data']?['participant_name'],
              'status': '1',
            },
          ]);
          await _showOutcome(
            success: true,
            message: data['message'] ?? 'Ticket scanné avec succès',
            ticketData: data,
          );
          return;
        }
        await _showApiError(data);
        return;
      }

      if (reponse.body.trim().isNotEmpty) {
        try {
          await _showApiError(json.decode(reponse.body));
          return;
        } catch (_) {}
      }

      await _showOutcome(
        success: false,
        message: 'Ticket hors cache — réseau indisponible',
        ticketData: {
          'success': false,
          'code': 'TICKET_NOT_IN_CACHE',
          'message': 'Ticket hors cache — réseau indisponible',
        },
      );
    } catch (_) {
      await _showOutcome(
        success: false,
        message: 'Ticket hors cache — réseau indisponible',
        ticketData: {
          'success': false,
          'code': 'TICKET_NOT_IN_CACHE',
          'message': 'Ticket hors cache — réseau indisponible',
        },
      );
    }
  }

  Future<void> _showApiError(dynamic data) async {
    final errorCode = data is Map ? data['code'] ?? '' : '';
    String message =
        data is Map ? (data['message'] ?? 'Erreur lors du scan') : 'Erreur';
    switch (errorCode) {
      case 'TICKET_ALREADY_SCANNED':
        message = '⚠️ Ce ticket a déjà été scanné';
        break;
      case 'TICKET_WRONG_EVENT':
        message = '❌ Ce ticket n\'appartient pas à cet événement';
        break;
      case 'AGENT_NOT_AUTHORIZED':
        message = '❌ Vous n\'êtes pas autorisé pour cet événement';
        break;
      case 'TICKET_NOT_FOUND':
        message = '❌ Ticket non trouvé';
        break;
      case 'TICKET_INVALID_STATUS':
        message = '❌ Ce ticket a été annulé ou remboursé';
        break;
      case 'EVENT_NOT_FOUND':
        message = '❌ Événement non trouvé';
        break;
    }
    await _showOutcome(
      success: false,
      message: message,
      ticketData: data is Map ? Map<String, dynamic>.from(data) : {},
    );
  }

  Future<void> _showOutcome({
    required bool success,
    required String message,
    required Map<String, dynamic> ticketData,
  }) async {
    snackbar(message, success ? Colors.lightGreen : Colors.redAccent);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => Success(
              message: message,
              color: success ? Colors.lightGreen : Colors.redAccent,
              ticketData: ticketData,
            ),
      ),
    );
    setState(() {
      isDataSent = result ?? false;
      qrCodeData = "Aucun code QR scanné";
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }
}
