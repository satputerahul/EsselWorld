/// Represents one ticket/booking row. A single QR can cover multiple
/// visitors (e.g. "REGULAR ADULT x 7" on one booking, as seen on real
/// Esselworld e-tickets) — so instead of a simple used/not-used flag,
/// we track how many of the total visitors have entered so far.
///
/// IMPORTANT: valid_date is informational only, NOT a hard gate check.
/// A ticket dated a few days ago (or a few days ahead) can still be
/// scanned and admitted — per requirement, guests who couldn't come
/// on their original date should still be let in later.
class Ticket {
  final String ticketId;       // Booking No. / Confirmation code from QR
  String ticketStatus;         // Valid / Partially Used / Used / Cancelled / Invalid
  final String ticketType;     // e.g. REGULAR ADULT, VIP, General
  final String validDate;      // yyyy-MM-dd — informational only
  final int totalVisitors;     // total people this ticket covers (e.g. 7)
  int visitorsUsed;            // how many have entered so far (e.g. 4)
  String? lastScannedAt;

  Ticket({
    required this.ticketId,
    required this.ticketStatus,
    required this.ticketType,
    required this.validDate,
    required this.totalVisitors,
    this.visitorsUsed = 0,
    this.lastScannedAt,
  });

  int get visitorsRemaining => totalVisitors - visitorsUsed;
  bool get isFullyUsed => visitorsUsed >= totalVisitors;
  bool get isPartiallyUsed => visitorsUsed > 0 && !isFullyUsed;

  Map<String, dynamic> toMap() {
    return {
      'ticket_id': ticketId,
      'ticket_status': ticketStatus,
      'ticket_type': ticketType,
      'valid_date': validDate,
      'total_visitors': totalVisitors,
      'visitors_used': visitorsUsed,
      'last_scanned_at': lastScannedAt,
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      ticketId: map['ticket_id'] as String,
      ticketStatus: map['ticket_status'] as String,
      ticketType: map['ticket_type'] as String,
      validDate: map['valid_date'] as String,
      totalVisitors: map['total_visitors'] as int,
      visitorsUsed: map['visitors_used'] as int,
      lastScannedAt: map['last_scanned_at'] as String?,
    );
  }

  /// Parses one row from the CSV supplied by Esselworld/backend team.
  /// Expected columns: ticket_id, ticket_status, ticket_type, valid_date, total_visitors
  /// (total_visitors defaults to 1 if the column is missing, for
  /// backward compatibility with simpler CSVs)
  factory Ticket.fromCsvRow(List<dynamic> row) {
    return Ticket(
      ticketId: row[0].toString().trim(),
      ticketStatus: row[1].toString().trim(),
      ticketType: row[2].toString().trim(),
      validDate: row[3].toString().trim(),
      totalVisitors:
          row.length > 4 ? (int.tryParse(row[4].toString().trim()) ?? 1) : 1,
    );
  }
}

enum VerifyStatus { valid, partiallyUsed, alreadyUsed, invalid, error }

class VerifyResult {
  final VerifyStatus status;
  final Ticket? ticket;
  final bool wasOffline;
  final int? visitorsEnteredThisScan; // how many were admitted in THIS action
  VerifyResult(
    this.status,
    this.ticket, {
    required this.wasOffline,
    this.visitorsEnteredThisScan,
  });
}