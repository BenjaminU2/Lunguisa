import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projecto/viewModels/welcome_viewmodel.dart';
import 'LoginPage.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WelcomeViewModel(),
      child: const WelcomeViewContent(),
    );
  }
}

class WelcomeViewContent extends StatelessWidget {
  const WelcomeViewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WelcomeViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0077C2), Color(0xFF005B9F)], // azul moderno
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logotipo centralizado
              Image.asset(
                'assets/Logotipo.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 40),

              // Texto motivacional com bom contraste
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  vm.messages[vm.currentPage],
                  key: ValueKey<int>(vm.currentPage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Botão moderno
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 6,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),

              const SizedBox(height: 30),
              const Text(
                'Por uma cidade melhor!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
