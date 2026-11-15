import 'package:flutter/foundation.dart';

class MainShellViewModel extends ChangeNotifier {
  int _index = 0;

  int get index => _index;
  int get mobileIndex => switch (_index) {
    0 => 0,
    1 => 1,
    4 => 2,
    5 => 3,
    _ => 4,
  };

  void select(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }

  void selectMobile(int index) {
    const mapping = [0, 1, 4, 5, 6];
    select(mapping[index]);
  }
}
