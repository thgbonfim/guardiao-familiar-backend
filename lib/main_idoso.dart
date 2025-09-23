import 'package:flutter/material.dart';
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
      home: ParentesScreen(),
    );
  }
}

// Modelo simples de parente
class Parente {
  final String id;
  final String nome;

  Parente({required this.id, required this.nome});
}

// Tela de seleção de parentes
class ParentesScreen extends StatelessWidget {
  ParentesScreen({super.key}); // Removido const

  // Lista de exemplo de parentes (você pode substituir por dados do backend)
  final List<Parente> parentes = [
    Parente(id: "f3016f69-182f-4d4e-9795-636a71ed4878", nome: "Querido(a)")
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escolha o parente"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: parentes.length,
        itemBuilder: (context, index) {
          final parente = parentes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: ListTile(
              title: Text(
                parente.nome,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navega para a tela do parente selecionado
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
      ),
    );
  }
}
