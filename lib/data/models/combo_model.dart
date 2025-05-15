import 'package:restaurante_app/data/models/product_model.dart';

class ComboModel {
  final String id;
  final String name;
  final double price;
  final int timePreparation;
  final List<ProductModel> products;
  final String? photo;  
  final bool? disponible;

  ComboModel({
    required this.id,
    required this.name,
    required this.price,
    this.photo,
    this.timePreparation = 0,
    this.products = const [],
    this.disponible = true,
  });

  // Convert ComboModel to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'photo': photo,
      'timePreparation': timePreparation,
      'products': products.map((product) => product.toMap()).toList(),  
      'disponible': disponible,
    };
  }

  // Create ComboModel from Map
  factory ComboModel.fromMap(Map<String, dynamic> map) {
    return ComboModel(
      id: map['id'] as String,
      name: map['name'] as String,
      price: map['price'] as double,
      photo: map['photo'] as String?,
      timePreparation: map['timePreparation'] as int,
      products: map['products'] as List<ProductModel>,
      disponible: map['disponible'] as bool,
    );
  }

  // CopyWith method
  ComboModel copyWith({
    String? id,
    String? name,
    double? price,
    String? photo,
    int? timePreparation,
    List<ProductModel>? products,
    bool? disponible,
  }) {
    return ComboModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      photo: photo ?? this.photo,
      timePreparation: timePreparation ?? this.timePreparation,
      products: products ?? this.products,
      disponible: disponible ?? this.disponible,
    );
  }
}