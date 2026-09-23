import '../db/db_helper.dart';
import 'mock_api_service.dart';
import 'connectivity_service.dart';

/// Uploads unsynced scan EVENTS (deltas) once connectivity returns.
/// Because every event carries its own visitorsEnteredThisEvent
/// (never a final total), syncing from multiple devices that shared
/// the same imported file is safe — the backend sums deltas rather
/// than one device's state overwriting another's.
class SyncService {
  static bool _isSyncing = false;

  static Future<SyncResult> syncNow() async {
    if (_isSyncing) {
      return SyncResult(attempted: 0, succeeded: 0, skippedAlreadyRunning: true);
    }

    _isSyncing = true;
    try {
      final online = await ConnectivityService.checkNowAndReturn();
      if (!online) {
        return SyncResult(attempted: 0, succeeded: 0, reason: 'No connection to backend');
      }

      final unsynced = await DbHelper.instance.getUnsyncedScanLogs();
      if (unsynced.isEmpty) {
        return SyncResult(attempted: 0, succeeded: 0);
      }

      final payload = unsynced
          .map((e) => {
                'event_id': e.eventId,
                'ticket_id': e.ticketId,
                'scan_status': e.scanStatus,
                'visitors_entered': e.visitorsEnteredThisEvent,
                'scan_datetime': e.scanDateTime,
                'device_info': e.deviceInfo,
              })
          .toList();

      final acceptedEventIds = await MockApiService.syncScanEvents(payload);

      final idsToMark = unsynced
          .where((e) => acceptedEventIds.contains(e.eventId))
          .map((e) => e.id!)
          .toList();

      await DbHelper.instance.markScanLogsSynced(idsToMark);

      return SyncResult(attempted: unsynced.length, succeeded: idsToMark.length);
    } catch (e) {
      return SyncResult(attempted: 0, succeeded: 0, reason: e.toString());
    } finally {
      _isSyncing = false;
    }
  }
}

class SyncResult {
  final int attempted;
  final int succeeded;
  final String? reason;
  final bool skippedAlreadyRunning;

  SyncResult({
    required this.attempted,
    required this.succeeded,
    this.reason,
    this.skippedAlreadyRunning = false,
  });

  bool get hadNothingToSync => attempted == 0 && reason == null;
}