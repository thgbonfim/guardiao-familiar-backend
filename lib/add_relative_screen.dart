// lib/add_relative_screen.dart - (VERSÃO COM DESIGN POLIDO)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  final String _apiUrl = "http://10.0.2.2:8000";

  Future<void> _addRelative() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final url = Uri.parse('$_apiUrl/parentes/cadastrar');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_da_familia': widget.familyId,
          'nome': _nameController.text,
          'apelido': _nicknameController.text,
        }),
      );
      if (response.statusCode == 200 && mounted) {
        // Retorna 'true' para a tela anterior saber que o cadastro deu certo
        Navigator.pop(context, true); 
      } else {
        // Aqui poderíamos adicionar um _errorMessage para mostrar na tela
        print("ERRO AO ADICIONAR PARENTE: Código ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("ERRO DE CONEXÃO: $e");
      setState(() => _isLoading = false);
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
          // ### ALTERAÇÃO AQUI: Estica os widgets filhos para preencher a largura ###
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nome do seu pai ou mãe",
                prefixIcon: Icon(Icons.person_outline), // Ícone adicionado
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: "Apelido (Ex: Mãe)",
                prefixIcon: Icon(Icons.label_outline), // Ícone adicionado
              ),
            ),
            const SizedBox(height: 32),
            // ### ALTERAÇÃO AQUI: Botão com feedback de carregamento ###
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