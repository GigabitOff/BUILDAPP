import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/construction_object.dart';
import '../../services/objects_service.dart';
import '../../services/invites_service.dart';
import 'object_tasks_screen.dart';
import 'photo_reports_screen.dart';
import 'object_materials_screen.dart';
import 'object_history_screen.dart';

class ObjectDetailScreen extends StatefulWidget {
  final ConstructionObject object;

  const ObjectDetailScreen({super.key, required this.object});

  @override
  State<ObjectDetailScreen> createState() => _ObjectDetailScreenState();
}

class _ObjectDetailScreenState extends State<ObjectDetailScreen> {
  final ObjectsService objectsService = ObjectsService();

  String userType = '';
  bool isAssigning = false;
  bool isCreatingInvite = false;
  bool isLoadingActiveTasksCount = false;
  bool isLoadingActiveTaskComments = false;
  int activeTasksCount = 0;
  int activeTaskCommentsTotal = 0;
  int activeTaskCommentsNew = 0;

  bool isHeaderExpanded = false;
  bool isInfoExpanded = false;
  bool isDescriptionExpanded = false;

  bool get isAdmin => userType == 'admin';

  ConstructionObject get object => widget.object;

  @override
  void initState() {
    super.initState();
    loadUserType();
    loadActiveTasksCount();
    loadActiveTaskCommentStats();
  }

