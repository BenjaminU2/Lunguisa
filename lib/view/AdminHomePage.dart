import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'admin_problems_page.dart';
import 'user_list_page.dart';
import 'appwrite_cliente.dart';
import 'LoginPage.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final Account _account = Account(AppwriteClient.client);
  final Databases _databases = Databases(AppwriteClient.client);

  int _problemCount = 0;
  int _userCount = 0;
  int _pendingCount = 0;
  int _resolvedCount = 0;

  int _segurancaCount = 0;
  int _limpezaCount = 0;
  int _buracoCount = 0;
  int _iluminacaoCount = 0;
  int _outroCount = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AppwriteClient.account.deleteSession(sessionId: 'current');
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadCounts() async {
    try {
      final problems = await _databases.listDocuments(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
      );

      int pending = 0;
      int resolved = 0;

      int seguranca = 0;
      int limpeza = 0;
      int buraco = 0;
      int iluminacao = 0;
      int outro = 0;

      final documents = problems.documents;

      for (var doc in documents) {
        final status = doc.data['status']?.toString().toLowerCase() ?? '';
        final category = doc.data['category']?.toString().toLowerCase() ?? '';

        if (status == 'pendente') pending++;
        if (status == 'resolvido') resolved++;

        if (category == 'segurança') seguranca++;
        else if (category == 'limpeza') limpeza++;
        else if (category == 'buraco') buraco++;
        else if (category == 'iluminação') iluminacao++;
        else outro++;
      }

      setState(() {
        _problemCount = problems.total;
        _pendingCount = pending;
        _resolvedCount = resolved;

        _segurancaCount = seguranca;
        _limpezaCount = limpeza;
        _buracoCount = buraco;
        _iluminacaoCount = iluminacao;
        _outroCount = outro;

        _userCount = 7; // Simulado
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erro ao carregar contagens: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Problemas Reportados'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllProblemsPage(client: AppwriteClient.client),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Lista de Usuários'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserListPage(client: AppwriteClient.client),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumo', style: textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryCard(Icons.report, 'Problemas', _problemCount),
                  const SizedBox(width: 16),
                  _buildSummaryCard(Icons.people, 'Usuários', _userCount),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryCard(Icons.hourglass_empty, 'Pendentes', _pendingCount),
                  const SizedBox(width: 16),
                  _buildSummaryCard(Icons.check_circle, 'Resolvidos', _resolvedCount),
                ],
              ),
              const SizedBox(height: 32),
              Text('Por Categoria', style: textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryCard(Icons.security, 'Segurança', _segurancaCount),
                  const SizedBox(width: 16),
                  _buildSummaryCard(Icons.cleaning_services, 'Limpeza', _limpezaCount),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryCard(Icons.construction, 'Buraco', _buracoCount),
                  const SizedBox(width: 16),
                  _buildSummaryCard(Icons.lightbulb, 'Iluminação', _iluminacaoCount),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryCard(Icons.category, 'Outro', _outroCount),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()), // espaçamento
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String label, int count) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}