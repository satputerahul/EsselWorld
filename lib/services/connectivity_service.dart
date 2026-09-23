import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Continuously determines whether the app can actually reach the
/// backend — not just whether Wi-Fi is connected. Relevant scenario
/// from requirements: no internet from 10 AM to 2 PM, then it
/// returns — the app needs to detect that transition automatically
/// and trigger a sync.
class ConnectivityService {
  // TODO: replace with your real webservice health-check endpoint.
  static const String _healthCheckUrl = 'https://example.com/api/health';

  static final _controller = StreamController<bool>.broadcast();
  static Stream<bool> get onStatusChange => _controller.stream;

  static bool _isOnline = false;
  static bool get isOnline => _isOnline;

  static Timer? _pollTimer;

  static void startMonitoring() {
    _checkNow();
    Connectivity().onConnectivityChanged.listen((_) => _checkNow());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkNow());
  }

  static void stopMonitoring() => _pollTimer?.cancel();

  static Future<void> _checkNow() async {
    final result = await _canReachBackend();
    if (result != _isOnline) {
      _isOnline = result;
      _controller.add(_isOnline);
    }
  }

  static Future<bool> _canReachBackend() async {
    try {
      final response = await http
          .get(Uri.parse(_healthCheckUrl))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkNowAndReturn() async {
    await _checkNow();
    return _isOnline;
  }
}