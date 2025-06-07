import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final int price;
  final int quantity;
  final String? notes;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toInt(),
      quantity: (json['quantity'] ?? 0).toInt(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      if (notes != null) 'notes': notes,
    };
  }

  OrderItem copyWith({
    String? productId,
    String? name,
    int? price,
    int? quantity,
    String? notes,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

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
    this.status = 'pendiente', // Estado por defecto
    this.updatedAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      mode: json['mode'] ?? 'mesa',
      tableNumber: json['tableNumber'],
      customerName: json['customerName'],
      address: json['address'],
      phone: json['phone'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toInt(),
      discount: (json['discount'] ?? 0).toInt(),
      total: (json['total'] ?? 0).toInt(),
      createdAt: json['createdAt'] ?? Timestamp.now(),
      status: json['status'] ?? 'pendiente',
      updatedAt: json['updatedAt'],
      completedAt: json['completedAt'],
      cancelledAt: json['cancelledAt'],
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
      default:
        return 'N/A';
    }
  }

  int get itemsCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
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
    return 'Order(id: $id, mode: $mode, status: $status, total: $total)';
  }
}