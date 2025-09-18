import 'package:flutter/material.dart';
import 'package:guardiao_familiar/welcome_screen.dart';

void main() {
  runApp(const GuardiaoFamiliarApp());
}

class GuardiaoFamiliarApp extends StatelessWidget {
  const GuardiaoFamiliarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardião Familiar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}