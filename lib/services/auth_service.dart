import 'registration_service.dart';

class AuthService {
  static bool _isLoggedIn = false;
  static String? _currentUser;

  static Future<LoginResult> login(String email, String password) async {
    final result = await RegistrationService.verifyLogin(email, password);
    if (result == LoginResult.success) {
      _isLoggedIn = true;
      _currentUser = email.trim().toLowerCase();
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