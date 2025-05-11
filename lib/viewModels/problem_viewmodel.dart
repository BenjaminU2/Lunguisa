import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import '../models/urban_problem.dart';
import '../repositorio/problem_repository.dart';

class ProblemViewModel with ChangeNotifier {
  final ProblemRepository _repository;
  final ImagePicker _picker = ImagePicker();

  String? _selectedProblemType;
  String _description = '';
  Uint8List? _imageBytes;
  Position? _currentPosition;

  ProblemViewModel(this._repository);

  // Setters públicos com notifyListeners()
  set selectedProblemType(String? value) {
    _selectedProblemType = value;
    notifyListeners();
  }

  set description(String value) {
    _description = value;
    notifyListeners(); // Adicionado aqui
  }

  // Getters públicos
  String? get selectedProblemType => _selectedProblemType;
  String get description => _description;
  Uint8List? get imageBytes => _imageBytes;
  Position? get currentPosition => _currentPosition;

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        _imageBytes = await pickedFile.readAsBytes();
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Erro ao capturar imagem: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Serviço de localização desativado');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão negada');
      }
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    notifyListeners();
  }

  // Método saveProblem corrigido (sem parâmetros)
  void saveProblem() {
    if (_selectedProblemType == null || _description.isEmpty) {
      throw Exception('Preencha todos os campos');
    }
    if (_currentPosition == null) {
      throw Exception('Localização não definida');
    }

    _repository.addProblem(
      UrbanProblem(
        type: _selectedProblemType!,
        description: _description,
        image: _imageBytes,
        location: _currentPosition!,
      ),
    );

    // Reset form
    _selectedProblemType = null;
    _description = '';
    _imageBytes = null;
    _currentPosition = null;
    notifyListeners();
  }
}