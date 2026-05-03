import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const BuildApp());
}

class BuildApp extends StatelessWidget {
  const BuildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUILDAPP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6FEB)),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const AppStartScreen(),
    );
  }
}

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  bool isLoading = true;
  bool hasToken = false;

  @override
  void initState() {
    super.initState();
    checkToken();
  }

  Future<void> checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    setState(() {
      hasToken = token != null && token.isNotEmpty;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (hasToken) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
