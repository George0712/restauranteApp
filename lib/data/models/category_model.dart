class CategoryModel {
  final String id;
  final String name;
  final String? photo;
  final bool disponible;

  CategoryModel({
    required this.id,
    required this.name,
    this.photo,
    this.disponible = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (photo != null) 'photo': photo,
      'disponible': disponible,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      photo: map['photo'],
      disponible: map['disponible'] ?? true,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? photo,
    bool? disponible,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      disponible: disponible ?? this.disponible,
    );
  }
}
