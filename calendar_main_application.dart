import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypals/providers/planner_provider.dart';
import 'package:studypals/screens/planner/planner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
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

