import 'package:flutter/material.dart';
import 'screens/import_screen.dart';

void main() {
  runApp(const EsselworldScannerApp());
}

class EsselworldScannerApp extends StatelessWidget {
  const EsselworldScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Esselworld Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
      ),
      home: const ImportScreen(),
    );
  }
}