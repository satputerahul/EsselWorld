import 'dart:io' show Platform;
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Auto-fetched, per-platform stable device identifier:
///  - Android: real ANDROID_ID (16-char hex). Stable across reboots,
///    reinstalls and updates. Changes only on factory reset.
///  - iOS / iOS simulator: identifierForVendor (UUID). Stable while
///    the app stays installed on that device/simulator.
class DeviceIdService {
  static String? _cachedDeviceId;
  static String? _cachedGateLabel;

  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      if (Platform.isAndroid) {
        final id = await const AndroidId().getId();
        _cachedDeviceId = (id == null || id.isEmpty) ? 'unavailable' : id;
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        final id = info.identifierForVendor;
        _cachedDeviceId = (id == null || id.isEmpty) ? 'unavailable' : id;
      } else {
        _cachedDeviceId = 'unsupported-platform';
      }
    } catch (_) {
      _cachedDeviceId = 'unavailable';
    }
    return _cachedDeviceId!;
  }

  static Future<String> getGateLabel() async {
    return _cachedGateLabel ?? 'Gate-1-Tablet-01';
  }

  static void setGateLabelForTesting(String label) {
    _cachedGateLabel = label;
  }

  static Future<String> getDeviceTag() async {
    return getGateLabel();
  }
}