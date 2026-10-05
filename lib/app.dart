import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/attendance/views/attendance_review_page.dart';

class ClassVisionApp extends StatelessWidget {
  const ClassVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassVision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AttendanceReviewPage(),
    );
  }
}
