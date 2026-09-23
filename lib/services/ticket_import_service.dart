import 'dart:io';
import 'package:csv/csv.dart';
import '../models/ticket_model.dart';
import '../db/db_helper.dart';

/// Imports the ticket/booking data file (CSV) into the local SQLite
/// database ONCE, before the tablet starts scanning for the day.
///
/// Expected CSV format (with header row):
///   ticket_id,ticket_status,ticket_type,valid_date,total_visitors
///   EW-00673105,Valid,REGULAR ADULT,2026-09-03,7
///   WKMI0M1NK10J3T,Valid,General,2026-08-28,2
///
/// If the same file is imported on multiple tablets (Gate-1, Gate-2,
/// Gate-3), every tablet starts with visitors_used = 0 — each device
/// then tracks its own local scans, and the event-based scan_logs
/// table reconciles the true combined count when they all sync.
class TicketImportService {
  static Future<int> importFromCsvFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('CSV file not found at $filePath');
    }
    final content = await file.readAsString();
    return importFromCsvString(content);
  }

  static Future<int> importFromCsvString(String csvContent) async {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.isEmpty) return 0;

    final dataRows =
        rows.first.first.toString().toLowerCase().contains('ticket')
            ? rows.sublist(1)
            : rows;

    final tickets = <Ticket>[];
    for (final row in dataRows) {
      if (row.length < 4) continue; // skip malformed/blank lines
      tickets.add(Ticket.fromCsvRow(row));
    }

    await DbHelper.instance.replaceAllTickets(tickets);
    return tickets.length;
  }
}