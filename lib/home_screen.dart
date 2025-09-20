// lib/home_screen.dart - (VERSÃO FINAL, COMPLETA E CORRIGIDA)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:guardiao_familiar/add_relative_screen.dart';
import 'package:guardiao_familiar/add_medication_screen.dart';

// Modelos de dados para organizar as informações
class Parente {
  final String id;
  final String nome;
  List<Remedio> remedios = [];
  Parente({required this.id, required this.nome});
}

class Remedio {
  final String nome;
  final String horario;
  Remedio({required this.nome, required this.horario});
}

class HomeScreen extends StatefulWidget {
  final String familyId;
  final String familyName;
  const HomeScreen({required this.familyId, required this.familyName, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Parente> _parentes = [];
  bool _isLoading = true;
  final String _apiUrl = "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    List<Parente> parentesCarregados = [];
    try {
      final parentesUrl = Uri.parse('$_apiUrl/familias/${widget.familyId}/parentes');
      final parentesResponse = await http.get(parentesUrl);

      if (parentesResponse.statusCode == 200) {
        final List<dynamic> parentesData = json.decode(parentesResponse.body);
        parentesCarregados = parentesData.map((data) => Parente(id: data['id'], nome: data['nome'])).toList();
        for (var parente in parentesCarregados) {
          final remediosUrl = Uri.parse('$_apiUrl/parentes/${parente.id}/remedios');
          final remediosResponse = await http.get(remediosUrl);
          if (remediosResponse.statusCode == 200) {
            final List<dynamic> remediosData = json.decode(remediosResponse.body);
            parente.remedios = remediosData.map((data) => Remedio(nome: data['nome_do_remedio'], horario: data['horario'])).toList();
          }
        }
      }
    } catch (e) {
      print("Erro ao buscar dados: $e");
    }
    setState(() {
      _parentes = parentesCarregados;
      _isLoading = false;
    });
  }

  void _navigateToAddRelative(BuildContext context) async {
    final bool? parenteFoiAdicionado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddRelativeScreen(familyId: widget.familyId)),
    );
    if (parenteFoiAdicionado == true) {
      _fetchData();
    }
  }

  void _navigateToAddMedication(BuildContext context, Parente parente) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMedicationScreen(parenteId: parente.id, parenteNome: parente.nome)),
    );
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.familyName),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parentes.isEmpty ? _buildEmptyState() : _buildRelativesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddRelative(context),
        tooltip: 'Adicionar Parente',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.group_add_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Nenhum parente cadastrado.',
            style: textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Clique no botão "+" para adicionar um familiar e começar a cuidar.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }

  Widget _buildRelativesList() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _parentes.length,
      itemBuilder: (context, index) {
        final parente = _parentes[index];
        return Card(
          elevation: 4,
          shadowColor: colorScheme.primary.withOpacity(0.2),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                parente.nome,
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const Divider(height: 24.0, thickness: 0.5),
              if (parente.remedios.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: Text('Nenhum lembrete cadastrado.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  ),
                )
              else
                ...parente.remedios.map((remedio) => ListTile(
                      leading: Icon(Icons.medication_outlined, color: colorScheme.secondary),
                      title: Text(remedio.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(remedio.horario),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )).toList(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => _navigateToAddMedication(context, parente),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text('Novo Lembrete'),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}