import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ticket_model.dart';
import '../models/scan_log_model.dart';

/// Persistent (physical, file-based) SQLite database — NOT in-memory.
/// openDatabase() with a real file path below always creates a file
/// on disk under the app's data directory, which survives app close
/// and device restart. (in-memory mode would instead use the special
/// path ":memory:", which we deliberately never use here.)
///
/// Two tables:
///  - tickets    : local mirror of the imported booking file. Every
///                 scan reads/updates THIS table, never the CSV.
///                 visitors_used is the CURRENT LOCAL count on this
///                 device — see scan_logs for why this is safe even
///                 across multiple devices sharing the same import.
///  - scan_logs  : an APPEND-ONLY event log. Every scan action adds
///                 one row with a delta (how many entered in THAT
///                 scan), never a final total. This is what makes
///                 multi-device merging safe — deltas from different
///                 devices simply add up, they never overwrite.
class DbHelper {
  static final DbHelper instance = DbHelper._internal();
  DbHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath(); // physical on-disk path
    final path = join(dbPath, 'esselworld_scanner.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tickets (
            ticket_id TEXT PRIMARY KEY,
            ticket_status TEXT NOT NULL,
            ticket_type TEXT NOT NULL,
            valid_date TEXT NOT NULL,
            total_visitors INTEGER NOT NULL DEFAULT 1,
            visitors_used INTEGER NOT NULL DEFAULT 0,
            last_scanned_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE scan_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id TEXT NOT NULL UNIQUE,
            ticket_id TEXT NOT NULL,
            scan_status TEXT NOT NULL,
            visitors_entered INTEGER NOT NULL,
            scan_datetime TEXT NOT NULL,
            device_info TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ---------------- TICKETS TABLE ----------------

  /// Wipes and reloads the tickets table from a fresh CSV import.
  /// Wrapped in a transaction so a large import doesn't leave the
  /// table half-populated if interrupted.
  ///
  /// IMPORTANT for the "same file imported to 2-3 devices" scenario:
  /// each device imports the SAME starting file (visitors_used = 0
  /// for everyone), then tracks its OWN local scans independently.
  /// The scan_logs event table is what reconciles the true combined
  /// total later during sync — this local tickets table is only this
  /// device's working view, used for fast local verification.
  Future<void> replaceAllTickets(List<Ticket> tickets) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tickets');
      final batch = txn.batch();
      for (final t in tickets) {
        batch.insert('tickets', t.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Ticket?> getTicketById(String ticketId) async {
    final db = await database;
    final rows = await db.query(
      'tickets',
      where: 'ticket_id = ?',
      whereArgs: [ticketId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Ticket.fromMap(rows.first);
  }

  /// Increments visitors_used by [count] on THIS device's local copy,
  /// and updates status accordingly. Does not touch other devices —
  /// they have their own separate local database files.
  Future<Ticket> incrementVisitorsUsed(
    String ticketId,
    int count,
    String scannedAt,
  ) async {
    final db = await database;
    final ticket = await getTicketById(ticketId);
    if (ticket == null) throw Exception('Ticket not found: $ticketId');

    final newUsed = ticket.visitorsUsed + count;
    final newStatus = newUsed >= ticket.totalVisitors ? 'Used' : 'Partially Used';

    await db.update(
      'tickets',
      {
        'visitors_used': newUsed,
        'ticket_status': newStatus,
        'last_scanned_at': scannedAt,
      },
      where: 'ticket_id = ?',
      whereArgs: [ticketId],
    );

    ticket.visitorsUsed = newUsed;
    ticket.ticketStatus = newStatus;
    ticket.lastScannedAt = scannedAt;
    return ticket;
  }

  Future<int> getTicketCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM tickets');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------------- SCAN LOGS TABLE (event log) ----------------

  Future<void> insertScanLog(ScanLogEntry entry) async {
    final db = await database;
    await db.insert(
      'scan_logs',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // event_id is UNIQUE
    );
  }

  Future<List<ScanLogEntry>> getAllScanLogs() async {
    final db = await database;
    final rows = await db.query('scan_logs', orderBy: 'id DESC');
    return rows.map((r) => ScanLogEntry.fromMap(r)).toList();
  }

  Future<List<ScanLogEntry>> getUnsyncedScanLogs() async {
    final db = await database;
    final rows = await db.query('scan_logs', where: 'synced = 0');
    return rows.map((r) => ScanLogEntry.fromMap(r)).toList();
  }

  Future<void> markScanLogsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE scan_logs SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as count FROM scan_logs WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// All events logged for one ticket on THIS device — useful for
  /// showing staff a history ("4 entered at 10:15 AM by this device").
  Future<List<ScanLogEntry>> getScanLogsForTicket(String ticketId) async {
    final db = await database;
    final rows = await db.query(
      'scan_logs',
      where: 'ticket_id = ?',
      whereArgs: [ticketId],
      orderBy: 'id ASC',
    );
    return rows.map((r) => ScanLogEntry.fromMap(r)).toList();
  }
}