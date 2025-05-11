import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'login.dart';


enum ProblemStatus { pendente, resolvido }

class UrbanProblem {
  final String type;
  final String description;
  final dynamic image; // File (mobile) ou Uint8List (web)
  final Position location;
  ProblemStatus status;
  final DateTime registrationDate;

  UrbanProblem({
    required this.type,
    required this.description,
    required this.image,
    required this.location,
    this.status = ProblemStatus.pendente,
    DateTime? registrationDate,
  }) : registrationDate = registrationDate ?? DateTime.now();
}

// ================== APP PRINCIPAL ==================
class UrbanProblemsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Problemas Urbanos',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ProblemReportPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ================== PÁGINA PRINCIPAL ==================
class ProblemReportPage extends StatefulWidget {
  @override
  _ProblemReportPageState createState() => _ProblemReportPageState();
}

class _ProblemReportPageState extends State<ProblemReportPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Dados do formulário
  String? _selectedProblemType;
  String _description = '';
  dynamic _imageFile;
  Position? _currentPosition;

  // Lista de problemas
  List<UrbanProblem> _reportedProblems = [];
  ProblemStatus? _filterStatus;

  // Lista de tipos de problemas
  final List<String> _problemTypes = [
    'Tubo de Água',
    'Fios de Corrente',
    'Lixo Não Recolhido',
    'Iluminação Pública',
    'Buraco na Rua',
    'Outro',
  ];

  // ================== MÉTODOS PRINCIPAIS ==================
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() => _imageFile = bytes);
        } else {
          setState(() => _imageFile = File(pickedFile.path));
        }
      }
    } catch (e) {
      _showSnackBar('Erro ao abrir a câmera: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Ative o serviço de localização');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Permissão negada');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Permissão permanentemente negada');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      _showSnackBar('Erro ao obter localização: $e');
    }
  }

  void _saveProblem() {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showSnackBar('Tire uma foto do problema');
      return;
    }
    if (_currentPosition == null) {
      _showSnackBar('Adicione a localização');
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _reportedProblems.add(
        UrbanProblem(
          type: _selectedProblemType!,
          description: _description,
          image: _imageFile,
          location: _currentPosition!,
        ),
      );

      // Reset form
      _selectedProblemType = null;
      _description = '';
      _imageFile = null;
      _currentPosition = null;
      _formKey.currentState!.reset();
    });

    _showSnackBar('Problema cadastrado!');
  }

  void _updateProblemStatus(int index, ProblemStatus newStatus) {
    setState(() {
      _reportedProblems[index].status = newStatus;
    });
    _showSnackBar('Status atualizado!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2), // Adicionei a duração (opcional)
      ), // Faltava este parêntese
    );
  }

  // ================== WIDGETS ==================
  Widget _buildImagePreview() {
    if (_imageFile == null) return Text('Nenhuma foto tirada');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: kIsWeb
          ? Image.memory(
        _imageFile as Uint8List,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      )
          : Image.file(
        _imageFile as File,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildProblemCard(UrbanProblem problem, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      color: problem.status == ProblemStatus.resolvido
          ? Colors.green[50]
          : Colors.orange[50],
      child: ListTile(
        leading: problem.image != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? Image.memory(
            problem.image as Uint8List,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
              : Image.file(
            problem.image as File,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        )
            : Icon(Icons.report_problem, size: 40),
        title: Text(problem.type),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(problem.description),
            SizedBox(height: 4),
            Text(
              'Status: ${problem.status == ProblemStatus.resolvido ? '✅ Resolvido' : '🟡 Pendente'}',
              style: TextStyle(
                color: problem.status == ProblemStatus.resolvido
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Data: ${problem.registrationDate.day}/${problem.registrationDate.month}/${problem.registrationDate.year}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (problem.status == ProblemStatus.pendente)
              IconButton(
                icon: Icon(Icons.check_circle, color: Colors.green),
                onPressed: () =>
                    _updateProblemStatus(index, ProblemStatus.resolvido),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    'Lat: ${problem.location.latitude.toStringAsFixed(4)}'),
                Text(
                    'Lng: ${problem.location.longitude.toStringAsFixed(4)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================== BUILD PRINCIPAL ==================
  @override
  Widget build(BuildContext context) {
    final filteredProblems = _filterStatus == null
        ? _reportedProblems
        : _reportedProblems
        .where((problem) => problem.status == _filterStatus)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Problemas Urbanos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Login(),
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFF43A047), // Mantendo a cor verde do seu tema
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Formulário de Cadastro
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cadastrar Novo Problema',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 16),
                          // Campo Tipo
                          Text('Tipo de Problema:'),
                          DropdownButtonFormField<String>(
                            value: _selectedProblemType,
                            items: _problemTypes
                                .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedProblemType = value),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Selecione',
                            ),
                            validator: (value) =>
                            value == null ? 'Selecione um tipo' : null,
                          ),
                          SizedBox(height: 16),
                          // Campo Descrição
                          Text('Descrição:'),
                          TextFormField(
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Descreva o problema',
                            ),
                            validator: (value) =>
                            value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                            onSaved: (value) => _description = value ?? '',
                          ),
                          SizedBox(height: 16),
                          // Campo Foto
                          Text('Foto:'),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(Icons.camera_alt),
                                label: Text('Tirar Foto'),
                                onPressed: _pickImage,
                              ),
                              SizedBox(width: 16),
                              _buildImagePreview(),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Campo Localização
                          Text('Localização:'),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(Icons.location_on),
                                label: Text('Obter Localização'),
                                onPressed: _getCurrentLocation,
                              ),
                              SizedBox(width: 16),
                              _currentPosition != null
                                  ? Flexible(
                                child: Text(
                                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                                      'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                ),
                              )
                                  : Text('Não localizado'),
                            ],
                          ),
                          SizedBox(height: 24),
                          // Botão Salvar
                          Center(
                            child: ElevatedButton(
                              onPressed: _saveProblem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Text('Cadastrar Problema'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Lista de Problemas
                if (_reportedProblems.isNotEmpty) ...[
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Problemas Reportados',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              DropdownButton<ProblemStatus?>(
                                value: _filterStatus,
                                hint: Text('Filtrar'),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text('Todos'),
                                  ),
                                  DropdownMenuItem(
                                    value: ProblemStatus.pendente,
                                    child: Text('Pendentes'),
                                  ),
                                  DropdownMenuItem(
                                    value: ProblemStatus.resolvido,
                                    child: Text('Resolvidos'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _filterStatus = value),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: filteredProblems.length,
                            itemBuilder: (context, index) {
                              // Encontra o índice correto na lista original
                              final originalIndex = _reportedProblems
                                  .indexOf(filteredProblems[index]);
                              return _buildProblemCard(
                                  filteredProblems[index], originalIndex);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}