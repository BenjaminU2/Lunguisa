import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'LoginPage.dart';
import 'appwrite_cliente.dart';

class AllProblemsPage extends StatefulWidget {
  final Client client;

  const AllProblemsPage({Key? key, required this.client}) : super(key: key);

  @override
  State<AllProblemsPage> createState() => _AllProblemsPageState();
}

class _AllProblemsPageState extends State<AllProblemsPage> {
  late final Databases _databases;
  late final Storage _storage;

  List<Map<String, dynamic>> _problems = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isRefreshing = false;

  String _selectedStatus = 'Todos';
  String _selectedCategory = 'Todos';
  String _searchText = '';

  final List<String> _statusOptions = ['Todos', 'Pendente', 'Resolvido'];
  final List<String> _categoryOptions = [
    'Todos',
    'Iluminação',
    'Buraco',
    'Limpeza',
    'Segurança',
    'Outro',
  ];

  final List<String> _periodOptions = [
    'Todos',
    'Últimos 7 dias',
    'Últimos 30 dias',
    'Selecionar intervalo'
  ];

  String _selectedPeriod = 'Todos';
  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _databases = Databases(widget.client);
    _storage = Storage(widget.client);
    _fetchAllProblems();
  }

  Future<void> _fetchAllProblems() async {
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
        queries: [Query.orderDesc('createdAt')],
      );

      final allProblems = await Future.wait(
        response.documents.map((doc) async {
          final data = doc.data;

          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
            final previewUrl = widget.client.endPoint.replaceAll('/v1', '') +
                '/v1/storage/buckets/problem_images/files/${data['imageUrl']}/view?project=${widget.client.config['project']}&mode=admin';
            data['imageUrl'] = previewUrl;
          } else {
            data['imageUrl'] = null;
          }

          data['description'] = data['description'] ?? 'Sem descrição';
          data['category'] = data['category'] ?? 'Outro';
          data['createdAt'] = data['createdAt'] ?? DateTime.now().toIso8601String();
          data['status'] = data['status'] ?? 'Pendente';
          data['location'] = data['location'] ?? 'Localização desconhecida';
          data['userName'] = data['userName'] ?? 'Desconhecido';
          data['userId'] = data['userId'] ?? ''; // Garante que o campo exista
          data['\$id'] = doc.$id;

          return data;
        }),
      );

      if (mounted) {
        setState(() {
          _problems = allProblems;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _isRefreshing = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _applyFilters() {
    return _problems.where((problem) {
      final createdAt = DateTime.parse(problem['createdAt']).toLocal();

      final matchStatus =
          _selectedStatus == 'Todos' || problem['status'] == _selectedStatus;
      final matchCategory =
          _selectedCategory == 'Todos' || problem['category'] == _selectedCategory;
      final matchSearch = _searchText.isEmpty ||
          problem['description'].toString().toLowerCase().contains(_searchText.toLowerCase()) ||
          problem['location'].toString().toLowerCase().contains(_searchText.toLowerCase()) ||
          problem['userName'].toString().toLowerCase().contains(_searchText.toLowerCase());

      bool matchDate = true;
      final now = DateTime.now();

      if (_selectedPeriod == 'Últimos 7 dias') {
        matchDate = createdAt.isAfter(now.subtract(const Duration(days: 7)));
      } else if (_selectedPeriod == 'Últimos 30 dias') {
        matchDate = createdAt.isAfter(now.subtract(const Duration(days: 30)));
      } else if (_selectedPeriod == 'Selecionar intervalo') {
        if (_startDate != null && _endDate != null) {
          matchDate = createdAt.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
              createdAt.isBefore(_endDate!.add(const Duration(days: 1)));
        }
      }

      return matchStatus && matchCategory && matchSearch && matchDate;
    }).toList();
  }

  Future<void> _toggleStatus(Map<String, dynamic> problem) async {
    final newStatus = problem['status'] == 'Resolvido' ? 'Pendente' : 'Resolvido';
    try {
      await _databases.updateDocument(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
        documentId: problem['\$id'],
        data: {'status': newStatus},
      );

      setState(() {
        problem['status'] = newStatus;
      });

      if (newStatus == 'Resolvido') {
        final DateTime createdAt = DateTime.parse(problem['createdAt']);
        final String formattedDate = DateFormat('dd/MM/yyyy').format(createdAt);

        await _databases.createDocument(
          databaseId: '68209b44001669c8bdba',
          collectionId: 'notifications',
          documentId: ID.unique(),
          data: {
            'userId': problem['userId'],
            'message': 'O problema que cadastrou no dia $formattedDate, do tipo ${problem['category']}, foi resolvido com sucesso.',
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $e')),
      );
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

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildProblemCard(Map<String, dynamic> problem) {
    final date = DateTime.parse(problem['createdAt']).toLocal();
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final categoryColor = _getProblemColor(problem['category']);
    final statusColor = problem['status'] == 'Resolvido' ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (problem['imageUrl'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                problem['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildChip(problem['category'], categoryColor),
                    const SizedBox(width: 8),
                    _buildChip(problem['status'], statusColor),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  problem['description'],
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Por: ${problem['userName']}',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Local: ${problem['location']}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  'Data: $formattedDate',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _toggleStatus(problem),
                    icon: const Icon(Icons.sync),
                    label: Text(problem['status'] == 'Resolvido'
                        ? 'Marcar como Pendente'
                        : 'Marcar como Resolvido'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProblems = _applyFilters();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos os Problemas'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isRefreshing = true);
          await _fetchAllProblems();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por descrição, local ou usuário',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() => _searchText = value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          items: _statusOptions.map((status) {
                            return DropdownMenuItem(value: status, child: Text(status));
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStatus = value!);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _categoryOptions.map((category) {
                            return DropdownMenuItem(value: category, child: Text(category));
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value!);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    items: _periodOptions.map((period) {
                      return DropdownMenuItem(value: period, child: Text(period));
                    }).toList(),
                    onChanged: (value) async {
                      setState(() => _selectedPeriod = value!);
                      if (value == 'Selecionar intervalo') {
                        await _selectDateRange();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Período',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                  ? const Center(child: Text('Erro ao carregar dados.'))
                  : filteredProblems.isEmpty
                  ? const Center(child: Text('Nenhum problema encontrado.'))
                  : ListView.builder(
                itemCount: filteredProblems.length,
                itemBuilder: (context, index) {
                  return _buildProblemCard(filteredProblems[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}