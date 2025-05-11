import 'package:geolocator/geolocator.dart';
import 'problem_status.dart';

class UrbanProblem {
  final String type;
  final String description;
  final dynamic image; // File (mobile) ou Uint8List (web)
  final Position location;
  final DateTime registrationDate;
  ProblemStatus status;

  UrbanProblem({
    required this.type,
    required this.description,
    required this.image,
    required this.location,
    this.status = ProblemStatus.pendente,
    DateTime? registrationDate,
  }) : registrationDate = registrationDate ?? DateTime.now();
}