import 'package:flutter/material.dart';

import '../services/offline_sync_service.dart';

class SyncQueueBadge extends StatelessWidget {
  const SyncQueueBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: OfflineSyncService.instance.unsyncedCount,
      builder: (context, count, _) {
        final pending = count > 0;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Tooltip(
            message: pending ? '$count scan(s) en file' : 'Synchronisé',
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: pending
                    ? const Color(0xFFFFB300)
                    : const Color(0xFF8BC34A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
