// create_family_screen.dart - (VERSÃO FINAL E CORRIGIDA)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart'; 

class CreateFamilyScreen extends StatefulWidget {
  final String userId;
  const CreateFamilyScreen({required this.userId, super.key});

  @override
  _CreateFamilyScreenState createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _familyNameController = TextEditingController();
  bool _isLoading = false; // Adicionado para dar feedback ao usuário

  Future<void> _createFamily() async {
    if (_familyNameController.text.trim().isEmpty) {
      // Evita criar família com nome vazio
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite um nome para a família.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('http://10.0.2.2:8000/familias/criar');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_do_usuario': widget.userId,
          'nome_da_familia': _familyNameController.text,
        }),
      );

      if (mounted) { // Garante que a tela ainda existe antes de navegar
        if (response.statusCode == 200) {
          print("FAMÍLIA CRIADA COM SUCESSO!");
          
          final responseData = json.decode(response.body);
          
          // ✅✅✅ CORREÇÃO PRINCIPAL APLICADA AQUI ✅✅✅
          // A API agora retorna a chave "id" em vez de "id_da_familia".
          final String? familyId = responseData['id'];

          // Verificação extra para garantir que o ID não é nulo
          if (familyId == null) {
              throw Exception("ID da família retornado como nulo pela API.");
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                familyId: familyId, // Agora 'familyId' terá um valor válido
                familyName: _familyNameController.text,
              ),
            ),
            (Route<dynamic> route) => false, // Remove todas as telas anteriores
          );

        } else {
          // Mostra o erro da API para o usuário
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${errorData['detail'] ?? 'Não foi possível criar a família.'}')),
          );
        }
      }

    } catch (e) {
      print("ERRO DE CONEXÃO OU NA LÓGICA: $e");
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro de conexão. Verifique o servidor.')),
          );
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Dê um nome ao seu grupo familiar para começar a cuidar de quem você ama.", 
              textAlign: TextAlign.center, 
              style: Theme.of(context).textTheme.titleMedium,
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
              onPressed: _isLoading ? null : _createFamily, // Desabilita o botão enquanto carrega
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                  ? const SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)
                    )
                  : const Text("CRIAR FAMÍLIA E ACESSAR"),
            ),
        ],),
      ),
    );
  }
}