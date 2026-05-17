class ObjectMaterial {
  final int id;
  final int constructionObjectId;
  final String name;
  final String? unit;
  final double quantity;
  final double price;
  final String? comment;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  ObjectMaterial({
    required this.id,
    required this.constructionObjectId,
    required this.name,
    this.unit,
    required this.quantity,
    required this.price,
    this.comment,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ObjectMaterial.fromJson(Map<String, dynamic> json) {
    return ObjectMaterial(
      id: json['id'] ?? 0,
      constructionObjectId: json['construction_object_id'] ?? 0,
      name: json['name'] ?? '',
      unit: json['unit'],
      quantity: double.tryParse(json['quantity'].toString()) ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0,
      comment: json['comment'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}



