import 'package:flutter/material.dart';
import '../services/device_id_service.dart';
import '../services/device_registration_service.dart';
import '../services/registration_service.dart';
import '../utils/app_colors.dart';
import '../widgets/otp_dialog.dart';
import 'login_screen.dart';

/// STEP 2: registers the staff member using this (already
/// device-registered) tablet. Username, Mobile No, User ID,
/// Password, Confirm password. On OTP success, proceeds to Login.
class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameC = TextEditingController();
  final _mobileC = TextEditingController();
  final _userIdC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _submitting = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _deviceEmailForOtp = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceEmail();
  }

  Future<void> _loadDeviceEmail() async {
    final email = await DeviceRegistrationService.getRegisteredEmail();
    if (!mounted) return;
    setState(() => _deviceEmailForOtp = email ?? '');
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _mobileC.dispose();
    _userIdC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _submitting = false);

    final verified = await showOtpDialog(context, emailForDisplay: _deviceEmailForOtp);

    if (verified == true) {
      final deviceId = await DeviceIdService.getDeviceId();

      await RegistrationService.register(
        username: _usernameC.text,
        mobile: _mobileC.text,
        userId: _userIdC.text,
        deviceId: deviceId,
        password: _passC.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful. Please login.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(prefillUsername: _usernameC.text.trim())),
      );
    }
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
    final logoSize = mq.size.width * (isTablet ? 0.30 : 0.42);

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
                      const Text('Sign Up',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      const SizedBox(height: 4),
                      const Text(
                        'Register this device for gate staff access',
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usernameC,
                                decoration: InputDecoration(labelText: 'Username', prefixIcon: _iconTile(Icons.person_outline)),
                                validator: (v) => (v ?? '').trim().isEmpty ? 'Username is required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _mobileC,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                decoration: InputDecoration(
                                  labelText: 'Mobile No.',
                                  prefixIcon: _iconTile(Icons.phone_outlined),
                                  counterText: '',
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) return 'Mobile number is required';
                                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return 'Enter a valid 10-digit number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _userIdC,
                                decoration: InputDecoration(labelText: 'User ID', prefixIcon: _iconTile(Icons.badge_outlined)),
                                validator: (v) => (v ?? '').trim().isEmpty ? 'User ID is required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passC,
                                obscureText: _obscurePass,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: _iconTile(Icons.lock_outline),
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
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmC,
                                obscureText: _obscureConfirm,
                                decoration: InputDecoration(
                                  labelText: 'Confirm password',
                                  prefixIcon: _iconTile(Icons.lock_reset),
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
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                                  onPressed: _submitting ? null : _onRegisterPressed,
                                  child: _submitting
                                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [Text('Register', style: TextStyle(fontSize: 16)), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 20)],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Already have an account?', style: TextStyle(color: Colors.black54)),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                              },
                              child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
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