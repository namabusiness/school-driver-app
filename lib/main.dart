import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'app_theme.dart';
import 'screens.dart';

void main() => runApp(const DriverApp());

class DriverApp extends StatefulWidget {
  const DriverApp({super.key});

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) => MaterialApp(
      title: 'School ERP Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppNavigator(controller: controller),
    ),
  );
}
