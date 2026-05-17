import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_config.dart';
import '../../services/task_comments_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool isLoading = true;
  String errorText = '';

  final List<Map<String, dynamic>> tasks = [];

  String selectedObject = 'Усі об’єкти';
  String selectedStatus = 'Усі статуси';
  String selectedSort = 'Новые сверху';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Немає токена авторизації. Выйди и зайди заново.');
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
        throw Exception(data['message'] ?? 'Ошибка получения завдань');
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
    String issueReason = '',
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
            body: jsonEncode({
              'status': statusToServer(status),
              if (issueReason.trim().isNotEmpty) 'issue_reason': issueReason.trim(),
              if (issueReason.trim().isNotEmpty) 'overdue_reason': issueReason.trim(),
              if (issueReason.trim().isNotEmpty) 'problem_description': issueReason.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Помилка оновлення статусу');
      }

      await loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Статус завдання обновлён')));
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

  String normalizeStatus(String status) {
    final value = status.trim();

    switch (value) {
      case 'Планируется':
      case 'Планується':
        return 'Планується';
      case 'В работе':
      case ' работе':
      case 'В роботі':
      case 'роботі':
        return 'В роботі';
      case 'Завершена':
      case 'Завершено':
      case 'Завершён':
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
    switch (normalizeStatus(status)) {
      case 'Планується':
        return 'Планируется';
      case 'В роботі':
        return 'В работе';
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

  DateTime? parseTaskDate(dynamic rawDate) {
    final value = '${rawDate ?? ''}'.trim();

    if (value.isEmpty || value == 'null') {
      return null;
    }

    return DateTime.tryParse(value);
  }

  bool isCompletedStatus(String status) {
    return normalizeStatus(status) == 'Завершено';
  }

  bool isTaskOverdue(Map<String, dynamic> task) {
    final deadline = parseTaskDate(task['deadline']);
    if (deadline == null) return false;

    return deadline.isBefore(DateTime.now()) &&
        !isCompletedStatus('${task['status'] ?? ''}');
  }

  String taskIssueReason(Map<String, dynamic> task) {
    return safeText(
      task['issue_reason'] ??
          task['overdue_reason'] ??
          task['problem_description'] ??
          task['fail_reason'] ??
          task['delay_reason'],
      fallback: '',
    );
  }

  bool hasTaskIssueReason(Map<String, dynamic> task) {
    return taskIssueReason(task).trim().isNotEmpty;
  }

  bool taskNeedsIssueReason(Map<String, dynamic> task, String status) {
    final normalized = normalizeStatus(status);

    return normalized == 'Проблема' ||
        normalized == 'Просрочена' ||
        normalized == 'Перепоставлена' ||
        normalized == 'Не виконано' ||
        (isTaskOverdue(task) && normalized != 'Завершено');
  }

  String safeText(dynamic value, {String fallback = 'Не указано'}) {
    final text = '${value ?? ''}'.trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return text;
  }

  List<String> get objectFilterItems {
    final values = <String>{'Усі об’єкти'};

    for (final task in tasks) {
      final objectName = safeText(task['object_name'], fallback: 'Без об’єкта');
      values.add(objectName);
    }

    return values.toList();
  }

  List<String> get statusFilterItems {
    final values = <String>{'Усі статуси'};

    for (final task in tasks) {
      final status = normalizeStatus(safeText(task['status'], fallback: 'Планується'));
      values.add(status);
    }

    return values.toList();
  }

  List<Map<String, dynamic>> get filteredTasks {
    var result = List<Map<String, dynamic>>.from(tasks);

    if (selectedObject != 'Усі об’єкти') {
      result = result.where((task) {
        final objectName = safeText(
          task['object_name'],
          fallback: 'Без об’єкта',
        );
        return objectName == selectedObject;
      }).toList();
    }

    if (selectedStatus != 'Усі статуси') {
      result = result.where((task) {
        final status = normalizeStatus(safeText(task['status'], fallback: 'Планується'));
        return status == selectedStatus;
      }).toList();
    }

    result.sort((a, b) {
      final aCreatedAt = parseTaskDate(a['created_at']) ?? DateTime(2000);
      final bCreatedAt = parseTaskDate(b['created_at']) ?? DateTime(2000);

      final aDeadline = parseTaskDate(a['deadline']) ?? DateTime(2100);
      final bDeadline = parseTaskDate(b['deadline']) ?? DateTime(2100);

      switch (selectedSort) {
        case 'Старые сверху':
          return aCreatedAt.compareTo(bCreatedAt);

        case 'Срок ближе':
          return aDeadline.compareTo(bDeadline);

        case 'Срок дальше':
          return bDeadline.compareTo(aDeadline);

        case 'Новые сверху':
        default:
          return bCreatedAt.compareTo(aCreatedAt);
      }
    });

    return result;
  }

  bool get isFilterActive {
    return selectedObject != 'Усі об’єкти' ||
        selectedStatus != 'Усі статуси' ||
        selectedSort != 'Новые сверху';
  }

  void resetFilters() {
    setState(() {
      selectedObject = 'Усі об’єкти';
      selectedStatus = 'Усі статуси';
      selectedSort = 'Новые сверху';
    });
  }

  void openFilterSheet() {
    String tempObject = selectedObject;
    String tempStatus = selectedStatus;
    String tempSort = selectedSort;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1F6FEB,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Color(0xFF1F6FEB),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Сортировка завдань',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Оберіть об’єкт, статус і порядок виводу',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      _FilterDropdown(
                        title: 'Об’єкт будівництва',
                        value: tempObject,
                        items: objectFilterItems,
                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            tempObject = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      _FilterDropdown(
                        title: 'Статус завдання',
                        value: tempStatus,
                        items: statusFilterItems,
                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            tempStatus = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      _FilterDropdown(
                        title: 'Сортировать',
                        value: tempSort,
                        items: const [
                          'Новые сверху',
                          'Старые сверху',
                          'Срок ближе',
                          'Срок дальше',
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            tempSort = value;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedObject = tempObject;
                              selectedStatus = tempStatus;
                              selectedSort = tempSort;
                            });

                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Применить'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F6FEB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedObject = 'Усі об’єкти';
                              selectedStatus = 'Усі статуси';
                              selectedSort = 'Новые сверху';
                            });

                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Сбросить фильтр'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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

  void showTaskDetails(Map<String, dynamic> task) {
    final int taskId = int.tryParse('${task['id'] ?? 0}') ?? 0;
    final String title = safeText(task['title'], fallback: 'Без названия');
    final String description = safeText(
      task['description'],
      fallback: 'Опис не указано',
    );
    final String status = normalizeStatus(safeText(task['status'], fallback: 'Планується'));
    final String issueReason = taskIssueReason(task);
    final String objectName = safeText(task['object_name']);
    final String objectAddress = safeText(task['object_address']);
    final String executorName = safeText(task['executor_name']);
    final String createdByName = safeText(task['created_by_name']);
    final String createdAt = formatDate(task['created_at']);
    final String deadline = formatDate(task['deadline']);
    final int commentsCount = int.tryParse(
          '${task['comments_count'] ?? task['comment_count'] ?? task['commentsCount'] ?? 0}',
        ) ??
        0;
    final int newCommentsCount = int.tryParse(
          '${task['new_comments_count'] ?? task['unread_comments_count'] ?? task['newCommentsCount'] ?? 0}',
        ) ??
        0;

    final Color statusColor = getStatusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String selectedStatus = status;
        final issueController = TextEditingController(text: issueReason);
        String sheetError = '';

        bool needsIssueReason(String value) {
          return taskNeedsIssueReason(task, value);
        }

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
                                _CommentBadge(
                                  totalCount: commentsCount,
                                  newCount: newCommentsCount,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            if (issueReason.isNotEmpty)
                              _InfoRow(
                                icon: Icons.report_problem_outlined,
                                label: 'Причина',
                                value: issueReason,
                              ),
                            _InfoRow(
                              icon: Icons.circle_outlined,
                              label: 'Об’єкт',
                              value: objectName,
                            ),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Адреса',
                              value: objectAddress,
                            ),
                            _InfoRow(
                              icon: Icons.person_outline,
                              label: 'Виконавець',
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

                      _TaskCommentsBlock(
                        taskId: taskId,
                        initialCount: commentsCount,
                        onCommentAdded: loadTasks,
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Статус завдання',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Планується',
                            child: Text('Планується'),
                          ),
                          DropdownMenuItem(
                            value: 'В роботі',
                            child: Text('В роботі'),
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
                            value: 'Перепоставлена',
                            child: Text('Перепоставлена'),
                          ),
                          DropdownMenuItem(
                            value: 'Просрочена',
                            child: Text('Просрочена'),
                          ),
                          DropdownMenuItem(
                            value: 'Не виконано',
                            child: Text('Не виконано'),
                          ),
                          DropdownMenuItem(
                            value: 'Завершено',
                            child: Text('Завершено'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            selectedStatus = value;
                            sheetError = '';
                          });
                        },
                      ),

                      if (needsIssueReason(selectedStatus)) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: issueController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Причина просрочки / невиконання',
                            hintText: 'Опиши, чому задача просрочена або не виконана',
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
                                      final reason = issueController.text.trim();

                                      if (needsIssueReason(selectedStatus) && reason.isEmpty) {
                                        setSheetState(() {
                                          sheetError = 'Опиши причину просрочки або невиконання';
                                        });
                                        return;
                                      }

                                      Navigator.pop(sheetContext);

                                      await updateTaskStatus(
                                        taskId: taskId,
                                        status: selectedStatus,
                                        issueReason: needsIssueReason(selectedStatus) ? reason : '',
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

  Widget buildFilterInfo() {
    if (!isFilterActive) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F6FEB).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF1F6FEB).withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_alt, size: 20, color: Color(0xFF1F6FEB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Фильтр: $selectedObject В· $selectedStatus В· $selectedSort',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F6FEB),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: resetFilters,
              icon: const Icon(Icons.close, size: 20),
              color: const Color(0xFF1F6FEB),
              tooltip: 'Сбросить',
            ),
          ],
        ),
      ),
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
            const Text(
              'Коли завдання з’являться на об’єктах, вони будуть тут одним списком.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFilteredEmptyState() {
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
                color: const Color(0xFF8A63D2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.manage_search,
                color: Color(0xFF8A63D2),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'По фильтру завдань нет',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Зміни об’єкт, статус або скинь фільтр.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: resetFilters,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Сбросить фильтр'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6FEB),
                foregroundColor: Colors.white,
              ),
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
              'Не вдалося завантажити завдання',
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

  Widget buildTaskList() {
    final visibleTasks = filteredTasks;

    if (tasks.isEmpty) {
      return buildEmptyState();
    }

    if (visibleTasks.isEmpty) {
      return Column(
        children: [
          buildFilterInfo(),
          Expanded(child: buildFilteredEmptyState()),
        ],
      );
    }

    return Column(
      children: [
        buildFilterInfo(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadTasks,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                22,
                isFilterActive ? 16 : 22,
                22,
                22,
              ),
              itemCount: visibleTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final task = visibleTasks[index];

                final title = safeText(task['title'], fallback: 'Без названия');
                final objectName = safeText(task['object_name']);
                final objectAddress = safeText(task['object_address']);
                final executorName = safeText(task['executor_name']);
                final status = safeText(
                  task['status'],
                  fallback: 'Планується',
                );
                final createdAt = formatDate(task['created_at']);
                final deadline = formatDate(task['deadline']);
                final statusColor = getStatusColor(status);
                final commentsCount = int.tryParse(
                      '${task['comments_count'] ?? task['comment_count'] ?? task['commentsCount'] ?? 0}',
                    ) ??
                    0;
                final newCommentsCount = int.tryParse(
                      '${task['new_comments_count'] ?? task['unread_comments_count'] ?? task['newCommentsCount'] ?? 0}',
                    ) ??
                    0;

                return _TaskCard(
                  title: title,
                  objectName: objectName,
                  objectAddress: objectAddress,
                  executorName: executorName,
                  status: normalizeStatus(status),
                  createdAt: createdAt,
                  deadline: deadline,
                  statusColor: statusColor,
                  isOverdue: isTaskOverdue(task),
                  hasIssueReason: hasTaskIssueReason(task),
                  commentsCount: commentsCount,
                  newCommentsCount: newCommentsCount,
                  onTap: () => showTaskDetails(task),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterIcon = isFilterActive ? Icons.filter_alt : Icons.tune;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Завдання',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading || tasks.isEmpty ? null : openFilterSheet,
            icon: Icon(filterIcon),
            tooltip: 'Сортировка',
          ),
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
          : buildTaskList(),
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
  final bool isOverdue;
  final bool hasIssueReason;
  final int commentsCount;
  final int newCommentsCount;
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
    required this.isOverdue,
    required this.hasIssueReason,
    required this.commentsCount,
    this.newCommentsCount = 0,
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
                    'Об’єкт: $objectName',
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
                      if (isOverdue) const _StatusBadge(text: 'Просрочено'),
                      if (isOverdue && !hasIssueReason) const _StatusBadge(text: 'Не виконано'),
                      _CommentBadge(
                        totalCount: commentsCount,
                        newCount: newCommentsCount,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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

class _FilterDropdown extends StatelessWidget {
  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeItems = items.contains(value) ? items : [value, ...items];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: safeItems.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}


class _StatusBadge extends StatelessWidget {
  final String text;

  const _StatusBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
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




