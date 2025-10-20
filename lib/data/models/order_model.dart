import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final int price;
  final int quantity;
  final String? notes;
  final List<String> modifications; // Para manejar modificaciones/adicionales
  final String? image; // Para mostrar imagen del producto
  final int? preparationTime; // Tiempo de preparación en minutos
  final String meseroId; // Nombre del mesero que tomó el pedido

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.meseroId,
    this.notes,
    this.modifications = const [],
    this.image,
    this.preparationTime,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? json['id'] ?? '', // Maneja ambos casos
      name: json['name'] ?? json['nombre'] ?? 'Producto sin nombre', // Maneja ambos casos
      price: (json['price'] ?? json['precio'] ?? 0).toInt(),
      quantity: (json['quantity'] ?? json['cantidad'] ?? 0).toInt(),
      notes: json['notes'] ?? json['notas'],
      modifications: List<String>.from(json['modifications'] ?? json['modificaciones'] ?? []),
      image: json['image'] ?? json['imagen'],
      preparationTime: json['preparationTime'] ?? json['tiempoPreparacion'] ?? json['time'],
      meseroId: json['meseroId'] ?? json['mesero'] ?? 'Desconocido', // Maneja ambos casos
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      if (notes != null) 'notes': notes,
      'modifications': modifications,
      if (image != null) 'image': image,
      if (preparationTime != null) 'preparationTime': preparationTime,
      'meseroId': meseroId, // Asegúrate de incluir el ID del mesero
    };
  }

  OrderItem copyWith({
    String? productId,
    String? name,
    int? price,
    int? quantity,
    String? notes,
    List<String>? modifications,
    String? image,
    int? preparationTime,
    String? meseroId, // Permite cambiar el ID del mesero si es necesario
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      modifications: modifications ?? this.modifications,
      image: image ?? this.image,
      preparationTime: preparationTime ?? this.preparationTime,
      meseroId: meseroId ?? this.meseroId, // Permite cambiar el ID del mesero si es necesario
    );
  }

  // Precio total incluyendo modificaciones
  int get totalPrice => price * quantity;

  // Mostrar modificaciones como string
  String get modificationsText => modifications.isEmpty 
      ? '' 
      : modifications.join(', ');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}

class Order {
  final String? id;
  final String mode; // mesa, domicilio, paraLlevar
  final String? tableNumber;
  final String? customerName;
  final String? address;
  final String? phone;
  final List<OrderItem> items;
  final int subtotal;
  final int discount;
  final int total;
  final Timestamp createdAt;
  final String status; // pendiente, preparando, terminado, cancelado
  final Timestamp? updatedAt;
  final Timestamp? completedAt;
  final Timestamp? cancelledAt;
  final String? meseroId; // Nombre del mesero que tomó el pedido
  

  Order({
    this.id,
    required this.mode,
    this.tableNumber,
    this.customerName,
    this.address,
    this.phone,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.createdAt,
    this.status = 'pendiente',
    this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.meseroId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> parsedItems = [];
    
    // Maneja diferentes estructuras de items
    if (json['items'] != null) {
      final itemsData = json['items'];
      if (itemsData is List) {
        for (var item in itemsData) {
          if (item is Map<String, dynamic>) {
            parsedItems.add(OrderItem.fromJson(item));
          }
        }
      }
    }
    
    // También maneja si los items vienen como 'productos'
    if (json['productos'] != null && parsedItems.isEmpty) {
      final productosData = json['productos'];
      if (productosData is List) {
        for (var producto in productosData) {
          if (producto is Map<String, dynamic>) {
            parsedItems.add(OrderItem.fromJson(producto));
          }
        }
      }
    }

    return Order(
      id: json['id'],
      mode: json['mode'] ?? json['tipo'] ?? 'mesa',
      tableNumber: json['tableNumber'] ?? json['mesa']?.toString(),
      customerName: json['customerName'] ?? json['cliente'],
      address: json['address'] ?? json['direccion'],
      phone: json['phone'] ?? json['telefono'],
      items: parsedItems,
      subtotal: (json['subtotal'] ?? 0).toInt(),
      discount: (json['discount'] ?? json['descuento'] ?? 0).toInt(),
      total: (json['total'] ?? 0).toInt(),
      createdAt: json['createdAt'] ?? json['fechaCreacion'] ?? Timestamp.now(),
      status: json['status'] ?? json['estado'] ?? 'pendiente',
      updatedAt: json['updatedAt'] ?? json['fechaActualizacion'],
      completedAt: json['completedAt'] ?? json['fechaCompletado'],
      cancelledAt: json['cancelledAt'] ?? json['fechaCancelado'],
      meseroId: json['meseroId'] ?? json['mesero'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'mode': mode,
      if (tableNumber != null) 'tableNumber': tableNumber,
      if (customerName != null) 'customerName': customerName,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'createdAt': createdAt,
      'status': status,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (cancelledAt != null) 'cancelledAt': cancelledAt,
      if (meseroId != null) 'meseroId': meseroId,
    };
  }

  Order copyWith({
    String? id,
    String? mode,
    String? tableNumber,
    String? customerName,
    String? address,
    String? phone,
    List<OrderItem>? items,
    int? subtotal,
    int? discount,
    int? total,
    Timestamp? createdAt,
    String? status,
    Timestamp? updatedAt,
    Timestamp? completedAt,
    Timestamp? cancelledAt,
    String? meseroId,
  }) {
    return Order(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      meseroId: meseroId ?? this.meseroId,
    );
  }

  // Métodos de utilidad
  bool get isPending => status == 'pendiente';
  bool get isInProgress => status == 'preparando';
  bool get isCompleted => status == 'terminado';
  bool get isCancelled => status == 'cancelado';

  Duration get timeSinceCreated {
    return DateTime.now().difference(createdAt.toDate());
  }

  String get displayId {
    return id?.substring(0, 6).toUpperCase() ?? 'N/A';
  }

  String get customerDisplay {
    switch (mode) {
      case 'mesa':
        return 'Mesa ${tableNumber ?? 'N/A'}';
      case 'domicilio':
        return customerName ?? 'Cliente sin nombre';
      case 'paraLlevar':
        return customerName ?? 'Cliente sin nombre';
      case 'rapido':
        return customerName ?? 'Pedido rápido';
      default:
        return 'N/A';
    }
  }

  int get itemsCount {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Order(id: $id, mode: $mode, status: $status, total: $total, items: ${items.length})';
  }
}
