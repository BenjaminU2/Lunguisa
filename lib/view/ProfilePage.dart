import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as models;
import 'appwrite_cliente.dart';
import 'package:appwrite/appwrite.dart';


class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<models.User> _userFuture;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
  }

  Future<models.User> _fetchUserData() async {
    try {
      final user = await AppwriteClient.account.get();
      _nameController = TextEditingController(text: user.name);
      _emailController = TextEditingController(text: user.email);
      return user;
    } catch (e) {
      throw Exception('Falha ao carregar dados do usuário');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await AppwriteClient.account.updateName(name: _nameController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      setState(() {
        _isEditing = false;
        _userFuture = _fetchUserData(); // Recarrega os dados
      });
    } on AppwriteException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: ${e.message}')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: FutureBuilder<models.User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Foto do perfil
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[800],
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nome
                  Text(
                    'Nome',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  _isEditing
                      ? TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Digite seu nome',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu nome';
                      }
                      return null;
                    },
                  )
                      : Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email
                  Text(
                    'Email',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  _isEditing
                      ? TextFormField(
                    controller: _emailController,
                    readOnly: true, // Email não pode ser editado
                    decoration: const InputDecoration(
                      hintText: 'Email (não pode ser alterado)',
                    ),
                  )
                      : Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.email,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ID do usuário
                  Text(
                    'ID do Usuário',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.$id,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botão de salvar (quando em modo edição)
                  if (_isEditing)
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'SALVAR ALTERAÇÕES',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                  // Botão de logout
                  TextButton(
                    onPressed: () async {
                      try {
                        await AppwriteClient.account.deleteSession(
                            sessionId: 'current');
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao sair: $e')),
                        );
                      }
                    },
                    child: const Text(
                      'Sair da conta',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}