class CategoryModel {
  final String id;
  final String name;
  final bool disponible;

  CategoryModel({
    required this.id,
    required this.name,
    this.disponible = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'disponible': disponible,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      disponible: map['disponible'] ?? true,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    bool? disponible,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      disponible: disponible ?? this.disponible,
    );
  }
}
