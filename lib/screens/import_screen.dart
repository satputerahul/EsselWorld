import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import '../services/ticket_import_service.dart';
import '../db/db_helper.dart';
import '../utils/responsive.dart';
import 'scan_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _importing = false;
  String? _statusMessage;
  int _currentTicketCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentCount();
  }

  Future<void> _loadCurrentCount() async {
    final count = await DbHelper.instance.getTicketCount();
    if (!mounted) return;
    setState(() => _currentTicketCount = count);
  }

  Future<void> _importFromFilePicker() async {
    setState(() {
      _importing = true;
      _statusMessage = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.single.path == null) {
        setState(() {
          _importing = false;
          _statusMessage = 'No file selected';
        });
        return;
      }
      final count = await TicketImportService.importFromCsvFile(
          result.files.single.path!);
      setState(() {
        _importing = false;
        _statusMessage = 'Imported $count tickets successfully';
        _currentTicketCount = count;
      });
    } catch (e) {
      setState(() {
        _importing = false;
        _statusMessage = 'Import failed: $e';
      });
    }
  }

  Future<void> _importSampleData() async {
    setState(() {
      _importing = true;
      _statusMessage = null;
    });
    try {
      final csvString =
          await rootBundle.loadString('assets/data/sample_tickets.csv');
      final count = await TicketImportService.importFromCsvString(csvString);
      setState(() {
        _importing = false;
        _statusMessage = 'Sample data loaded: $count tickets';
        _currentTicketCount = count;
      });
    } catch (e) {
      setState(() {
        _importing = false;
        _statusMessage = 'Import failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Load ticket data'),
        backgroundColor: Color(0xFF0E7C86),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(r.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storage, size: 64, color: Color(0xFF0E7C86)),
                const SizedBox(height: 16),
                Text(
                  'Tickets currently in local database: $_currentTicketCount',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Load the booking data file provided by the backend team before going offline. Each ticket may cover multiple visitors — partial entry is tracked automatically.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_importing) const CircularProgressIndicator(),
                if (!_importing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _importFromFilePicker,
                      icon: const Icon(Icons.file_open),
                      label: const Text('Choose CSV file'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0E7C86),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importSampleData,
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Load sample test data'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusMessage!.startsWith('Import failed')
                          ? Colors.red
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ScanScreen()),
                      );
                    },
                    child: const Text('Done  \u2192 Back to scanner'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
