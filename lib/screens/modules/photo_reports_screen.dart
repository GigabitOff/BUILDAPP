import 'package:flutter/material.dart';

class PhotoReportsScreen extends StatelessWidget {
  const PhotoReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {'title': 'Монтаж окон', 'object': 'ЖК Центральный', 'date': 'Сегодня'},
      {
        'title': 'Материалы на объекте',
        'object': 'Коттеджный городок',
        'date': 'Вчера',
      },
      {
        'title': 'Проверка фасада',
        'object': 'Реконструкция офиса',
        'date': '28.04.2026',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Фотоотчёты',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Добавление фото подключим следующим шагом'),
            ),
          );
        },
        backgroundColor: const Color(0xFF1F6FEB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Добавить'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(22),
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final report = reports[index];

          return _PhotoReportCard(
            title: report['title']!,
            object: report['object']!,
            date: report['date']!,
          );
        },
      ),
    );
  }
}

class _PhotoReportCard extends StatelessWidget {
  final String title;
  final String object;
  final String date;

  const _PhotoReportCard({
    required this.title,
    required this.object,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Открываем фотоотчёт: $title')));
      },
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
              child: const Icon(
                Icons.photo_camera_outlined,
                color: Color(0xFF1F6FEB),
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    object,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 13, color: Colors.black38),
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
