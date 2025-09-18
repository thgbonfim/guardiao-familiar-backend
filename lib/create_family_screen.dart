import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardiao_familiar/home_screen.dart';

class CreateFamilyScreen extends StatefulWidget {
  final String userId;
  const CreateFamilyScreen({required this.userId, super.key});

  @override
  _CreateFamilyScreenState createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _familyNameController = TextEditingController();

  Future<void> _createFamily() async {
    final url = Uri.parse('http://10.0.2.2:8000/familias/criar');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_do_usuario': widget.userId, 'nome_da_familia': _familyNameController.text}),
      );

      if (response.statusCode == 200 && mounted) {
        final responseData = json.decode(response.body);
        final familyId = responseData['id_da_familia'];
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(familyId: familyId, familyName: _familyNameController.text)),
          (Route<dynamic> route) => false,
        );
      } else {
        print("ERRO AO CRIAR FAMÍLIA: Código ${response.statusCode}");
      }
    } catch (e) {
      print("ERRO DE CONEXÃO: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crie sua Família")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Dê um nome ao seu grupo familiar para começar a cuidar de quem você ama.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextField(controller: _familyNameController, decoration: const InputDecoration(labelText: "Ex: Família Silva")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _createFamily, child: const Text("CRIAR FAMÍLIA E ACESSAR")),
          ],
        ),
      ),
    );
  }
}