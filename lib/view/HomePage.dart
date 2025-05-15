import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import 'appwrite_cliente.dart';
import 'ReportProblemPage.dart';

class HomePage extends StatefulWidget {
  final Client client;
  final String userId;

  const HomePage({super.key, required this.client, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Databases _databases;
  late final Account _account;
  List<Map<String, dynamic>> _problems = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _databases = Databases(widget.client);
    _account = Account(widget.client);
    _loadUserData();
    _fetchProblems();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _account.get();
      setState(() {
        _userName = user.name;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar dados do usuário: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchProblems() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _databases.listDocuments(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
        queries: [
          Query.orderDesc('createdAt'),
          Query.limit(20),
        ],
      );

      setState(() {
        _problems = response.documents.map((doc) => doc.data).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar problemas: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToReportProblem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportProblemPage(userId: widget.userId,userName: _userName,),
      ),
    );
  }

  void _logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sair: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProblemCard(Map<String, dynamic> problem) {
    final date = DateTime.parse(problem['createdAt']).toLocal();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getProblemIcon(problem['category']),
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  problem['title'] ?? 'Sem título',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              problem['description'] ?? 'Sem descrição',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  problem['location'] ?? 'Local desconhecido',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  problem['userName'] ?? 'Anônimo',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () => _upvoteProblem(problem['\$id']),
                  color: Colors.green,
                ),
                Text('${problem['upvotes'] ?? 0}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {},
                  color: Colors.green,
                ),
                Text('${problem['comments'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upvoteProblem(String problemId) async {
    try {
      final currentProblem = _problems.firstWhere((p) => p['\$id'] == problemId);
      final currentUpvotes = currentProblem['upvotes'] ?? 0;

      await _databases.updateDocument(
        databaseId: 'default',
        collectionId: 'problems',
        documentId: problemId,
        data: {
          'upvotes': currentUpvotes + 1,
        },
      );

      _fetchProblems(); // Atualiza a lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao votar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getProblemIcon(String category) {
    switch (category.toLowerCase()) {
      case 'buraco na via':
        return Icons.construction;
      case 'fios soltos':
        return Icons.electrical_services;
      case 'lixo não recolhido':
        return Icons.delete;
      case 'iluminação pública':
        return Icons.lightbulb;
      case 'vazamento de água':
        return Icons.water_damage;
      default:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Problemas na Comunidade'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToReportProblem,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text('Erro ao carregar problemas'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchProblems,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_problems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.thumb_up, size: 60, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                'Nenhum problema reportado ainda!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Seja o primeiro a contribuir para uma cidade melhor!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _navigateToReportProblem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Reportar Problema',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProblems,
      child: ListView.builder(
        itemCount: _problems.length,
        itemBuilder: (context, index) {
          return _buildProblemCard(_problems[index]);
        },
      ),
    );
  }
}