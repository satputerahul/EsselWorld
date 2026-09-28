import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/registration_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import 'registration_screen.dart';
import 'scan_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillEmail;
  const LoginScreen({super.key, this.prefillEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailC = TextEditingController();
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
    final email = widget.prefillEmail ?? await RegistrationService.getRegisteredEmail();
    if (!mounted) return;
    if (email != null) _emailC.text = email;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.login(_emailC.text, _passC.text);

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case LoginResult.success:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
        break;
      case LoginResult.wrongCredentials:
        setState(() => _error = 'Invalid email or password');
        break;
      case LoginResult.wrongDevice:
        setState(() => _error = 'This account is registered on a different device');
        break;
      case LoginResult.notRegistered:
        setState(() => _error = 'No account found on this device. Please register.');
        break;
    }
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(r.horizontalPadding),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Staff Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('EsselWorld Gate Scanner', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passC,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    onSubmitted: (_) => _handleLogin(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleLogin,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", style: TextStyle(color: Colors.black54)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                          );
                        },
                        child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}