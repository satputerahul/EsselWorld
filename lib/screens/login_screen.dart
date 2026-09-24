import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import 'scan_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'gate1');
  final _passwordController = TextEditingController(text: 'gate123');
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await AuthService.login(_usernameController.text, _passwordController.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    } else {
      setState(() => _error = 'Invalid username or password');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(r.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.qr_code_scanner, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text('Staff Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('EsselWorld Gate Scanner', style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
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
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    'Test credentials:\ngate1 / gate123\nadmin / admin123',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}