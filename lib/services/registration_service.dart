import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_id_service.dart';

enum LoginResult { success, wrongCredentials, wrongDevice, notRegistered }

/// STEP 2 record: the staff USER account, separate from
/// DeviceRegistrationService. Password stored as a SHA-256 hash,
/// account bound to this device's id.
class RegistrationService {
  static const _kUsername = 'reg_username';
  static const _kMobile = 'reg_mobile';
  static const _kUserId = 'reg_user_id';
  static const _kDeviceId = 'reg_device_id';
  static const _kPasswordHash = 'reg_password_hash';

  static String _hash(String password, String deviceId) {
    return sha256.convert(utf8.encode('$deviceId:$password')).toString();
  }

  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kUserId) && prefs.containsKey(_kPasswordHash);
  }

  static Future<void> register({
    required String username,
    required String mobile,
    required String userId,
    required String deviceId,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsername, username.trim());
    await prefs.setString(_kMobile, mobile.trim());
    await prefs.setString(_kUserId, userId.trim());
    await prefs.setString(_kDeviceId, deviceId);
    await prefs.setString(_kPasswordHash, _hash(password, deviceId));
  }

  static Future<LoginResult> verifyLogin(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString(_kUsername);
    final savedHash = prefs.getString(_kPasswordHash);
    final savedDeviceId = prefs.getString(_kDeviceId);

    if (savedUsername == null || savedHash == null || savedDeviceId == null) {
      return LoginResult.notRegistered;
    }

    final currentDeviceId = await DeviceIdService.getDeviceId();
    if (currentDeviceId != savedDeviceId) return LoginResult.wrongDevice;

    final usernameOk = username.trim() == savedUsername;
    final passOk = _hash(password, currentDeviceId) == savedHash;
    return (usernameOk && passOk) ? LoginResult.success : LoginResult.wrongCredentials;
  }

  static Future<String?> getRegisteredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUsername);
  }

  static Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUsername);
    await prefs.remove(_kMobile);
    await prefs.remove(_kUserId);
    await prefs.remove(_kDeviceId);
    await prefs.remove(_kPasswordHash);
  }
}