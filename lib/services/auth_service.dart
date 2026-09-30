import 'registration_service.dart';

class AuthService {
  static bool _isLoggedIn = false;
  static String? _currentUser;

  static Future<LoginResult> login(String username, String password) async {
    final result = await RegistrationService.verifyLogin(username, password);
    if (result == LoginResult.success) {
      _isLoggedIn = true;
      _currentUser = username.trim();
    }
    return result;
  }

  static bool get isLoggedIn => _isLoggedIn;
  static String? get currentUser => _currentUser;

  static void logout() {
    _isLoggedIn = false;
    _currentUser = null;
  }
}