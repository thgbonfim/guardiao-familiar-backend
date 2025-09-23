import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';  // Importa o Logger

class AddRelativeScreen extends StatefulWidget {
  final String familyId;
  const AddRelativeScreen({required this.familyId, super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddRelativeScreenState createState() => _AddRelativeScreenState();
}

class _AddRelativeScreenState extends State<AddRelativeScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage; // variável para mostrar erro

  final String _apiUrl = "http://10.0.2.2:8000";

  final Logger logger = Logger('AddRelativeScreen');  // Logger

  Future<void> _addRelative() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;  // limpa erro antes de começar
    });

    final url = Uri.parse('$_apiUrl/parentes/cadastrar');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_da_familia': widget.familyId,
          'nome': _nameController.text.trim(),
          'apelido': _nicknameController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return; // garante que o contexto ainda existe
        Navigator.pop(context, true);
      } else {
        logger.warning("ERRO AO ADICIONAR PARENTE: Código ${response.statusCode}");
        setState(() {
          _errorMessage = "Erro ao adicionar parente: código ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.severe("Erro ao adicionar parente: $e");
      setState(() {
        _errorMessage = "Erro de conexão. Tente novamente.";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Parente'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) // Mostra erro se houver
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nome do seu pai ou mãe",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: "Apelido (Ex: Mãe)",
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _addRelative,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0),
                    )
                  : const Text("SALVAR PARENTE"),
            ),
          ],
        ),
      ),
    );
  }
}
