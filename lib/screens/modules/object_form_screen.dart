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
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isSaving = false;
  bool isLoadingExecutors = false;

  String status = 'Планується';

  List<Map<String, dynamic>> executors = [];
  int? selectedExecutorId;
  String selectedExecutorName = '';

  final List<String> statuses = const [
    'Планується',
    'В роботі',
    'Контроль',
    'На паузе',
    'Завершено',
    'Проблема',
  ];

  @override
  void initState() {
    super.initState();
    loadExecutors();
  }

  @override
  void dispose() {
    nameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadExecutors() async {
    setState(() {
      isLoadingExecutors = true;
    });

    try {
      final result = await objectsService.getExecutors();

      if (!mounted) return;

      setState(() {
        executors = result;

        if (executors.isNotEmpty) {
          final firstExecutor = executors.first;
          selectedExecutorId = int.tryParse('${firstExecutor['id']}');
          selectedExecutorName = '${firstExecutor['name'] ?? ''}';
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingExecutors = false;
        });
      }
    }
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day.$month.$year';
  }

  DateTime? parseDate(String value) {
    try {
      final parts = value.split('.');

      if (parts.length != 3) {
        return null;
      }

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  Future<void> pickDate(TextEditingController controller) async {
    if (isSaving) return;

    final now = DateTime.now();
    final currentValue = parseDate(controller.text.trim());

    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Оберіть дату',
      cancelText: 'Скасувати',
      confirmText: 'Вибрати',
    );

    if (picked == null) return;

    setState(() {
      controller.text = formatDate(picked);
    });
  }

  Future<void> saveObject() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedExecutorId == null || selectedExecutorId == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Оберіть виконавця')));
      return;
    }

    setState(() {
      isSaving = true;
    });

    final object = ConstructionObject(
      id: 0,
      name: nameController.text.trim(),
      address: '',
      status: status,
      customer: '',
      responsible: '',
      executorId: selectedExecutorId,
      executorName: selectedExecutorName,
      startDate: startDateController.text.trim(),
      endDate: endDateController.text.trim(),
      description: descriptionController.text.trim(),
      tasksCount: 0,
      photosCount: 0,
    );

    try {
      final savedObject = await objectsService.createObject(object);

      await objectsService.assignExecutorToObject(
        objectId: savedObject.id,
        userId: selectedExecutorId!,
        roleOnObject: 'executor',
      );

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
      suffixIcon: label.contains('Дата') || label.contains('План')
          ? const Icon(Icons.arrow_drop_down)
          : null,
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

  Widget dateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: !isSaving,
      onTap: () => pickDate(controller),
      decoration: inputDecoration(label, icon).copyWith(
        hintText: 'Вибрати дату',
        suffixIcon: IconButton(
          onPressed: isSaving ? null : () => pickDate(controller),
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Открыть календарь',
        ),
      ),
    );
  }

  Widget executorDropdown() {
    return DropdownButtonFormField<int>(
      value: selectedExecutorId,
      isExpanded: true,
      items: executors.map((executor) {
        final int userId = int.tryParse('${executor['id']}') ?? 0;
        final String name = '${executor['name'] ?? ''}'.trim();

        return DropdownMenuItem<int>(
          value: userId,
          child: Text(name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: isSaving || isLoadingExecutors
          ? null
          : (value) {
              if (value == null) return;

              final selected = executors.firstWhere(
                (executor) => int.tryParse('${executor['id']}') == value,
                orElse: () => {},
              );

              setState(() {
                selectedExecutorId = value;
                selectedExecutorName = '${selected['name'] ?? ''}'.trim();
              });
            },
      validator: (value) {
        if (value == null || value == 0) {
          return 'Оберіть виконавця';
        }

        return null;
      },
      decoration: inputDecoration('Виконавець', Icons.engineering_outlined),
      hint: Text(
        isLoadingExecutors ? 'Завантажуємо виконавців...' : 'Оберіть виконавця',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool disableSave = isSaving || isLoadingExecutors;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Новий об’єкт',
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
                    'Створення об’єкта',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Заповніть дані',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Об’єкт буде відправлено на сервер і записано в БД',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            field(
              controller: nameController,
              label: 'Назва об’єкта',
              icon: Icons.circle_outlined,
              requiredField: true,
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: status,
              items: statuses.map((item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
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

            executorDropdown(),

            const SizedBox(height: 14),

            dateField(
              controller: startDateController,
              label: 'Дата початку',
              icon: Icons.calendar_month_outlined,
            ),

            const SizedBox(height: 14),

            dateField(
              controller: endDateController,
              label: 'План завершення',
              icon: Icons.event_available_outlined,
            ),

            const SizedBox(height: 14),

            field(
              controller: descriptionController,
              label: 'Опис',
              icon: Icons.notes_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: disableSave ? null : saveObject,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  isSaving
                      ? 'Зберігаємо...'
                      : isLoadingExecutors
                      ? 'Завантажуємо виконавців...'
                      : 'Зберегти об’єкт',
                ),
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
