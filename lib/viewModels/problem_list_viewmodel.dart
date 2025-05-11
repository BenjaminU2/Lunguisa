import 'package:flutter/material.dart';
import '../models/problem_status.dart';
import '../models/urban_problem.dart';
import '../repositorio/problem_repository.dart';

class ProblemListViewModel with ChangeNotifier {
  final ProblemRepository _repository;
  ProblemStatus? _filterStatus;

  ProblemListViewModel(this._repository);

  ProblemStatus? get filterStatus => _filterStatus;

  List<UrbanProblem> get filteredProblems => _filterStatus == null
      ? _repository.getProblems()
      : _repository.getProblems(filter: _filterStatus);

  void updateFilter(ProblemStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void updateProblemStatus(int index, ProblemStatus status) {
    _repository.updateProblemStatus(index, status);
    notifyListeners();
  }
}