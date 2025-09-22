// lib/home_screen_idoso.dart - (VERSÃO FINAL E DEFINITIVA)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Lembrete {
  final String id;
  final String nome;
  final String horario;

  Lembrete({required this.id, required this.nome, required this.horario});

  factory Lembrete.fromJson(Map<String, dynamic> json) {
    return Lembrete(
      id: json['id'] ?? '',
      nome: json['nome_do_remedio'] ?? 'Remédio desconhecido',
      horario: json['horario'] ?? '--:--',
    );
  }
}

class HomeScreenIdoso extends StatefulWidget {
  const HomeScreenIdoso({super.key});

  @override
  State<HomeScreenIdoso> createState() => _HomeScreenIdosoState();
}

class _HomeScreenIdosoState extends State<HomeScreenIdoso> {
  final String parenteId = "42a9c7a2-5299-467d-8d49-684de94e9148";
  final String apiUrl = "http://10.0.2.2:8000";

  Lembrete? _proximoLembrete;
  bool _isLoading = true;
  String _mensagemTela = "Carregando lembretes...";
  String _nomeParente = "Querido(a)";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        print("Timer ativado: Verificando novos remédios...");
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    // Para chamadas que não são a inicial, ativa o loading
    if (!_isLoading && mounted) {
      setState(() { _isLoading = true; });
    }

    try {
      final url = Uri.parse('$apiUrl/parentes/$parenteId/remedios');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> remedios = json.decode(response.body);
          
          setState(() {
            if (remedios.isNotEmpty) {
              _proximoLembrete = Lembrete.fromJson(remedios.first);
            } else {
              _proximoLembrete = null;
              _mensagemTela = "Você já tomou todos os seus remédios por hoje. Parabéns!";
              if (_timer?.isActive ?? false) {
                print("Não há mais remédios pendentes, cancelando o Timer.");
                _timer?.cancel();
              }
            }
          });
        } else {
           setState(() {
             _proximoLembrete = null;
             _mensagemTela = "Falha ao carregar dados do servidor.";
           });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _proximoLembrete = null;
          _mensagemTela = "Erro de conexão. Verifique sua internet.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmarRemedio() async {
    if (_proximoLembrete == null || _isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$apiUrl/remedios/confirmar');
      final corpoJson = json.encode({'id_do_remedio': _proximoLembrete!.id});
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: corpoJson,
      );

      if (mounted) {
        if (response.statusCode == 200) {
          await _fetchData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao confirmar: ${response.body}')),
          );
           if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão ao confirmar.')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // ✅ LÓGICA DE RENDERIZAÇÃO SIMPLIFICADA E CORRIGIDA ✅
          child: _isLoading
              ? const Center(child: CircularProgressIndicator()) // 1. Se está carregando, MOSTRA O LOADING.
              : _proximoLembrete == null
                  ? _buildSuccessScreen() // 2. Se não está carregando E não tem remédio, MOSTRA SUCESSO.
                  : _buildRemedyScreen(), // 3. Se não está carregando E tem remédio, MOSTRA O REMÉDIO.
        ),
      ),
    );
  }

  // --- Widgets de construção da UI (divididos para maior clareza) ---

  Widget _buildSuccessScreen() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            _mensagemTela,
            style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRemedyScreen() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.waving_hand_rounded, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Text('Olá, $_nomeParente!', style: textTheme.headlineSmall?.copyWith(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('HORA DO REMÉDIO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.2)),
            Text(_proximoLembrete!.horario, style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 24),
            Text(_proximoLembrete!.nome, textAlign: TextAlign.center, style: textTheme.displaySmall?.copyWith(color: colorScheme.primary)),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 113, 215, 10).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 5),
              )
            ],
            borderRadius: BorderRadius.circular(32),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 113, 215, 10),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 120),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
            onPressed: _isLoading ? null : _confirmarRemedio,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('✓  JÁ TOMEI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
        ),
      ],
    );
  }
}