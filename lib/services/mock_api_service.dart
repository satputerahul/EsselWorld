import '../models/ticket_model.dart';

/// HARDCODED test data standing in for the real webservice, since no
/// backend is available yet. Modeled on the real ticket samples
/// shared (BookMyShow "M-TICKETS", District app booking, and the
/// official Esselworld E-Ticket with 7 visitors on one booking).
///
/// SWAP THIS FILE for a real ApiService (HTTP calls) once the
/// backend team provides endpoints. Screens/services call the same
/// method names either way.
class MockApiService {
  // In-memory "server-side" state for this test session, seeded with
  // data resembling your real samples. Resets when the app restarts —
  // this is a STAND-IN for a real backend database, not persistence.
  static final Map<String, Ticket> _serverTickets = {
    'EW-00673105': Ticket(
      ticketId: 'EW-00673105',
      ticketStatus: 'Valid',
      ticketType: 'REGULAR ADULT - Water Kingdom',
      validDate: '2026-09-03',
      totalVisitors: 7,
      visitorsUsed: 0,
    ),
    '2SZ5MD': Ticket(
      ticketId: '2SZ5MD', // BookMyShow confirmation code
      ticketStatus: 'Valid',
      ticketType: 'M-Ticket - Water Kingdom',
      validDate: '2026-09-03',
      totalVisitors: 1,
      visitorsUsed: 0,
    ),
    'WKMI0M1NK10J3T': Ticket(
      ticketId: 'WKMI0M1NK10J3T', // District app booking id
      ticketStatus: 'Valid',
      ticketType: 'Mega Splash Offer + Duo Offer',
      validDate: '2026-08-28',
      totalVisitors: 2,
      visitorsUsed: 0,
    ),
    'EW-1004': Ticket(
      ticketId: 'EW-1004',
      ticketStatus: 'Used',
      ticketType: 'General',
      validDate: '2026-09-03',
      totalVisitors: 1,
      visitorsUsed: 1,
    ),
    'EW-1006': Ticket(
      ticketId: 'EW-1006',
      ticketStatus: 'Cancelled',
      ticketType: 'General',
      validDate: '2026-09-03',
      totalVisitors: 1,
      visitorsUsed: 0,
    ),
    // Old-dated ticket — per requirement, still scannable/valid today
    // even though valid_date has passed.
    'EW-0922': Ticket(
      ticketId: 'EW-0922',
      ticketStatus: 'Valid',
      ticketType: 'General',
      validDate: '2026-09-22',
      totalVisitors: 4,
      visitorsUsed: 0,
    ),
  };

  static Future<Ticket?> fetchTicket(String ticketId) async {
    await Future.delayed(const Duration(milliseconds: 400)); // simulate latency
    final t = _serverTickets[ticketId];
    if (t == null) return null;
    // return a copy so callers can't mutate "server" state directly
    return Ticket(
      ticketId: t.ticketId,
      ticketStatus: t.ticketStatus,
      ticketType: t.ticketType,
      validDate: t.validDate,
      totalVisitors: t.totalVisitors,
      visitorsUsed: t.visitorsUsed,
      lastScannedAt: t.lastScannedAt,
    );
  }

  /// Simulates the backend accepting an increment (delta) rather than
  /// a final total — mirrors how real sync should work, so swapping
  /// in a real API later requires no logic changes elsewhere.
  static Future<bool> admitVisitors(
    String ticketId,
    int count, {
    required String deviceInfo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final t = _serverTickets[ticketId];
    if (t == null) return false;

    t.visitorsUsed += count;
    t.ticketStatus = t.visitorsUsed >= t.totalVisitors ? 'Used' : 'Partially Used';
    return true;
  }

  /// Simulates the sync endpoint — accepts a batch of scan-log
  /// deltas and returns which event_ids were accepted. In a real
  /// backend this would sum deltas per ticket and reject/flag any
  /// that would push visitorsUsed above totalVisitors.
  static Future<List<String>> syncScanEvents(
    List<Map<String, dynamic>> events,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final accepted = <String>[];

    for (final event in events) {
      final ticketId = event['ticket_id'] as String;
      final delta = event['visitors_entered'] as int;
      final eventId = event['event_id'] as String;

      final t = _serverTickets[ticketId];
      if (t == null) {
        // Ticket not on "server" (test data gap) — still accept the
        // event so local sync doesn't get stuck retrying forever in
        // this mock; a real backend would handle this explicitly.
        accepted.add(eventId);
        continue;
      }

      final wouldBeTotal = t.visitorsUsed + delta;
      if (wouldBeTotal > t.totalVisitors) {
        // Conflict: combined scans from multiple devices exceed the
        // ticket's visitor count. In this mock we still accept it
        // but cap at totalVisitors, and flag for manual review in a
        // real system. This is exactly the "30 on device A + 50 on
        // device B" scenario from the requirements.
        t.visitorsUsed = t.totalVisitors;
      } else {
        t.visitorsUsed = wouldBeTotal;
      }
      t.ticketStatus = t.visitorsUsed >= t.totalVisitors ? 'Used' : 'Partially Used';
      accepted.add(eventId);
    }

    return accepted;
  }
}