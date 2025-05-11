import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/problem_viewmodel.dart';

class ProblemReportPage extends StatefulWidget {
  const ProblemReportPage({Key? key}) : super(key: key);

  @override
  _ProblemReportPageState createState() => _ProblemReportPageState();
}

class _ProblemReportPageState extends State<ProblemReportPage> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _problemTypes = [
    'Tubo de Água',
    'Buraco na Rua',
    'Lixo Não Recolhido',
    'Iluminação Pública',
    'Outro'
  ];

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProblemViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Problema')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Dropdown para tipo de problema
              DropdownButtonFormField<String>(
                value: viewModel.selectedProblemType,
                items: _problemTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  viewModel.selectedProblemType = value; // Usando o setter
                },
                decoration: InputDecoration(
                  labelText: 'Tipo de Problema',
                  border: OutlineInputBorder(),
                ),
              ),

              // Campo de descrição
              TextFormField(
                onChanged: (value) {
                  viewModel.description = value; // Usando o setter
                },
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              // Botão para salvar
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    viewModel.saveProblem(); // Chamada sem parâmetros
                  }
                },
                child: const Text('Salvar Problema'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}