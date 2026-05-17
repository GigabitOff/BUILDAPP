from pathlib import Path

path = Path("lib/screens/modules/object_tasks_screen.dart")
text = path.read_text(encoding="utf-8")

# 1. Добавляем переменные фильтра после tasks
old = "  final List<Map<String, String>> tasks = [];\n\n  static const List<String> taskStatuses = ["
new = """  final List<Map<String, String>> tasks = [];

  String selectedStatusFilter = 'Усі статуси';
  String selectedSortOrder = 'Нові зверху';

  static const List<String> statusFilters = [
    'Усі статуси',
    'Планується',
    'В роботі',
    'Контроль',
    'Проблема',
    'Завершено',
  ];

  static const List<String> sortOrders = [
    'Нові зверху',
    'Старі зверху',
  ];

  static const List<String> taskStatuses = ["""

if old not in text:
    print("Не нашёл место для переменных фильтра")
else:
    text = text.replace(old, new)

# 2. Добавляем filteredTasks после statusToServer
marker = """  Future<void> loadTasks() async {"""
insert = """  List<Map<String, String>> get filteredTasks {
    final result = tasks.where((task) {
      final status = normalizeStatus(task['status'] ?? '');

      if (selectedStatusFilter != 'Усі статуси' &&
          status != selectedStatusFilter) {
        return false;
      }

      return true;
    }).toList();

    result.sort((a, b) {
      final aDate = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
      final bDate = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);

      if (selectedSortOrder == 'Старі зверху') {
        return aDate.compareTo(bDate);
      }

      return bDate.compareTo(aDate);
    });

    return result;
  }

"""

if "List<Map<String, String>> get filteredTasks" not in text:
    if marker not in text:
        print("Не нашёл место для filteredTasks")
    else:
        text = text.replace(marker, insert + marker)

# 3. Добавляем showFilterSheet перед buildEmptyState
marker = """  Widget buildEmptyState() {"""
insert = """  void showFilterSheet() {
    String tempStatus = selectedStatusFilter;
    String tempSort = selectedSortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      'Сортування завдань',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.objectName,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Статус завдання',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: tempStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: statusFilters.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          tempStatus = value;
                        });
                      },
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Сортування',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: tempSort,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: sortOrders.map((sort) {
                        return DropdownMenuItem<String>(
                          value: sort,
                          child: Text(sort),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          tempSort = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedStatusFilter = tempStatus;
                            selectedSortOrder = tempSort;
                          });

                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Застосувати'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F6FEB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedStatusFilter = 'Усі статуси';
                            selectedSortOrder = 'Нові зверху';
                          });

                          Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Скинути фільтр'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

"""

if "void showFilterSheet()" not in text:
    if marker not in text:
        print("Не нашёл место для showFilterSheet")
    else:
        text = text.replace(marker, insert + marker)

# 4. Добавляем кнопку фильтра в AppBar
old = """        actions: [
          IconButton(
            onPressed: isLoading ? null : loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Оновити',
          ),
        ],"""

new = """        actions: [
          IconButton(
            onPressed: showFilterSheet,
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Фільтр',
          ),
          IconButton(
            onPressed: isLoading ? null : loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Оновити',
          ),
        ],"""

if "Icons.tune_outlined" not in text:
    if old not in text:
        print("Не нашёл блок actions")
    else:
        text = text.replace(old, new)

# 5. Меняем список tasks на filteredTasks в build
old = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""
new = """  @override
  Widget build(BuildContext context) {
    final visibleTasks = filteredTasks;

    return Scaffold("""

if "final visibleTasks = filteredTasks;" not in text:
    text = text.replace(old, new)

text = text.replace(": tasks.isEmpty", ": visibleTasks.isEmpty")
text = text.replace("itemCount: tasks.length", "itemCount: visibleTasks.length")
text = text.replace("final task = tasks[index];", "final task = visibleTasks[index];")

path.write_text(text, encoding="utf-8")
print("filter added to object_tasks_screen.dart")
