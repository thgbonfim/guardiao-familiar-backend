import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:logging/logging.dart';

class Lembrete {
  final String id;
  final String nome;
  final String horario;
  final bool confirmado;

  Lembrete({
    required this.id,
    required this.nome,
    required this.horario,
    this.confirmado = false,
  });

  factory Lembrete.fromJson(Map<String, dynamic> json) {
    return Lembrete(
      id: json['id'] ?? '',
      nome: json['nome_do_remedio'] ?? 'Remédio desconhecido',
      horario: json['horario'] ?? '--:--',
      confirmado: json['confirmado'] ?? false,
    );
  }
}

class HomeScreenIdoso extends StatefulWidget {
  const HomeScreenIdoso({super.key});

  @override
  State<HomeScreenIdoso> createState() => _HomeScreenIdosoState();
}

class _HomeScreenIdosoState extends State<HomeScreenIdoso> {
  final Logger logger = Logger('HomeScreenIdoso');
  final String parenteId = "f3016f69-182f-4d4e-9795-636a71ed4878";
  final String apiUrl = "http://10.0.2.2:8000";

  Lembrete? _proximoLembrete;
  bool _isLoading = true;
  String _mensagemTela = "Carregando lembretes...";
  final String _nomeParente = "Querido(a)";
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _setupLogger();
    _fetchData();
    _iniciarTimer();
  }

  void _setupLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint(
          '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    });
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        logger.info("Timer ativado: Verificando novos remédios...");
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$apiUrl/parentes/$parenteId/remedios');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> remedios = json.decode(response.body);
        if (remedios.isNotEmpty) {
          final lembrete = Lembrete.fromJson(remedios.first);
          logger.fine("Lembrete recebido: ${lembrete.nome} às ${lembrete.horario}");
          setState(() {
            _proximoLembrete = lembrete;
            _mensagemTela = "";
            _isLoading = false;
          });
        } else {
          logger.info("Nenhum remédio pendente para hoje.");
          _cancelTimerWithMessage(
              "Você já tomou todos os seus remédios por hoje. Parabéns!");
        }
      } else {
        logger.warning("Resposta do servidor com código ${response.statusCode}");
        _updateUIOnError("Falha ao carregar dados do servidor.");
      }
    } catch (e) {
      logger.severe("Erro ao buscar dados: $e");
      _updateUIOnError("Erro de conexão. Verifique sua internet.");
    }
  }

  void _cancelTimerWithMessage(String message) {
    if (_timer?.isActive ?? false) {
      logger.info("Não há mais remédios pendentes, cancelando o Timer.");
      _timer?.cancel();
    }
    if (mounted) {
      setState(() {
        _proximoLembrete = null;
        _mensagemTela = message;
        _isLoading = false;
      });
    }
  }

  void _updateUIOnError(String message) {
    if (mounted) {
      setState(() {
        _proximoLembrete = null;
        _mensagemTela = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmarRemedio() async {
    if (_proximoLembrete == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$apiUrl/remedios/confirmar');
      final corpoJson = json.encode({'id_do_remedio': _proximoLembrete!.id});

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: corpoJson,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        logger.info("Remédio confirmado com sucesso: ${_proximoLembrete!.nome}");

        // Redireciona para a tela de sucesso e atualiza dados ao voltar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SucessoScreen(
              mensagem: 'Remédio confirmado com sucesso!',
            ),
          ),
        ).then((_) => _fetchData());
      } else {
        logger.warning("Erro ao confirmar remédio: ${response.body}");
        _showSnackBar('Erro ao confirmar: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      logger.severe("Erro de conexão ao confirmar remédio: $e");
      _showSnackBar('Erro de conexão ao confirmar.');
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _proximoLembrete == null
                  ? _buildMessageScreen(_mensagemTela)
                  : _buildRemedyScreen(),
        ),
      ),
    );
  }

  Widget _buildMessageScreen(String mensagem) {
    return Center(
      child: Text(
        mensagem,
        style: const TextStyle(fontSize: 18, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRemedyScreen() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (_proximoLembrete!.confirmado) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Você já confirmou o remédio:\n${_proximoLembrete!.nome}',
              style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.waving_hand_rounded, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Text(
                  'Olá, $_nomeParente!',
                  style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'HORA DO REMÉDIO',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              _proximoLembrete!.horario,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _proximoLembrete!.nome,
              textAlign: TextAlign.center,
              style: textTheme.displaySmall?.copyWith(color: colorScheme.primary),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 113, 215, 10).withAlpha(102),
                blurRadius: 20,
                offset: const Offset(0, 5),
              )
            ],
            borderRadius: BorderRadius.circular(32),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 113, 215, 10),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 120),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
            onPressed: _isLoading ? null : _confirmarRemedio,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    '✓  JÁ TOMEI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class SucessoScreen extends StatelessWidget {
  final String mensagem;

  const SucessoScreen({super.key, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
              const SizedBox(height: 32),
              Text(
                mensagem,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
