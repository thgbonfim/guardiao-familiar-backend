import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardiao_familiar/create_family_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _register() async {
    final url = Uri.parse('http://10.0.2.2:8000/usuarios/cadastrar');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nome_completo': _nameController.text,
          'email': _emailController.text,
          'senha': _passwordController.text,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        final responseData = json.decode(response.body);
        final userId = responseData['id_do_usuario'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CreateFamilyScreen(userId: userId),
          ),
        );
      } else {
        print("ERRO NO CADASTRO: Código ${response.statusCode}");
        print("Resposta da API: ${response.body}");
      }
    } catch (e) {
      print("ERRO DE CONEXÃO: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crie sua Conta")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Seu nome completo")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Seu melhor e-mail"), keyboardType: TextInputType.emailAddress),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Crie uma senha"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: const Text("CRIAR CONTA")),
          ],
        ),
      ),
    );
  }
}