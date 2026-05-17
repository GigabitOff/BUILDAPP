import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/phone_login_screen.dart';
import 'screens/pin_code_screen.dart';
import 'services/push_notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationsService.initialize();
  runApp(const EVENTHESAPP());
}

class EVENTHESAPP extends StatelessWidget {
  const EVENTHESAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EVENTHESAPP',
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
  String? savedToken;
  String? savedPhone;

  @override
  void initState() {
    super.initState();
    checkAuthState();
  }

  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');
    final phone = prefs.getString('auth_phone');

    final authorized =
        token != null && token.isNotEmpty && phone != null && phone.isNotEmpty;

    if (authorized) {
      await PushNotificationsService.registerCurrentDevice();
    }

    if (!mounted) return;

    setState(() {
      savedToken = token;
      savedPhone = phone;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasToken = savedToken != null && savedToken!.isNotEmpty;
    final hasPhone = savedPhone != null && savedPhone!.isNotEmpty;

    if (hasToken && hasPhone) {
      return PinCodeScreen(phone: savedPhone!);
    }

    return const PhoneLoginScreen();
  }
}
