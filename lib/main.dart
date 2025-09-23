// lib/main.dart - (VERSÃO FINAL E CORRIGIDA)
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:guardiao_familiar/welcome_screen.dart';

void main() {
  // Inicializa o pacote de formatação de datas para o português do Brasil.
  // Essencial para mostrar "Terça-feira", "Setembro", etc.
  initializeDateFormatting('pt_BR', null).then((_) {
    runApp(const GuardiaoFamiliarApp());
  });
}

class GuardiaoFamiliarApp extends StatelessWidget {
  const GuardiaoFamiliarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardião Familiar',
      debugShowCheckedModeBanner: false,
      
      // O tema agora é chamado a partir da nossa classe AppTheme.
      theme: AppTheme.lightTheme,
      
      // A tela inicial do seu fluxo de cuidador.
      home: const WelcomeScreen(),
    );
  }
}

// --- CLASSE DE TEMA DEDICADA ---
// Mover a lógica do tema para uma classe separada torna o código mais limpo
// e fácil de gerenciar, especialmente se você adicionar um tema escuro no futuro.

class AppTheme {
  // ✅ CORREÇÃO APLICADA AQUI
  // Usamos a paleta de cores 'MaterialColor' completa, que contém as "sombras" (.shadeX).
  static const MaterialColor _primaryColor = Colors.teal;

  // Tema claro (lightTheme)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      primary: _primaryColor, // Define a cor primária explicitamente
    ),
    scaffoldBackgroundColor: Colors.grey[50],

    // Tema para Botões Elevados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor, // Usa a cor principal
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Tema para Campos de Texto
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      
      // Estilo do rótulo (ex: "Seu melhor e-mail")
      labelStyle: TextStyle(
        // Agora, como _primaryColor é uma paleta, podemos acessar suas sombras.
        color: _primaryColor.shade900, 
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),

      // Borda quando o campo não está em foco
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        // E aqui também podemos usar uma sombra mais clara.
        borderSide: BorderSide(color: _primaryColor.shade200, width: 1.5),
      ),

      // Borda quando o campo está em foco (selecionado)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        // E aqui a cor principal
        borderSide: const BorderSide(color: _primaryColor, width: 2.5),
      ),
       // Borda de erro
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
      // Borda de erro em foco
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2.5),
      ),
    ),
  );
}