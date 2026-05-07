import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

import 'modules/auth_check_screen.dart';
import 'modules/objects_screen.dart';
import 'modules/tasks_screen.dart';
import 'modules/photo_reports_screen.dart';
import 'modules/notifications_screen.dart';
import '../services/notifications_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();

  bool isLoading = true;
  String userName = '';
  String userEmail = '';
  String userType = '';
  int unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('user_name') ?? 'Пользователь';
      userEmail = prefs.getString('user_email') ?? '';
      userType = prefs.getString('user_type') ?? '';
      isLoading = false;
    });

    await loadUnreadNotificationsCount();
  }


  Future<void> loadUnreadNotificationsCount() async {
    try {
      final count = await NotificationsService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        unreadNotificationsCount = count;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        unreadNotificationsCount = 0;
      });
    }
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );

    if (!mounted) return;

    await loadUnreadNotificationsCount();
  }

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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

  void openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'BUILDAPP',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: openNotifications,
                icon: const Icon(Icons.notifications_none_outlined),
                tooltip: 'Уведомления',
              ),
              if (unreadNotificationsCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      unreadNotificationsCount > 99
                          ? '99+'
                          : unreadNotificationsCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
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
                  'Добро пожаловать',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                if (userType.isNotEmpty) ...[
                  const SizedBox(height: 12),
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
                      'Роль: $userType',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          buildCard(
            icon: Icons.verified_user_outlined,
            title: 'Проверить авторизацию',
            subtitle: 'Проверка токена через /api/me',
            onTap: () => openPage(const AuthCheckScreen()),
          ),

          const SizedBox(height: 16),

          buildCard(
            icon: Icons.notifications_none_outlined,
            title: 'Уведомления',
            subtitle: unreadNotificationsCount > 0
                ? 'Непрочитанных: $unreadNotificationsCount'
                : 'Изменения по объектам',
            onTap: openNotifications,
          ),

          const SizedBox(height: 16),

          buildCard(
            icon: Icons.apartment_outlined,
            title: 'Объекты строительства',
            subtitle: 'Следующий модуль BUILDAPP',
            onTap: () => openPage(const ObjectsScreen()),
          ),

          const SizedBox(height: 16),

          buildCard(
            icon: Icons.task_alt_outlined,
            title: 'Задачи',
            subtitle: 'Контроль работ, статусы, исполнители',
            onTap: () => openPage(const TasksScreen()),
          ),

          const SizedBox(height: 16),

          buildCard(
            icon: Icons.photo_camera_outlined,
            title: 'Фотоотчёты',
            subtitle: 'Фото с объекта и история выполнения',
            onTap: () => openPage(const PhotoReportsScreen()),
          ),
        ],
      ),
    );
  }
}
