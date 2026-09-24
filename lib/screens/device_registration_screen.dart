import 'package:flutter/material.dart';
import '../services/device_whitelist_service.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import 'login_screen.dart';

/// Checked BEFORE login — this is a hardware-level gate ("is this
/// tablet allowed to run the app at all"), independent of who is
/// using it. Only an approved device ever reaches the Login screen.
class DeviceRegistrationScreen extends StatefulWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  State<DeviceRegistrationScreen> createState() => _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  bool _checking = true;
  bool _approved = false;
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _checkDevice();
  }

  Future<void> _checkDevice() async {
    final deviceId = await DeviceWhitelistService.getCurrentDeviceId();
    final approved = await DeviceWhitelistService.isDeviceApproved();

    if (!mounted) return;
    setState(() {
      _deviceId = deviceId;
      _approved = approved;
      _checking = false;
    });

    if (approved) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.all(r.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_checking) ...[
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 20),
                  const Text('Checking device authorization\u2026', style: TextStyle(color: Colors.black54)),
                ] else if (_approved) ...[
                  const Icon(Icons.verified, color: AppColors.success, size: 64),
                  const SizedBox(height: 16),
                  const Text('Device authorized', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ] else ...[
                  const Icon(Icons.block, color: AppColors.error, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'This device is not authorized',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contact IT to register this device before it can be used for scanning.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('This device\'s ID:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 4),
                        SelectableText(
                          _deviceId,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'For testing: add this ID to the approved list in device_whitelist_service.dart',
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _checking = true);
                      _checkDevice();
                    },
                    child: const Text('Check again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}