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

  bool isLoading = true;
  String errorText = '';
  String searchText = '';
  String userType = '';

  bool get isAdmin => userType == 'admin';

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

      if (!mounted) return;

      setState(() {
        objects
          ..clear()
          ..addAll(loadedObjects);

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
    ).showSnackBar(const SnackBar(content: Text('Объект добавлен')));
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
          'Объекты строительства',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadObjects,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),

      // Кнопка "Добавить" только для админа
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: addObject,
              backgroundColor: const Color(0xFF1F6FEB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            )
          : null,

      body: RefreshIndicator(
        onRefresh: loadObjects,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? 'Все рабочие объекты' : 'Мои рабочие объекты',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Контроль строительства',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAdmin
                        ? 'Админ видит все объекты и может создавать новые'
                        : 'Здесь только объекты, назначенные тебе',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
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
                hintText: 'Поиск объекта...',
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

            Row(
              children: [
                _SmallStatCard(
                  title: 'Всего',
                  value: objects.length.toString(),
                  icon: Icons.apartment_outlined,
                ),
                const SizedBox(width: 12),
                _SmallStatCard(
                  title: 'В работе',
                  value: objects
                      .where((e) => e.status == 'В работе')
                      .length
                      .toString(),
                  icon: Icons.work_outline,
                ),
              ],
            ),

            const SizedBox(height: 18),

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
                    onTap: () => openObject(item),
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

class _SmallStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SmallStatCard({
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

class _ObjectCard extends StatelessWidget {
  final ConstructionObject object;
  final Color statusColor;
  final VoidCallback onTap;

  const _ObjectCard({
    required this.object,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsibleText = object.responsible.isEmpty
        ? 'Ответственный: не указан'
        : 'Ответственный: ${object.responsible}';

    final executorText = object.executorName.isEmpty
        ? 'Исполнитель: не назначен'
        : 'Исполнитель: ${object.executorName}';

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
                    Icons.apartment_outlined,
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
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(text: object.status, color: statusColor),
                const SizedBox(width: 10),
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
                      const SizedBox(height: 4),
                      Text(
                        executorText,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
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

            const SizedBox(height: 14),

            Row(
              children: [
                _MiniInfo(
                  icon: Icons.task_alt_outlined,
                  text: '${object.tasksCount} задач',
                ),
                const SizedBox(width: 16),
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
    final safeText = text.isEmpty ? 'Без статуса' : text;

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

  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.black38, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
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
            'Загружаем объекты...',
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
            'Не удалось загрузить объекты',
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
            'Объекты не найдены',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Добавь новый объект или измени поиск',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
