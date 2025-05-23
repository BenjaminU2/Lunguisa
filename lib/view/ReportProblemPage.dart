import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import 'appwrite_cliente.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:typed_data';




class ReportProblemPage extends StatefulWidget {
  final String userId;
  final String userName;

  const ReportProblemPage({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  _ReportProblemPageState createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _problemTypes = [
    'Iluminação',
    'Buraco',
    'Limpeza',
    'Segurança',
    'Outro'
  ];

  String? _selectedProblemType;
  String _description = '';
  bool _addPhoto = false;
  bool _getLocation = false;
  bool _isLoading = false;
  Uint8List? _imageBytes;
  Position? _currentPosition;
  String? _locationAddress;

  final Databases _databases = Databases(AppwriteClient.client);
  final Storage _storage = Storage(AppwriteClient.client);

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao capturar imagem: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desativado');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão negada');
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();

      // You could add reverse geocoding here to get address if needed
      setState(() {
        _locationAddress = '${_currentPosition?.latitude.toStringAsFixed(4)}, '
            '${_currentPosition?.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitProblem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProblemType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um tipo de problema')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageId;
      // Upload image if exists
      if (_imageBytes != null) {
        final imageFile = InputFile.fromBytes(
          bytes: _imageBytes!,
          filename: 'problem_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final uploadedFile = await _storage.createFile(
          bucketId: 'problem_images',
          fileId: ID.unique(),
          file: imageFile,
        );
        imageId = uploadedFile.$id;
      }

      // Save problem to database
      await _databases.createDocument(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
        documentId: ID.unique(),
        data: {
          'description': _description,
          'category': _selectedProblemType,
          'imageUrl': imageId,
          'status': 'pendente',
          'userId': widget.userId,
          'userName': widget.userName,
          'createdAt': DateTime.now().toIso8601String(),
          'location': _currentPosition != null
              ? '${_currentPosition!.latitude},${_currentPosition!.longitude}'
              : '', // ou coloque um valor padrão se preferir
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problema reportado com sucesso!')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    } on AppwriteException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reportar problema: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro desconhecido: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_imageBytes == null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.photo_camera, size: 50, color: Colors.grey),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        _imageBytes!,
        height: 150,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildLocationInfo() {
    if (_currentPosition == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Localização não obtida',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Localização obtida:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_locationAddress ?? ''),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Problema Urbano'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Seção: Foto
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text(
                          'Adicionar Foto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        value: _addPhoto,
                        onChanged: (value) {
                          setState(() => _addPhoto = value!);
                          if (value!) _pickImage();
                        },
                        activeColor: const Color(0xFF1565C0),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_addPhoto) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: const Text('Tirar Foto', style: TextStyle(color: Colors.white)),
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildImagePreview(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Seção: Tipo de Problema
              DropdownButtonFormField<String>(
                value: _selectedProblemType,
                items: _problemTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedProblemType = value),
                decoration: InputDecoration(
                  labelText: 'Tipo de Problema',
                  prefixIcon: const Icon(Icons.category, color: Color(0xFF1565C0)),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  hintText: 'Selecione o tipo de problema',
                ),
                validator: (value) => value == null ? 'Selecione um tipo' : null,
              ),
              const SizedBox(height: 20),

              // Seção: Localização
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text(
                          'Incluir Localização Atual',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        value: _getLocation,
                        onChanged: (value) {
                          setState(() => _getLocation = value!);
                          if (value!) _getCurrentLocation();
                        },
                        activeColor: const Color(0xFF1565C0),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_getLocation) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.location_on, color: Colors.white),
                          label: const Text('Obter Localização', style: TextStyle(color: Colors.white)),
                          onPressed: _getCurrentLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildLocationInfo(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Seção: Descrição
              TextFormField(
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição detalhada',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description, color: Color(0xFF1565C0)),
                  border: OutlineInputBorder(),
                  hintText: 'Descreva o problema detalhadamente',
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Digite uma descrição' : null,
                onChanged: (value) => _description = value,
              ),
              const SizedBox(height: 24),

              // Botão de Envio
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProblem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'REPORTAR PROBLEMA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}