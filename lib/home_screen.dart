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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    List<Parente> parentesCarregados = [];
    try {
      final parentesUrl = Uri.parse('http://10.0.2.2:8000/familias/${widget.familyId}/parentes');
      final parentesResponse = await http.get(parentesUrl);

      if (parentesResponse.statusCode == 200) {
        final List<dynamic> parentesData = json.decode(parentesResponse.body);
        parentesCarregados = parentesData.map((data) => Parente(id: data['id'], nome: data['nome'])).toList();
        for (var parente in parentesCarregados) {
          final remediosUrl = Uri.parse('http://10.0.2.2:8000/parentes/${parente.id}/remedios');
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddRelativeScreen(familyId: widget.familyId)),
    );
    _fetchData();
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
      appBar: AppBar(title: Text(widget.familyName), automaticallyImplyLeading: false),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Bem-vindo(a)!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Vamos começar adicionando o familiar que você irá cuidar.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _navigateToAddRelative(context),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: const Text('+ Adicionar Parente', style: TextStyle(fontSize: 18)),
          ),
        ],),
      ),
    );
  }

  Widget _buildRelativesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _parentes.length,
      itemBuilder: (context, index) {
        final parente = _parentes[index];
        return Card(
          elevation: 4, margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(parente.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (parente.remedios.isEmpty)
                const Text('Nenhum lembrete de remédio cadastrado ainda.')
              else
                ...parente.remedios.map((remedio) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• ${remedio.nome} - ${remedio.horario}'),
                    )).toList(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _navigateToAddMedication(context, parente),
                  child: const Text('+ Novo Lembrete'),
                ),
              ),
            ],),
          ),
        );
      },
    );
  }
}