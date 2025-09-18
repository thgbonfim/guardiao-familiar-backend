import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddRelativeScreen extends StatefulWidget {
  final String familyId;
  const AddRelativeScreen({required this.familyId, super.key});

  @override
  _AddRelativeScreenState createState() => _AddRelativeScreenState();
}

class _AddRelativeScreenState extends State<AddRelativeScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();

  Future<void> _addRelative() async {
    final url = Uri.parse('http://10.0.2.2:8000/parentes/cadastrar');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_da_familia': widget.familyId, 'nome': _nameController.text, 'apelido': _nicknameController.text}),
      );
      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context);
      } else {
        print("ERRO AO ADICIONAR PARENTE: Código ${response.statusCode}");
      }
    } catch (e) {
      print("ERRO DE CONEXÃO: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Parente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nome do seu pai ou mãe")),
          const SizedBox(height: 16),
          TextField(controller: _nicknameController, decoration: const InputDecoration(labelText: "Apelido (Ex: Mãe)")),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _addRelative, child: const Text("SALVAR PARENTE")),
        ],),
      ),
    );
  }
}