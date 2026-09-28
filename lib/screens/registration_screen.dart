import 'package:flutter/material.dart';
import '../services/device_id_service.dart';
import '../services/registration_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _serialC = TextEditingController(); // manual entry
  final _deviceIdC = TextEditingController(); // auto-fetched, read-only
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _loadingDeviceId = true;
  bool _submitting = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  @override
  void dispose() {
    _emailC.dispose();
    _serialC.dispose();
    _deviceIdC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  /// Only the Device ID is fetched automatically.
  Future<void> _loadDeviceId() async {
    final deviceId = await DeviceIdService.getDeviceId();
    if (!mounted) return;
    setState(() {
      _deviceIdC.text = deviceId;
      _loadingDeviceId = false;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    await RegistrationService.register(
      email: _emailC.text,
      serial: _serialC.text.trim(),
      deviceId: _deviceIdC.text,
      password: _passC.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration successful. Please login.')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(prefillEmail: _emailC.text.trim())),
    );
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
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.app_registration, size: 44, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    const Text('Register', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text(
                      'Register this device to use the scanner',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Serial number: MANUAL entry
                    TextFormField(
                      controller: _serialC,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Serial number',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return 'Serial number is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Device ID: AUTO-fetched, read-only
                    TextFormField(
                      controller: _deviceIdC,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Device ID (auto)',
                        hintText: _loadingDeviceId ? 'Fetching\u2026' : null,
                        prefixIcon: const Icon(Icons.tablet_android),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.04),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passC,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Password is required';
                        if (v!.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _confirmC,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Confirm your password';
                        if (v != _passC.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_loadingDeviceId || _submitting) ? null : _register,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Register'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?', style: TextStyle(color: Colors.black54)),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}