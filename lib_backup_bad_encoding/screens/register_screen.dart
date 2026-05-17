import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final authService = AuthService();

  final organizationController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController(text: '+38(0');
  final emailController = TextEditingController();
  final passwordController = TextEditingController(text: '123456');

  bool isLoading = false;
  bool showPassword = false;

  @override
  void dispose() {
    organizationController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String cleanPhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    final phone = cleanPhone(phoneController.text.trim());

    setState(() {
      isLoading = true;
    });

    try {
      await authService.register(
        organization: organizationController.text.trim(),
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phone,
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Р РµРіРёСЃС‚СЂР°С†РёСЏ СѓСЃРїРµС€РЅР°')));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Р—Р°РїРѕР»РЅРё РїРѕР»Рµ';
            }

            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F6FEB), Color(0xFF4C8DFF)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.apartment_outlined, color: Colors.white, size: 42),
          SizedBox(height: 14),
          Text(
            'Р РµРіРёСЃС‚СЂР°С†РёСЏ РєРѕРјРїР°РЅРёРё',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'РЎРѕР·РґР°Р№ РїРµСЂРІС‹Р№ Р°РєРєР°СѓРЅС‚ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂР°. РџРѕСЃР»Рµ СЌС‚РѕРіРѕ РјРѕР¶РЅРѕ РґРѕР±Р°РІР»СЏС‚СЊ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№, РѕР±СЉРµРєС‚С‹ Рё Р·Р°РґР°С‡Рё.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget infoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F6FEB).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF1F6FEB)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Р­С‚РѕС‚ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ СЃС‚Р°РЅРµС‚ Р°РґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂРѕРј РЅРѕРІРѕР№ РєРѕРјРїР°РЅРёРё.',
              style: TextStyle(
                color: Color(0xFF1F6FEB),
                fontWeight: FontWeight.w700,
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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Р РµРіРёСЃС‚СЂР°С†РёСЏ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            header(),

            const SizedBox(height: 18),

            infoBox(),

            const SizedBox(height: 18),

            field(
              controller: organizationController,
              label: 'РќР°Р·РІР°РЅРёРµ РєРѕРјРїР°РЅРёРё',
              icon: Icons.business_outlined,
            ),

            const SizedBox(height: 14),

            field(
              controller: nameController,
              label: 'Р’Р°С€Рµ РёРјСЏ',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 14),

            field(
              controller: phoneController,
              label: 'РўРµР»РµС„РѕРЅ',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              helperText: 'Р¤РѕСЂРјР°С‚: +38(099)123 45 67',
              inputFormatters: [UkrainianPhoneFormatter()],
              validator: (value) {
                final phone = cleanPhone(value ?? '');

                if (phone.isEmpty || phone == '380') {
                  return 'Р—Р°РїРѕР»РЅРё С‚РµР»РµС„РѕРЅ';
                }

                if (phone.length != 12) {
                  return 'Р’РІРµРґРёС‚Рµ РїРѕР»РЅС‹Р№ РЅРѕРјРµСЂ С‚РµР»РµС„РѕРЅР°';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            field(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Р—Р°РїРѕР»РЅРё email';
                }

                if (!email.contains('@')) {
                  return 'РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ email';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            field(
              controller: passwordController,
              label: 'РџР°СЂРѕР»СЊ',
              icon: Icons.lock_outline,
              obscureText: !showPassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              validator: (value) {
                final password = value ?? '';

                if (password.isEmpty) {
                  return 'Р—Р°РїРѕР»РЅРё РїР°СЂРѕР»СЊ';
                }

                if (password.length < 6) {
                  return 'РњРёРЅРёРјСѓРј 6 СЃРёРјРІРѕР»РѕРІ';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : register,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1_outlined),
                label: Text(
                  isLoading ? 'Р РµРіРёСЃС‚СЂРёСЂСѓСЋ...' : 'Р—Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°С‚СЊСЃСЏ',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6FEB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                'РЈ РјРµРЅСЏ СѓР¶Рµ РµСЃС‚СЊ Р°РєРєР°СѓРЅС‚',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UkrainianPhoneFormatter extends TextInputFormatter {
  static const String prefix = '+38(0';

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

    final buffer = StringBuffer(prefix);

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