  Future<void> loadUserType() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userType = prefs.getString('user_type') ?? '';
    });
  }


  Future<void> loadActiveTasksCount() async {
    if (!mounted) return;

    setState(() {
      isLoadingActiveTasksCount = true;
    });

    try {
      final count = await objectsService.getObjectActiveTasksCount(object.id);

      if (!mounted) return;

      setState(() {
        activeTasksCount = count;
        isLoadingActiveTasksCount = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        activeTasksCount = 0;
        isLoadingActiveTasksCount = false;
      });
    }
  }


  Future<void> loadActiveTaskCommentStats() async {
    if (!mounted) return;

    setState(() {
      isLoadingActiveTaskComments = true;
    });

    try {
      final stats = await objectsService.getObjectActiveTaskCommentStats(object.id);

      if (!mounted) return;

      setState(() {
        activeTaskCommentsTotal = stats.totalComments;
        activeTaskCommentsNew = stats.newComments;
        isLoadingActiveTaskComments = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        activeTaskCommentsTotal = 0;
        activeTaskCommentsNew = 0;
        isLoadingActiveTaskComments = false;
      });
    }
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
      default:
        return const Color(0xFF1F6FEB);
    }
  }

  void showPlug(BuildContext context, String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$text подключим следующим шагом')));
  }

  Future<void> showAssignExecutorDialog() async {
    if (isAssigning) return;

    setState(() {
      isAssigning = true;
    });

    try {
      final executors = await objectsService.getExecutors();

      if (!mounted) return;

      setState(() {
        isAssigning = false;
      });

      if (executors.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Исполнители не найдены')));
        return;
      }

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
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
                    'Назначить исполнителя',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    object.name,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...executors.map((executor) {
                    final int userId = int.tryParse('${executor['id']}') ?? 0;
                    final String name = '${executor['name'] ?? ''}';
                    final String email = '${executor['email'] ?? ''}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await assignExecutor(userId, name);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1F6FEB,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.engineering_outlined,
                                  color: Color(0xFF1F6FEB),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty ? 'Без имени' : name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isAssigning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> assignExecutor(int userId, String name) async {
    if (userId <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Некорректный исполнитель')));
      return;
    }

    setState(() {
      isAssigning = true;
    });

    try {
      await objectsService.assignExecutorToObject(
        objectId: object.id,
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        isAssigning = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Виконавець назначен: $name')));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isAssigning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> shareProjectInvite() async {
    if (isCreatingInvite) return;

    setState(() {
      isCreatingInvite = true;
    });

    try {
      final result = await InvitesService.createProjectInvite(
        objectId: object.id,
        roleOnObject: 'executor',
      );

      if (!mounted) return;

      setState(() {
        isCreatingInvite = false;
      });

      if (result['success'] == true) {
        final inviteLink = result['invite_link']?.toString() ?? '';

        if (inviteLink.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сервер не вернул ссылку приглашения'),
            ),
          );
          return;
        }

        await Share.share(
          'Тебя пригласили в проект EVENTHESAPP:\n\n'
          '${object.name}\n'
          '${object.address}\n\n'
          '$inviteLink',
          subject: 'Приглашение в EVENTHESAPP',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Не вдалося створити запрошення',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCreatingInvite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка створення запрошення: $e')),
      );
    }
  }

  Future<void> openObjectTasks() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ObjectTasksScreen(objectId: object.id, objectName: object.name),
      ),
    );

    await loadActiveTasksCount();
  }

  void openPhotoReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PhotoReportsScreen(objectId: object.id, objectName: object.name),
      ),
    );
  }

  void openObjectMaterials() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ObjectMaterialsScreen(objectId: object.id, objectName: object.name),
      ),
    );
  }

  void openObjectHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ObjectHistoryScreen(objectId: object.id, objectName: object.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(object.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          object.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: isCreatingInvite
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              tooltip: 'Поделиться проектом',
              onPressed: isCreatingInvite ? null : shareProjectInvite,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          _HeaderCard(
            object: object,
            activeTasksCount: activeTasksCount,
            activeTaskCommentsTotal: activeTaskCommentsTotal,
            activeTaskCommentsNew: activeTaskCommentsNew,
            isLoadingActiveTasksCount: isLoadingActiveTasksCount,
            isLoadingActiveTaskComments: isLoadingActiveTaskComments,
            expanded: isHeaderExpanded,
            onTap: () {
              setState(() {
                isHeaderExpanded = !isHeaderExpanded;
              });
            },
          ),

          const SizedBox(height: 18),

          _InfoBlock(
            title: 'Информация',
            expanded: isInfoExpanded,
            onTap: () {
              setState(() {
                isInfoExpanded = !isInfoExpanded;
              });
            },
            children: [
              _InfoRow(
                icon: Icons.engineering_outlined,
                label: 'Створив',
                value: object.responsible,
              ),
              if (object.executorName.trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.person_pin_circle_outlined,
                  label: 'Виконавець',
                  value: object.executorName,
                ),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Дата початку',
                value: object.startDate,
              ),
              _InfoRow(
                icon: Icons.event_available_outlined,
                label: 'План завершення',
                value: object.endDate,
              ),
              _InfoRow(
                icon: Icons.flag_outlined,
                label: 'Статус',
                value: object.status,
                valueColor: statusColor,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _DescriptionBlock(
            description: object.description,
            expanded: isDescriptionExpanded,
            onTap: () {
              setState(() {
                isDescriptionExpanded = !isDescriptionExpanded;
              });
            },
          ),

          const SizedBox(height: 14),

          _ActionCard(
            icon: Icons.task_alt_outlined,
            title: 'Завдання по об’єкту',
            subtitle: 'В роботі або плануються',
            indicatorValue: isLoadingActiveTasksCount ? '...' : activeTasksCount.toString(),
            indicatorLabel: 'активні',
            commentsTotalValue: isLoadingActiveTaskComments ? '...' : activeTaskCommentsTotal.toString(),
            commentsNewValue: isLoadingActiveTaskComments ? '...' : activeTaskCommentsNew.toString(),
            onTap: openObjectTasks,
          ),

          const SizedBox(height: 14),

          _ActionCard(
            icon: Icons.history_outlined,
            title: 'История об’єкта',
            subtitle: 'Все действия и изменения по об’єкту',
            onTap: openObjectHistory,
          ),

          const SizedBox(height: 14),

          _ActionCard(
            icon: Icons.photo_camera_outlined,
            title: 'Фотозвіти',
            subtitle: 'Фото с об’єкта и история выполнения',
            onTap: openPhotoReports,
          ),

          if (isAdmin) const SizedBox(height: 14),

          if (isAdmin)
            _ActionCard(
              icon: Icons.person_add_alt_1_outlined,
              title: isAssigning
                  ? 'Назначаем исполнителя...'
                  : 'Назначить исполнителя',
              subtitle: 'Вибрати мастера или бригаду для этого об’єкта',
              onTap: isAssigning ? () {} : showAssignExecutorDialog,
            ),

          if (isAdmin) const SizedBox(height: 14),

          if (isAdmin)
            _ActionCard(
              icon: Icons.share_outlined,
              title: isCreatingInvite
                  ? 'Создаём ссылку...'
                  : 'Поделиться проектом',
              subtitle: 'Отправить ссылку в Viber, Telegram, Facebook или SMS',
              onTap: isCreatingInvite ? () {} : shareProjectInvite,
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ConstructionObject object;
  final int activeTasksCount;
  final int activeTaskCommentsTotal;
  final int activeTaskCommentsNew;
  final bool isLoadingActiveTasksCount;
  final bool isLoadingActiveTaskComments;
  final bool expanded;
  final VoidCallback onTap;

  const _HeaderCard({
    required this.object,
    required this.activeTasksCount,
    required this.activeTaskCommentsTotal,
    required this.activeTaskCommentsNew,
    required this.isLoadingActiveTasksCount,
    required this.isLoadingActiveTaskComments,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: double.infinity,
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
                      const Text(
                        'Карточка об’єкта',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        object.name,
                        maxLines: expanded ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _HeaderCounterPill(
                              icon: Icons.task_alt_outlined,
                              value: isLoadingActiveTasksCount ? '...' : activeTasksCount.toString(),
                              title: 'Активні',
                            ),
                            _HeaderCounterPill(
                              icon: Icons.chat_bubble_outline_rounded,
                              value: isLoadingActiveTaskComments ? '...' : activeTaskCommentsTotal.toString(),
                              title: activeTaskCommentsNew > 0 ? 'Нові: $activeTaskCommentsNew' : 'Коментарі',
                              highlight: activeTaskCommentsNew > 0,
                            ),
                            _HeaderCounterPill(
                              icon: Icons.photo_camera_outlined,
                              value: object.photosCount.toString(),
                              title: 'Фото',
                            ),
                          ],
                        ),
                        if (object.address.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            object.address,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            object.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}


class _HeaderCounterPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final bool highlight;

  const _HeaderCounterPill({
    required this.icon,
    required this.value,
    required this.title,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.white.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _CounterCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1F6FEB), size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final List<Widget> children;

  const _InfoBlock({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withValues(alpha: 0.05),
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.black45,
                  size: 28,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: expanded
                  ? Column(
                      children: [
                        const SizedBox(height: 14),
                        ...children,
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.isEmpty ? 'Не указано' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.black38, size: 22),
          const SizedBox(width: 12),
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
              style: TextStyle(
                color: valueColor ?? Colors.black87,
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

class _DescriptionBlock extends StatelessWidget {
  final String description;
  final bool expanded;
  final VoidCallback onTap;

  const _DescriptionBlock({
    required this.description,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeDescription = description.isEmpty
        ? 'Опис не указано'
        : description;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                const Expanded(
                  child: Text(
                    'Опис',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.black45,
                  size: 28,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          safeDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.35,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? indicatorValue;
  final String? indicatorLabel;
  final String? commentsTotalValue;
  final String? commentsNewValue;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.indicatorValue,
    this.indicatorLabel,
    this.commentsTotalValue,
    this.commentsNewValue,
  });

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withValues(alpha: 0.05),
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
                color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF1F6FEB), size: 28),
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  if (indicatorValue != null || commentsTotalValue != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (indicatorValue != null)
                          _ActionIndicatorBadge(
                            value: indicatorValue!,
                            label: indicatorLabel ?? '',
                          ),
                        if (commentsTotalValue != null)
                          _ActionCommentBadge(
                            totalValue: commentsTotalValue!,
                            newValue: commentsNewValue,
                          ),
                      ],
                    ),
                  ],
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



class _ActionCommentBadge extends StatelessWidget {
  final String totalValue;
  final String? newValue;

  const _ActionCommentBadge({
    required this.totalValue,
    this.newValue,
  });

  bool get hasNew {
    final value = int.tryParse(newValue ?? '0') ?? 0;
    return value > 0;
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = hasNew ? const Color(0xFFD93025) : const Color(0xFF1F6FEB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: mainColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: mainColor.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 14,
            color: mainColor,
          ),
          const SizedBox(width: 6),
          Text(
            'Коментарі',
            style: TextStyle(
              color: mainColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Всього: $totalValue',
            style: TextStyle(
              color: mainColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Нові: ${newValue ?? '0'}',
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

class _ActionIndicatorBadge extends StatelessWidget {
  final String value;
  final String label;

  const _ActionIndicatorBadge({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF1F6FEB).withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F6FEB),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1F6FEB),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}
