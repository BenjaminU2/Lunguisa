import 'package:flutter/material.dart';
import 'view/appwrite_cliente.dart';
import 'view/CadastroPage.dart';
import 'view/LoginPage.dart';
import 'view/HomePage.dart';
import 'view/WelcomePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reporte de Problemas',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        future: AppwriteClient.isSessionActive(),
        builder: (context, snapshot) {
          // Enquanto verifica, mostra uma tela de loading simples
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Se tem sessão, vai pra Home; senão, vai pro Login
          if (snapshot.data == true) {
            return FutureBuilder(
              future: _getUserData(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return HomePage(
                  client: AppwriteClient.client,
                  userId: userSnapshot.data ?? '', // Usar ID obtido ou string vazia
                );
              },
            );
          } else {
            return const WelcomePage();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/cadastro': (context) => const CadastroPage(),
        '/home': (context) {
          return FutureBuilder(
            future: _getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return HomePage(
                client: AppwriteClient.client,
                userId: snapshot.data ?? '',
              );
            },
          );
        },
      },
    );
  }

  static Future<String> _getUserData() async {
    try {
      final user = await AppwriteClient.account.get();
      return user.$id; // Retorna o ID do usuário
    } catch (e) {
      return ''; // Retorna string vazia em caso de erro
    }
  }
}