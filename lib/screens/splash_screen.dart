import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/device_registration_service.dart';
import '../services/registration_service.dart';
import '../utils/app_colors.dart';
import 'device_registration_screen.dart';
import 'login_screen.dart';
import 'user_registration_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
    await Future.delayed(const Duration(milliseconds: 2200));

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
          Image.asset('assets/images/registration_bg.png', fit: BoxFit.cover),
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
                _WaterLoadingRing(controller: _ringController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterLoadingRing extends StatelessWidget {
  final AnimationController controller;
  const _WaterLoadingRing({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomPaint(painter: _WaterRingPainter(progress: controller.value)),
      ),
    );
  }
}

class _WaterRingPainter extends CustomPainter {
  final double progress;
  _WaterRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final trackPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, trackPaint);

    for (int i = 0; i < 3; i++) {
      final angle = (progress * 2 * math.pi) + (i * (2 * math.pi / 3));
      final dropCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final isLead = i == 0;
      final dropPaint = Paint()..color = AppColors.primary.withOpacity(isLead ? 1.0 : 0.45);
      canvas.drawCircle(dropCenter, isLead ? 6 : 4.5, dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterRingPainter oldDelegate) => oldDelegate.progress != progress;
}