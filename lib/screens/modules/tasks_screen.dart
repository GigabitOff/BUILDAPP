import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      {
        'title': 'Проверить монтаж окон',
        'object': 'ЖК Центральный',
        'status': 'Новая',
      },
      {
        'title': 'Сделать фотоотчёт',
        'object': 'Коттеджный городок',
        'status': 'В работе',
      },
      {
        'title': 'Принять материалы',
        'object': 'Склад / объект',
        'status': 'Важно',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Задачи',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(22),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final task = tasks[index];

          return _TaskCard(
            title: task['title']!,
            object: task['object']!,
            status: task['status']!,
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String object;
  final String status;

  const _TaskCard({
    required this.title,
    required this.object,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Checkbox(
            value: false,
            onChanged: (_) {},
            activeColor: const Color(0xFF1F6FEB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 10),
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
                  object,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFF1F6FEB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
