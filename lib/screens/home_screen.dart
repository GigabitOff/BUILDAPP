import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/license_exception.dart';
import '../services/users_service.dart';

import 'phone_login_screen.dart';
import 'license_blocked_screen.dart';

import 'modules/auth_check_screen.dart';
import 'modules/notifications_screen.dart';
import 'modules/objects_screen.dart';
import 'modules/photo_reports_screen.dart';
import 'modules/tasks_screen.dart';
import 'modules/users_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();

  bool isLoading = true;
  bool isHeaderExpanded = false;

  String userName = '';
  String userEmail = '';
  String userType = '';

  int unreadNotificationsCount = 0;
  int usersCount = 0;
  int objectsCount = 0;
  int tasksCount = 0;
  int taskCommentsTotal = 0;
  int taskCommentsNew = 0;
  int photoReportsCount = 0;

  bool get isAdmin {
    return userType == 'admin' || userType == '1';
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('user_name') ?? 'Користувач';
      userEmail = prefs.getString('user_email') ?? '';
      userType = prefs.getString('user_type') ?? '';
      isLoading = false;
    });

    await loadDashboardCounts();
  }

  void _openLicenseBlocked(LicenseException e) {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LicenseBlockedScreen(
          message: e.message,
          code: e.code,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> loadDashboardCounts() async {
    try {
      final counts = await DashboardService.getCounts();

      int loadedUsersCount = 0;

      if (isAdmin) {
        try {
          final users = await UsersService.getUsers();
          loadedUsersCount = users.length;
        } on LicenseException catch (e) {
          _openLicenseBlocked(e);
          return;
        } catch (_) {
          loadedUsersCount = 0;
        }
      }

      if (!mounted) return;

      setState(() {
        unreadNotificationsCount = counts['notifications']['new'] ?? 0;
        usersCount = loadedUsersCount;
        objectsCount = counts['objects']['total'] ?? 0;
        tasksCount = counts['tasks']['total'] ?? 0;
        taskCommentsTotal = counts['comments']?['total'] ?? 0;
        taskCommentsNew = counts['comments']?['new'] ?? 0;
        photoReportsCount = counts['photoReports']['total'] ?? 0;
      });
    } on LicenseException catch (e) {
      _openLicenseBlocked(e);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        unreadNotificationsCount = 0;
        usersCount = 0;
        objectsCount = 0;
        tasksCount = 0;
        taskCommentsTotal = 0;
        taskCommentsNew = 0;
        photoReportsCount = 0;
      });
    }
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );

    if (!mounted) return;

    await loadDashboardCounts();
  }

  Future<void> openUsers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UsersScreen()),
    );

    if (!mounted) return;

    await loadDashboardCounts();
  }

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
    );
  }

  Widget buildHeader() {
    return InkWell(
      onTap: () {
        setState(() {
          isHeaderExpanded = !isHeaderExpanded;
        });
      },
      borderRadius: BorderRadius.circular(26),
      child: Container(
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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ласкаво просимо',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isHeaderExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ],
            ),
            if (isHeaderExpanded) ...[
              const SizedBox(height: 14),
              if (userEmail.isNotEmpty)
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
          ],
        ),
      ),
    );
  }

  Widget buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int? badgeCount,
    bool isNew = false,
    List<Widget> extraLines = const [],
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
                  if (extraLines.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...extraLines,
                  ],
                ],
              ),
            ),
            if (badgeCount != null)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isNew ? Colors.redAccent : const Color(0xFF1F6FEB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }


  Widget buildTaskCommentsLine() {
    final hasNew = taskCommentsNew > 0;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 15,
              color: const Color(0xFF1F6FEB),
            ),
            const SizedBox(width: 4),
            Text(
              'Коментарі',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          'Всього: $taskCommentsTotal',
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Нові: $taskCommentsNew',
          style: TextStyle(
            color: hasNew ? Colors.redAccent : Colors.black.withValues(alpha: 0.45),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
          'EVENTHESAPP',
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
                tooltip: 'Сповіщення',
              ),
              if (unreadNotificationsCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
      body: RefreshIndicator(
        onRefresh: loadDashboardCounts,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            buildHeader(),
            const SizedBox(height: 24),
            buildCard(
              icon: Icons.notifications_none_outlined,
              title: 'Сповіщення',
              subtitle: unreadNotificationsCount > 0
                  ? 'Непрочитані: $unreadNotificationsCount'
                  : 'Зміни по об’єктах',
              badgeCount: unreadNotificationsCount,
              isNew: unreadNotificationsCount > 0,
              onTap: openNotifications,
            ),
            const SizedBox(height: 16),
            buildCard(
              icon: Icons.circle_outlined,
              title: 'Об’єкти',
              subtitle: 'Усього об’єктів: $objectsCount',
              badgeCount: objectsCount,
              onTap: () => openPage(const ObjectsScreen()),
            ),
            const SizedBox(height: 16),
            buildCard(
              icon: Icons.task_alt_outlined,
              title: 'Завдання',
              subtitle: 'Усього завдань: $tasksCount',
              badgeCount: tasksCount,
              extraLines: [buildTaskCommentsLine()],
              onTap: () => openPage(const TasksScreen()),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              buildCard(
                icon: Icons.people_alt_outlined,
                title: 'Користувачі',
                subtitle: 'Усього користувачів: $usersCount',
                badgeCount: usersCount,
                onTap: openUsers,
              ),
            ],
            const SizedBox(height: 16),
            buildCard(
              icon: Icons.photo_camera_outlined,
              title: 'Фотозвіти',
              subtitle: 'Усього фотозвітів: $photoReportsCount',
              badgeCount: photoReportsCount,
              onTap: () => openPage(const PhotoReportsScreen()),
            ),
            const SizedBox(height: 16),
            buildCard(
              icon: Icons.verified_user_outlined,
              title: 'Перевірити авторизацію',
              subtitle: 'Перевірка токена через /api/me',
              onTap: () => openPage(const AuthCheckScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
