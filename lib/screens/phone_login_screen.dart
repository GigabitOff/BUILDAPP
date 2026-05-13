import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'pin_code_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;

  static const Color _blue = Color(0xFF1F6FEB);
  static const Color _bg = Color(0xFFF4F6FA);

  Future<void> _sendCode() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (phone.length != 12) {
      _showMessage('Введите полный номер телефона');
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.startPhoneLogin(phone: phone);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PinCodeScreen(phone: phone)),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        color: _blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'BUILDAPP',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Контроль строительства',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Вход по телефону',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Введите номер, который закреплён за пользователем',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [UkrainianPhoneFormatter()],
                      decoration: InputDecoration(
                        labelText: 'Телефон',
                        hintText: '+38(0__) ___ __ __',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Получить PIN-код',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Вход через сервер BUILDAPP',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
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

class UkrainianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('38')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    final buffer = StringBuffer('+38(0');

    if (digits.isNotEmpty) {
      buffer.write(digits.substring(0, digits.length >= 2 ? 2 : digits.length));
    }

    buffer.write(')');

    if (digits.length > 2) {
      buffer.write(' ');
      buffer.write(digits.substring(2, digits.length >= 5 ? 5 : digits.length));
    }

    if (digits.length > 5) {
      buffer.write(' ');
      buffer.write(digits.substring(5, digits.length >= 7 ? 7 : digits.length));
    }

    if (digits.length > 7) {
      buffer.write(' ');
      buffer.write(digits.substring(7, digits.length));
    }

    final text = buffer.toString();

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
