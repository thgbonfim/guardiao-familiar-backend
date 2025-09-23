import 'package:flutter/material.dart';
import 'package:guardiao_familiar/home_screen_idoso.dart';
import 'package:logging/logging.dart';

void main() {
  _setupLogging();
  runApp(const GuardiaoFamiliarIdosoApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.time}: ${record.loggerName} - ${record.message}',
    );
  });
}

class GuardiaoFamiliarIdosoApp extends StatelessWidget {
  const GuardiaoFamiliarIdosoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardião Familiar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreenIdoso(),
    );
  }
}
