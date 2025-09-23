import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'package:guardiao_familiar/add_relative_screen.dart';
import 'package:guardiao_familiar/add_medication_screen.dart';

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
  bool foiTomado;
  Remedio({
    required this.id,
    required this.nome,
    required this.horario,
    this.foiTomado = false,
  });
}

class HomeScreen extends StatefulWidget {
  final String familyId;
  final String familyName;
  const HomeScreen({required this.familyId, required this.familyName, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger logger = Logger('HomeScreen');
  final String _apiUrl = "http://10.0.2.2:8000";

  final ValueNotifier<List<Parente>> _parentesNotifier = ValueNotifier([]);
  bool _isLoading = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _setupLogging();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer.cancel();
    _parentesNotifier.dispose();
    super.dispose();
  }

  void _setupLogging() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint(
          '[${record.level.name}] ${record.time}: ${record.loggerName} - ${record.message}');
    });
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final parentesUrl = Uri.parse('$_apiUrl/familias/${widget.familyId}/parentes');
      final parentesResponse = await http.get(parentesUrl);
      if (parentesResponse.statusCode == 200) {
        final List<dynamic> parentesData = json.decode(parentesResponse.body);
        final List<Parente> parentesCarregados = parentesData
            .map((data) => Parente(id: data['id'], nome: data['nome']))
            .toList();

        final futuresRemedios = parentesCarregados.map((parente) async {
          final remediosUrl = Uri.parse('$_apiUrl/parentes/${parente.id}/remedios');
          final remediosResponse = await http.get(remediosUrl);
          if (remediosResponse.statusCode == 200) {
            final List<dynamic> remediosData = json.decode(remediosResponse.body);
            parente.remedios = remediosData
                .map((r) => Remedio(
                      id: r['id'],
                      nome: r['nome_do_remedio'],
                      horario: r['horario'],
                      foiTomado: r['foi_tomado'] ?? false,
                    ))
                .toList();
          }
        }).toList();

        await Future.wait(futuresRemedios);
        _parentesNotifier.value = parentesCarregados;
      }
    } catch (e) {
      logger.severe("Erro ao buscar dados: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleConfirmarRemedio(Parente parente, Remedio remedio, bool novoValor) async {
    try {
      // 🔹 Endpoint corrigido: /remedios/confirmar
      final url = Uri.parse('$_apiUrl/remedios/confirmar');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"id_do_remedio": remedio.id}),
      );

      if (response.statusCode == 200) {
        remedio.foiTomado = novoValor;
        _parentesNotifier.notifyListeners();
        logger.info(
            "Remédio ${remedio.nome} atualizado para ${novoValor ? "Tomado" : "Não tomado"}");
      } else {
        logger.warning("Falha ao confirmar remédio: ${response.body}");
      }
    } catch (e) {
      logger.severe("Erro ao confirmar remédio: $e");
    }
  }

  void _navigateToAddRelative(BuildContext context) async {
    final bool? parenteFoiAdicionado = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddRelativeScreen(familyId: widget.familyId)),
    );
    if (parenteFoiAdicionado == true) _fetchData();
  }

  void _navigateToAddMedication(BuildContext context, Parente parente) async {
    final bool? remedioFoiAdicionado = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              AddMedicationScreen(parenteId: parente.id, parenteNome: parente.nome)),
    );
    if (remedioFoiAdicionado == true) _fetchData();
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
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ValueListenableBuilder<List<Parente>>(
                valueListenable: _parentesNotifier,
                builder: (context, parentes, _) {
                  if (parentes.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: parentes.length,
                    itemBuilder: (context, index) {
                      final parente = parentes[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(parente.nome,
                                  style: Theme.of(context).textTheme.headlineSmall),
                              const Divider(),
                              if (parente.remedios.isEmpty)
                                const Text('Nenhum lembrete cadastrado.')
                              else
                                ...parente.remedios.map((remedio) => CheckboxListTile(
                                      value: remedio.foiTomado,
                                      onChanged: (novoValor) {
                                        if (novoValor != null &&
                                            !remedio.foiTomado) {
                                          _toggleConfirmarRemedio(
                                              parente, remedio, novoValor);
                                        }
                                      },
                                      title: Text(remedio.nome),
                                      subtitle: Text(remedio.horario),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    )),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.tonal(
                                  onPressed: () =>
                                      _navigateToAddMedication(context, parente),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add),
                                      SizedBox(width: 8),
                                      Text('Novo Lembrete'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddRelative(context),
        tooltip: 'Adicionar Parente',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
        child: Text("Clique no '+' para adicionar um parente."));
  }
}
