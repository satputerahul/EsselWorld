import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const EsselworldScannerApp());
}

class EsselworldScannerApp extends StatelessWidget {
  const EsselworldScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EsselWorld Scanner',
      debugShowCheckedModeBanner: true,
      theme: AppColors.theme,
      home: const SplashScreen(),
    );
  }
}