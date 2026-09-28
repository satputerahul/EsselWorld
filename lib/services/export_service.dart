import 'dart:io';
import 'dart:ui' show Rect;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../db/db_helper.dart';

/// Manual Backup/Export: lets staff export the full scan event log
/// as CSV and share it (email, Drive, USB transfer app).
class ExportService {
  static Future<File> _buildCsvFile() async {
    final logs = await DbHelper.instance.getAllScanLogs();

    final rows = <List<dynamic>>[
      ['Event ID', 'Ticket ID', 'Status', 'Visitors Entered', 'Date/Time', 'Device', 'Synced'],
      ...logs.map((e) => [
            e.eventId,
            e.ticketId,
            e.scanStatus,
            e.visitorsEnteredThisEvent,
            e.scanDateTime,
            e.deviceInfo,
            e.synced ? 'Yes' : 'No',
          ]),
    ];

    final csvString = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/scan_log_export_$timestamp.csv');
    await file.writeAsString(csvString);
    return file;
  }

  /// [sharePositionOrigin] is required on iOS: it tells the share sheet
  /// where to anchor itself (the export button's on-screen rectangle).
  static Future<void> shareScanLog({Rect? sharePositionOrigin}) async {
    final file = await _buildCsvFile();
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Esselworld scan log export',
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}