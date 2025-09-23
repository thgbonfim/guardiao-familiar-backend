// lib/register_screen.dart - (VERSÃO FINAL COM GRADIENTE)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:guardiao_familiar/create_family_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  final String _apiUrl = "http://10.0.2.2:8000";

  Future<void> _register() async {
    // A lógica de _register() continua a mesma
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _errorMessage = ''; });
    final url = Uri.parse('$_apiUrl/usuarios/cadastrar');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nome_completo': _fullNameController.text,
          'email': _emailController.text,
          'senha': _passwordController.text,
        }),
      );
      if (response.statusCode == 200 && mounted) {
        final responseData = json.decode(response.body);
        final userId = responseData['id_do_usuario'];
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CreateFamilyScreen(userId: userId)));
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = errorData['detail'] ?? 'Ocorreu um erro ao cadastrar.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão. Verifique o servidor.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ### NOVO: Aplicando o mesmo design da tela de Login ###
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
           Theme.of(context).colorScheme.primary.withAlpha((0.8 * 255).round()),
Theme.of(context).colorScheme.primary.withAlpha((0.5 * 255).round()),

              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text("Crie sua Conta", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
              floating: true,
            ),
            SliverFillRemaining(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 60,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(labelText: "Seu nome completo", prefixIcon: Icon(Icons.person_outline)),
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: "Seu melhor e-mail", prefixIcon: Icon(Icons.email_outlined)),
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: "Crie uma senha", prefixIcon: Icon(Icons.lock_outline)),
                          obscureText: true,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                          ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0),
                                )
                              : const Text("CRIAR CONTA"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}