/// HARDCODED login for testing — no real backend yet. Replace with
/// a real API call once available; screens calling login() won't
/// need to change.
class AuthService {
  static const Map<String, String> _testCredentials = {
    'gate1': 'gate123',
    'admin': 'admin123',
  };

  static bool _isLoggedIn = false;
  static String? _currentUser;

  static Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500)); // simulate network
    final expectedPassword = _testCredentials[username.trim().toLowerCase()];
    if (expectedPassword != null && expectedPassword == password) {
      _isLoggedIn = true;
      _currentUser = username.trim();
      return true;
    }
    return false;
  }

  static bool get isLoggedIn => _isLoggedIn;
  static String? get currentUser => _currentUser;

  static void logout() {
    _isLoggedIn = false;
    _currentUser = null;
  }
}