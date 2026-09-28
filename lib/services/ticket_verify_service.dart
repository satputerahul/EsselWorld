import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/scan_log_model.dart';
import '../db/db_helper.dart';
import 'mock_api_service.dart';
import 'connectivity_service.dart';
import 'device_id_service.dart';

class TicketLookupResult {
  final VerifyStatus status;
  final Ticket? ticket;
  final bool wasOffline;
  TicketLookupResult(this.status, this.ticket, {required this.wasOffline});
}

class TicketVerifyService {
  static final _uuid = Uuid();


  static Future<TicketLookupResult> lookup(String scannedCode) async {
    final isOnline = await ConnectivityService.checkNowAndReturn();

    if (isOnline) {
      try {
        final ticket = await MockApiService.fetchTicket(scannedCode);
        return _classifyLookup(ticket, wasOffline: false);
      } catch (_) {
        return _lookupOffline(scannedCode);
      }
    }
    return _lookupOffline(scannedCode);
  }

  static Future<TicketLookupResult> _lookupOffline(String scannedCode) async {
    final ticket = await DbHelper.instance.getTicketById(scannedCode);
    return _classifyLookup(ticket, wasOffline: true);
  }

  static TicketLookupResult _classifyLookup(Ticket? ticket, {required bool wasOffline}) {
    if (ticket == null) {
      return TicketLookupResult(VerifyStatus.invalid, null, wasOffline: wasOffline);
    }
    if (ticket.ticketStatus == 'Cancelled' || ticket.ticketStatus == 'Invalid') {
      return TicketLookupResult(VerifyStatus.invalid, ticket, wasOffline: wasOffline);
    }
    if (ticket.isFullyUsed) {
      return TicketLookupResult(VerifyStatus.alreadyUsed, ticket, wasOffline: wasOffline);
    }
    if (ticket.isPartiallyUsed) {
      return TicketLookupResult(VerifyStatus.partiallyUsed, ticket, wasOffline: wasOffline);
    }

    return TicketLookupResult(VerifyStatus.valid, ticket, wasOffline: wasOffline);
  }

  // ---------------- STEP 2: ADMIT VISITORS ----------------

  static Future<VerifyResult> admitVisitors(
    String scannedCode,
    int count,
  ) async {
    final deviceInfo = await DeviceIdService.getDeviceTag();
    final isOnline = await ConnectivityService.checkNowAndReturn();

    if (isOnline) {
      try {
        return await _admitOnline(scannedCode, count, deviceInfo);
      } catch (_) {
        return _admitOffline(scannedCode, count, deviceInfo);
      }
    }
    return _admitOffline(scannedCode, count, deviceInfo);
  }

  static Future<VerifyResult> _admitOnline(
    String scannedCode,
    int count,
    String deviceInfo,
  ) async {
    final ok = await MockApiService.admitVisitors(scannedCode, count, deviceInfo: deviceInfo);
    if (!ok) {
      return VerifyResult(VerifyStatus.invalid, null, wasOffline: false);
    }
    final updated = await MockApiService.fetchTicket(scannedCode);
    final status = updated!.isFullyUsed ? VerifyStatus.valid : VerifyStatus.partiallyUsed;
    return VerifyResult(
      status,
      updated,
      wasOffline: false,
      visitorsEnteredThisScan: count,
    );
  }

  /// Offline admit: updates this device's LOCAL tickets table (fast,
  /// immediate feedback for staff) AND appends an event to scan_logs
  /// (the delta, for safe multi-device sync later). Requirement #6/#7.
  static Future<VerifyResult> _admitOffline(
    String scannedCode,
    int count,
    String deviceInfo,
  ) async {
    final db = DbHelper.instance;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final nowDisplay = DateFormat('hh:mm a, dd MMM').format(now);

    final updatedTicket = await db.incrementVisitorsUsed(scannedCode, count, nowDisplay);

    await db.insertScanLog(ScanLogEntry(
      eventId: _uuid.v4(),
      ticketId: scannedCode,
      scanStatus: updatedTicket.isFullyUsed ? 'Used' : 'Partially Used',
      visitorsEnteredThisEvent: count,
      scanDateTime: nowIso,
      deviceInfo: deviceInfo,
    ));

    final status =
        updatedTicket.isFullyUsed ? VerifyStatus.valid : VerifyStatus.partiallyUsed;

    return VerifyResult(
      status,
      updatedTicket,
      wasOffline: true,
      visitorsEnteredThisScan: count,
    );
  }
}