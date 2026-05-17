import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'pin_code_screen.dart';
import 'register_screen.dart';

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
      _showMessage('Р’РІРµРґРёС‚Рµ РїРѕР»РЅС‹Р№ РЅРѕРјРµСЂ С‚РµР»РµС„РѕРЅР°');
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

  Future<void> _openRegister() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Widget _registerBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _blue.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          const Text(
            'РќРµС‚ Р°РєРєР°СѓРЅС‚Р°?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Р—Р°СЂРµРіРёСЃС‚СЂРёСЂСѓР№С‚Рµ РєРѕРјРїР°РЅРёСЋ Рё СЃРѕР·РґР°Р№С‚Рµ РїРµСЂРІС‹Р№ Р°РєРєР°СѓРЅС‚ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _openRegister,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text(
                'Р—Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°С‚СЊСЃСЏ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                side: const BorderSide(color: _blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                      'EVENTHESAPP',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'РљРѕРЅС‚СЂРѕР»СЊ СЃС‚СЂРѕРёС‚РµР»СЊСЃС‚РІР°',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Р’С…РѕРґ РїРѕ С‚РµР»РµС„РѕРЅСѓ',
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
                        'Р’РІРµРґРёС‚Рµ РЅРѕРјРµСЂ, РєРѕС‚РѕСЂС‹Р№ Р·Р°РєСЂРµРїР»С‘РЅ Р·Р° РїРѕР»СЊР·РѕРІР°С‚РµР»РµРј',
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
                        labelText: 'РўРµР»РµС„РѕРЅ',
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
                                'РџРѕР»СѓС‡РёС‚СЊ PIN-РєРѕРґ',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),

                    _registerBox(),

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
                          'Р’С…РѕРґ С‡РµСЂРµР· СЃРµСЂРІРµСЂ EVENTHESAPP',
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



