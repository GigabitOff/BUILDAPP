import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ObjectTasksScreen extends StatefulWidget {
  final int objectId;
  final String objectName;

  const ObjectTasksScreen({
    super.key,
    required this.objectId,
    required this.objectName,
  });

  @override
  State<ObjectTasksScreen> createState() => _ObjectTasksScreenState();
}

class _ObjectTasksScreenState extends State<ObjectTasksScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  static const String baseUrl = 'http://185.112.41.227:3036';

  String userType = '';

  bool isLoading = false;
  bool isSaving = false;

  bool get isAdmin => userType == 'admin';

  final List<Map<String, String>> tasks = [];

  @override
  void initState() {
    super.initState();
    loadUserType();
    loadTasks();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> loadUserType() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userType = prefs.getString('user_type') ?? '';
    });
  }

  Future<void> loadTasks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await getToken();

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/construction-objects/${widget.objectId}/tasks',
            ),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List items = data['data'] ?? [];

        setState(() {
          tasks.clear();

          tasks.addAll(
            items.map<Map<String, String>>((item) {
              return {
                'id': '${item['id'] ?? ''}',
                'title': '${item['title'] ?? ''}',
                'description': '${item['description'] ?? ''}',
                'status': '${item['status'] ?? 'Планируется'}',
                'date': '${item['created_at'] ?? ''}',
                'updatedAt': '${item['updated_at'] ?? ''}',
                'createdByName': '${item['created_by_name'] ?? ''}',
              };
            }).toList(),
          );
        });
      } else {
        throw Exception(data['message'] ?? 'Ошибка загрузки задач');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось загрузить задачи: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> createTask(String status) async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введи название задачи')));
      return false;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final token = await getToken();

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/api/construction-objects/${widget.objectId}/tasks',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'title': title,
              'description': description,
              'status': status,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        titleController.clear();
        descriptionController.clear();

        await loadTasks();

        if (!mounted) return false;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Задача создана')));

        return true;
      } else {
        throw Exception(data['message'] ?? 'Ошибка создания задачи');
      }
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось создать задачу: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );

      return false;
    } finally {
      if (!mounted) return false;

      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    if (taskId.isEmpty) return;

    try {
      final token = await getToken();

      final response = await http
          .put(
            Uri.parse('$baseUrl/api/object-tasks/$taskId/status'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await loadTasks();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Статус задачи обновлён')));
      } else {
        throw Exception(data['message'] ?? 'Ошибка обновления статуса');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось обновить статус: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (taskId.isEmpty) return;

    try {
      final token = await getToken();

      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/object-tasks/$taskId'),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await loadTasks();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Задача удалена')));
      } else {
        throw Exception(data['message'] ?? 'Ошибка удаления задачи');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось удалить задачу: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'В работе':
        return const Color(0xFF1F6FEB);
      case 'Планируется':
        return const Color(0xFF8A63D2);
      case 'Контроль':
        return const Color(0xFFFF9800);
      case 'Завершена':
        return const Color(0xFF22A06B);
      case 'Проблема':
        return const Color(0xFFD93025);
      default:
        return const Color(0xFF1F6FEB);
    }
  }

  String formatDate(String rawDate) {
    if (rawDate.isEmpty || rawDate == 'null') return '';

    try {
      final date = DateTime.parse(rawDate).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day.$month.$year $hour:$minute';
    } catch (_) {
      return rawDate;
    }
  }

  void showAddTaskSheet() {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Только администратор может создавать задачи'),
        ),
      );
      return;
    }

    titleController.clear();
    descriptionController.clear();

    String selectedStatus = 'Планируется';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Новая задача',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.objectName,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Название задачи',
                            hintText: 'Например: проверить монтаж окон',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Описание',
                            hintText: 'Что нужно сделать?',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Статус',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Планируется',
                              child: Text('Планируется'),
                            ),
                            DropdownMenuItem(
                              value: 'В работе',
                              child: Text('В работе'),
                            ),
                            DropdownMenuItem(
                              value: 'Контроль',
                              child: Text('Контроль'),
                            ),
                            DropdownMenuItem(
                              value: 'Проблема',
                              child: Text('Проблема'),
                            ),
                            DropdownMenuItem(
                              value: 'Завершена',
                              child: Text('Завершена'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setSheetState(() {
                              selectedStatus = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () {
                                        Navigator.pop(sheetContext);
                                      },
                                child: const Text('Отмена'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final created = await createTask(
                                          selectedStatus,
                                        );

                                        if (created && mounted) {
                                          Navigator.pop(sheetContext);
                                        }
                                      },
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(
                                  isSaving ? 'Сохраняем...' : 'Добавить',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showChangeStatusSheet(Map<String, String> task) {
    final taskId = task['id'] ?? '';
    String selectedStatus = task['status'] ?? 'Планируется';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Изменить статус',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Статус',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Планируется',
                          child: Text('Планируется'),
                        ),
                        DropdownMenuItem(
                          value: 'В работе',
                          child: Text('В работе'),
                        ),
                        DropdownMenuItem(
                          value: 'Контроль',
                          child: Text('Контроль'),
                        ),
                        DropdownMenuItem(
                          value: 'Проблема',
                          child: Text('Проблема'),
                        ),
                        DropdownMenuItem(
                          value: 'Завершена',
                          child: Text('Завершена'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                            },
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetContext);

                              await updateTaskStatus(
                                taskId: taskId,
                                status: selectedStatus,
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Сохранить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void openTaskDetails(Map<String, String> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final status = task['status'] ?? '';
        final statusColor = getStatusColor(status);
        final createdByName = task['createdByName'] ?? '';
        final taskId = task['id'] ?? '';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Задача',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        IconButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await deleteTask(taskId);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Удалить',
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (task['description'] ?? '').isEmpty
                              ? 'Описание не указано'
                              : task['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (createdByName.isNotEmpty)
                          _TaskInfoRow(
                            icon: Icons.person_outline,
                            label: 'Создал',
                            value: createdByName,
                          ),
                        _TaskInfoRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Дата',
                          value: formatDate(task['date'] ?? ''),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            showChangeStatusSheet(task);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Статус'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Закрыть'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.task_alt_outlined,
                color: Color(0xFF1F6FEB),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Задач пока нет',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Нажми “Добавить”, чтобы создать первую задачу по объекту.'
                  : 'По этому объекту задач пока нет.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Задачи по объекту',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: isSaving ? null : showAddTaskSheet,
              backgroundColor: const Color(0xFF1F6FEB),
              foregroundColor: Colors.white,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_task_outlined),
              label: Text(isSaving ? 'Сохраняем...' : 'Добавить'),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? buildEmptyState()
          : RefreshIndicator(
              onRefresh: loadTasks,
              child: ListView.separated(
                padding: const EdgeInsets.all(22),
                itemCount: tasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final task = tasks[index];

                  return _TaskCard(
                    title: task['title'] ?? '',
                    description: task['description'] ?? '',
                    status: task['status'] ?? '',
                    date: formatDate(task['date'] ?? ''),
                    statusColor: getStatusColor(task['status'] ?? ''),
                    onTap: () => openTaskDetails(task),
                  );
                },
              ),
            ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String description;
  final String status;
  final String date;
  final Color statusColor;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.status,
    required this.date,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeDescription = description.isEmpty
        ? 'Описание не указано'
        : description;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
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
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.task_alt_outlined,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Без названия' : title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    safeDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black38,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _TaskInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TaskInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.isEmpty ? 'Не указано' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.black38, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Flexible(
            child: Text(
              safeValue,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
