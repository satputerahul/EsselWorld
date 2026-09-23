/// One scan EVENT — not a final state snapshot. This distinction is
/// what makes multi-device sync safe: if Gate-1 admits 4 people and
/// Gate-2 admits 3 people on the SAME ticket (both offline, same
/// imported file), each device logs its own +4 and +3 events
/// independently. When both sync later, the backend sums the deltas
/// (4+3=7) instead of one device's "visitorsUsed=4" overwriting the
/// other's "visitorsUsed=3". Never sync a total — always sync an
/// increment.
class ScanLogEntry {
  final int? id; // local SQLite auto-increment
  final String eventId; // globally unique (uuid) — prevents double-counting
  // the same event twice if sync is retried after a partial failure.
  final String ticketId;
  final String scanStatus; // Valid / Partially Used / Already Used / Invalid
  final int visitorsEnteredThisEvent; // the DELTA admitted in this scan
  final String scanDateTime; // ISO string
  final String deviceInfo; // gate/device identifier
  final bool synced;

  ScanLogEntry({
    this.id,
    required this.eventId,
    required this.ticketId,
    required this.scanStatus,
    required this.visitorsEnteredThisEvent,
    required this.scanDateTime,
    required this.deviceInfo,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'ticket_id': ticketId,
      'scan_status': scanStatus,
      'visitors_entered': visitorsEnteredThisEvent,
      'scan_datetime': scanDateTime,
      'device_info': deviceInfo,
      'synced': synced ? 1 : 0,
    };
  }

  factory ScanLogEntry.fromMap(Map<String, dynamic> map) {
    return ScanLogEntry(
      id: map['id'] as int?,
      eventId: map['event_id'] as String,
      ticketId: map['ticket_id'] as String,
      scanStatus: map['scan_status'] as String,
      visitorsEnteredThisEvent: map['visitors_entered'] as int,
      scanDateTime: map['scan_datetime'] as String,
      deviceInfo: map['device_info'] as String,
      synced: (map['synced'] as int) == 1,
    );
  }
}