class ConstructionObject {
  final int id;
  final String name;
  final String address;
  final String status;
  final String customer;
  final String responsible;
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
      'responsible': responsible,
      'executor_name': executorName,
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
      responsible: json['responsible'] ?? '',
      executorName: json['executor_name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      description: json['description'] ?? '',
      tasksCount: json['tasks_count'] ?? 0,
      photosCount: json['photos_count'] ?? 0,
    );
  }
}



