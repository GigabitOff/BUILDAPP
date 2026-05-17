class ConstructionObject {
  final int id;
  final String name;
  final String address;
  final String status;
  final String customer;

  // Відповідальний = кто создал объект / админ
  final String responsible;

  // Виконавець = выбранный исполнитель
  final int? executorId;
  final String executorName;

  final String startDate;
  final String endDate;
  final String description;
  final int tasksCount;
  final int photosCount;

  const ConstructionObject({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    required this.customer,
    required this.responsible,
    this.executorId,
    required this.executorName,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.tasksCount,
    required this.photosCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'status': status,
      'customer': customer,

      // ВАЖНО:
      // responsible НЕ отправляем.
      // Сервер сам ставит responsible по текущему пользователю.
      'executor_id': executorId,

      'start_date': startDate,
      'end_date': endDate,
      'description': description,
      'tasks_count': tasksCount,
      'photos_count': photosCount,
    };
  }

  factory ConstructionObject.fromJson(Map<String, dynamic> json) {
    return ConstructionObject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? '',
      customer: json['customer'] ?? '',
      responsible: json['responsible'] ?? json['creator_name'] ?? '',
      executorId: _toNullableInt(json['executor_id']),
      executorName: json['executor_name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      description: json['description'] ?? '',
      tasksCount: _toInt(json['tasks_count']),
      photosCount: _toInt(json['photos_count']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
