class AdditionalModel {
  final String id;
  final String name;
  final double price;
  final bool disponible;
  final String? photo;

  AdditionalModel({
    required this.id,
    required this.name,
    required this.price,
    this.photo,
    this.disponible = true,
  });

  // Convert Additional to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      if(photo != null) 'photo': photo,
      'disponible': disponible,
    };
  }

  // Create Additional from Map
  factory AdditionalModel.fromMap(Map<String, dynamic> map, String id) {
    return AdditionalModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      disponible: map['disponible'] ?? true,
      photo: map['photo'] ?? '',
    );
  }

  // CopyWith method
  AdditionalModel copyWith({
    String? id,
    String? name,
    double? price,
    String? photo,
    bool? disponible,
  }) {
    return AdditionalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      photo: photo ?? this.photo,
      disponible: disponible ?? this.disponible,
    );
  }
}