// lib/main.dart - (VERSÃO COM RÓTULOS DOS CAMPOS MAIORES E EM NEGRITO)

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
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          
          // ### ALTERAÇÃO AQUI PARA DEIXAR O TÍTULO MAIOR E EM NEGRITO ###
          labelStyle: TextStyle(
            color: Colors.teal.shade900,
            fontWeight: FontWeight.bold, // Adicionado o negrito
            fontSize: 16,               // Aumentado o tamanho da fonte
          ),
          // ####################################################################

          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Colors.teal.shade200, width: 1.5),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.teal, width: 2.5),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}