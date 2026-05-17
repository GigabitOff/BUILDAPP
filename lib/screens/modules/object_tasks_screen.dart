import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_user.dart';
import '../../services/object_history_service.dart';
import '../../services/task_comments_service.dart';
import '../../services/users_service.dart';

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
  final List<AppUser> executors = [];
  bool isLoadingUsers = false;

  String selectedStatusFilter = 'Усі статуси';
  String selectedSortOrder = 'Нові зверху';

  static const List<String> taskStatuses = [
    'Планується',
    'В роботі',
    'Контроль',
    'Проблема',
    'Перепоставлена',
    'Просрочена',
    'Не виконано',
    'Завершено',
  ];

  static const List<String> statusFilters = [
    'Усі статуси',
    'Планується',
    'В роботі',
    'Контроль',
    'Проблема',
    'Перепоставлена',
    'Просрочена',
    'Не виконано',
    'Завершено',
  ];

  static const List<String> sortOrders = ['Нові зверху', 'Старі зверху'];

  @override
  void initState() {
    super.initState();
    loadUserType();
    loadUsers();
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

  String normalizeStatus(String status) {
    final value = status.trim();

    switch (value) {
      case 'Планируется':
      case 'Планується':
        return 'Планується';

      case 'В работе':
      case 'работе':
      case 'роботі':
      case 'В роботі':
        return 'В роботі';

      case 'Контроль':
        return 'Контроль';

      case 'Проблема':
        return 'Проблема';

      case 'Завершён':
      case 'Завершена':
      case 'Завершено':
        return 'Завершено';

      case 'Просрочена':
      case 'Прострочена':
      case 'overdue':
        return 'Просрочена';

      case 'Перепоставлена':
      case 'Перепостановка':
      case 'Перенесена':
      case 'rescheduled':
        return 'Перепоставлена';

      case 'Не выполнено':
      case 'Не виконано':
      case 'Невиконано':
      case 'failed':
        return 'Не виконано';

      default:
        return value.isEmpty ? 'Планується' : value;
    }
  }

  String statusToServer(String status) {
    final value = normalizeStatus(status);

    switch (value) {
      case 'Планується':
        return 'Планируется';

      case 'В роботі':
        return 'В работе';

      case 'Контроль':
        return 'Контроль';

      case 'Проблема':
        return 'Проблема';

      case 'Завершено':
        return 'Завершена';

      case 'Просрочена':
        return 'Просрочена';

      case 'Перепоставлена':
        return 'Перепоставлена';

      case 'Не виконано':
        return 'Не выполнено';

      default:
        return status.trim();
    }
  }

  List<Map<String, String>> get filteredTasks {
    final result = tasks.where((task) {
      final status = normalizeStatus(task['status'] ?? '');

      if (selectedStatusFilter != 'Усі статуси' &&
          status != selectedStatusFilter) {
        return false;
      }

      return true;
    }).toList();

    result.sort((a, b) {
      final aDate = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
      final bDate = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);

      if (selectedSortOrder == 'Старі зверху') {
        return aDate.compareTo(bDate);
      }

      return bDate.compareTo(aDate);
    });

    return result;
  }

  Future<void> loadUsers() async {
    if (!mounted) return;

    setState(() {
      isLoadingUsers = true;
    });

    try {
      final result = await UsersService.getUsers();
      final executorUsers = result.where((user) => user.isExecutor).toList();

      if (!mounted) return;

      setState(() {
        executors
          ..clear()
          ..addAll(executorUsers.isNotEmpty ? executorUsers : result);
      });
    } catch (_) {
      // Если список пользователей временно не загрузился — экран задач не ломаем.
    } finally {
      if (!mounted) return;

      setState(() {
        isLoadingUsers = false;
      });
    }
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
                'status': normalizeStatus('${item['status'] ?? 'Планується'}'),
                'date': '${item['created_at'] ?? ''}',
                'deadline': '${item['deadline'] ?? item['deadline_at'] ?? ''}',
                'updatedAt': '${item['updated_at'] ?? ''}',
                'createdByName': '${item['created_by_name'] ?? ''}',
                'executorId': '${item['executor_id'] ?? item['assigned_to'] ?? item['executor_user_id'] ?? ''}',
                'executorName': '${item['executor_name'] ?? item['assigned_to_name'] ?? item['executor'] ?? ''}',
                'autoReschedule': '${item['auto_reschedule'] ?? '0'}',
                'rescheduleIntervalHours': '${item['reschedule_interval_hours'] ?? ''}',
                'issueReason': '${item['issue_reason'] ?? item['overdue_reason'] ?? item['problem_description'] ?? item['fail_reason'] ?? item['delay_reason'] ?? ''}',
                'commentsCount': '${item['comments_count'] ?? item['comment_count'] ?? item['commentsCount'] ?? 0}',
                'newCommentsCount': '${item['new_comments_count'] ?? item['unread_comments_count'] ?? item['newCommentsCount'] ?? 0}',
              };
            }).toList(),
          );
        });
      } else {
        throw Exception(data['message'] ?? 'Помилка завантаження завдань');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не вдалося завантажити завдання: ${e.toString().replaceFirst('Exception: ', '')}',
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

  Future<bool> createTask(
    String status, {
    required int executorId,
    required String executorName,
    DateTime? deadline,
    bool autoReschedule = false,
    int rescheduleIntervalHours = 24,
  }) async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введи назву завдання')));
      return false;
    }

    if (executorId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вибери виконавця')),
      );
      return false;
    }

    if (autoReschedule && deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для автоперепостановки потрібно вказати строк'),
        ),
      );
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
              'status': statusToServer(status),
              'executor_id': executorId,
              'assigned_to': executorId,
              if (deadline != null) 'deadline': formatDateTimeForServer(deadline),
              'auto_reschedule': autoReschedule ? 1 : 0,
              'reschedule_interval_hours': rescheduleIntervalHours,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        // Пишем событие в историю объекта.
        // Не валим создание задачи, если история временно не записалась.
        try {
          await ObjectHistoryService.createHistoryItem(
            objectId: widget.objectId,
            actionType: 'task_created',
            title: 'Створено завдання',
            description: buildTaskCreatedHistoryDescription(
              title: title,
              description: description,
              executorName: executorName,
              deadline: deadline,
              autoReschedule: autoReschedule,
              rescheduleIntervalHours: rescheduleIntervalHours,
            ),
          );
        } catch (_) {}

        titleController.clear();
        descriptionController.clear();

        await loadTasks();

        if (!mounted) return false;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Завдання створено')));

        return true;
      } else {
        throw Exception(data['message'] ?? 'Помилка створення завдання');
      }
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не вдалося створити завдання: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> updateTaskStatus({
    required String taskId,
    required String status,
    required String oldStatus,
    required String taskTitle,
    String issueReason = '',
  }) async {
    if (taskId.isEmpty) return;

    final normalizedOldStatus = normalizeStatus(oldStatus);
    final normalizedNewStatus = normalizeStatus(status);

    if (normalizedOldStatus == normalizedNewStatus && issueReason.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Статус не змінився')),
      );
      return;
    }

    try {
      final token = await getToken();
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Користувач';

      final response = await http
          .put(
            Uri.parse('$baseUrl/api/object-tasks/$taskId/status'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'status': statusToServer(normalizedNewStatus),
              if (issueReason.trim().isNotEmpty) 'issue_reason': issueReason.trim(),
              if (issueReason.trim().isNotEmpty) 'overdue_reason': issueReason.trim(),
              if (issueReason.trim().isNotEmpty) 'problem_description': issueReason.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Пишем в историю объекта, что пользователь поменял статус задачи.
        // Если история не записалась — саму смену статуса не откатываем.
        try {
          await ObjectHistoryService.createHistoryItem(
            objectId: widget.objectId,
            actionType: 'task_status_changed',
            title: 'Змінено статус завдання',
            description: issueReason.trim().isEmpty
                ? '$userName змінив статус завдання "$taskTitle": $normalizedOldStatus → $normalizedNewStatus'
                : '$userName змінив статус завдання "$taskTitle": $normalizedOldStatus → $normalizedNewStatus. Причина: ${issueReason.trim()}',
          );
        } catch (_) {}

        await loadTasks();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Статус завдання оновлено')),
        );
      } else {
        throw Exception(data['message'] ?? 'Помилка оновлення статусу');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не вдалося оновити статус: ${e.toString().replaceFirst('Exception: ', '')}',
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
        ).showSnackBar(const SnackBar(content: Text('Завдання видалено')));
      } else {
        throw Exception(data['message'] ?? 'Помилка видалення завдання');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Не вдалося видалити завдання: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (normalizeStatus(status)) {
      case 'В роботі':
        return const Color(0xFF1F6FEB);
      case 'Планується':
        return const Color(0xFF8A63D2);
      case 'Контроль':
        return const Color(0xFFFF9800);
      case 'Завершено':
        return const Color(0xFF22A06B);
      case 'Проблема':
      case 'Перепоставлена':
        return const Color(0xFFFF9800);
      case 'Просрочена':
      case 'Не виконано':
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

  DateTime? parseTaskDate(String rawDate) {
    final value = rawDate.trim();

    if (value.isEmpty || value == 'null') return null;

    return DateTime.tryParse(value);
  }

  bool isCompletedStatus(String status) {
    return normalizeStatus(status) == 'Завершено';
  }

  bool isTaskOverdue(Map<String, String> task) {
    final deadline = parseTaskDate(task['deadline'] ?? '');
    if (deadline == null) return false;

    return deadline.isBefore(DateTime.now()) &&
        !isCompletedStatus(task['status'] ?? '');
  }

  bool hasTaskIssueReason(Map<String, String> task) {
    return (task['issueReason'] ?? '').trim().isNotEmpty;
  }

  bool taskNeedsIssueReason(Map<String, String> task, String status) {
    final normalized = normalizeStatus(status);

    return normalized == 'Проблема' ||
        normalized == 'Просрочена' ||
        normalized == 'Перепоставлена' ||
        normalized == 'Не виконано' ||
        (isTaskOverdue(task) && normalized != 'Завершено');
  }

  String formatDateTimeForServer(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');

    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:00';
  }

  String formatRescheduleInterval(int hours) {
    if (hours == 1) return 'через 1 годину';
    if (hours == 3) return 'через 3 години';
    if (hours == 6) return 'через 6 годин';
    if (hours == 12) return 'через 12 годин';
    if (hours == 24) return 'через 1 день';
    if (hours == 48) return 'через 2 дні';
    if (hours == 72) return 'через 3 дні';
    if (hours == 168) return 'через 7 днів';

    return 'через $hours год';
  }

  String buildTaskCreatedHistoryDescription({
    required String title,
    required String description,
    required String executorName,
    required DateTime? deadline,
    required bool autoReschedule,
    required int rescheduleIntervalHours,
  }) {
    final parts = <String>[
      description.isEmpty
          ? 'Створено завдання: $title'
          : 'Створено завдання: $title. $description',
    ];

    if (executorName.trim().isNotEmpty) {
      parts.add('Виконавець: ${executorName.trim()}');
    }

    if (deadline != null) {
      parts.add('Строк виконання: ${formatDate(formatDateTimeForServer(deadline))}');
    }

    if (autoReschedule) {
      parts.add(
        'Автоперепостановка: так, ${formatRescheduleInterval(rescheduleIntervalHours)}',
      );
    }

    return parts.join('. ');
  }

  Future<DateTime?> pickDeadline(DateTime? currentDeadline) async {
    final now = DateTime.now();
    final initialDate = currentDeadline ?? now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Вибери дату строку',
      cancelText: 'Скасувати',
      confirmText: 'Далі',
    );

    if (date == null) return null;

    if (!mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      helpText: 'Вибери час строку',
      cancelText: 'Скасувати',
      confirmText: 'Готово',
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  List<DropdownMenuItem<String>> buildStatusItems() {
    return taskStatuses.map((status) {
      return DropdownMenuItem<String>(value: status, child: Text(status));
    }).toList();
  }

  void showAddTaskSheet() {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Тільки адміністратор може створювати завдання'),
        ),
      );
      return;
    }

    titleController.clear();
    descriptionController.clear();

    String selectedStatus = 'Планується';
    int? selectedExecutorId;
    String selectedExecutorName = '';
    DateTime? selectedDeadline;
    bool autoReschedule = false;
    int rescheduleIntervalHours = 24;
    String sheetError = '';

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
                          'Нове завдання',
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
                            labelText: 'Назва завдання',
                            hintText: 'Наприклад: перевірити монтаж вікон',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Опис',
                            hintText: 'Що потрібно зробити?',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: selectedExecutorId,
                          decoration: const InputDecoration(
                            labelText: 'Виконавець',
                            border: OutlineInputBorder(),
                          ),
                          hint: Text(
                            isLoadingUsers
                                ? 'Завантажуємо виконавців...'
                                : 'Вибери виконавця',
                          ),
                          items: executors.map((user) {
                            return DropdownMenuItem<int>(
                              value: user.id,
                              child: Text(
                                user.name.isEmpty ? user.email : user.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: isSaving || isLoadingUsers
                              ? null
                              : (value) {
                                  final selectedUser = executors
                                      .where((user) => user.id == value)
                                      .cast<AppUser?>()
                                      .firstWhere(
                                        (user) => user != null,
                                        orElse: () => null,
                                      );

                                  setSheetState(() {
                                    selectedExecutorId = value;
                                    selectedExecutorName = selectedUser == null
                                        ? ''
                                        : (selectedUser.name.isEmpty
                                            ? selectedUser.email
                                            : selectedUser.name);
                                    sheetError = '';
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Статус',
                            border: OutlineInputBorder(),
                          ),
                          items: buildStatusItems(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;

                                  setSheetState(() {
                                    selectedStatus = value;
                                    sheetError = '';
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picked = await pickDeadline(
                                    selectedDeadline,
                                  );

                                  if (picked == null) return;

                                  setSheetState(() {
                                    selectedDeadline = picked;
                                    sheetError = '';
                                  });
                                },
                          icon: const Icon(Icons.event_available_outlined),
                          label: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              selectedDeadline == null
                                  ? 'Вказати строк виконання'
                                  : 'Строк: ${formatDate(formatDateTimeForServer(selectedDeadline!))}',
                            ),
                          ),
                        ),
                        if (selectedDeadline != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      setSheetState(() {
                                        selectedDeadline = null;
                                        autoReschedule = false;
                                      });
                                    },
                              icon: const Icon(Icons.close),
                              label: const Text('Прибрати строк'),
                            ),
                          ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Автоматично перепоставити',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text(
                            'Якщо строк пройшов, сервер створить нову задачу',
                          ),
                          value: autoReschedule,
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    autoReschedule = value;
                                    if (value && selectedDeadline == null) {
                                      sheetError =
                                          'Спочатку вкажи строк виконання';
                                    } else {
                                      sheetError = '';
                                    }
                                  });
                                },
                        ),
                        if (autoReschedule) ...[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: rescheduleIntervalHours,
                            decoration: const InputDecoration(
                              labelText: 'Новий строк після прострочки',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 1,
                                child: Text('+1 година'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('+3 години'),
                              ),
                              DropdownMenuItem(
                                value: 6,
                                child: Text('+6 годин'),
                              ),
                              DropdownMenuItem(
                                value: 12,
                                child: Text('+12 годин'),
                              ),
                              DropdownMenuItem(
                                value: 24,
                                child: Text('+1 день'),
                              ),
                              DropdownMenuItem(
                                value: 48,
                                child: Text('+2 дні'),
                              ),
                              DropdownMenuItem(
                                value: 72,
                                child: Text('+3 дні'),
                              ),
                              DropdownMenuItem(
                                value: 168,
                                child: Text('+7 днів'),
                              ),
                            ],
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value == null) return;

                                    setSheetState(() {
                                      rescheduleIntervalHours = value;
                                    });
                                  },
                          ),
                        ],
                        if (sheetError.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            sheetError,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                                child: const Text('Скасувати'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        setSheetState(() {
                                          sheetError = '';
                                        });

                                        if (selectedExecutorId == null) {
                                          setSheetState(() {
                                            sheetError = 'Вибери виконавця';
                                          });
                                          return;
                                        }

                                        final created = await createTask(
                                          selectedStatus,
                                          executorId: selectedExecutorId!,
                                          executorName: selectedExecutorName,
                                          deadline: selectedDeadline,
                                          autoReschedule: autoReschedule,
                                          rescheduleIntervalHours:
                                              rescheduleIntervalHours,
                                        );

                                        if (created && mounted) {
                                          Navigator.pop(sheetContext);
                                        } else {
                                          setSheetState(() {
                                            sheetError =
                                                'Не вдалося створити завдання. Перевір дані або сервер.';
                                          });
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
                                  isSaving ? 'Зберігаємо...' : 'Додати',
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
    String selectedStatus = normalizeStatus(task['status'] ?? 'Планується');
    final issueController = TextEditingController(
      text: (task['issueReason'] ?? '').trim(),
    );
    String sheetError = '';

    bool needsIssueReason(String status) {
      return taskNeedsIssueReason(task, status);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final needReason = needsIssueReason(selectedStatus);

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
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Змінити статус',
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
                          items: buildStatusItems(),
                          onChanged: (value) {
                            if (value == null) return;

                            setSheetState(() {
                              selectedStatus = value;
                              sheetError = '';
                            });
                          },
                        ),
                        if (needReason) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: issueController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Причина просрочки / невиконання',
                              hintText: 'Наприклад: немає матеріалу, виконавець не встиг, замовник не допустив на об’єкт...',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              if (sheetError.isNotEmpty) {
                                setSheetState(() {
                                  sheetError = '';
                                });
                              }
                            },
                          ),
                        ],
                        if (sheetError.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              sheetError,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                },
                                child: const Text('Скасувати'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final reason = issueController.text.trim();

                                  if (needReason && reason.isEmpty) {
                                    setSheetState(() {
                                      sheetError = 'Опиши причину просрочки або невиконання';
                                    });
                                    return;
                                  }

                                  Navigator.pop(sheetContext);

                                  await updateTaskStatus(
                                    taskId: taskId,
                                    status: selectedStatus,
                                    oldStatus: task['status'] ?? 'Планується',
                                    taskTitle: task['title'] ?? 'Без назви',
                                    issueReason: needReason ? reason : '',
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Зберегти'),
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
    ).whenComplete(issueController.dispose);
  }

  void openTaskDetails(Map<String, String> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final status = normalizeStatus(task['status'] ?? '');
        final statusColor = getStatusColor(status);
        final createdByName = task['createdByName'] ?? '';
        final executorName = task['executorName'] ?? '';
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
                          'Завдання',
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
                          tooltip: 'Видалити',
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
                              ? 'Опис не вказано'
                              : task['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
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
                            if (isTaskOverdue(task)) const _StatusBadge(text: 'Просрочено'),
                            if (isTaskOverdue(task) && !hasTaskIssueReason(task))
                              const _StatusBadge(text: 'Не виконано'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if ((task['issueReason'] ?? '').trim().isNotEmpty)
                          _TaskInfoRow(
                            icon: Icons.report_problem_outlined,
                            label: 'Причина',
                            value: (task['issueReason'] ?? '').trim(),
                          ),
                        if (createdByName.isNotEmpty)
                          _TaskInfoRow(
                            icon: Icons.person_outline,
                            label: 'Створив',
                            value: createdByName,
                          ),
                        if (executorName.isNotEmpty)
                          _TaskInfoRow(
                            icon: Icons.engineering_outlined,
                            label: 'Виконавець',
                            value: executorName,
                          ),
                        _TaskInfoRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Дата',
                          value: formatDate(task['date'] ?? ''),
                        ),
                        _TaskInfoRow(
                          icon: Icons.event_available_outlined,
                          label: 'Строк',
                          value: formatDate(task['deadline'] ?? ''),
                        ),
                        _TaskInfoRow(
                          icon: Icons.autorenew_outlined,
                          label: 'Автоперепостановка',
                          value: (task['autoReschedule'] == '1' ||
                                  task['autoReschedule'] == 'true')
                              ? 'Так'
                              : 'Ні',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TaskCommentsBlock(
                    taskId: int.tryParse(taskId) ?? 0,
                    initialCount: int.tryParse(task['commentsCount'] ?? '0') ?? 0,
                    onCommentAdded: loadTasks,
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
                          child: const Text('Закрити'),
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

  void showFilterSheet() {
    String tempStatus = selectedStatusFilter;
    String tempSort = selectedSortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Сортування завдань',
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
                    const SizedBox(height: 18),
                    const Text(
                      'Статус завдання',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: tempStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: statusFilters.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          tempStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Сортування',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: tempSort,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: sortOrders.map((sort) {
                        return DropdownMenuItem<String>(
                          value: sort,
                          child: Text(sort),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          tempSort = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedStatusFilter = tempStatus;
                            selectedSortOrder = tempSort;
                          });

                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Застосувати'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F6FEB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedStatusFilter = 'Усі статуси';
                            selectedSortOrder = 'Нові зверху';
                          });

                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Скинути фільтр'),
                      ),
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
              'Завдань поки немає',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Натисни “Додати”, щоб створити перше завдання по об’єкту.'
                  : 'По цьому об’єкту завдань поки немає.',
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
    final visibleTasks = filteredTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Завдання по об’єкту',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: showFilterSheet,
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Фільтр',
          ),
          IconButton(
            onPressed: isLoading ? null : loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Оновити',
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
              label: Text(isSaving ? 'Зберігаємо...' : 'Додати'),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : visibleTasks.isEmpty
          ? buildEmptyState()
          : RefreshIndicator(
              onRefresh: loadTasks,
              child: ListView.separated(
                padding: const EdgeInsets.all(22),
                itemCount: visibleTasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final task = visibleTasks[index];

                  return _TaskCard(
                    title: task['title'] ?? '',
                    description: task['description'] ?? '',
                    status: normalizeStatus(task['status'] ?? ''),
                    date: formatDate(task['date'] ?? ''),
                    deadline: formatDate(task['deadline'] ?? ''),
                    executorName: task['executorName'] ?? '',
                    statusColor: getStatusColor(task['status'] ?? ''),
                    isOverdue: isTaskOverdue(task),
                    hasIssueReason: hasTaskIssueReason(task),
                    commentsCount: int.tryParse(task['commentsCount'] ?? '0') ?? 0,
                    newCommentsCount: int.tryParse(task['newCommentsCount'] ?? '0') ?? 0,
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
  final String deadline;
  final String executorName;
  final Color statusColor;
  final bool isOverdue;
  final bool hasIssueReason;
  final int commentsCount;
  final int newCommentsCount;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.status,
    required this.date,
    required this.deadline,
    required this.executorName,
    required this.statusColor,
    required this.isOverdue,
    required this.hasIssueReason,
    required this.commentsCount,
    this.newCommentsCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeDescription = description.isEmpty
        ? 'Опис не вказано'
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
                    title.isEmpty ? 'Без назви' : title,
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
                  if (executorName.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.engineering_outlined,
                          size: 16,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Виконавець: ${executorName.trim()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                      if (isOverdue) const _StatusBadge(text: 'Просрочено'),
                      if (isOverdue && !hasIssueReason)
                        const _StatusBadge(text: 'Не виконано'),
                      _CommentBadge(
                        totalCount: commentsCount,
                        newCount: newCommentsCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (deadline.isNotEmpty)
                    Text(
                      'Строк: $deadline',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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



class _CommentBadge extends StatelessWidget {
  final int totalCount;
  final int newCount;

  const _CommentBadge({
    required this.totalCount,
    this.newCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasNew = newCount > 0;
    final mainColor = hasNew ? const Color(0xFFD93025) : const Color(0xFF1F6FEB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: mainColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 13,
            color: mainColor,
          ),
          const SizedBox(width: 5),
          Text(
            'Всього: $totalCount',
            style: TextStyle(
              color: mainColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'Нові: $newCount',
            style: TextStyle(
              color: mainColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCommentsBlock extends StatefulWidget {
  final int taskId;
  final int initialCount;
  final Future<void> Function()? onCommentAdded;

  const _TaskCommentsBlock({
    required this.taskId,
    required this.initialCount,
    this.onCommentAdded,
  });

  @override
  State<_TaskCommentsBlock> createState() => _TaskCommentsBlockState();
}

class _TaskCommentsBlockState extends State<_TaskCommentsBlock> {
  final TextEditingController _controller = TextEditingController();
  final List<TaskComment> _comments = [];

  bool _expanded = false;
  bool _isLoading = false;
  bool _isSending = false;
  String _error = '';

  int get _visibleCount => _comments.isNotEmpty ? _comments.length : widget.initialCount;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (widget.taskId <= 0) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await TaskCommentsService.getTaskComments(widget.taskId);
      if (!mounted) return;

      setState(() {
        _comments
          ..clear()
          ..addAll(result);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.taskId <= 0) return;

    setState(() {
      _isSending = true;
      _error = '';
    });

    try {
      await TaskCommentsService.addTaskComment(
        taskId: widget.taskId,
        comment: text,
      );
      _controller.clear();
      await _loadComments();
      await widget.onCommentAdded?.call();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });
    }
  }

  String _formatDate(String rawDate) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final shouldLoad = !_expanded && _comments.isEmpty;

              setState(() {
                _expanded = !_expanded;
              });

              if (shouldLoad) {
                await _loadComments();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F6FEB).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF1F6FEB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Коментарі по задачі',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _visibleCount == 0
                              ? 'Переписка поки порожня'
                              : '$_visibleCount повідомлень',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_comments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Коментарів ще немає. Напиши перший коментар, щоб постановщик і виконавець бачили переписку.',
                        style: TextStyle(color: Colors.black54, height: 1.35),
                      ),
                    )
                  else
                    ..._comments.map((comment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      comment.userName.isEmpty
                                          ? 'Користувач'
                                          : comment.userName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDate(comment.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black38,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                comment.comment,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error,
                      style: const TextStyle(
                        color: Color(0xFFD93025),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Написати коментар...',
                            filled: true,
                            fillColor: const Color(0xFFF4F6FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _sendComment,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: const Color(0xFF1F6FEB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;

  const _StatusBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD93025).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD93025),
          fontSize: 12,
          fontWeight: FontWeight.w900,
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
    final safeValue = value.isEmpty ? 'Не вказано' : value;

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
