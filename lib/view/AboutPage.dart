import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre Nós'),
        backgroundColor: Colors.blue.shade800,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nossa Missão',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Este aplicativo foi criado com o objetivo de facilitar a comunicação entre cidadãos e órgãos públicos, permitindo o registro e o acompanhamento de problemas urbanos de forma prática e eficiente.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 32),
            const Text(
              'Quem Somos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            _buildTeamMember(
              name: 'Benjamin Utui',
              role: 'Desenvolvedor Flutter',
              imagePath: 'assets/benjamin.jpg',
            ),
            const SizedBox(height: 16),
            _buildTeamMember(
              name: 'Faizal Abdala',
              role: 'Desenvolvedor Flutter',
              imagePath: 'assets/faizal.jpg',
            ),
            const SizedBox(height: 16),
            _buildTeamMember(
              name: 'Job Cavele',
              role: 'Desenvolvedor Flutter',
              imagePath: 'assets/jobcavele.jpg',
            ),
            const SizedBox(height: 16),
            _buildTeamMember(
              name: 'Yuran Nhaguaga',
              role: 'Desenvolvedor Flutter',
              imagePath: 'assets/yuran.jpg',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2025 - Projeto Cidadão Conectado',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTeamMember({
    required String name,
    required String role,
    String? imagePath,
    String? imageUrl,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: imagePath != null
              ? AssetImage(imagePath)
              : NetworkImage(imageUrl!) as ImageProvider,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              role,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
