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
          (item) => [
            item.name,
            item.room,
            item.time,
            item.courseName,
            '${item.remote?.year ?? ''}',
          ].any((value) => value.toLowerCase().contains(_query)),
        )
        .toList();
  }
}
