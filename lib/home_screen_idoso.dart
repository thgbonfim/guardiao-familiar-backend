// lib/home_screen_idoso.dart - (VERSÃO REATORADA E COM NOVO ESTILO)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Modelo de Dados ---
class Lembrete {
  final String id;
  final String nome;
  final String horario;
  bool confirmado;

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
    );
  }
}

// --- Tela Principal ---
class HomeScreenIdoso extends StatefulWidget {
  final String parenteId;
  final String nomeParente;

  const HomeScreenIdoso({
    super.key,
    required this.parenteId,
    required this.nomeParente,
  });

  @override
  State<HomeScreenIdoso> createState() => _HomeScreenIdosoState();
}

class _HomeScreenIdosoState extends State<HomeScreenIdoso> {
  final Logger logger = Logger('HomeScreenIdoso');
  final String apiUrl = "http://10.0.2.2:8000";

  List<Lembrete> _remedios = [];
  bool _isLoading = true;
  String _mensagemTela = "Carregando lembretes...";
  Timer? _timer;
  Set<String> _remediosConfirmadosIds = {};

  @override
  void initState() {
    super.initState();
    _setupLogger();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadConfirmedRemedios();
    await _fetchData();
    _iniciarTimer();
  }

  void _setupLogger() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
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

  // --- Lógica de Persistência Local (SharedPreferences) ---
  String get _prefsKey => 'remedios_confirmados_${widget.parenteId}';

  Future<void> _loadConfirmedRemedios() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _remediosConfirmadosIds = prefs.getStringList(_prefsKey)?.toSet() ?? {};
      });
    }
  }

  Future<void> _saveConfirmedRemedios() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _remediosConfirmadosIds.toList());
  }

  // --- Lógica de Comunicação com a API ---
  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$apiUrl/parentes/${widget.parenteId}/remedios');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<Lembrete> remediosDaApi = jsonList.map((json) => Lembrete.fromJson(json)).toList();
        
        // Atualiza o estado da lista com base nas confirmações salvas localmente
        _updateRemediosState(remediosDaApi);
      } else {
        _updateUIOnError("Falha ao carregar dados do servidor.");
      }
    } catch (e) {
      logger.severe("Erro de conexão em _fetchData: $e");
      _updateUIOnError("Erro de conexão. Verifique sua internet.");
    }
  }

  Future<void> _confirmarRemedio(Lembrete remedio) async {
    // Para o timer temporariamente para evitar chamadas conflitantes
    _timer?.cancel();

    // Feedback imediato na UI
    setState(() {
      remedio.confirmado = true;
      _remediosConfirmadosIds.add(remedio.id);
    });
    await _saveConfirmedRemedios();
    
    // Confirma no servidor em segundo plano
    try {
      final url = Uri.parse('$apiUrl/remedios/confirmar');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_do_remedio': remedio.id}),
      ).timeout(const Duration(seconds: 10));
      
      logger.info('Remédio ${remedio.nome} confirmado no servidor com sucesso!');
      _showSnackBar('Remédio ${remedio.nome} confirmado!');

    } catch (e) {
      logger.warning('Falha ao confirmar no servidor (salvo localmente): $e');
      _showSnackBar('Remédio confirmado (offline).');
      // Opcional: implementar lógica para tentar sincronizar mais tarde
    } finally {
      // Reinicia o timer após a operação
      _iniciarTimer();
    }
  }

  // --- Métodos de Atualização de Estado e UI ---
  void _updateRemediosState(List<Lembrete> listaDaApi) {
    if (!mounted) return;

    for (var remedio in listaDaApi) {
      if (_remediosConfirmadosIds.contains(remedio.id)) {
        remedio.confirmado = true;
      }
    }
    
    setState(() {
      _remedios = listaDaApi;
      if (_remedios.isEmpty) {
        _mensagemTela = "Nenhum remédio agendado para hoje.";
      }
      _isLoading = false;
    });
  }

  void _updateUIOnError(String message) {
    if (mounted) {
      setState(() {
        _remedios = [];
        _mensagemTela = message;
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  bool _checkAllConfirmed() {
    if (_remedios.isEmpty) return true;
    return _remedios.every((remedio) => remedio.confirmado);
  }

  // --- Widgets de Construção da UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _checkAllConfirmed()
                  ? _buildMessageScreen("Você já tomou todos os seus remédios por hoje. Parabéns!")
                  : _buildRemediesList(),
        ),
      ),
    );
  }

  Widget _buildMessageScreen(String message) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            message,
            style: textTheme.headlineSmall?.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRemediesList() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: _remedios.length,
            itemBuilder: (context, index) {
              final remedio = _remedios[index];
              return _buildRemedyCard(remedio);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waving_hand_rounded, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Text(
            'Olá, ${widget.nomeParente}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildRemedyCard(Lembrete remedio) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 4,
      shadowColor: colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('HORA DO REMÉDIO', style: textTheme.bodyLarge?.copyWith(color: Colors.black54, fontWeight: FontWeight.bold)),
            Text(remedio.horario, style: textTheme.displayLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              remedio.nome,
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildConfirmationButton(remedio),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationButton(Lembrete remedio) {
    if (remedio.confirmado) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 8),
          Text('Confirmado!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _confirmarRemedio(remedio),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 113, 215, 10),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text('✓ JÁ TOMEI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}