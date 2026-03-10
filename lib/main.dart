import 'package:flutter/material.dart';
import 'package:my_app/pages/login.dart';
import 'package:my_app/pages/home.dart';

void main() => runApp(const GencCuzdan());

class GencCuzdan extends StatelessWidget {
  const GencCuzdan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Genç Cüzdan',
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
