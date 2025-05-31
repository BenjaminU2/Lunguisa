import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import 'ReportProblemPage.dart';

class ListPage extends StatefulWidget {
  final Client client;
  final String userId;

  const ListPage({super.key, required this.client, required this.userId});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  late final Databases _databases;
  late final Storage _storage;
  late final Account _account;
  List<Map<String, dynamic>> _problems = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _userName = '';
  bool _isRefreshing = false;

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
      if (mounted) {
        setState(() {
          _userName = user.name;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados do utilizador: $e');
    }
  }

  Future<void> _fetchUserProblems() async {
    if (!mounted) return;

    try {
      if (!_isRefreshing) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

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

          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
            try {
              final previewUrl = widget.client.endPoint.replaceAll('/v1', '') +
                  '/v1/storage/buckets/problem_images/files/${data['imageUrl'].toString()}/view?project=${widget.client.config['project']}&mode=admin';

              data['imageUrl'] = previewUrl;

            } catch (e) {
              debugPrint('Erro ao carregar imagem: $e');
              data['imageUrl'] = null;
            }
          } else {
            data['imageUrl'] = null;
          }

          // Garantir que todos campos existem
          data['description'] = data['description'] ?? 'Sem descrição';
          data['category'] = data['category'] ?? 'Outro';
          data['createdAt'] = data['createdAt'] ?? DateTime.now().toIso8601String();
          data['status'] = data['status'] ?? 'Pendente';
          data['location'] = data['location'] ?? 'Localização desconhecida';


          return data;
        }),
      );

      if (mounted) {
        setState(() {
          _problems = userProblems;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar problemas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _isRefreshing = false;
        });
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
            content: Text('Erro ao terminar sessão: ${e.toString()}'),
          ),
        );
      }
    }
  }





  Color _getProblemColor(String? category) {
    switch (category) {
      case 'Iluminação':
        return Colors.orange;
      case 'Buraco':
        return Colors.red;
      case 'Limpeza':
        return Colors.green;
      case 'Segurança':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildProblemCard(Map<String, dynamic> problem) {
    final date = DateTime.parse(problem['createdAt']).toLocal();
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final categoryColor = _getProblemColor(problem['category']);
    final statusColor = problem['status'] == 'Resolvido' ? Colors.green : Colors.orange;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (problem['imageUrl'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                problem['imageUrl'],
                width: double.infinity,
                height: 220, // imagem maior
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 220,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
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
                /// Categoria e Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        problem['category'],
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        problem['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                /// Descrição
                Text(
                  problem['description'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),

                /// Localização
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        problem['location'],
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// Data
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
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
        backgroundColor: Colors.blue[800],
        title: const Text('Problemas Reportados'),
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
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _isRefreshing = true;
          });
          await _fetchUserProblems();
        },
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
              const Text('Ainda não reportou nenhum problema'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToReportProblem,
                child: const Text('Reportar um problema'),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _problems.length,
          itemBuilder: (context, index) {
            return _buildProblemCard(_problems[index]);
          },
        ),
      ),
    );
  }
}