import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/registration_service.dart';
import '../utils/app_colors.dart';
import 'import_screen.dart';
import 'scan_screen.dart';
import 'user_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillUsername;
  const LoginScreen({super.key, this.prefillUsername});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final username = widget.prefillUsername ?? await RegistrationService.getRegisteredUsername();
    if (!mounted) return;
    if (username != null) _usernameC.text = username;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.login(_usernameC.text, _passC.text);

    if (!mounted) return;

    switch (result) {
      case LoginResult.success:
        final online = await ConnectivityService.checkNowAndReturn();
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => online ? const ScanScreen() : const ImportScreen()),
        );
        break;
      case LoginResult.wrongCredentials:
        setState(() {
          _loading = false;
          _error = 'Invalid username or password';
        });
        break;
      case LoginResult.wrongDevice:
        setState(() {
          _loading = false;
          _error = 'This account is registered on a different device';
        });
        break;
      case LoginResult.notRegistered:
        setState(() {
          _loading = false;
          _error = 'No account found on this device. Please register.';
        });
        break;
    }
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Widget _iconTile(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppColors.primaryDark, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isTablet = mq.size.width >= 600;
    final cardMaxWidth = isTablet ? 520.0 : double.infinity;
    final logoSize = mq.size.width * (isTablet ? 0.32 : 0.48);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgroundIMG.png', fit: BoxFit.cover),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 18, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: logoSize,
                        height: logoSize,
                        child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 4),
                      const Text('Staff Login',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      const SizedBox(height: 4),
                      const Text(
                        'Login to start scanning tickets',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _usernameC,
                              decoration: InputDecoration(labelText: 'Username', prefixIcon: _iconTile(Icons.person_outline)),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passC,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: _iconTile(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              onSubmitted: (_) => _handleLogin(),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                                onPressed: _loading ? null : _handleLogin,
                                child: _loading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [Text('Login', style: TextStyle(fontSize: 16)), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 20)],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Don't have an account?", style: TextStyle(color: Colors.black54)),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserRegistrationScreen()));
                              },
                              child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}