import 'package:flutter/foundation.dart';

class MainShellViewModel extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void select(int index) {
    if (index == _index || index == 2) return;
    _index = index;
    notifyListeners();
  }
}
