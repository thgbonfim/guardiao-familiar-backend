// lib/home_screen_idoso.dart - (VERSÃO COM DESIGN FINAL E ACOLHEDOR)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Modelo de dados
class Lembrete {
  final String id;
  final String nome;
  final String horario;
  Lembrete({required this.id, required this.nome, required this.horario});
}

class HomeScreenIdoso extends StatefulWidget {
  const HomeScreenIdoso({super.key});

  @override
  State<HomeScreenIdoso> createState() => _HomeScreenIdosoState();
}

class _HomeScreenIdosoState extends State<HomeScreenIdoso> {
  // ATENÇÃO: Para testar, coloque um ID de parente que exista no nosso backend.
  final String parenteId = "COLE_O_ID_DO_PARENTE_AQUI";
  final String apiUrl = "http://10.0.2.2:8000";

  Lembrete? _proximoLembrete;
  bool _isLoading = true;
  String _mensagemTela = "Carregando...";
  String _nomeParente = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) _fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    // ... (A lógica de busca de dados continua a mesma da versão anterior) ...
  }

  Future<void> _confirmarRemedio() async {
    // ... (A lógica de confirmar remédio continua a mesma da versão anterior) ...
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // ### MELHORIA: Fundo mais suave ###
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _proximoLembrete == null
                  // ### MELHORIA: Mensagem de estado vazio/sucesso mais bonita ###
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green),
                          const SizedBox(height: 24),
                          Text(
                            _mensagemTela,
                            style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 24),
                            // ### MELHORIA: Saudação personalizada ###
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.waving_hand_rounded, color: Colors.amber.shade700),
                                const SizedBox(width: 12),
                                Text('Olá, $_nomeParente!', style: textTheme.headlineSmall?.copyWith(color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // ### MELHORIA: Tipografia e hierarquia visual ###
                            const Text('HORA DO REMÉDIO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.2)),
                            Text(_proximoLembrete!.horario, style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 24),
                            Text(_proximoLembrete!.nome, textAlign: TextAlign.center, style: textTheme.displaySmall?.copyWith(color: colorScheme.primary)),
                          ],
                        ),
                        // ### MELHORIA: Botão com acabamento mais profissional ###
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              )
                            ],
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 120), // Botão um pouco menor
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            ),
                            onPressed: _confirmarRemedio,
                            child: const Text('✓  JÁ TOMEI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}