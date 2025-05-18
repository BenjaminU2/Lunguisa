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
  late final Storage _storage;
  late final Account _account;
  List<Map<String, dynamic>> _problems = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _userName = '';

  final Color appBarColor = const Color(0xFF089CFF);

  @override
  void initState() {
    super.initState();
    _databases = Databases(widget.client);
    _storage = Storage(widget.client);
    _account = Account(widget.client);
    _loadUserData();
    _fetchUserProblems();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _account.get();
      setState(() {
        _userName = user.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados do usuário: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchUserProblems() async {
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
          Query.equal('userId', widget.userId),
        ],
      );

      final userProblems = await Future.wait(
        response.documents.map((doc) async {
          final data = doc.data;
          if (data['imageId'] != null && data['imageId'].toString().isNotEmpty) {
            try {
              final imageUrl = _storage.getFilePreview(
                bucketId: 'problems_images',
                fileId: data['imageId'].toString(),
              );
              data['imageUrl'] = imageUrl.toString();
            } catch (e) {
              debugPrint('Erro ao carregar imagem: $e');
              data['imageUrl'] = null;
            }
          } else {
            data['imageUrl'] = null;
          }
          return data;
        }),
      );

      setState(() {
        _problems = userProblems;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar problemas: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar seus problemas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToReportProblem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportProblemPage(
          userId: widget.userId,
          userName: _userName,
        ),
      ),
    );

    if (result == true) {
      await _fetchUserProblems();
    }
  }

  Future<void> _logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _upvoteProblem(String problemId) async {
    try {
      final document = await _databases.getDocument(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
        documentId: problemId,
      );

      int currentUpvotes = document.data['upvotes'] ?? 0;

      await _databases.updateDocument(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
        documentId: problemId,
        data: {
          'upvotes': currentUpvotes + 1,
        },
      );

      setState(() {
        _problems = _problems.map((problem) {
          if (problem['\$id'] == problemId) {
            problem['upvotes'] = (problem['upvotes'] ?? 0) + 1;
          }
          return problem;
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voto registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao votar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao votar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getProblemIcon(String? category) {
    switch (category) {
      case 'Iluminação':
        return Icons.lightbulb;
      case 'Buraco':
        return Icons.warning;
      case 'Limpeza':
        return Icons.clean_hands;
      case 'Segurança':
        return Icons.security;
      default:
        return Icons.report_problem;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (problem['imageUrl'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                problem['imageUrl'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.grey, size: 48),
                          SizedBox(height: 8),
                          Text('Imagem não disponível', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getProblemIcon(problem['category']),
                      color: appBarColor,
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
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.thumb_up),
                      onPressed: () => _upvoteProblem(problem['\$id']),
                      color: appBarColor,
                    ),
                    Text('${problem['upvotes'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Problemas Reportados'),
        backgroundColor: appBarColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToReportProblem,
        child: const Icon(Icons.add),
        backgroundColor: appBarColor,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUserProblems,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Erro ao carregar problemas'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchUserProblems,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        )
            : _problems.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info, color: Colors.blue, size: 48),
              const SizedBox(height: 16),
              const Text('Você ainda não reportou nenhum problema'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToReportProblem,
                child: const Text('Reportar um problema'),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _problems.length,
          itemBuilder: (context, index) {
            return _buildProblemCard(_problems[index]);
          },
        ),
      ),
    );
  }
}