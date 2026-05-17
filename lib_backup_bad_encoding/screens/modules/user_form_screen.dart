import 'package:flutter/material.dart';

import '../../services/users_service.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController(text: '123456');

  bool isSaving = false;
  String usertype = 'executor';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> saveUser() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      await UsersService.createUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
        usertype: usertype,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ СЃРѕР·РґР°РЅ')));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredField = true,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Р—Р°РїРѕР»РЅРё РїРѕР»Рµ';
              }

              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget roleSelect() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: usertype,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'executor', child: Text('РСЃРїРѕР»РЅРёС‚РµР»СЊ')),
            DropdownMenuItem(value: 'manager', child: Text('РњРµРЅРµРґР¶РµСЂ')),
            DropdownMenuItem(value: 'admin', child: Text('РђРґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂ')),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              usertype = value;
            });
          },
        ),
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
              'РџРѕСЃР»Рµ СЃРѕР·РґР°РЅРёСЏ РёСЃРїРѕР»РЅРёС‚РµР»СЏ РµРіРѕ РјРѕР¶РЅРѕ Р±СѓРґРµС‚ РїСЂРёРІСЏР·Р°С‚СЊ Рє РѕР±СЉРµРєС‚Сѓ СЃС‚СЂРѕРёС‚РµР»СЊСЃС‚РІР°.',
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
          'РЎРѕР·РґР°С‚СЊ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            infoBox(),

            const SizedBox(height: 18),

            field(
              controller: nameController,
              label: 'РРјСЏ',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 14),

            field(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 14),

            field(
              controller: phoneController,
              label: 'РўРµР»РµС„РѕРЅ',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 14),

            field(
              controller: passwordController,
              label: 'РџР°СЂРѕР»СЊ',
              icon: Icons.lock_outline,
              obscureText: false,
            ),

            const SizedBox(height: 14),

            roleSelect(),

            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveUser,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'РЎРѕС…СЂР°РЅСЏСЋ...' : 'РЎРѕР·РґР°С‚СЊ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ'),
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
        ),
      ),
    );
  }
}



