import 'package:flutter/material.dart';

import 'screens/shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

/// アプリのルートウィジェット。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pj-walter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Shell(),
    );
  }
}
