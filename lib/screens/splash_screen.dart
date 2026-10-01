import 'package:flutter/material.dart';
import '../services/device_registration_service.dart';
import '../services/registration_service.dart';
import 'device_registration_screen.dart';
import 'login_screen.dart';
import 'user_registration_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Logo gentle float up/down, like it's bobbing on water.
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  // Water-drop ring image, continuously rotating.
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _decideNext();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _decideNext() async {
    await Future.delayed(const Duration(milliseconds: 5000));

    final deviceRegistered = await DeviceRegistrationService.isDeviceRegistered();
    if (!mounted) return;

    if (!deviceRegistered) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DeviceRegistrationScreen()),
      );
      return;
    }

    final userRegistered = await RegistrationService.isRegistered();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => userRegistered ? const LoginScreen() : const UserRegistrationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/backgroundIMG.png', fit: BoxFit.cover),
          Container(color: Colors.white.withOpacity(0.15)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (context, child) {
                    return Transform.translate(offset: Offset(0, _floatAnim.value), child: child);
                  },
                  child: Image.asset('assets/icon/app_icon.png', width: 220, height: 220, fit: BoxFit.contain),
                ),
                const SizedBox(height: 36),
                RotationTransition(
                  turns: _ringController,
                  child: Image.asset(
                    'assets/images/water_loader.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}