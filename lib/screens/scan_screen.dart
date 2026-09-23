import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/ticket_model.dart';
import '../services/ticket_verify_service.dart';
import '../services/camera_permission_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../utils/responsive.dart';
import 'result_screen.dart';
import 'scan_log_screen.dart';
import 'visitor_count_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _codeController = TextEditingController();

  int scannedCount = 0;
  bool _isProcessingScan = false;

  bool _permissionGranted = false;
  bool _permissionPermanentlyDenied = false;
  bool _checkingPermission = true;

  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();

    ConnectivityService.startMonitoring();
    _isOnline = ConnectivityService.isOnline;
    ConnectivityService.onStatusChange.listen((online) {
      if (!mounted) return;
      setState(() => _isOnline = online);
      if (online) {
        SyncService.syncNow(); // auto-sync the moment connectivity returns
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await CameraPermissionService.checkStatus();
    if (!mounted) return;
    setState(() {
      _permissionGranted = status.isGranted;
      _permissionPermanentlyDenied = status.isPermanentlyDenied;
      _checkingPermission = false;
    });
    if (!status.isGranted && !status.isPermanentlyDenied) {
      final result = await CameraPermissionService.requestPermission();
      if (!mounted) return;
      setState(() {
        _permissionGranted = result.isGranted;
        _permissionPermanentlyDenied = result.isPermanentlyDenied;
      });
    }
  }

  /// Step 1: look up the ticket, then route based on what's found.
  Future<void> _handleScan(String code) async {
    if (code.trim().isEmpty || _isProcessingScan) return;
    _isProcessingScan = true;

    final lookup = await TicketVerifyService.lookup(code.trim());

    if (!mounted) {
      _isProcessingScan = false;
      return;
    }

    // Invalid / already fully used — go straight to result screen,
    // nothing to ask the staff.
    if (lookup.status == VerifyStatus.invalid || lookup.status == VerifyStatus.alreadyUsed) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: VerifyResult(lookup.status, lookup.ticket, wasOffline: lookup.wasOffline),
          ),
        ),
      );
      _resetAfterScan();
      return;
    }

    // Valid or Partially Used — ask staff how many people are
    // entering right now (handles both "first scan of 7" and
    // "3 more of the remaining 3" cases identically).
    final ticket = lookup.ticket!;
    final countToAdmit = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => VisitorCountScreen(ticket: ticket)),
    );

    if (countToAdmit == null || countToAdmit <= 0) {
      // staff cancelled — no admission recorded
      _resetAfterScan();
      return;
    }

    final result = await TicketVerifyService.admitVisitors(ticket.ticketId, countToAdmit);

    if (result.status == VerifyStatus.valid) {
      setState(() => scannedCount += countToAdmit);
    } else if (result.status == VerifyStatus.partiallyUsed) {
      setState(() => scannedCount += countToAdmit);
    }

    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
    _resetAfterScan();
  }

  void _resetAfterScan() {
    _codeController.clear();
    _isProcessingScan = false;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingScan) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) _handleScan(code);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Esselworld gate scanner'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Scan log',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanLogScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 20),
              child: Column(
                children: [
                  _modeBadge(r),
                  const SizedBox(height: 12),
                  _counterCard(r),
                  const SizedBox(height: 20),
                  _cameraArea(r),
                  const SizedBox(height: 20),
                  _manualTestInput(r),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeBadge(Responsive r) {
    final color = _isOnline ? Colors.green : Colors.orange;
    final label = _isOnline ? 'Online mode' : 'Offline mode';
    final icon = _isOnline ? Icons.wifi : Icons.wifi_off;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _counterCard(Responsive r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Visitors admitted today', style: TextStyle(fontSize: 14 * r.baseFontScale)),
          Text('$scannedCount', style: TextStyle(fontSize: 20 * r.baseFontScale, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _cameraArea(Responsive r) {
    if (_checkingPermission) {
      return SizedBox(height: r.scannerHeight, child: const Center(child: CircularProgressIndicator()));
    }

    if (_permissionGranted) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: r.scannerHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(controller: _scannerController, onDetect: _onDetect),
              IgnorePointer(
                child: Center(
                  child: Container(
                    width: r.scannerHeight * 0.7,
                    height: r.scannerHeight * 0.7,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: r.scannerHeight,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_permissionPermanentlyDenied ? Icons.no_photography : Icons.camera_alt_outlined,
              color: Colors.white70, size: 40),
          const SizedBox(height: 12),
          Text(
            _permissionPermanentlyDenied
                ? 'Camera permission is off.\nEnable it from settings to scan QR codes.'
                : 'Camera access is needed to scan tickets',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _permissionPermanentlyDenied ? CameraPermissionService.openSettings : _requestCameraPermission,
            child: Text(_permissionPermanentlyDenied ? 'Open settings' : 'Allow camera'),
          ),
        ],
      ),
    );
  }

  Widget _manualTestInput(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Or enter manually (for testing)', style: TextStyle(fontSize: 13 * r.baseFontScale, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          decoration: InputDecoration(
            hintText: 'Try: EW-00673105, 2SZ5MD, WKMI0M1NK10J3T, EW-1004, EW-1006, EW-0922',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onSubmitted: _handleScan,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleScan(_codeController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Verify ticket'),
          ),
        ),
      ],
    );
  }
}