// lib/main_idoso.dart

import 'package:flutter/material.dart';
import 'package:guardiao_familiar/home_screen_idoso.dart';

void main() {
  runApp(const GuardiaoFamiliarIdosoApp());
}

class GuardiaoFamiliarIdosoApp extends StatelessWidget {
  const GuardiaoFamiliarIdosoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardião Familiar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreenIdoso(),
    );
  }
}