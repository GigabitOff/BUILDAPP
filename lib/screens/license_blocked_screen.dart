import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'phone_login_screen.dart';

class LicenseBlockedScreen extends StatefulWidget {
  final String message;
  final String code;

  const LicenseBlockedScreen({
    super.key,
    required this.message,
    this.code = 'LICENSE_BLOCKED',
  });

  @override
  State<LicenseBlockedScreen> createState() => _LicenseBlockedScreenState();
}

class _LicenseBlockedScreenState extends State<LicenseBlockedScreen> {
  final AuthService _authService = AuthService();
  bool _loading = false;

  static const Color _blue = Color(0xFF1F6FEB);
  static const Color _bg = Color(0xFFF4F6FA);

  Future<void> _changeAccount() async {
    setState(() => _loading = true);

    try {
      await _authService.logout();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
      (route) => false,
    );
  }

  String get _title {
    switch (widget.code) {
      case 'LICENSE_EXPIRED':
        return 'Тестовий період завершився';
      case 'LICENSE_INACTIVE':
        return 'Ліцензію деактивовано';
      case 'LICENSE_NOT_FOUND':
        return 'Ліцензію не знайдено';
      default:
        return 'Доступ заблоковано';
    }
  }

  IconData get _icon {
    switch (widget.code) {
      case 'LICENSE_EXPIRED':
        return Icons.event_busy_outlined;
      case 'LICENSE_NOT_FOUND':
        return Icons.key_off_outlined;
      default:
        return Icons.lock_person_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        _icon,
                        color: Colors.redAccent,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message.isEmpty
                          ? 'Доступ до застосунку тимчасово обмежено.'
                          : widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _blue.withValues(alpha: 0.12)),
                      ),
                      child: const Text(
                        'Зверніться до адміністратора EVENTHESAPP для продовження доступу.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _changeAccount,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.phone_android_outlined),
                        label: Text(
                          _loading ? 'Зачекайте...' : 'Змінити номер телефону',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.code,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
