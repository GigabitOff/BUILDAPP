import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final AuthService authService = AuthService();

  bool isLoading = false;
  String resultText = 'Нажми кнопку, чтобы проверить токен через /api/me';

  Future<void> checkToken() async {
    setState(() {
      isLoading = true;
      resultText = 'Проверяем токен...';
    });

    try {
      final data = await authService.me();

      if (!mounted) return;

      setState(() {
        resultText =
            '✅ Токен рабочий\n\nПользователь: ${data['user']['name']}\nEmail: ${data['user']['email'] ?? ''}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        resultText =
            '❌ Ошибка\n\n${e.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Проверка авторизации',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageCard(
              icon: Icons.verified_user_outlined,
              title: 'Проверка токена',
              subtitle: resultText,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : checkToken,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(isLoading ? 'Проверяем...' : 'Проверить токен'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6FEB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF1F6FEB), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
