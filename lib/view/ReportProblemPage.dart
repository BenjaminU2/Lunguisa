import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'appwrite_cliente.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'dart:async';


class ReportProblemPage extends StatefulWidget {
  final String userId;
  final String userName;
  bool _isGettingLocation = false;

  ReportProblemPage({
    Key? key, // Alterado de super.key para Key? key
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _category = 'Buraco na via';
  File? _imageFile; // Para mobile
  XFile? _pickedFile; // Para web e mobile
  bool _isLoading = false;
  bool _isGettingLocation = false;

  final List<String> _categories = [
    'Buraco na via',
    'Fios soltos',
    'Lixo não recolhido',
    'Iluminação pública',
    'Vazamento de água',
    'Outro'
  ];
  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() => _isGettingLocation = true);

    try {
      // Verifica se o serviço de localização está ativo
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Por favor, ative o GPS no seu dispositivo');
      }

      // Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão permanentemente negada. Ative nas configurações do aplicativo');
      }

      // Obtém a posição com timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      // Converte para endereço com tratamento de nulos
      if (position != null) {
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).catchError((e) {
          throw Exception('Falha ao converter coordenadas em endereço');
        });

        String address = 'Coordenadas: ${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)}';

        if (placemarks != null && placemarks.isNotEmpty) {
          geo.Placemark place = placemarks.first;
          address = [
            place.street,
            place.subLocality,
            place.locality,
            place.postalCode
          ].where((part) => part != null && part.isNotEmpty).join(', ');
        }

        setState(() => _locationController.text = address);
      }
    } on TimeoutException {
      throw Exception('Tempo excedido ao obter localização');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString().replaceFirst('Exception: ', '')}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }


  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        if (!kIsWeb) {
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitProblem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_pickedFile != null) {
        final storage = AppwriteClient.storage;

        if (kIsWeb) {
          final bytes = await _pickedFile!.readAsBytes();
          final response = await storage.createFile(
            bucketId: 'problem_images',
            fileId: ID.unique(),
            file: InputFile.fromBytes(
              bytes: bytes,
              filename: _pickedFile!.name,
            ),
          );
          imageUrl = storage.getFileView(
            bucketId: 'problem_images',
            fileId: response.$id,
          ).toString();
        } else {
          final response = await storage.createFile(
            bucketId: 'problem_images',
            fileId: ID.unique(),
            file: InputFile.fromPath(
              path: _imageFile!.path,
            ),
          );
          imageUrl = storage.getFileView(
            bucketId: 'problem_images',
            fileId: response.$id,
          ).toString();
        }
      }

      await AppwriteClient.databases.createDocument(
        databaseId: '68209b44001669c8bdba',
        collectionId: 'problems',
        documentId: ID.unique(),
        data: {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'location': _locationController.text,
          'category': _category,
          'userId': widget.userId,
          'userName': widget.userName,
          'imageUrl': imageUrl,
          'upvotes': 0,

          'status': 'pendente',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Problema reportado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reportar problema: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Problema'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: _pickedFile == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt, size: 50, color: Colors.green),
                      SizedBox(height: 8),
                      Text('Adicionar foto do problema'),
                    ],
                  )
                      : kIsWeb
                      ? Image.network(_pickedFile!.path, fit: BoxFit.cover)
                      : Image.file(File(_pickedFile!.path), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Localização',
                prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                suffixIcon: IconButton(
                  icon: _isGettingLocation
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.my_location, color: Colors.green),
                  onPressed: _getCurrentLocation,
                  tooltip: 'Usar minha localização atual',
                ),
                border: const OutlineInputBorder(),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, obtenha a localização automática ou insira manualmente';
                }
                return null;
              },
            ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category, color: Colors.green),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Localização',
                  prefixIcon: Icon(Icons.location_on, color: Colors.green),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe a localização';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição detalhada',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description, color: Colors.green),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, descreva o problema';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProblem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Reportar Problema', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}