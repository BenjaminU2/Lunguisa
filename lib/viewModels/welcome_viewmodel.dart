import 'package:flutter/foundation.dart';
import 'dart:async';

class WelcomeViewModel extends ChangeNotifier {
  int currentPage = 0;

  final List<String> messages = [
    'Juntos, podemos construir uma cidade mais limpa, segura e cheia de esperança.',
    'A mudança começa em cada um de nós. Seja a diferença!',
    'Uma comunidade unida constrói um futuro brilhante.',
  ];

  WelcomeViewModel() {
    _startMessageRotation();
  }

  void _startMessageRotation() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      currentPage = (currentPage + 1) % messages.length;
      notifyListeners();
    });
  }
}
