import 'package:flutter/material.dart';
import '../services/device_id_service.dart';
import '../services/device_registration_service.dart';
import '../utils/app_colors.dart';
import '../widgets/otp_dialog.dart';
import 'user_registration_screen.dart';

/// STEP 1: registers this physical tablet. Email + Serial (manual) +
/// Device ID (auto-fetched, read-only). On OTP success, proceeds to
/// User Registration.
class DeviceRegistrationScreen extends StatefulWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  State<DeviceRegistrationScreen> createState() => _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _serialC = TextEditingController();
  final _deviceIdC = TextEditingController();

  bool _loadingDeviceId = true;
  bool _submitting = false;

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
    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    final deviceId = await DeviceIdService.getDeviceId();
    if (!mounted) return;
    setState(() {
      _deviceIdC.text = deviceId;
      _loadingDeviceId = false;
    });
  }

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _submitting = false);

    final verified = await showOtpDialog(context, emailForDisplay: _emailC.text.trim());

    if (verified == true) {
      await DeviceRegistrationService.completeRegistration(
        email: _emailC.text,
        serial: _serialC.text,
        deviceId: _deviceIdC.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserRegistrationScreen()));
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
                      const Text('Device Registration',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      const Text(
                        'Register this device before it can be used for scanning',
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
                                controller: _emailC,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(labelText: 'Email ID', prefixIcon: _iconTile(Icons.email_outlined)),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) return 'Email is required';
                                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _serialC,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(labelText: 'Serial number', prefixIcon: _iconTile(Icons.confirmation_number_outlined)),
                                validator: (v) => (v ?? '').trim().isEmpty ? 'Serial number is required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _deviceIdC,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Device ID (auto)',
                                  hintText: _loadingDeviceId ? 'Fetching\u2026' : null,
                                  prefixIcon: _iconTile(Icons.tablet_android),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.05),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                                  onPressed: (_loadingDeviceId || _submitting) ? null : _onRegisterPressed,
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