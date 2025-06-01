import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class UserListPage extends StatefulWidget {
  final Client client;

  const UserListPage({super.key, required this.client});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late final Databases _databases;
  Map<String, int> _userCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _databases = Databases(widget.client);
    _fetchUserCounts();
  }

  Future<void> _fetchUserCounts() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
      );

      final documents = response.documents;
      final Map<String, int> counts = {};

      for (final doc in documents) {
        final userName = doc.data['userName'] ?? 'Desconhecido';
        counts[userName] = (counts[userName] ?? 0) + 1;
      }

      setState(() {
        _userCounts = counts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _userCounts = {};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários e Problemas'),
        backgroundColor: Colors.blue[800],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userCounts.isEmpty
          ? const Center(child: Text('Nenhum usuário encontrado.'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: _userCounts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = _userCounts.keys.elementAt(index);
            final count = _userCounts[user]!;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue[700],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  user,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Problemas reportados'),
                trailing: Chip(
                  label: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.green[500],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}