import 'package:flutter/material.dart';

import '../../models/construction_object.dart';
import '../../services/objects_service.dart';

class ObjectFormScreen extends StatefulWidget {
  const ObjectFormScreen({super.key});

  @override
  State<ObjectFormScreen> createState() => _ObjectFormScreenState();
}

class _ObjectFormScreenState extends State<ObjectFormScreen> {
  final formKey = GlobalKey<FormState>();
  final ObjectsService objectsService = ObjectsService();

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final customerController = TextEditingController();
  final responsibleController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isSaving = false;
  String status = 'Планируется';

  final List<String> statuses = const [
    'Планируется',
    'В работе',
    'Контроль',
    'На паузе',
    'Завершён',
    'Проблема',
  ];

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    customerController.dispose();
    responsibleController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> saveObject() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final object = ConstructionObject(
      id: 0,
      name: nameController.text.trim(),
      address: addressController.text.trim(),
      status: status,
      customer: customerController.text.trim(),
      responsible: responsibleController.text.trim(),
      executorName: '',
      startDate: startDateController.text.trim(),
      endDate: endDateController.text.trim(),
      description: descriptionController.text.trim(),
      tasksCount: 0,
      photosCount: 0,
    );

    try {
      final savedObject = await objectsService.createObject(object);

      if (!mounted) return;

      Navigator.pop(context, savedObject);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: !isSaving,
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Заполни поле';
              }
              return null;
            }
          : null,
      decoration: inputDecoration(label, icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Новый объект',
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
            Container(
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
                  Text(
                    'Создание объекта',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Заполни данные',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Объект будет отправлен на сервер и записан в БД',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            field(
              controller: nameController,
              label: 'Название объекта',
              icon: Icons.apartment_outlined,
              requiredField: true,
            ),

            const SizedBox(height: 14),

            field(
              controller: addressController,
              label: 'Адрес',
              icon: Icons.location_on_outlined,
              requiredField: true,
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: status,
              items: statuses.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        status = value;
                      });
                    },
              decoration: inputDecoration('Статус', Icons.flag_outlined),
            ),

            const SizedBox(height: 14),

            field(
              controller: customerController,
              label: 'Заказчик',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 14),

            field(
              controller: responsibleController,
              label: 'Ответственный',
              icon: Icons.engineering_outlined,
            ),

            const SizedBox(height: 14),

            field(
              controller: startDateController,
              label: 'Дата начала',
              icon: Icons.calendar_month_outlined,
            ),

            const SizedBox(height: 14),

            field(
              controller: endDateController,
              label: 'План завершения',
              icon: Icons.event_available_outlined,
            ),

            const SizedBox(height: 14),

            field(
              controller: descriptionController,
              label: 'Описание',
              icon: Icons.notes_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveObject,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Сохраняем...' : 'Сохранить объект'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6FEB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
