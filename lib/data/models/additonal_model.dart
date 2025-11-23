class AdditionalModel {
  final String id;
  final String name;
  final double price;
  final bool disponible;

  AdditionalModel({
    required this.id,
    required this.name,
    required this.price,
    this.disponible = true,
  });

  // Convert Additional to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
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
    );
  }

  // CopyWith method
  AdditionalModel copyWith({
    String? id,
    String? name,
    double? price,
    bool? disponible,
  }) {
    return AdditionalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      disponible: disponible ?? this.disponible,
    );
  }
}