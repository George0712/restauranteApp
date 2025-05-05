class ProductModel {
  final String id;
  final String name;
  final double price;
  final int tiempoPreparacion;
  final String category;
  final String ingredientes;
  final bool disponible;
  final String? photo;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.tiempoPreparacion,
    required this.category,
    required this.ingredientes,
    this.disponible = true,
    this.photo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'time': tiempoPreparacion,
      'category': category,
      'ingredients': ingredientes,
      'disponible': disponible,
      if(photo != null) 'photo': photo,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble() ,
      tiempoPreparacion: map['time'] is int
          ? map['time']
          : int.tryParse(map['time'].toString()) ?? 0,
      category: map['category'] ?? '',
      ingredientes: map['ingredients'] ?? '',
      disponible: map['disponible'] ?? true,
      photo: map['photo'] ?? '',
    );
  }

    ProductModel copyWith({
      String? id,
      String? name,
      double? price,
      int? tiempoPreparacion,
      String? category,
      String? ingredientes,
      bool? disponible,
      String? photo,
    }) {
      return ProductModel(
        id: id ?? this.id,
        name: name ?? this.name,
        price: price ?? this.price,
        tiempoPreparacion: tiempoPreparacion ?? this.tiempoPreparacion,
        category: category ?? this.category,
        ingredientes: ingredientes ?? this.ingredientes,
        disponible: disponible ?? this.disponible,
        photo: photo ?? this.photo,
      );
    }
}