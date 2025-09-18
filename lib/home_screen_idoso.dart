// lib/home_screen_idoso.dart - A interface ultra-simples para o parente

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Para o timer de atualização

// Modelo simples para o lembrete de remédio
class Lembrete {
  final String id;
  final String nome;
  final String horario;
  Lembrete({required this.id, required this.nome, required this.horario});
}

class HomeScreenIdoso extends StatefulWidget {
  // No futuro, o ID do parente virá de um login, por enquanto, vamos fixá-lo
  final String parenteId = "a8646d0e-d4ea-44cf-901b-e624b9e682e6";

  const HomeScreenIdoso({super.key});

  @override
  State<HomeScreenIdoso> createState() => _HomeScreenIdosoState();
}

class _HomeScreenIdosoState extends State<HomeScreenIdoso> {
  Lembrete? _proximoLembrete;
  bool _isLoading = true;
  String _mensagem = "Carregando lembretes...";

  @override
  void initState() {
    super.initState();
    _buscarLembretes();
    // Inicia um timer para verificar por novos lembretes a cada minuto
    Timer.periodic(const Duration(minutes: 1), (timer) => _buscarLembretes());
  }

  Future<void> _buscarLembretes() async {
    // Busca na API os remédios do parente (cujo ID está fixado acima)
    final url = Uri.parse('http://10.0.2.2:8000/parentes/${widget.parenteId}/remedios');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> remediosData = json.decode(response.body);
        // Lógica para encontrar o próximo remédio do dia (simplificado por enquanto)
        // Aqui, vamos apenas pegar o primeiro da lista como exemplo
        if (remediosData.isNotEmpty) {
          final primeiroRemedio = remediosData[0];
          setState(() {
            _proximoLembrete = Lembrete(
              id: primeiroRemedio['id'],
              nome: primeiroRemedio['nome_do_remedio'],
              horario: primeiroRemedio['horario'],
            );
            _isLoading = false;
          });
        } else {
           setState(() {
            _proximoLembrete = null;
            _mensagem = "Nenhum remédio para hoje. Pode descansar!";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Erro ao buscar lembretes: $e");
      setState(() {
        _mensagem = "Erro de conexão.";
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmarRemedio() async {
    if (_proximoLembrete == null) return;

    final url = Uri.parse('http://10.0.2.2:8000/remedios/confirmar');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_do_remedio': _proximoLembrete!.id}),
      );

      if (response.statusCode == 200 && mounted) {
        print("Confirmação enviada com sucesso!");
        setState(() {
          _proximoLembrete = null; // Remove o lembrete da tela após confirmar
          _mensagem = "Obrigado por confirmar! Tenha um ótimo dia!";
        });
      }
    } catch (e) { print("Erro ao confirmar: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Se estiver carregando, mostra um indicador
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              // Se não houver lembrete, mostra uma mensagem de descanso
              : _proximoLembrete == null
                  ? Center(child: Text(_mensagem, style: const TextStyle(fontSize: 28, color: Colors.grey), textAlign: TextAlign.center,))
                  // Se houver um lembrete, mostra a tela principal
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            Text(
                              'HORA DO REMÉDIO',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                            Text(
                              _proximoLembrete!.horario,
                              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _proximoLembrete!.nome,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 150), // Botão gigante
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: _confirmarRemedio,
                          child: const Text('✓  JÁ TOMEI', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}