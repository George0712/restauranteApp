class Additional {
  final String id;
  final String name;
  final double price;
  final String? photo;

  Additional({
    required this.id,
    required this.name,
    required this.price,
    this.photo
  });

  // Convert Additional to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      if(photo != null) 'photo': photo,
    };
  }

  // Create Additional from Map
  factory Additional.fromMap(Map<String, dynamic> map, String id) {
    return Additional(
      id: id,
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      photo: map['photo'] ?? '',
    );
  }

  // CopyWith method
  Additional copyWith({
    String? id,
    String? name,
    double? price,
    String? photo,
  }) {
    return Additional(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      photo: photo ?? this.photo,
    );
  }
}