import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_user.dart';
import '../../services/users_service.dart';
import 'user_form_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool isLoading = true;
  String error = '';
  int currentUserId = 0;

  List<AppUser> users = [];

  @override
  void initState() {
    super.initState();
    initScreen();
  }

  Future<void> initScreen() async {
    await loadCurrentUserId();
    await loadUsers();
  }

  Future<void> loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUserId = prefs.getInt('user_id') ?? 0;

    if (savedUserId > 0) {
      currentUserId = savedUserId;
      return;
    }

    final token = prefs.getString('auth_token') ?? '';
    final userIdFromToken = getUserIdFromToken(token);

    if (userIdFromToken > 0) {
      currentUserId = userIdFromToken;
      await prefs.setInt('user_id', userIdFromToken);
    }
  }

  int getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return 0;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> json = jsonDecode(decoded);

      return int.tryParse(json['id'].toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> loadUsers() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final result = await UsersService.getUsers();

      if (!mounted) return;

      setState(() {
        users = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> openCreateUser() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserFormScreen()),
    );

    if (created == true) {
      await loadUsers();
    }
  }

  Future<void> deleteUser(AppUser user) async {
    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('РЎР°РјРѕРіРѕ СЃРµР±СЏ СѓРґР°Р»РёС‚СЊ РЅРµР»СЊР·СЏ')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('РЈРґР°Р»РёС‚СЊ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ?'),
        content: Text(
          'РЈРґР°Р»РёС‚СЊ "${user.name}"?\n\nР•РіРѕ С‚Р°РєР¶Рµ РѕС‚РІСЏР¶РµС‚ РѕС‚ РѕР±СЉРµРєС‚РѕРІ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('РћС‚РјРµРЅР°'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('РЈРґР°Р»РёС‚СЊ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await UsersService.deleteUser(user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ СѓРґР°Р»С‘РЅ')));

      await loadUsers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget buildUserCard(AppUser user) {
    final bool isCurrentUser = user.id == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF1F6FEB),
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                if ((user.phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone!,
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        user.roleTitle,
                        style: const TextStyle(
                          color: Color(0xFF1F6FEB),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Р­С‚Рѕ РІС‹',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isCurrentUser ? null : () => deleteUser(user),
            icon: Icon(
              Icons.delete_outline,
              color: isCurrentUser ? Colors.black26 : Colors.redAccent,
            ),
            tooltip: isCurrentUser ? 'РќРµР»СЊР·СЏ СѓРґР°Р»РёС‚СЊ СЃРµР±СЏ' : 'РЈРґР°Р»РёС‚СЊ',
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('РџРѕРІС‚РѕСЂРёС‚СЊ'),
              ),
            ],
          ),
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 64,
                color: Colors.black.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 12),
              const Text(
                'РџРѕР»СЊР·РѕРІР°С‚РµР»РµР№ РїРѕРєР° РЅРµС‚',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'РЎРѕР·РґР°Р№ РїРµСЂРІРѕРіРѕ РёСЃРїРѕР»РЅРёС‚РµР»СЏ Рё РїРѕС‚РѕРј РїСЂРёРІСЏР¶Рё РµРіРѕ Рє РѕР±СЉРµРєС‚Сѓ.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadUsers,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Р’СЃРµРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№: ${users.length}',
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...users.map(buildUserCard),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'РџРѕР»СЊР·РѕРІР°С‚РµР»Рё',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: loadUsers,
            icon: const Icon(Icons.refresh),
            tooltip: 'РћР±РЅРѕРІРёС‚СЊ',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateUser,
        backgroundColor: const Color(0xFF1F6FEB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text(
          'РЎРѕР·РґР°С‚СЊ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: buildBody(),
    );
  }
}



