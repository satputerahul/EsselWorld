import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_id_service.dart';

enum LoginResult { success, wrongCredentials, wrongDevice, notRegistered }

/// Stores the registered account locally (SharedPreferences) since there
/// is no backend yet. The password is stored as a SHA-256 hash, never
/// plain text, and the account is bound to this device's ID.
///
/// When the API exists, register() and verifyLogin() become API calls;
/// the screens don't need to change.
class RegistrationService {
  static const _kEmail = 'reg_email';
  static const _kSerial = 'reg_serial';
  static const _kDeviceId = 'reg_device_id';
  static const _kPasswordHash = 'reg_password_hash';

  static String _hash(String password, String deviceId) {
    return sha256.convert(utf8.encode('$deviceId:$password')).toString();
  }

  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kEmail) && prefs.containsKey(_kPasswordHash);
  }

  static Future<void> register({
    required String email,
    required String serial,
    required String deviceId,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email.trim().toLowerCase());
    await prefs.setString(_kSerial, serial);
    await prefs.setString(_kDeviceId, deviceId);
    await prefs.setString(_kPasswordHash, _hash(password, deviceId));
  }

  static Future<LoginResult> verifyLogin(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kEmail);
    final savedHash = prefs.getString(_kPasswordHash);
    final savedDeviceId = prefs.getString(_kDeviceId);

    if (savedEmail == null || savedHash == null || savedDeviceId == null) {
      return LoginResult.notRegistered;
    }

    final currentDeviceId = await DeviceIdService.getDeviceId();
    if (currentDeviceId != savedDeviceId) return LoginResult.wrongDevice;

    final emailOk = email.trim().toLowerCase() == savedEmail;
    final passOk = _hash(password, currentDeviceId) == savedHash;
    return (emailOk && passOk) ? LoginResult.success : LoginResult.wrongCredentials;
  }

  static Future<String?> getRegisteredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmail);
  }

  /// Testing helper: wipes the registration so you can register again.
  static Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmail);
    await prefs.remove(_kSerial);
    await prefs.remove(_kDeviceId);
    await prefs.remove(_kPasswordHash);
  }
}