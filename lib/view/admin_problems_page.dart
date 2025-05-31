import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import 'appwrite_cliente.dart';
import 'package:appwrite/models.dart' as models;
import 'package:projecto/main.dart';
import 'package:projecto/view/LoginPage.dart';



class AdminProblemsPage extends StatefulWidget {
  final models.User user;
  final Databases databases;
  final String databaseId;
  final String collectionId;

  const AdminProblemsPage({
    Key? key,
    required this.user,
    required this.databases,
    required this.databaseId,
    required this.collectionId,
  }) : super(key: key);

  @override
  State<AdminProblemsPage> createState() => _AdminProblemsPageState();
}

class _AdminProblemsPageState extends State<AdminProblemsPage> {
  final Databases _databases = Databases(AppwriteClient.client);
  final Storage _storage = Storage(AppwriteClient.client);

  List<Map<String, dynamic>> _problems = [];
  bool _isLoading = true;
  bool _hasError = false;

  // Filtros consistentes com o cadastro
  String? _selectedStatus = 'pendente';
  String? _selectedCategory;
  final List<String> _statusOptions = ['pendente', 'resolvido'];
  final List<String> _categoryOptions = [
    'Iluminação',
    'Buraco',
    'Limpeza',
    'Segurança',
    'Outro'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllProblems(); // Busca todos os problemas inicialmente
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



  Future<void> _fetchAllProblems() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      //Consulta inicial sem filtros para trazer todos os problemas
      final response = await _databases.listDocuments(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
        queries: [
          Query.orderDesc('createdAt'), // Ordena do mais recente
          Query.limit(100), // Limite razoável para teste
        ],
      );

      // Processa todos os documentos
      final problems = await Future.wait(
        response.documents.map((doc) async {
          final data = doc.data;
          data['\$id'] = doc.$id; // Garante que o ID do documento está incluído

          // Processa imagem se existir
          if (data['imageId'] != null && data['imageId'].toString().isNotEmpty) {
            try {
              final imageUrl = _storage.getFilePreview(
                bucketId: 'problem_images',
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

          // Padroniza categoria "Outro" para categorias não listadas
          if (!_categoryOptions.contains(data['category'])) {
            data['category'] = 'Outro';
          }

          return data;
        }),
      );

      setState(() {
        _problems = problems;
        _isLoading = false;
      });

      debugPrint('Total de problemas carregados: ${problems.length}');

    } catch (e) {
      debugPrint('Erro ao carregar problemas: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar problemas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateProblemStatus(String problemId, String newStatus) async {
    try {
      await _databases.updateDocument(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
        documentId: problemId,
        data: {'status': newStatus},
      );

      setState(() {
        _problems = _problems.map((problem) {
          if (problem['\$id'] == problemId) {
            problem['status'] = newStatus;
          }
          return problem;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status atualizado para ${newStatus == 'resolvido' ? 'Resolvido' : 'Pendente'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFilterChips() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar Problemas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Filtro por Status
            Wrap(
              spacing: 8,
              children: _statusOptions.map((status) {
                return ChoiceChip(
                  label: Text(
                    status == 'pendente' ? 'Pendentes' : 'Resolvidos',
                    style: TextStyle(
                      color: _selectedStatus == status
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? status : null;
                    });
                    _fetchFilteredProblems();
                  },
                  selectedColor: Colors.blue[800],
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Filtro por Categoria
            Wrap(
              spacing: 8,
              children: _categoryOptions.map((category) {
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                    _fetchFilteredProblems();
                  },
                  selectedColor: Colors.blue[800],
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Botão para limpar filtros
            if (_selectedCategory != null || _selectedStatus != null)
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedStatus = null;
                    });
                    _fetchAllProblems();
                  },
                  child: const Text('Limpar Filtros'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchFilteredProblems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> queries = [
        Query.orderDesc('createdAt'),
      ];

      if (_selectedStatus != null) {
        queries.add(Query.equal('status', _selectedStatus!));
      }

      if (_selectedCategory != null) {
        queries.add(Query.equal('category', _selectedCategory!));
      }

      final response = await _databases.listDocuments(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
        queries: queries,
      );

      final problems = await Future.wait(
        response.documents.map((doc) async {
          final data = doc.data;
          data['\$id'] = doc.$id;

          if (data['imageId'] != null && data['imageId'].toString().isNotEmpty) {
            try {
              final imageUrl = _storage.getFilePreview(
                bucketId: 'problem_images',
                fileId: data['imageId'].toString(),
              );
              data['imageUrl'] = imageUrl.toString();
            } catch (e) {
              data['imageUrl'] = null;
            }
          } else {
            data['imageUrl'] = null;
          }

          return data;
        }),
      );

      setState(() {
        _problems = problems;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao filtrar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProblemCard(Map<String, dynamic> problem) {
    final date = DateTime.parse(problem['createdAt']).toLocal();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Pode implementar ação ao clicar no card
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do problema
            if (problem['imageUrl'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  problem['imageUrl'],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
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
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Imagem não disponível', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Detalhes do problema
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho com status e categoria
                  Row(
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: problem['status'] == 'pendente'
                              ? Colors.orange[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          problem['status'] == 'pendente' ? 'PENDENTE' : 'RESOLVIDO',
                          style: TextStyle(
                            color: problem['status'] == 'pendente'
                                ? Colors.orange[800]
                                : Colors.green[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Categoria
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          problem['category']?.toString().toUpperCase() ?? 'OUTRO',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Descrição
                  Text(
                    problem['description'] ?? 'Sem descrição',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 12),

                  // Rodapé com informações do usuário e data
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          problem['userName'] ?? 'Usuário desconhecido',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Botão de ação
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateProblemStatus(
                        problem['\$id'],
                        problem['status'] == 'pendente' ? 'resolvido' : 'pendente',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: problem['status'] == 'pendente'
                            ? Colors.green
                            : Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        problem['status'] == 'pendente'
                            ? 'MARCAR COMO RESOLVIDO'
                            : 'REABRIR PROBLEMA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Painel Administrativo'),
        centerTitle: true,
        elevation: 0,
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _logout(context);
            },
            child: const Text('Sair'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllProblems,
            tooltip: 'Recarregar problemas',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAllProblems,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Erro ao carregar problemas'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchAllProblems,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                      ),
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
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Nenhum problema encontrado'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchAllProblems,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                      ),
                      child: const Text('Recarregar'),
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
          ),
        ],
      ),
    );
  }
}