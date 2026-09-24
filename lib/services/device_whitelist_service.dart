import 'device_id_service.dart';

/// Checks whether THIS physical device is authorized to run the app
/// at all — checked before login, since login only identifies WHO
/// is using the tablet, not whether the tablet itself is trusted.
///
/// HARDCODED for testing since there's no backend yet. Once a real
/// API exists, isDeviceApproved() becomes an HTTP call against
/// Esselworld's device registry instead of this local list — every
/// other screen stays the same.
class DeviceWhitelistService {
  /// Sample approved device IDs for testing. Add your real test
  /// tablet's Android ID here once you see it on the "not
  /// authorized" screen (it's displayed there for convenience).
  static const List<String> _approvedDeviceIds = [
    'test-device-001',
    'test-device-002',
    'emulator-android-id', // common emulator ANDROID_ID value
  ];

  /// TESTING ONLY: set true to skip the whitelist check entirely
  /// (useful while developing on a device whose ID you haven't
  /// added yet). Set false before demoing the actual restriction
  /// behavior to your manager.
  static const bool bypassForTesting = true;

  static Future<bool> isDeviceApproved() async {
    if (bypassForTesting) return true;
    final deviceId = await DeviceIdService.getDeviceId();
    return _approvedDeviceIds.contains(deviceId);
  }

  static Future<String> getCurrentDeviceId() async {
    return DeviceIdService.getDeviceId();
  }
}