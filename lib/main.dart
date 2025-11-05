import 'package:flutter/material.dart';
import 'screens/ar_selector_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Warehouse AR",
      theme: ThemeData(primaryColor: Colors.blueAccent,),
      home: const ARSelectorScreen(),
    );
  }
}
