// add_medication_screen.dart - Tela para cadastrar um lembrete de remédio

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddMedicationScreen extends StatefulWidget {
  final String parenteId;
  final String parenteNome;

  const AddMedicationScreen({required this.parenteId, required this.parenteNome, super.key});

  @override
  _AddMedicationScreenState createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _remedioNomeController = TextEditingController();
  final _horarioController = TextEditingController();
  
  // Mapa para controlar quais dias da semana estão selecionados
  final Map<String, bool> _diasSelecionados = {
    'domingo': false, 'segunda': true, 'terca': true, 'quarta': true, 
    'quinta': true, 'sexta': true, 'sabado': false,
  };

  Future<void> _salvarLembrete() async {
    final url = Uri.parse('http://10.0.2.2:8000/remedios/cadastrar');
    
    // Pega a lista de dias que foram marcados como 'true'
    final List<String> dias = _diasSelecionados.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_do_parente': widget.parenteId,
          'nome_do_remedio': _remedioNomeController.text,
          'horario': _horarioController.text,
          'dias_da_semana': dias,
        }),
      );

      if (response.statusCode == 200) {
        print("LEMBRETE DE REMÉDIO SALVO COM SUCESSO!");
        if (mounted) Navigator.pop(context); // Volta para a tela principal
      } else {
        print("ERRO AO SALVAR LEMBRETE: Código ${response.statusCode}");
        print("Resposta da API: ${response.body}");
      }
    } catch (e) {
      print("ERRO DE CONEXÃO: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novo Lembrete para ${widget.parenteNome}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _remedioNomeController,
              decoration: InputDecoration(labelText: 'Nome do Remédio'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _horarioController,
              decoration: InputDecoration(labelText: 'Horário (ex: 08:00)'),
              keyboardType: TextInputType.datetime,
            ),
            SizedBox(height: 24),
            Text('Dias da Semana:', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            // Componentes para selecionar os dias da semana
            Wrap(
              spacing: 8.0,
              children: _diasSelecionados.keys.map((String dia) {
                return FilterChip(
                  label: Text(dia.substring(0, 3).toUpperCase()),
                  selected: _diasSelecionados[dia]!,
                  onSelected: (bool selecionado) {
                    setState(() {
                      _diasSelecionados[dia] = selecionado;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _salvarLembrete,
              child: Text('SALVAR LEMBRETE'),
            ),
          ],
        ),
      ),
    );
  }
}