import 'package:flutter/foundation.dart';

import '../../../data/models/school_models.dart';

class ClassesViewModel extends ChangeNotifier {
  String _query = '';

  String get query => _query;

  void search(String value) {
    _query = value.trim().toLowerCase();
    notifyListeners();
  }

  List<SchoolClass> filter(List<SchoolClass> classes) {
    if (_query.isEmpty) return classes;
    return classes
        .where(
          (item) =>
              item.name.toLowerCase().contains(_query) ||
              item.room.toLowerCase().contains(_query),
        )
        .toList();
  }
}
