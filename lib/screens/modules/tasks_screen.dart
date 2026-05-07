import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_config.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool isLoading = true;
  String errorText = '';

  final List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Нет токена авторизации. Выйди и зайди заново.');
    }

    return token;
  }

  Future<void> loadTasks() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      final token = await getToken();

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/tasks'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Ошибка получения задач');
      }

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Сервер вернул ошибку');
      }

      final List items = data['data'] ?? [];

      if (!mounted) return;

      setState(() {
        tasks
          ..clear()
          ..addAll(items.map((item) => Map<String, dynamic>.from(item)));
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> updateTaskStatus({
    required int taskId,
    required String status,
  }) async {
    try {
      final token = await getToken();

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/api/object-tasks/$taskId/status'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Ошибка обновления статуса');
      }

      await loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Статус задачи обновлён')));
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

  String formatDate(dynamic rawDate) {
    final value = '${rawDate ?? ''}';

    if (value.isEmpty || value == 'null') return 'Не указано';

    try {
      final date = DateTime.parse(value).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day.$month.$year $hour:$minute';
    } catch (_) {
      return value;
    }
  }

  String safeText(dynamic value, {String fallback = 'Не указано'}) {
    final text = '${value ?? ''}'.trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  void showTaskDetails(Map<String, dynamic> task) {
    final int taskId = int.tryParse('${task['id'] ?? 0}') ?? 0;
    final String title = safeText(task['title'], fallback: 'Без названия');
    final String description = safeText(
      task['description'],
      fallback: 'Описание не указано',
    );
    final String status = safeText(task['status'], fallback: 'Планируется');
    final String objectName = safeText(task['object_name']);
    final String objectAddress = safeText(task['object_address']);
    final String executorName = safeText(task['executor_name']);
    final String createdByName = safeText(task['created_by_name']);
    final String createdAt = formatDate(task['created_at']);
    final String deadline = formatDate(task['deadline']);

    final Color statusColor = getStatusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String selectedStatus = status;

        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      const Text(
                        'Задача',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              description,
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

                            const SizedBox(height: 16),

                            _InfoRow(
                              icon: Icons.apartment_outlined,
                              label: 'Объект',
                              value: objectName,
                            ),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Адрес',
                              value: objectAddress,
                            ),
                            _InfoRow(
                              icon: Icons.person_outline,
                              label: 'Исполнитель',
                              value: executorName,
                            ),
                            _InfoRow(
                              icon: Icons.admin_panel_settings_outlined,
                              label: 'Создал',
                              value: createdByName,
                            ),
                            _InfoRow(
                              icon: Icons.calendar_month_outlined,
                              label: 'Создано',
                              value: createdAt,
                            ),
                            _InfoRow(
                              icon: Icons.timer_outlined,
                              label: 'Срок',
                              value: deadline,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Статус задачи',
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
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Закрыть'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: taskId == 0
                                  ? null
                                  : () async {
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
              ),
            );
          },
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
            const Text(
              'Когда задачи появятся на объектах, они будут здесь одним списком.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD93025), size: 46),
            const SizedBox(height: 14),
            const Text(
              'Не удалось загрузить задачи',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
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
          'Задачи',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorText.isNotEmpty
          ? buildErrorState()
          : tasks.isEmpty
          ? buildEmptyState()
          : RefreshIndicator(
              onRefresh: loadTasks,
              child: ListView.separated(
                padding: const EdgeInsets.all(22),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final task = tasks[index];

                  final title = safeText(
                    task['title'],
                    fallback: 'Без названия',
                  );
                  final objectName = safeText(task['object_name']);
                  final objectAddress = safeText(task['object_address']);
                  final executorName = safeText(task['executor_name']);
                  final status = safeText(
                    task['status'],
                    fallback: 'Планируется',
                  );
                  final createdAt = formatDate(task['created_at']);
                  final deadline = formatDate(task['deadline']);
                  final statusColor = getStatusColor(status);

                  return _TaskCard(
                    title: title,
                    objectName: objectName,
                    objectAddress: objectAddress,
                    executorName: executorName,
                    status: status,
                    createdAt: createdAt,
                    deadline: deadline,
                    statusColor: statusColor,
                    onTap: () => showTaskDetails(task),
                  );
                },
              ),
            ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String objectName;
  final String objectAddress;
  final String executorName;
  final String status;
  final String createdAt;
  final String deadline;
  final Color statusColor;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.objectName,
    required this.objectAddress,
    required this.executorName,
    required this.status,
    required this.createdAt,
    required this.deadline,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDeadline = deadline != 'Не указано';

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Объект: $objectName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    objectAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          executorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
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
                      _SmallBadge(
                        icon: Icons.calendar_month_outlined,
                        text: createdAt,
                      ),
                      if (hasDeadline)
                        _SmallBadge(icon: Icons.timer_outlined, text: deadline),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black45),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.trim().isEmpty ? 'Не указано' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black38, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
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
