import '../models/urban_problem.dart';
import '../models/problem_status.dart';


class ProblemRepository {
  final List<UrbanProblem> _problems = [];

  List<UrbanProblem> getProblems({ProblemStatus? filter}) {
    return filter == null
        ? _problems
        : _problems.where((p) => p.status == filter).toList();
  }

  void addProblem(UrbanProblem problem) {
    _problems.add(problem);
  }

  void updateProblemStatus(int index, ProblemStatus newStatus) {
    _problems[index].status = newStatus;
  }
}