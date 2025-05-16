import 'package:flutter/material.dart';
import 'view/appwrite_cliente.dart';
import 'view/CadastroPage.dart';
import 'view/LoginPage.dart';
import 'view/HomePage.dart';

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/cadastro': (context) => const CadastroPage(),
        '/home': (context) {
          // Você precisará passar os parâmetros necessários aqui
          // ou usar um gerenciador de estado
          return const Placeholder(); // Substitua pelo seu HomePage
        },
      },
    );
  }
}