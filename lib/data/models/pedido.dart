import 'package:cloud_firestore/cloud_firestore.dart';

class ItemPedido {
  final String id;
  final String nombre;
  final double precio;
  final int cantidad;
  final String? notas;
  final String? productId;
  final int? tiempoPreparacion;
  final List<Map<String, dynamic>>? adicionales; // ✅ Usar Map en lugar de Adicional

  ItemPedido({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    this.notas,
    this.productId,
    this.tiempoPreparacion,
    this.adicionales, // ✅ Como Map
  });

  // En fromJson:
  factory ItemPedido.fromJson(Map<String, dynamic> json) {
  return ItemPedido(
    id: json['productId'] ?? json['id'] ?? '',
    nombre: json['name'] ?? json['nombre'] ?? '',
    precio: (json['price'] as num?)?.toDouble() ?? 0.0,
    cantidad: json['quantity'] ?? json['cantidad'] ?? 1,
    notas: json['notes'] ?? json['notas'],
    productId: json['productId'],
    tiempoPreparacion: json['tiempoPreparacion'] ?? json['prepTime'],
    // ✅ AÑADIR VALIDACIÓN ROBUSTA:
    adicionales: _parseAdicionales(json['adicionales']),
  );
}

// ✅ FUNCIÓN HELPER PARA PARSING SEGURO:
static List<Map<String, dynamic>>? _parseAdicionales(dynamic adicionalesData) {
  if (adicionalesData == null) return null;
  
  try {
    if (adicionalesData is List) {
      return adicionalesData
          .where((item) => item != null && item is Map<String, dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    }
  } catch (e) {
    print("🚨 Error parseando adicionales: $e");
  }
  
  return null;
}


  // En toJson:
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nombre,
      'price': precio,
      'quantity': cantidad,
      'notes': notas,
      'productId': productId,
      'tiempoPreparacion': tiempoPreparacion,
      'adicionales': adicionales, // ✅ Ya es una lista de Maps
    };
  }
}


class Pedido {
  final String id;
  final String status;
  final String mode;
  final double subtotal;
  final double total;
  final String? tableNumber; // UUID - mantener para compatibilidad
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final List<ItemPedido> items;
  final String? cliente;
  final String? notas;
  final String? meseroId;
  final String? meseroNombre;
  
  // ✅ NUEVOS CAMPOS PARA INFORMACIÓN LEGIBLE:
  final int? mesaId;           // Número real de la mesa (1, 2, 3, etc.)
  final String? mesaNombre;    // "Mesa 3" - información legible
  final String? clienteNombre; // Nombre del cliente para historial
  
  Pedido({
    required this.id,
    required this.status,
    required this.mode,
    required this.subtotal,
    required this.total,
    this.tableNumber,
    this.updatedAt,
    this.createdAt,
    required this.items,
    this.cliente,
    this.notas,
    this.meseroId,
    this.meseroNombre,
    // ✅ Nuevos parámetros:
    this.mesaId,
    this.mesaNombre,
    this.clienteNombre,
  });

  // Getters para compatibilidad con código existente
  String get estado => status;
  String get modo => mode;
  int get mesaIdLegacy {
    // Si tenemos el mesaId nuevo, usarlo; sino, usar 0 por defecto
    return mesaId ?? 0;
  }
  String get tableUuid => tableNumber ?? '';
  DateTime get fecha => updatedAt ?? createdAt ?? DateTime.now();
  double? get propina => null;
  double get totalConPropina => total;


  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pendiente',
      mode: json['mode'] ?? 'mesa',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      tableNumber: json['tableNumber'],
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : null,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : null,
      items: _parseItems(json['items']),
      cliente: json['cliente'],
      notas: json['notas'],
      meseroId: json['meseroId'],
      meseroNombre: json['meseroNombre'],
      // ✅ Nuevos campos:
      mesaId: json['mesaId'] as int?,
      mesaNombre: json['mesaNombre'],
      clienteNombre: json['clienteNombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'mode': mode,
      'subtotal': subtotal,
      'total': total,
      'tableNumber': tableNumber,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'items': items.map((item) => item.toJson()).toList(),
      'cliente': cliente,
      'notas': notas,
      'meseroId': meseroId,
      'meseroNombre': meseroNombre,
      // ✅ Nuevos campos:
      'mesaId': mesaId,
      'mesaNombre': mesaNombre,
      'clienteNombre': clienteNombre,
    };
  }

  // Función helper para parsing seguro de items
  static List<ItemPedido> _parseItems(dynamic itemsData) {
    if (itemsData == null) return [];
    
    try {
      if (itemsData is List) {
        return itemsData
            .where((item) => item != null && item is Map<String, dynamic>)
            .map((item) => ItemPedido.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print("🚨 Error parseando items: $e");
    }
    
    return [];
  }
}

enum EstadoPedido {
  pendiente,
  preparando, // Cambié 'enPreparacion' por 'preparando' para coincidir con Firestore
  terminado,  // Cambié 'listo' por 'terminado' para coincidir con Firestore
  entregado,
  cancelado,
}