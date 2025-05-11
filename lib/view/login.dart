import 'package:flutter/material.dart';
import 'package:projecto/view/CadastroPage.dart';
import 'TelaCadastroProblema.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    // Controladores para os campos de texto
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: Column(
        children: <Widget>[
          // Cabeçalho com ícone e título
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 2.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF43A047),
                  Color(0xFFE0E0E0),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(90),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Spacer(),
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 32,
                      right: 32,
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Formulário
          Container(
            padding: const EdgeInsets.only(top: 62),
            child: Column(
              children: <Widget>[
                // Campo de e-mail
                Container(
                  width: MediaQuery.of(context).size.width / 1.2,
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.email, color: Colors.grey),
                      hintText: 'Email',
                      border: InputBorder.none,
                    ),
                  ),
                ),

                // Campo de senha
                Container(
                  width: MediaQuery.of(context).size.width / 1.2,
                  height: 50,
                  margin: const EdgeInsets.only(top: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.vpn_key, color: Colors.grey),
                      hintText: 'Password',
                      border: InputBorder.none,
                    ),
                  ),
                ),

                // Espaçamento
                const SizedBox(height: 40),

                // Botão de login
                SizedBox(
                  width: MediaQuery.of(context).size.width / 1.2,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (email == 'benjaminutui@gmail.com' && password == 'BenjaminUtui') {
                        // Credenciais corretas - navegar para UrbanProblemsApp
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProblemReportPage()
                          ),
                        );
                      } else {
                        // Credenciais incorretas - mostrar mensagem de erro
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email ou senha incorretos'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ).merge(
                      ButtonStyle(
                        overlayColor: MaterialStateProperty.resolveWith<Color>(
                              (states) => Colors.transparent,
                        ),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF43A047),
                            Color(0xFFE0E0E0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 88.0, minHeight: 50.0),
                        alignment: Alignment.center,
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Link para cadastro
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UrbanProblemsApp(),
                      ),
                    );
                  },
                  child: const Text(
                    'Criar conta',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}