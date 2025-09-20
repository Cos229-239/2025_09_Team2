import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/planner_page.dart';
import 'providers/planner_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlannerProvider>(
      create: (_) => PlannerProvider(),
      child: MaterialApp(
        title: 'StudyPals Planner',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const PlannerPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
