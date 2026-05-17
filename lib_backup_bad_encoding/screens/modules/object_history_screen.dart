import 'package:flutter/material.dart';

import '../../models/object_history_item.dart';
import '../../services/object_history_service.dart';

class ObjectHistoryScreen extends StatefulWidget {
  final int objectId;
  final String objectName;

  const ObjectHistoryScreen({
    super.key,
    required this.objectId,
    required this.objectName,
  });

  @override
  State<ObjectHistoryScreen> createState() => _ObjectHistoryScreenState();
}

class _ObjectHistoryScreenState extends State<ObjectHistoryScreen> {
  bool isLoading = true;
  bool isSaving = false;
  String? error;
  List<ObjectHistoryItem> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final items = await ObjectHistoryService.getHistory(widget.objectId);

      if (!mounted) return;

      setState(() {
        history = items;
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

  String actionTitle(String type) {
    switch (type) {
      case 'created':
        return 'РЎРѕР·РґР°РЅРёРµ';
      case 'updated':
        return 'РР·РјРµРЅРµРЅРёРµ';
      case 'task':
        return 'Р—Р°РґР°С‡Р°';
      case 'photo':
        return 'Р¤РѕС‚Рѕ';
      case 'material':
        return 'РњР°С‚РµСЂРёР°Р»';
      case 'executor':
        return 'РСЃРїРѕР»РЅРёС‚РµР»СЊ';
      case 'manual':
        return 'Р—Р°РїРёСЃСЊ';
      default:
        return type.isEmpty ? 'РЎРѕР±С‹С‚РёРµ' : type;
    }
  }

  IconData actionIcon(String type) {
    switch (type) {
      case 'created':
        return Icons.add_circle_outline;
      case 'updated':
        return Icons.edit_note_outlined;
      case 'task':
        return Icons.task_alt_outlined;
      case 'photo':
        return Icons.photo_camera_outlined;
      case 'material':
        return Icons.inventory_2_outlined;
      case 'executor':
        return Icons.engineering_outlined;
      case 'manual':
        return Icons.note_add_outlined;
      default:
        return Icons.history_outlined;
    }
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) return '';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  Future<void> showAddHistoryDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();

              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Р’РІРµРґРёС‚Рµ Р·Р°РіРѕР»РѕРІРѕРє')),
                );
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                await ObjectHistoryService.createHistoryItem(
                  objectId: widget.objectId,
                  title: title,
                  description: description,
                );

                if (!context.mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                });

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst('Exception: ', ''),
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Р”РѕР±Р°РІРёС‚СЊ Р·Р°РїРёСЃСЊ'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Р—Р°РіРѕР»РѕРІРѕРє',
                        hintText: 'РќР°РїСЂРёРјРµСЂ: РџСЂРёРЅСЏР»Рё РјР°С‚РµСЂРёР°Р»С‹',
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'РћРїРёСЃР°РЅРёРµ',
                        hintText: 'Р§С‚Рѕ РїСЂРѕРёР·РѕС€Р»Рѕ РїРѕ РѕР±СЉРµРєС‚Сѓ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context, false),
                  child: const Text('РћС‚РјРµРЅР°'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : save,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Р”РѕР±Р°РІРёС‚СЊ'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (result == true) {
      await loadHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Р—Р°РїРёСЃСЊ РґРѕР±Р°РІР»РµРЅР°')),
      );
    }
  }

  Widget buildHistoryCard(ObjectHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              actionIcon(item.actionType),
              color: const Color(0xFF1F6FEB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      actionTitle(item.actionType),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                if (item.description != null && item.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      item.description!,
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (item.userName != null && item.userName!.isNotEmpty)
                      Text(
                        item.userName!,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      formatDate(item.createdAt),
                      style: const TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (history.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.history_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'РСЃС‚РѕСЂРёРё РїРѕРєР° РЅРµС‚',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'РЎРѕР±С‹С‚РёСЏ РїРѕ РѕР±СЉРµРєС‚Сѓ РїРѕСЏРІСЏС‚СЃСЏ Р·РґРµСЃСЊ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(22),
        itemCount: history.length,
        itemBuilder: (context, index) {
          return buildHistoryCard(history[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          'РСЃС‚РѕСЂРёСЏ: ${widget.objectName}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: isSaving ? null : showAddHistoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}



