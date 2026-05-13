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

  bool get isAdmin => userType == 'admin';

  ConstructionObject get object => widget.object;

  @override
  void initState() {
    super.initState();
    loadUserType();
  }

  Future<void> loadUserType() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userType = prefs.getString('user_type') ?? '';
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'В работе':
        return const Color(0xFF1F6FEB);
      case 'Планируется':
        return const Color(0xFF8A63D2);
      case 'Контроль':
        return const Color(0xFFFF9800);
      case 'Завершён':
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
      ).showSnackBar(SnackBar(content: Text('Исполнитель назначен: $name')));
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
          'Тебя пригласили в проект BUILDAPP:\n\n'
          '${object.name}\n'
          '${object.address}\n\n'
          '$inviteLink',
          subject: 'Приглашение в BUILDAPP',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Не удалось создать приглашение',
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
        SnackBar(content: Text('Ошибка создания приглашения: $e')),
      );
    }
  }

  void openObjectTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ObjectTasksScreen(objectId: object.id, objectName: object.name),
      ),
    );
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
          Container(
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
                const Text(
                  'Карточка объекта',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  object.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  object.address,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
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
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              _CounterCard(
                title: 'Задачи',
                value: object.tasksCount.toString(),
                icon: Icons.task_alt_outlined,
              ),
              const SizedBox(width: 12),
              _CounterCard(
                title: 'Фото',
                value: object.photosCount.toString(),
                icon: Icons.photo_camera_outlined,
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (isAdmin)
            _ActionCard(
              icon: Icons.person_add_alt_1_outlined,
              title: isAssigning
                  ? 'Назначаем исполнителя...'
                  : 'Назначить исполнителя',
              subtitle: 'Выбрать мастера или бригаду для этого объекта',
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

          if (isAdmin) const SizedBox(height: 18),

          _InfoBlock(
            title: 'Информация',
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Заказчик',
                value: object.customer,
              ),
              _InfoRow(
                icon: Icons.engineering_outlined,
                label: 'Ответственный',
                value: object.responsible,
              ),
              _InfoRow(
                icon: Icons.person_pin_circle_outlined,
                label: 'Исполнитель',
                value: object.executorName,
              ),
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                label: 'Дата начала',
                value: object.startDate,
              ),
              _InfoRow(
                icon: Icons.event_available_outlined,
                label: 'План завершения',
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

          const SizedBox(height: 18),

          _DescriptionBlock(description: object.description),

          const SizedBox(height: 18),

          _ActionCard(
            icon: Icons.task_alt_outlined,
            title: 'Задачи по объекту',
            subtitle: 'Работы, статусы, исполнители',
            onTap: openObjectTasks,
          ),

          const SizedBox(height: 14),

          _ActionCard(
            icon: Icons.photo_camera_outlined,
            title: 'Фотоотчёты',
            subtitle: 'Фото с объекта и история выполнения',
            onTap: openPhotoReports,
          ),

          const SizedBox(height: 14),

          _ActionCard(
            icon: Icons.inventory_2_outlined,
            title: 'Материалы',
            subtitle: 'Поставка, остатки, использование',
            onTap: openObjectMaterials,
          ),

          const SizedBox(height: 14),

          _ActionCard(
            icon: Icons.history_outlined,
            title: 'История объекта',
            subtitle: 'Все действия и изменения по объекту',
            onTap: openObjectHistory,
          ),

          const SizedBox(height: 80),
        ],
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
  final List<Widget> children;

  const _InfoBlock({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
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

  const _DescriptionBlock({required this.description});

  @override
  Widget build(BuildContext context) {
    final safeDescription = description.isEmpty
        ? 'Описание не указано'
        : description;

    return Container(
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
          const Text(
            'Описание',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
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
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
