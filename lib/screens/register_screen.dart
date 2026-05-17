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

  final licenseController = TextEditingController();
  final organizationController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController(text: '+38(0');
  final emailController = TextEditingController();
  final passwordController = TextEditingController(text: '123456');

  bool isLoading = false;
  bool isCheckingLicense = false;
  bool showPassword = false;
  bool licenseVerified = false;
  String? verifiedLicenseKey;
  String? verifiedCompanyName;

  @override
  void dispose() {
    licenseController.dispose();
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

  Future<void> checkLicense() async {
    final licenseKey = licenseController.text.trim();

    if (licenseKey.isEmpty) {
      showMessage('Введіть ліцензійний ключ');
      return;
    }

    setState(() {
      isCheckingLicense = true;
    });

    try {
      final data = await authService.checkLicenseKey(licenseKey: licenseKey);
      final license = data['license'] ?? {};
      final companyName = license['company_name']?.toString() ?? '';

      setState(() {
        licenseVerified = true;
        verifiedLicenseKey = licenseKey;
        verifiedCompanyName = companyName;
        organizationController.text = companyName;
      });

      showMessage('Ліцензію знайдено: $companyName');
    } catch (e) {
      setState(() {
        licenseVerified = false;
        verifiedLicenseKey = null;
        verifiedCompanyName = null;
        organizationController.clear();
      });

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() {
        isCheckingLicense = false;
      });
    }
  }

  Future<void> register() async {
    if (!licenseVerified || verifiedLicenseKey == null) {
      showMessage('Спочатку перевірте ліцензійний ключ');
      return;
    }

    if (!formKey.currentState!.validate()) return;

    final phone = cleanPhone(phoneController.text.trim());

    setState(() {
      isLoading = true;
    });

    try {
      await authService.register(
        licenseKey: verifiedLicenseKey!,
        organization: organizationController.text.trim(),
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phone,
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Реєстрація успішна')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void resetLicense() {
    setState(() {
      licenseVerified = false;
      verifiedLicenseKey = null;
      verifiedCompanyName = null;
      organizationController.clear();
    });
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Заповніть поле';
            }

            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: readOnly ? const Color(0xFFEFF4FF) : Colors.white,
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
          Icon(Icons.vpn_key_outlined, color: Colors.white, size: 42),
          SizedBox(height: 14),
          Text(
            'Реєстрація за ліцензією',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Спочатку введіть ліцензійний ключ. Після перевірки відкриється форма створення адміністратора.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget licenseBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ліцензійний ключ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Ключ видає адміністратор EVENTHESAPP після створення клієнта.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.3),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: licenseController,
            enabled: !licenseVerified,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Наприклад: STROYSBOR-TEST-2026',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: licenseVerified
                  ? const Icon(Icons.check_circle, color: Color(0xFF188038))
                  : null,
              filled: true,
              fillColor: const Color(0xFFF7F8FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isCheckingLicense
                  ? null
                  : licenseVerified
                      ? resetLicense
                      : checkLicense,
              icon: isCheckingLicense
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      licenseVerified
                          ? Icons.edit_outlined
                          : Icons.verified_user_outlined,
                    ),
              label: Text(
                isCheckingLicense
                    ? 'Перевіряю...'
                    : licenseVerified
                        ? 'Змінити ключ'
                        : 'Перевірити ліцензію',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6FEB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (licenseVerified && verifiedCompanyName != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF188038).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Компанія знайдена: $verifiedCompanyName',
                style: const TextStyle(
                  color: Color(0xFF188038),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
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
              'Цей користувач буде створений у компанії, яка привʼязана до ліцензійного ключа.',
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

  Widget registrationFields() {
    if (!licenseVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Форма реєстрації відкриється після перевірки ліцензійного ключа.',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        infoBox(),
        const SizedBox(height: 18),
        field(
          controller: organizationController,
          label: 'Назва компанії',
          icon: Icons.business_outlined,
          readOnly: true,
        ),
        const SizedBox(height: 14),
        field(
          controller: nameController,
          label: 'Ваше ім’я',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        field(
          controller: phoneController,
          label: 'Телефон',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          helperText: 'Формат: +38(099)123 45 67',
          inputFormatters: [UkrainianPhoneFormatter()],
          validator: (value) {
            final phone = cleanPhone(value ?? '');

            if (phone.isEmpty || phone == '380') {
              return 'Заповніть телефон';
            }

            if (phone.length != 12) {
              return 'Введіть повний номер телефону';
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
              return 'Заповніть email';
            }

            if (!email.contains('@')) {
              return 'Некоректний email';
            }

            return null;
          },
        ),
        const SizedBox(height: 14),
        field(
          controller: passwordController,
          label: 'Пароль',
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
              return 'Заповніть пароль';
            }

            if (password.length < 6) {
              return 'Мінімум 6 символів';
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
            label: Text(isLoading ? 'Реєструю...' : 'Зареєструватися'),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Реєстрація',
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
            licenseBlock(),
            const SizedBox(height: 18),
            registrationFields(),
            const SizedBox(height: 14),
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                'У мене вже є акаунт',
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
