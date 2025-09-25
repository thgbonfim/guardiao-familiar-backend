// lib/add_medication_screen.dart - VERSÃO CORRIGIDA

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddMedicationScreen extends StatefulWidget {
  final String parenteId;
  final String parenteNome;

  const AddMedicationScreen({
    required this.parenteId,
    required this.parenteNome,
    super.key,
  });

  @override
  AddMedicationScreenState createState() => AddMedicationScreenState();
}

class AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _horarioController = TextEditingController();
  
  // ====================== AQUI ESTÁ A CORREÇÃO ======================
  // Alteramos as chaves do mapa para corresponder exatamente ao que o back-end espera.
  final Map<String, bool> _diasSelecionados = {
    'Segunda-feira': true,
    'Terça-feira': true,
    'Quarta-feira': true,
    'Quinta-feira': true,
    'Sexta-feira': true,
    'Sábado': false,
    'Domingo': false,
  };
  // =================================================================

  bool _isLoading = false;

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final List<String> diasFinais = _diasSelecionados.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();

    if (diasFinais.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, selecione pelo menos um dia da semana.')),
        );
        return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://10.0.2.2:8000/remedios/cadastrar');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_do_parente': widget.parenteId,
          'nome_do_remedio': _nomeController.text,
          'horario': _horarioController.text,
          'dias_da_semana': diasFinais,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          Navigator.pop(context, true);
        } else {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${errorData['detail'] ?? 'Não foi possível salvar o lembrete.'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão ao salvar o lembrete.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novo Lembrete para ${widget.parenteNome}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome do Remédio'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _horarioController,
                  decoration: const InputDecoration(labelText: 'Horário (HH:MM)', hintText: 'Ex: 08:30'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 24),
                Text('Repetir nos dias:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _diasSelecionados.keys.map((dia) {
                    // O rótulo do botão continua pequeno (ex: "SEG"), mas o valor enviado será "Segunda-feira".
                    return FilterChip(
                      label: Text(dia.substring(0,3).toUpperCase()),
                      selected: _diasSelecionados[dia]!,
                      onSelected: (bool selecionado) {
                        setState(() {
                          _diasSelecionados[dia] = selecionado;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveMedication,
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3)) 
                      : const Text('SALVAR LEMBRETE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}