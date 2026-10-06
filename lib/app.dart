import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/home/view/home_page.dart';
import 'features/home/viewmodel/home_view_model.dart';

class ClassVisionApp extends StatelessWidget {
  const ClassVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: MaterialApp(
        title: 'ClassVision',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomePage(),
      ),
    );
  }
}
