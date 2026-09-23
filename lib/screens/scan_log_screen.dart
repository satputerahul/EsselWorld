import 'package:flutter/material.dart';
import '../models/scan_log_model.dart';
import '../db/db_helper.dart';
import '../services/sync_service.dart';
import '../services/export_service.dart';
import '../utils/responsive.dart';

class ScanLogScreen extends StatefulWidget {
  const ScanLogScreen({super.key});

  @override
  State<ScanLogScreen> createState() => _ScanLogScreenState();
}

class _ScanLogScreenState extends State<ScanLogScreen> {
  List<ScanLogEntry> _logs = [];
  bool _loading = true;
  bool _syncing = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await DbHelper.instance.getAllScanLogs();
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _syncMessage = null;
    });
    final result = await SyncService.syncNow();
    setState(() {
      _syncing = false;
      if (result.reason != null) {
        _syncMessage = 'Sync failed: ${result.reason}';
      } else if (result.hadNothingToSync) {
        _syncMessage = 'Nothing to sync — all records up to date';
      } else {
        _syncMessage = 'Synced ${result.succeeded} of ${result.attempted} events';
      }
    });
    await _loadLogs();
  }

  Future<void> _exportAndShare() async {
    try {
      await ExportService.shareScanLog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final unsyncedCount = _logs.where((l) => !l.synced).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan log'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(r.horizontalPadding),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _statChip('${_logs.length}', 'Total events', Colors.indigo)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statChip(
                                  '$unsyncedCount',
                                  'Pending sync',
                                  unsyncedCount > 0 ? Colors.orange : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          if (_syncMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(_syncMessage!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _syncing ? null : _syncNow,
                                  icon: _syncing
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.sync, size: 18),
                                  label: const Text('Sync now'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _exportAndShare,
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Export'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(child: Text('No scans recorded yet', style: TextStyle(color: Colors.black45)))
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                return ListTile(
                                  leading: Icon(
                                    log.synced ? Icons.cloud_done : Icons.cloud_off,
                                    color: log.synced ? Colors.green : Colors.orange,
                                  ),
                                  title: Text('${log.ticketId}  (+${log.visitorsEnteredThisEvent})',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${log.scanStatus} • ${log.scanDateTime} • ${log.deviceInfo}'),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}