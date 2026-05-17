import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/construction_object.dart';
import '../../services/objects_service.dart';
import 'object_detail_screen.dart';
import 'object_form_screen.dart';

class ObjectsScreen extends StatefulWidget {
  const ObjectsScreen({super.key});

  @override
  State<ObjectsScreen> createState() => _ObjectsScreenState();
}

class _ObjectsScreenState extends State<ObjectsScreen> {
  final TextEditingController searchController = TextEditingController();
  final ObjectsService objectsService = ObjectsService();

  final List<ConstructionObject> objects = [];
  final Map<int, int> activeTasksByObject = {};
  final Map<int, ObjectActiveTaskCommentStats> taskCommentStatsByObject = {};

  bool isLoading = true;
  bool isDeleting = false;
  String errorText = '';
  String searchText = '';
  String userType = '';
  bool isHeaderExpanded = false;

  bool get isAdmin => userType == 'admin';

  int get totalTasksInWork {
    return activeTasksByObject.values.fold<int>(0, (sum, count) => sum + count);
  }

  @override
  void initState() {
    super.initState();
    initScreen();
  }

  Future<void> initScreen() async {
    await loadUserType();
    await loadObjects();
  }

  Future<void> loadUserType() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userType = prefs.getString('user_type') ?? '';
    });
  }

  Future<void> loadObjects() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      final loadedObjects = await objectsService.getObjects();

      final taskCountEntries = await Future.wait(
        loadedObjects.map((object) async {
          try {
            final count = await objectsService.getObjectActiveTasksCount(
              object.id,
            );
            return MapEntry(object.id, count);
          } catch (_) {
            return MapEntry(object.id, 0);
          }
        }),
      );

      final commentStatsEntries = await Future.wait(
        loadedObjects.map((object) async {
          try {
            final stats = await objectsService.getObjectActiveTaskCommentStats(
              object.id,
            );
            return MapEntry(object.id, stats);
          } catch (_) {
            return MapEntry(
              object.id,
              const ObjectActiveTaskCommentStats(
                totalComments: 0,
                newComments: 0,
              ),
            );
          }
        }),
      );

      if (!mounted) return;

      setState(() {
        objects
          ..clear()
          ..addAll(loadedObjects);

        activeTasksByObject
          ..clear()
          ..addEntries(taskCountEntries);

        taskCommentStatsByObject
          ..clear()
          ..addEntries(commentStatsEntries);

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

  List<ConstructionObject> get filteredObjects {
    if (searchText.trim().isEmpty) {
      return objects;
    }

    final query = searchText.toLowerCase();

    return objects.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.address.toLowerCase().contains(query) ||
          item.status.toLowerCase().contains(query) ||
          item.customer.toLowerCase().contains(query) ||
          item.responsible.toLowerCase().contains(query) ||
          item.executorName.toLowerCase().contains(query);
    }).toList();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case ' работе':
        return const Color(0xFF1F6FEB);
      case 'Планується':
        return const Color(0xFF8A63D2);
      case 'Контроль':
        return const Color(0xFFFF9800);
      case 'Завершено':
        return const Color(0xFF22A06B);
      case 'Проблема':
        return const Color(0xFFD93025);
      case 'На паузе':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF1F6FEB);
    }
  }

  void openObject(ConstructionObject object) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ObjectDetailScreen(object: object)),
    );
  }

  Future<void> addObject() async {
    final result = await Navigator.push<ConstructionObject>(
      context,
      MaterialPageRoute(builder: (_) => const ObjectFormScreen()),
    );

    if (result == null) return;

    setState(() {
      objects.insert(0, result);
      searchController.clear();
      searchText = '';
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Об’єкт додано')));
  }

  Future<void> deleteObject(ConstructionObject object) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Видаляти об’єкти може тільки адміністратор'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !isDeleting,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Видалити об’єкт?',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            'Об’єкт "${object.name}" буде прихований із застосунку.\n\n'
            'Завдання, материалы, фотоотчёты, история и уведомления по об’єкту останутся в базе для контроля и возможного восстановления.\n\n'
            'Полное удаление связанных данных не выполняется.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Скасувати'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Видалити об’єкт'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isDeleting = true;
    });

    try {
      await objectsService.deleteObject(object.id);

      if (!mounted) return;

      setState(() {
        objects.removeWhere((item) => item.id == object.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Об’єкт видалено')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredObjects;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Об’єкти',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading || isDeleting ? null : loadObjects,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),

      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: isDeleting ? null : addObject,
              backgroundColor: const Color(0xFF1F6FEB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Додати'),
            )
          : null,

      body: RefreshIndicator(
        onRefresh: loadObjects,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  isHeaderExpanded = !isHeaderExpanded;
                });
              },
              borderRadius: BorderRadius.circular(26),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F6FEB), Color(0xFF4C8DFF)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdmin
                                    ? 'Усі робочі об’єкти'
                                    : 'Мої робочі об’єкти',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Контроль об’єктів',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(
                            isHeaderExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    if (isHeaderExpanded) ...[
                      const SizedBox(height: 10),
                      Text(
                        isAdmin
                            ? 'Адмін бачить об’єкти своєї компанії та може створювати нові'
                            : 'Тут лише об’єкти, призначені вам',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _HeaderStatCard(
                            title: 'Усього',
                            value: objects.length.toString(),
                            icon: Icons.circle_outlined,
                          ),
                          const SizedBox(width: 12),
                          _HeaderStatCard(
                            title: 'Задач',
                            value: totalTasksInWork.toString(),
                            icon: Icons.work_outline,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Пошук об’єкта...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),


            if (isDeleting)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Видаляємо об’єкт...',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),

            if (isLoading)
              const _LoadingState()
            else if (errorText.isNotEmpty)
              _ErrorState(text: errorText, onRetry: loadObjects)
            else if (list.isEmpty)
              const _EmptyState()
            else
              ...list.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ObjectCard(
                    object: item,
                    statusColor: getStatusColor(item.status),
                    isAdmin: isAdmin,
                    activeTasksCount: activeTasksByObject[item.id] ?? 0,
                    commentStats: taskCommentStatsByObject[item.id] ??
                        const ObjectActiveTaskCommentStats(
                          totalComments: 0,
                          newComments: 0,
                        ),
                    onTap: () => openObject(item),
                    onDelete: () => deleteObject(item),
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

class _HeaderStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _HeaderStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectCard extends StatelessWidget {
  final ConstructionObject object;
  final Color statusColor;
  final bool isAdmin;
  final int activeTasksCount;
  final ObjectActiveTaskCommentStats commentStats;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ObjectCard({
    required this.object,
    required this.statusColor,
    required this.isAdmin,
    required this.activeTasksCount,
    required this.commentStats,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final responsibleText = object.responsible.trim().isEmpty
        ? 'Створив: не вказано'
        : 'Створив: ${object.responsible}';

    final executorName = object.executorName.trim();
    final hasExecutor = executorName.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.circle_outlined,
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
                        object.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        object.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Видалити об’єкт',
                  ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        responsibleText,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasExecutor) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Відповідальний: $executorName',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _MiniInfo(
                  icon: Icons.task_alt_outlined,
                  text: '${object.tasksCount} задач',
                ),
                _MiniInfo(
                  icon: Icons.work_outline,
                  text: '$activeTasksCount в роботі',
                  color: const Color(0xFF1F6FEB),
                ),
                _MiniInfo(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: 'коментарі: всього ${commentStats.totalComments}',
                  color: const Color(0xFF1F6FEB),
                ),
                _MiniInfo(
                  icon: Icons.mark_chat_unread_outlined,
                  text: 'нові ${commentStats.newComments}',
                  color: commentStats.newComments > 0
                      ? const Color(0xFFD93025)
                      : Colors.black38,
                ),
                _MiniInfo(
                  icon: Icons.photo_camera_outlined,
                  text: '${object.photosCount} фото',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final safeText = text.isEmpty ? 'Без статусу' : text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        safeText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _MiniInfo({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.black38;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: effectiveColor, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color ?? Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Завантажуємо об’єкти...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _ErrorState({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 44, color: Color(0xFFD93025)),
          const SizedBox(height: 12),
          const Text(
            'Не вдалося завантажити об’єкти',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F6FEB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off, size: 44, color: Colors.black38),
          SizedBox(height: 12),
          Text(
            'Об’єкти не найдены',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Додайте новий об’єкт або змініть пошук',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}




