import 'package:shared_preferences/shared_preferences.dart';

/// STEP 1 record: device-level registration (email, serial, device id).
/// Answers "is this physical tablet allowed to run the app at all" —
/// separate from user login. Local storage for now; swap for API
/// calls once the backend exists.
class DeviceRegistrationService {
  static const _kEmail = 'device_reg_email';
  static const _kSerial = 'device_reg_serial';
  static const _kDeviceId = 'device_reg_device_id';
  static const _kVerified = 'device_reg_verified';

  static Future<bool> isDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kVerified) ?? false;
  }

  /// Called only AFTER OTP verification succeeds.
  static Future<void> completeRegistration({
    required String email,
    required String serial,
    required String deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email.trim().toLowerCase());
    await prefs.setString(_kSerial, serial.trim());
    await prefs.setString(_kDeviceId, deviceId);
    await prefs.setBool(_kVerified, true);
  }

  static Future<String?> getRegisteredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmail);
  }

  static Future<String?> getRegisteredSerial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSerial);
  }

  static Future<void> clearForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmail);
    await prefs.remove(_kSerial);
    await prefs.remove(_kDeviceId);
    await prefs.remove(_kVerified);
  }
}