import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardiao_familiar/home_screen_idoso.dart';
import 'package:logging/logging.dart';

void main() {
  _setupLogging();
  runApp(GuardiaoFamiliarApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.time}: ${record.loggerName} - ${record.message}',
    );
  });
}

class GuardiaoFamiliarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardião Familiar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: ParentesScreen(familiaId: "7842756d-fbb5-45a9-b2e9-78a7617fc460"),
    );
  }
}

// Modelo de parente
class Parente {
  final String id;
  final String nome;

  Parente({required this.id, required this.nome});

  factory Parente.fromJson(Map<String, dynamic> json) {
    return Parente(
      id: json['id'] ?? '',
      nome: json['nome'] ?? 'Sem nome',
    );
  }
}

// Tela de seleção de parentes com fetch do backend
class ParentesScreen extends StatefulWidget {
  final String familiaId;

  const ParentesScreen({super.key, required this.familiaId});

  @override
  State<ParentesScreen> createState() => _ParentesScreenState();
}

class _ParentesScreenState extends State<ParentesScreen> {
  final Logger logger = Logger('ParentesScreen');
  final String apiUrl = "http://10.0.2.2:8000"; // Ajuste se necessário

  late Future<List<Parente>> _futureParentes;

  @override
  void initState() {
    super.initState();
    _futureParentes = _fetchParentes();
  }

  Future<List<Parente>> _fetchParentes() async {
    try {
      final url = Uri.parse('$apiUrl/familias/${widget.familiaId}/parentes');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Parente.fromJson(json)).toList();
      } else {
        logger.warning('Falha ao carregar parentes: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      logger.severe('Erro ao buscar parentes: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escolha o parente"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Parente>>(
        future: _futureParentes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar parentes.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum parente encontrado.'));
          } else {
            final parentes = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: parentes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final parente = parentes[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: ListTile(
                    title: Text(
                      parente.nome,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreenIdoso(
                            parenteId: parente.id,
                            nomeParente: parente.nome,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
