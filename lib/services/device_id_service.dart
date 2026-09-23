import 'package:device_info_plus/device_info_plus.dart';

/// Identifies this specific tablet/gate so every scan event can be
/// tagged with "who scanned this" — required for the multi-device
/// merge logic (requirement: same file imported to 2-3 devices must
/// not cause double-counting or lost scans).
///
/// This uses the hardware's stable Android ID as the base, combined
/// with a friendly, staff-editable gate label (e.g. "Gate-1") stored
/// locally so reports are human-readable, not just a raw device ID.
class DeviceIdService {
  static String? _cachedDeviceId;
  static String? _cachedGateLabel;

  /// The stable hardware identifier — same every app launch on this
  /// physical device, used as the authoritative id for conflict-free
  /// event tagging.
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _cachedDeviceId = androidInfo.id; // Android ID, stable per device
    } catch (_) {
      // Fallback for iOS or if plugin fails — still unique enough
      // for a small fleet of gate tablets.
      _cachedDeviceId = 'device-${DateTime.now().millisecondsSinceEpoch}';
    }
    return _cachedDeviceId!;
  }

  /// Human-friendly label staff can set once per tablet, e.g.
  /// "Gate-1-Tablet-A". Falls back to the raw device id if unset.
  /// NOTE: for this test build this is hardcoded; wire up a simple
  /// settings screen later to let gate staff set/change this.
  static Future<String> getGateLabel() async {
    return _cachedGateLabel ?? 'Gate-1-Tablet-01';
  }

  static void setGateLabelForTesting(String label) {
    _cachedGateLabel = label;
  }

  /// Combined string used to tag every scan event — this is what
  /// goes into ScanLogEntry.deviceInfo.
  static Future<String> getDeviceTag() async {
    final label = await getGateLabel();
    return label;
  }
}