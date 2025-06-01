import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_cliente.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final Databases databases = Databases(AppwriteClient.client);
  final Account account = Account(AppwriteClient.client);

  final String databaseId = '68209b44001669c8bdba';
  final String collectionId = 'notifications';

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final models.User user = await account.get();
      final result = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );

      setState(() {
        notifications = result.documents
            .map((doc) => {
          'message': doc.data['message'] as String,
          'createdAt': doc.data['\$createdAt'] as String,
        })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar notificações: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text('Nenhuma notificação disponível.'))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final date = DateTime.parse(notif['createdAt']).toLocal();
          final formattedDate =
              '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(notif['message']),
              subtitle: Text('Recebido em: $formattedDate'),
            ),
          );
        },
      ),
     );
  }
}