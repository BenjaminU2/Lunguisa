import 'package:flutter/material.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  void _cadastrar() {
    if (senhaController.text != confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem!')),
      );
      return;
    }

    // Aqui você pode adicionar lógica de envio para API/Firebase/etc.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro realizado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          // Cabeçalho
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
                bottomRight: Radius.circular(90),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Spacer(),
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.app_registration,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 32, left: 32),
                    child: Text(
                      'Cadastro',
                      style: TextStyle(color: Colors.white, fontSize: 18),
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
                _buildTextField(context, icon: Icons.person, hint: 'Nome completo', controller: nomeController),
                _buildTextField(context, icon: Icons.email, hint: 'Email', controller: emailController),
                _buildTextField(context, icon: Icons.vpn_key, hint: 'Senha', controller: senhaController, obscure: true),
                _buildTextField(context, icon: Icons.lock_outline, hint: 'Confirmar senha', controller: confirmarSenhaController, obscure: true),

                const SizedBox(height: 40),

                // Botão de Cadastrar
                GestureDetector(
                  onTap: _cadastrar,
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width / 1.2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFFE0E0E0)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: const Center(
                      child: Text(
                        'CADASTRAR',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Link para login
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Já tenho conta',
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

  Widget _buildTextField(BuildContext context,
      {required IconData icon,
        required String hint,
        required TextEditingController controller,
        bool obscure = false}) {
    return Container(
      width: MediaQuery.of(context).size.width / 1.2,
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
