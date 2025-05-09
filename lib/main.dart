import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(UrbanProblemsApp());
}

class UrbanProblemsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Problemas Urbanos',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ProblemReportPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProblemReportPage extends StatefulWidget {
  @override
  _ProblemReportPageState createState() => _ProblemReportPageState();
}

class _ProblemReportPageState extends State<ProblemReportPage> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _problemTypes = [
    'Tubo de Água',
    'Fios de Corrente',
    'Lixo Não Recolhido',
    'Iluminação Pública',
    'Buraco na Rua',
    'Outro',
  ];

  String? _selectedProblemType;
  String _description = '';
  File? _imageFile;
  Position? _currentPosition;

  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _reportedProblems = [];

  // Função para pegar imagem da câmera
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 800, maxHeight: 800);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao abrir a câmera: $e');
    }
  }

  // Função para obter localização atual
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar se o serviço de localização está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Serviço de localização desabilitado. Por favor, ative-o nas configurações.');
      return;
    }

    // Verificar permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Permissão de localização negada');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Permissão de localização permanentemente negada. Não podemos acessar a localização.');
      return;
    }

    // Obter posição atual
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      _showSnackBar('Erro ao obter localização: $e');
    }
  }

  // Função para salvar problema cadastrado
  void _saveProblem() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    if (_imageFile == null) {
      _showSnackBar('Por favor, tire uma foto do problema.');
      return;
    }
    if (_currentPosition == null) {
      _showSnackBar('Por favor, adicione a localização do problema.');
      return;
    }

    _formKey.currentState!.save();

    final newProblem = {
      'tipo': _selectedProblemType,
      'descricao': _description,
      'imagem': _imageFile,
      'localizacao': _currentPosition,
    };

    setState(() {
      _reportedProblems.add(newProblem);
      // Resetar form
      _selectedProblemType = null;
      _description = '';
      _imageFile = null;
      _currentPosition = null;
      _formKey.currentState!.reset();
    });

    _showSnackBar('Problema cadastrado com sucesso!');

    // Apenas para debug, imprimindo no console
    print('Problemas cadastrados:');
    for (var pb in _reportedProblems) {
      print('Tipo: ${pb['tipo']}');
      print('Descrição: ${pb['descricao']}');
      print('Localização: Lat ${pb['localizacao'].latitude}, Long ${pb['localizacao'].longitude}');
      print('Imagem Path: ${(pb['imagem'] as File).path}');
      print('---');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ajuste para responsividade mobile com limites
    final double maxWidth = MediaQuery.of(context).size.width > 600 ? 600 : MediaQuery.of(context).size.width * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Problemas Urbanos'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: maxWidth,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de Problema:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Selecione o tipo de problema',
                    ),
                    value: _selectedProblemType,
                    items: _problemTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Selecione um tipo de problema' : null,
                    onChanged: (value) {
                      setState(() {
                        _selectedProblemType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Descrição do problema:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Descreva o problema',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite a descrição do problema';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _description = value ?? '';
                    },
                    initialValue: _description,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Foto do problema:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.camera_alt),
                        label: Text('Tirar Foto'),
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _imageFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFile!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Text('Nenhuma foto tirada'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Localização do problema:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.location_on),
                        label: Text('Adicionar Localização'),
                        onPressed: _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _currentPosition != null
                          ? Flexible(
                        child: Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Long: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 14),
                        ),
                      )
                          : Text('Localização não adicionada'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveProblem,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14),
                        child: Text(
                          'Cadastrar Problema',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ),
                  if (_reportedProblems.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Problemas Cadastrados:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _reportedProblems.length,
                      itemBuilder: (context, index) {
                        final problem = _reportedProblems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          child: ListTile(
                            leading: problem['imagem'] != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(problem['imagem'], width: 50, height: 50, fit: BoxFit.cover),
                            )
                                : Icon(Icons.report_problem, color: Colors.redAccent, size: 40),
                            title: Text(problem['tipo'] ?? 'Sem tipo'),
                            subtitle: Text(problem['descricao'] ?? ''),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Lat: ${problem['localizacao'].latitude.toStringAsFixed(4)}',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Lng: ${problem['localizacao'].longitude.toStringAsFixed(4)}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}