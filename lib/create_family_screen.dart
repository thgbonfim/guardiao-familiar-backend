// create_family_screen.dart - (VERSÃO REFACTORED)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';  // Importa o logger

import 'home_screen.dart';

final logger = Logger('CreateFamilyScreen');  // Define o logger

class CreateFamilyScreen extends StatefulWidget {
  final String userId;

  const CreateFamilyScreen({required this.userId, super.key});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final TextEditingController _familyNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _addFamily() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://10.0.2.2:8000/familias/criar');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_do_usuario': widget.userId,                // Corrigido aqui
          'nome_da_familia': _familyNameController.text.trim(),  // Corrigido aqui
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final familyId = responseData['id'];                   // Chave 'id' conforme backend
        final familyName = responseData['nome_da_familia'];    // Chave 'nome_da_familia'

        if (familyId == null) {
          throw Exception("ID da família retornado como nulo pela API.");
        }

        logger.info("✅ FAMÍLIA CRIADA COM SUCESSO!");

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              familyId: familyId,
              familyName: familyName,
            ),
          ),
          (_) => false,
        );
      } else {
        final errorData = json.decode(response.body);
        if (!mounted) return;
        _showSnackbar(
          'Erro: ${errorData['detail'] ?? 'Não foi possível criar a família.'}',
        );
      }
    } catch (e, stackTrace) {
      logger.severe("❌ ERRO AO CRIAR FAMÍLIA: $e", e, stackTrace);
      if (!mounted) return;
      _showSnackbar('Erro de conexão. Verifique o servidor.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Crie sua Família")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Dê um nome ao seu grupo familiar para começar a cuidar de quem você ama.",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _familyNameController,
              decoration: const InputDecoration(
                labelText: "Ex: Família Silva",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addFamily,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Text("CRIAR FAMÍLIA E ACESSAR"),
            ),
          ],
        ),
      ),
    );
  }
}
