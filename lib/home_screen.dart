// lib/home_screen.dart - (VERSÃO FINAL COM ORDENAÇÃO, GRUPOS E DATA)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Importa o pacote de formatação de data

// Garanta que estes arquivos existam no seu projeto
import 'package:guardiao_familiar/add_relative_screen.dart';
import 'package:guardiao_familiar/add_medication_screen.dart';

// --- Modelos de Dados ---
class Parente {
  final String id;
  final String nome;
  List<Remedio> remedios = [];

  Parente({required this.id, required this.nome});
}

class Remedio {
  final String id;
  final String nome;
  final String horario;
  bool isTaken;

  Remedio({required this.id, required this.nome, required this.horario, this.isTaken = false});

  // Factory para criar a partir do JSON (considerando que o back-end enviará 'foi_tomado')
  factory Remedio.fromJson(Map<String, dynamic> json) {
    return Remedio(
      id: json['id'],
      nome: json['nome_do_remedio'],
      horario: json['horario'],
      isTaken: json['foi_tomado'] ?? false,
    );
  }
}

// --- Tela Principal ---
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if(mounted && !_isLoading) _fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!_isLoading && mounted) setState(() => _isLoading = true);
   
    try {
      // ... (lógica de busca de parentes, já está correta) ...
      final parentesUrl = Uri.parse('$_apiUrl/familias/${widget.familyId}/parentes');
      final parentesResponse = await http.get(parentesUrl);

      if (parentesResponse.statusCode == 200) {
        final List<dynamic> parentesData = json.decode(parentesResponse.body);
        final List<Parente> parentesCarregados = parentesData.map((data) => Parente(id: data['id'], nome: data['nome'])).toList();

        final futuresRemedios = parentesCarregados.map((parente) async {
          final remediosUrl = Uri.parse('$_apiUrl/parentes/${parente.id}/remedios');
          final remediosResponse = await http.get(remediosUrl);
          if (remediosResponse.statusCode == 200) {
            final List<dynamic> remediosData = json.decode(remediosResponse.body);
            // ATENÇÃO: seu backend precisa enviar o campo 'foi_tomado' para o checkbox funcionar com dados reais
            parente.remedios = remediosData.map((r) => Remedio.fromJson(r)).toList();
            
            // ✅ ORDENA OS REMÉDIOS POR HORÁRIO
            parente.remedios.sort((a, b) => a.horario.compareTo(b.horario));
          }
        }).toList();

        await Future.wait(futuresRemedios);
        
        if (mounted) setState(() => _parentes = parentesCarregados);
      }
    } catch (e) {
      print("Erro ao buscar dados: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToAddRelative() async {
    final bool? result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddRelativeScreen(familyId: widget.familyId)));
    if (result == true) _fetchData();
  }

  void _navigateToAddMedication(Parente parente) async {
    final bool? result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddMedicationScreen(parenteId: parente.id, parenteNome: parente.nome)));
    if (result == true) _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ GERA O TEXTO COM O DIA DA SEMANA
    final String hoje = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        // ✅ TÍTULO COM DATA
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.familyName),
            Text(
              hoje,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        toolbarHeight: 70, // Aumenta a altura para caber o subtítulo
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _parentes.isEmpty 
                ? _buildEmptyState() 
                : _buildRelativesList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddRelative,
        tooltip: 'Adicionar Parente',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  // --- Widgets de Construção da UI ---

  Widget _buildEmptyState() {
    // ... (código do estado vazio, já está correto)
    return const Center(child: Text("Clique no '+' para adicionar um parente."));
  }

  Widget _buildRelativesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _parentes.length,
      itemBuilder: (context, index) {
        final parente = _parentes[index];
        return _buildParenteCard(parente);
      },
    );
  }

  Widget _buildParenteCard(Parente parente) {
    // ✅ LÓGICA DE AGRUPAMENTO
    final pendentes = parente.remedios.where((r) => !r.isTaken).toList();
    final tomados = parente.remedios.where((r) => r.isTaken).toList();

    return Card(
      // ... (estilo do Card, já está correto)
      elevation: 4, margin: const EdgeInsets.symmetric(vertical: 8.0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              children: [
                CircleAvatar(child: Text(parente.nome.isNotEmpty ? parente.nome[0] : 'P')),
                const SizedBox(width: 12),
                Text(parente.nome, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const Divider(height: 20),
            
            // Lista de remédios PENDENTES
            if (pendentes.isEmpty && tomados.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Nenhum lembrete cadastrado.')))
            else
              ...pendentes.map((remedio) => _buildRemedyTile(remedio)),
            
            // Divisor e lista de remédios TOMADOS
            if (tomados.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text("Concluídos", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              ...tomados.map((remedio) => _buildRemedyTile(remedio)),
            ],

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => _navigateToAddMedication(parente),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 8),
                  Text('Novo Lembrete'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemedyTile(Remedio remedio) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      value: remedio.isTaken,
      // Desabilita o checkbox se já foi tomado
      onChanged: remedio.isTaken ? null : (bool? newValue) {
        setState(() {
          remedio.isTaken = newValue ?? false;
        });
        // Aqui viria a chamada para a API para confirmar
        // _toggleConfirmarRemedio(remedio);
      },
      title: Text(
        remedio.nome, 
        // ✅ ESTILO PARA ITENS CONCLUÍDOS
        style: TextStyle(
          fontWeight: FontWeight.w500,
          decoration: remedio.isTaken ? TextDecoration.lineThrough : TextDecoration.none,
          color: remedio.isTaken ? Colors.grey : Colors.black,
        )
      ),
      secondary: Text(
        remedio.horario, 
        style: TextStyle(
          color: Colors.grey[600],
          decoration: remedio.isTaken ? TextDecoration.lineThrough : TextDecoration.none,
        )
      ),
    );
  }
}