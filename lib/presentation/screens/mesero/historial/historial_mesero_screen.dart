import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:restaurante_app/presentation/widgets/tab_label.dart';
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(pedidosStatsProvider);

    return statsAsync.when(
      data: (stats) => _buildHistorialContent(stats),
      loading: () => _buildLoadingScreen(),
      error: (error, _) => _buildErrorScreen(error),
    );
  }

  Widget _buildHistorialContent(Map<String, int> stats) {
    final pendingCount = (stats['pendiente'] ?? 0) +
                        (stats['preparando'] ?? 0) +
                        (stats['en_preparacion'] ?? 0);
    final completedCount = (stats['terminado'] ?? 0) +
                          (stats['pagado'] ?? 0) +
                          (stats['entregado'] ?? 0) +
                          (stats['cancelado'] ?? 0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1F2937),
                  Color(0xFF111827),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF111827),
                    Color(0xFF0B1120),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Historial de Pedidos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _BuildCustomTabBar(
                      pendingCount: pendingCount,
                      completedCount: completedCount,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TabBarView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildPedidosEnCurso(),
                          _buildPedidosCompletados(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF111827),
              Color(0xFF0B1120),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object error) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1F2937),
                Color(0xFF111827),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF111827),
              Color(0xFF0B1120),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar estadísticas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPedidosEnCurso() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
        .collection('pedido')
        .where('status', whereIn: ['pendiente', 'preparando', 'en_preparacion'])
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Error al cargar pedidos en curso', snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget('No hay pedidos en curso');
        }

        final docs = snapshot.data!.docs;
        
        // Ordenar por fecha de creación (más reciente primero)
        docs.sort((a, b) {
          try {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            
            DateTime fechaA = DateTime.now();
            DateTime fechaB = DateTime.now();
            
            // Intentar obtener fecha de varios campos posibles
            if (dataA['createdAt'] is Timestamp) {
              fechaA = (dataA['createdAt'] as Timestamp).toDate();
            } else if (dataA['timestamp'] is Timestamp) {
              fechaA = (dataA['timestamp'] as Timestamp).toDate();
            } else if (dataA['date'] is Timestamp) {
              fechaA = (dataA['date'] as Timestamp).toDate();
            }
            
            if (dataB['createdAt'] is Timestamp) {
              fechaB = (dataB['createdAt'] as Timestamp).toDate();
            } else if (dataB['timestamp'] is Timestamp) {
              fechaB = (dataB['timestamp'] as Timestamp).toDate();
            } else if (dataB['date'] is Timestamp) {
              fechaB = (dataB['date'] as Timestamp).toDate();
            }
            
            return fechaB.compareTo(fechaA); // Más reciente primero
          } catch (e) {
            // En caso de error, mantener orden original
            return 0;
          }
        });
        
        // Limitar a 50 elementos para mejor rendimiento
        final limitedDocs = docs.take(50).toList();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: limitedDocs.length,
          itemBuilder: (context, index) {
            return _buildPedidoCard(limitedDocs[index]);
          },
        );
      },
    );
  }

  Widget _buildPedidosCompletados() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pedido')
          .where('status', whereIn: ['terminado', 'cancelado', 'completado', 'entregado', 'pagado', 'finalizado', 'cerrado'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget('Error al cargar pedidos completados', snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget('No hay pedidos completados');
        }

        final docs = snapshot.data!.docs;
        
        // Ordenar por fecha de creación (más reciente primero)
        docs.sort((a, b) {
          try {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            
            DateTime fechaA = DateTime.now();
            DateTime fechaB = DateTime.now();
            
            // Intentar obtener fecha de varios campos posibles
            if (dataA['createdAt'] is Timestamp) {
              fechaA = (dataA['createdAt'] as Timestamp).toDate();
            } else if (dataA['timestamp'] is Timestamp) {
              fechaA = (dataA['timestamp'] as Timestamp).toDate();
            } else if (dataA['date'] is Timestamp) {
              fechaA = (dataA['date'] as Timestamp).toDate();
            }
            
            if (dataB['createdAt'] is Timestamp) {
              fechaB = (dataB['createdAt'] as Timestamp).toDate();
            } else if (dataB['timestamp'] is Timestamp) {
              fechaB = (dataB['timestamp'] as Timestamp).toDate();
            } else if (dataB['date'] is Timestamp) {
              fechaB = (dataB['date'] as Timestamp).toDate();
            }
            
            return fechaB.compareTo(fechaA); // Más reciente primero
          } catch (e) {
            // En caso de error, mantener orden original
            return 0;
          }
        });
        
        // Limitar a 100 elementos para el historial completo
        final limitedDocs = docs.take(100).toList();

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: limitedDocs.length,
          itemBuilder: (context, index) {
            return _buildPedidoCard(limitedDocs[index]);
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String message, dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Error: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(DocumentSnapshot pedido) {
    try {
      final data = pedido.data() as Map<String, dynamic>? ?? {};
      
      // Manejo robusto de datos
      final String pedidoId = pedido.id;
      final String mode = data['mode']?.toString() ?? 'desconocido';
      final String tableNumber = data['tableNumber']?.toString() ?? 'N/A';
      final String customerName = data['customerName']?.toString() ?? 'Cliente';
      final String status = data['status']?.toString() ?? 'desconocido';
      final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
      
      // Manejo robusto del total
      double total = 0.0;
      try {
        if (data['total'] != null) {
          if (data['total'] is num) {
            total = data['total'].toDouble();
          } else if (data['total'] is String) {
            total = double.tryParse(data['total']) ?? 0.0;
          }
        }
      } catch (e) {
        // Intentar calcular total desde items si falla
        try {
          total = items.fold<double>(0.0, (acc, item) {
            if (item is Map<String, dynamic>) {
              final itemPrice = item['price'] ?? 0;
              final itemQuantity = item['quantity'] ?? 1;
              if (itemPrice is num && itemQuantity is num) {
                return acc + (itemPrice * itemQuantity).toDouble();
              }
            }
            return acc;
          });
        } catch (e2) {
          total = 0.0;
        }
      }
      
      // Manejo robusto de la fecha
      DateTime fecha = DateTime.now();
      try {
        if (data['createdAt'] is Timestamp) {
          fecha = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          fecha = DateTime.parse(data['createdAt']);
        } else if (data['timestamp'] is Timestamp) {
          fecha = (data['timestamp'] as Timestamp).toDate();
        } else if (data['date'] is Timestamp) {
          fecha = (data['date'] as Timestamp).toDate();
        }
      } catch (e) {
        // Mantener fecha actual si hay error
      }
      
      final String displayTitle = mode == 'mesa' ? '$tableNumber' : customerName;
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(status).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              _mostrarDetallesPedido(pedidoId, data);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y estado
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(status).withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          _getStatusDisplayName(status),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Información secundaria
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatearFecha(fecha),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.restaurant,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${items.length} items',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Total y flecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${_formatearNumero(total)}',
                        style: const TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ],
                  ),
                  
                  // ID del pedido (para debugging)
                  if (pedidoId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${pedidoId.length > 14 ? pedidoId.substring(0, 14) : pedidoId}...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      // Tarjeta de error mejorada
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error al cargar pedido',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${pedido.id}',
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              Text(
                'Error: ${e.toString()}',
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final diferencia = now.difference(fecha);
    
    if (diferencia.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(fecha)}';
    } else if (diferencia.inDays == 1) {
      return 'Ayer ${DateFormat('HH:mm').format(fecha)}';
    } else if (diferencia.inDays < 7) {
      return '${diferencia.inDays} días atrás';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    }
  }
  
  String _formatearNumero(double numero) {
    return numero.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
  
  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparando':
      case 'en_preparacion':
        return 'En Preparación';
      case 'terminado':
        return 'Terminado';
      case 'completado':
        return 'Completado';
      case 'entregado':
        return 'Entregado';
      case 'pagado':
        return 'Pagado';
      case 'cancelado':
        return 'Cancelado';
      case 'listo_para_pago':
        return 'Listo para Pago';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'preparando':
      case 'en_preparacion':
        return Colors.blue;
      case 'terminado':
      case 'completado':
      case 'entregado':
        return Colors.green;
      case 'pagado':
        return const Color(0xFF4CAF50);
      case 'cancelado':
        return Colors.red;
      case 'listo_para_pago':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  void _mostrarDetallesPedido(String pedidoId, [Map<String, dynamic>? datosIniciales]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF8B5CF6),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalles del Pedido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('pedido').doc(pedidoId).snapshots(),
                builder: (context, snapshot) {
                  // Usar datos iniciales si están disponibles y no hay snapshot aún
                  Map<String, dynamic>? data = datosIniciales;
                  
                  if (snapshot.hasError) {
                    return _buildErrorContent('Error al cargar los detalles', snapshot.error.toString());
                  }
                  
                  if (snapshot.hasData && snapshot.data!.exists) {
                    try {
                      data = snapshot.data!.data() as Map<String, dynamic>;
                    } catch (e) {
                      return _buildErrorContent('Error al procesar los datos', e.toString());
                    }
                  } else if (data == null && snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B5CF6),
                      ),
                    );
                  }
                  
                  if (data == null || data.isEmpty) {
                    return _buildErrorContent('Pedido no encontrado', 'No se pudieron cargar los datos del pedido');
                  }
                  
                  return _buildPedidoDetails(pedidoId, data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorContent(String titulo, String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPedidoDetails(String pedidoId, Map<String, dynamic> data) {
    // Extraer datos de manera segura
    final String mode = data['mode']?.toString() ?? 'desconocido';
    final String tableNumber = data['tableNumber']?.toString() ?? 'N/A';
    final String customerName = data['customerName']?.toString() ?? 'Cliente';
    final String status = data['status']?.toString() ?? 'desconocido';
    final bool pagado = data['pagado'] == true;
    final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
    
    // Calcular total de manera robusta
    double total = 0.0;
    try {
      if (data['total'] is num) {
        total = data['total'].toDouble();
      } else if (data['total'] is String) {
        total = double.tryParse(data['total']) ?? 0.0;
      }
      
      // Si total es 0, intentar calcular desde items
      if (total == 0.0 && items.isNotEmpty) {
        total = items.fold<double>(0.0, (acc, item) {
          if (item is Map<String, dynamic>) {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            return acc + (price * quantity);
          }
          return acc;
        });
      }
    } catch (e) {
      total = 0.0;
    }
    
    // Extraer fecha
    DateTime fecha = DateTime.now();
    try {
      if (data['createdAt'] is Timestamp) {
        fecha = (data['createdAt'] as Timestamp).toDate();
      } else if (data['timestamp'] is Timestamp) {
        fecha = (data['timestamp'] as Timestamp).toDate();
      }
    } catch (e) {
      // Mantener fecha actual
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del pedido
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      mode == 'mesa' ? Icons.table_restaurant : Icons.person,
                      color: const Color(0xFF8B5CF6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mode == 'mesa' ? 'Mesa $tableNumber' : customerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(status).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        _getStatusDisplayName(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatearFecha(fecha),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (pagado) ...[
                      const Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Pagado',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${pedidoId.length > 12 ? pedidoId.substring(0, 12) : pedidoId}...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Título de items
          Text(
            'Items del Pedido (${items.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Lista de items
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay items en este pedido',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemCard(item, index);
            }),
          
          const SizedBox(height: 24),
          
          // Total y Acciones
          Column(
            children: [
              // Total del pedido (informativo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFF8B5CF6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total del Pedido',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_formatearNumero(total)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botón de imprimir
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _imprimirPedido(pedidoId, data),
                  icon: const Icon(Icons.print, size: 20),
                  label: const Text(
                    'Imprimir Recibo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botón de compartir
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Mostrar diálogo para elegir cómo compartir
                    _mostrarOpcionesCompartir(context, pedidoId, data);
                  },
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text(
                    'Compartir Recibo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemCard(dynamic item, int index) {
    if (item is! Map<String, dynamic>) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'Item con formato inválido',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    
    final String name = item['name']?.toString() ?? 'Producto sin nombre';
    final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final String? notes = item['notes']?.toString();
    final List<dynamic> adicionales = item['adicionales'] as List<dynamic>? ?? [];
    
    final double totalItem = price * quantity;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'x$quantity',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${_formatearNumero(price)} c/u',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${_formatearNumero(totalItem)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            // Adicionales si existen
            if (adicionales.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Adicionales:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: adicionales.map((adicional) {
                  final String nombreAdicional = adicional is Map<String, dynamic>
                      ? adicional['name']?.toString() ?? 'Adicional'
                      : adicional.toString();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      nombreAdicional,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // Notas si existen
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.note_outlined,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(
                          color: Colors.orange.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _imprimirPedido(String pedidoId, Map<String, dynamic> data) async {
    try {
      HapticFeedback.lightImpact();
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 16),
              Text(
                'Generando recibo...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
      
      final pdf = await _generarPDF(pedidoId, data);
      
      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();
      
      // Intentar impresión nativa primero, si falla usar web
      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Pedido_${pedidoId.substring(0, 8)}.pdf',
        );
      } catch (printingError) {
        // Si la impresión nativa falla, mostrar preview alternativo
        await _mostrarPreviewPDF(pedidoId, data, pdf);
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el recibo: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => _imprimirPedido(pedidoId, data),
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }
  
  Future<pw.Document> _generarPDF(String pedidoId, Map<String, dynamic> data) async {
    final pdf = pw.Document();
    
    // Extraer datos de manera segura
    final String mode = data['mode']?.toString() ?? 'desconocido';
    final String tableNumber = data['tableNumber']?.toString() ?? 'N/A';
    final String customerName = data['customerName']?.toString() ?? 'Cliente';
    final String status = data['status']?.toString() ?? 'desconocido';
    final bool pagado = data['pagado'] == true;
    final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
    
    // Calcular total
    double total = 0.0;
    try {
      if (data['total'] is num) {
        total = data['total'].toDouble();
      } else if (data['total'] is String) {
        total = double.tryParse(data['total']) ?? 0.0;
      }
      
      if (total == 0.0 && items.isNotEmpty) {
        total = items.fold<double>(0.0, (acc, item) {
          if (item is Map<String, dynamic>) {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            return acc + (price * quantity);
          }
          return acc;
        });
      }
    } catch (e) {
      total = 0.0;
    }
    
    // Extraer fecha
    DateTime fecha = DateTime.now();
    try {
      if (data['createdAt'] is Timestamp) {
        fecha = (data['createdAt'] as Timestamp).toDate();
      } else if (data['timestamp'] is Timestamp) {
        fecha = (data['timestamp'] as Timestamp).toDate();
      }
    } catch (e) {
      // Mantener fecha actual
    }
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header del restaurante
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'RESTAURANTE APP',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Recibo de Pedido',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 32),
              
              // Información del pedido
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Pedido ID: ${pedidoId.substring(0, 12)}...'),
                      pw.Text(mode == 'mesa' ? 'Mesa: $tableNumber' : 'Cliente: $customerName'),
                      pw.Text('Estado: ${_getStatusDisplayName(status)}'),
                      if (pagado) pw.Text('✓ PAGADO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}'),
                      pw.Text('Hora: ${DateFormat('HH:mm').format(fecha)}'),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 32),
              
              // Línea separadora
              pw.Divider(),
              
              pw.SizedBox(height: 16),
              
              // Header de items
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Cant.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Precio Unit.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // Items del pedido
              ...items.asMap().entries.map((entry) {
                final item = entry.value;
                if (item is! Map<String, dynamic>) {
                  return pw.Container();
                }
                
                final String name = item['name']?.toString() ?? 'Producto';
                final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
                final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final String? notes = item['notes']?.toString();
                final List<dynamic> adicionales = item['adicionales'] as List<dynamic>? ?? [];
                final double totalItem = price * quantity;
                
                return pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(flex: 3, child: pw.Text(name)),
                        pw.Expanded(flex: 1, child: pw.Text('x$quantity')),
                        pw.Expanded(flex: 2, child: pw.Text('\$${_formatearNumero(price)}')),
                        pw.Expanded(flex: 2, child: pw.Text('\$${_formatearNumero(totalItem)}', textAlign: pw.TextAlign.right)),
                      ],
                    ),
                    
                    // Adicionales si existen
                    if (adicionales.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16),
                        child: pw.Text(
                          'Adicionales: ${adicionales.map((a) => a is Map<String, dynamic> ? a['name']?.toString() ?? 'Adicional' : a.toString()).join(", ")}',
                          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                        ),
                      ),
                    ],
                    
                    // Notas si existen
                    if (notes != null && notes.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16),
                        child: pw.Text(
                          'Nota: $notes',
                          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                        ),
                      ),
                    ],
                    
                    pw.SizedBox(height: 8),
                  ],
                );
              }),
              
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),
              
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'TOTAL: \$${_formatearNumero(total)}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      '¡Gracias por su preferencia!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Impreso el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }
  
  Future<void> _mostrarPreviewPDF(String pedidoId, Map<String, dynamic> data, pw.Document pdf) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.print_outlined,
                    color: Color(0xFF8B5CF6),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Vista Previa del Recibo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content - Recibo en formato texto
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _buildReciboTexto(pedidoId, data),
              ),
            ),
            
            // Botones
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Primera fila de botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copiarReciboTexto(pedidoId, data),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copiar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF8B5CF6)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _imprimirWeb(pedidoId, data),
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Imprimir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Segunda fila de botones
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _guardarPDF(pedidoId, pdf),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Guardar PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _compartirTexto(pedidoId, data),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Compartir Imagen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReciboTexto(String pedidoId, Map<String, dynamic> data) {
    // Extraer datos de manera segura
    final String mode = data['mode']?.toString() ?? 'desconocido';
    final String tableNumber = data['tableNumber']?.toString() ?? 'N/A';
    final String customerName = data['customerName']?.toString() ?? 'Cliente';
    final String status = data['status']?.toString() ?? 'desconocido';
    final bool pagado = data['pagado'] == true;
    final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
    
    // Calcular total
    double total = 0.0;
    try {
      if (data['total'] is num) {
        total = data['total'].toDouble();
      } else if (data['total'] is String) {
        total = double.tryParse(data['total']) ?? 0.0;
      }
      
      if (total == 0.0 && items.isNotEmpty) {
        total = items.fold<double>(0.0, (acc, item) {
          if (item is Map<String, dynamic>) {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            return acc + (price * quantity);
          }
          return acc;
        });
      }
    } catch (e) {
      total = 0.0;
    }
    
    // Extraer fecha
    DateTime fecha = DateTime.now();
    try {
      if (data['createdAt'] is Timestamp) {
        fecha = (data['createdAt'] as Timestamp).toDate();
      } else if (data['timestamp'] is Timestamp) {
        fecha = (data['timestamp'] as Timestamp).toDate();
      }
    } catch (e) {
      // Mantener fecha actual
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Center(
            child: Text(
              'RESTAURANTE APP\n===================\nRECIBO DE PEDIDO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          
          // Información del pedido
          Text(
            'Pedido ID: ${pedidoId.substring(0, 12)}...\n'
            '${mode == 'mesa' ? 'Mesa: $tableNumber' : 'Cliente: $customerName'}\n'
            'Estado: ${_getStatusDisplayName(status)}\n'
            '${pagado ? '✓ PAGADO\n' : ''}'
            'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}\n'
            '===================',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          
          // Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            if (item is! Map<String, dynamic>) {
              return Container();
            }
            
            final String name = item['name']?.toString() ?? 'Producto';
            final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final String? notes = item['notes']?.toString();
            final List<dynamic> adicionales = item['adicionales'] as List<dynamic>? ?? [];
            final double totalItem = price * quantity;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. $name\n'
                    '   x$quantity @ \$${_formatearNumero(price)} = \$${_formatearNumero(totalItem)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                  
                  if (adicionales.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '   Adicionales: ${adicionales.map((a) => a is Map<String, dynamic> ? a['name']?.toString() ?? 'Adicional' : a.toString()).join(', ')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '   Nota: $notes',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Total
          Text(
            '===================\n'
            'TOTAL: \$${_formatearNumero(total)}\n'
            '===================\n\n'
            '¡Gracias por su preferencia!\n\n'
            'Impreso: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Future<void> _copiarReciboTexto(String pedidoId, Map<String, dynamic> data) async {
    try {
      final texto = _generarTextoRecibo(pedidoId, data);
      await Clipboard.setData(ClipboardData(text: texto));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo copiado al portapapeles'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al copiar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  String _generarTextoRecibo(String pedidoId, Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('RESTAURANTE APP');
    buffer.writeln('===================');
    buffer.writeln('RECIBO DE PEDIDO');
    buffer.writeln('');
    
    // Información del pedido
    final String mode = data['mode']?.toString() ?? 'desconocido';
    final String tableNumber = data['tableNumber']?.toString() ?? 'N/A';
    final String customerName = data['customerName']?.toString() ?? 'Cliente';
    final String status = data['status']?.toString() ?? 'desconocido';
    final bool pagado = data['pagado'] == true;
    final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
    
    DateTime fecha = DateTime.now();
    try {
      if (data['createdAt'] is Timestamp) {
        fecha = (data['createdAt'] as Timestamp).toDate();
      } else if (data['timestamp'] is Timestamp) {
        fecha = (data['timestamp'] as Timestamp).toDate();
      }
    } catch (e) {
      // Mantener fecha actual
    }
    
    buffer.writeln('Pedido ID: ${pedidoId.substring(0, 12)}...');
    buffer.writeln(mode == 'mesa' ? 'Mesa: $tableNumber' : 'Cliente: $customerName');
    buffer.writeln('Estado: ${_getStatusDisplayName(status)}');
    if (pagado) buffer.writeln('✓ PAGADO');
    buffer.writeln('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}');
    buffer.writeln('===================');
    buffer.writeln('');
    
    // Items
    double total = 0.0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map<String, dynamic>) continue;
      
      final String name = item['name']?.toString() ?? 'Producto';
      final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final String? notes = item['notes']?.toString();
      final List<dynamic> adicionales = item['adicionales'] as List<dynamic>? ?? [];
      final double totalItem = price * quantity;
      total += totalItem;
      
      buffer.writeln('${i + 1}. $name');
      buffer.writeln('   x$quantity @ \$${_formatearNumero(price)} = \$${_formatearNumero(totalItem)}');
      
      if (adicionales.isNotEmpty) {
        buffer.writeln('   Adicionales: ${adicionales.map((a) => a is Map<String, dynamic> ? a['name']?.toString() ?? 'Adicional' : a.toString()).join(', ')}');
      }
      
      if (notes != null && notes.isNotEmpty) {
        buffer.writeln('   Nota: $notes');
      }
      
      buffer.writeln('');
    }
    
    // Total
    buffer.writeln('===================');
    buffer.writeln('TOTAL: \$${_formatearNumero(total)}');
    buffer.writeln('===================');
    buffer.writeln('');
    buffer.writeln('¡Gracias por su preferencia!');
    buffer.writeln('');
    buffer.writeln('Impreso: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    
    return buffer.toString();
  }
  
  Future<void> _imprimirWeb(String pedidoId, Map<String, dynamic> data) async {
    try {
      final texto = _generarTextoRecibo(pedidoId, data);
      
      // Copiar al portapapeles y mostrar instrucciones
      await Clipboard.setData(ClipboardData(text: texto));
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.print,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recibo Preparado',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Text(
              'El recibo se ha copiado al portapapeles.\n\n'
              '• Abre cualquier aplicación de texto (Word, Notepad, etc.)\n'
              '• Pega el contenido (Ctrl+V)\n'
              '• Usa Ctrl+P para imprimir\n\n'
              'También puedes usar el botón "Guardar PDF" '
              'para una mejor calidad de impresión.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Entendido',
                  style: TextStyle(color: Color(0xFF8B5CF6)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al preparar impresión: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<void> _guardarPDF(String pedidoId, pw.Document pdf) async {
    try {
      final pdfBytes = await pdf.save();
      
      // Usar Printing.sharePdf que funciona en la mayoría de plataformas
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Pedido_${pedidoId.substring(0, 8)}.pdf',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF compartido exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir PDF: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<void> _compartirTexto(String pedidoId, Map<String, dynamic> data) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 16),
              Text(
                'Generando imagen del recibo...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
      
      // Generar imagen PNG del recibo
      final imageBytes = await _generarImagenRecibo(pedidoId, data);
      
      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();
      
      // Guardar imagen temporal
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/recibo_pedido_${pedidoId.substring(0, 8)}.png');
      await file.writeAsBytes(imageBytes);
      
      // Compartir usando el selector nativo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Recibo del Pedido ${pedidoId.substring(0, 8)}',
        subject: 'Recibo - Restaurante App',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen del recibo compartida exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir imagen: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
  
  void _mostrarOpcionesCompartir(BuildContext context, String pedidoId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Icon(
                    Icons.share,
                    color: Color(0xFF8B5CF6),
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¿Cómo quieres compartir?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Opciones
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Opción 1: Como imagen
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Cerrar opciones
                        Navigator.pop(context); // Cerrar detalles
                        _compartirTexto(pedidoId, data); // Compartir imagen
                      },
                      icon: const Icon(Icons.image, size: 20),
                      label: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compartir como Imagen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Genera una imagen PNG del recibo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Opción 2: Como texto para WhatsApp
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Cerrar opciones
                        Navigator.pop(context); // Cerrar detalles
                        _compartirComoTexto(pedidoId, data); // Compartir texto
                      },
                      icon: const Icon(Icons.message, size: 20),
                      label: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compartir para WhatsApp',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Texto formateado con emojis',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botón cancelar
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _compartirComoTexto(String pedidoId, Map<String, dynamic> data) async {
    try {
      
      // Extraer datos de manera segura
      final String mode = data['mode']?.toString() ?? 'desconocido';
      final String tableNumber = data['tableNumber']?.toString() ?? 'N/A';
      final String customerName = data['customerName']?.toString() ?? 'Cliente';
      final String status = data['status']?.toString() ?? 'desconocido';
      final bool pagado = data['pagado'] == true;
      final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
      
      // Calcular total
      double total = 0.0;
      try {
        if (data['total'] is num) {
          total = data['total'].toDouble();
        } else if (data['total'] is String) {
          total = double.tryParse(data['total']) ?? 0.0;
        }
        
        if (total == 0.0 && items.isNotEmpty) {
          total = items.fold<double>(0.0, (acc, item) {
            if (item is Map<String, dynamic>) {
              final price = (item['price'] as num?)?.toDouble() ?? 0.0;
              final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
              return acc + (price * quantity);
            }
            return acc;
          });
        }
      } catch (e) {
        total = 0.0;
      }
      
      // Extraer fecha
      DateTime fecha = DateTime.now();
      try {
        if (data['createdAt'] is Timestamp) {
          fecha = (data['createdAt'] as Timestamp).toDate();
        } else if (data['timestamp'] is Timestamp) {
          fecha = (data['timestamp'] as Timestamp).toDate();
        }
      } catch (e) {
        // Mantener fecha actual
      }
      
      // Crear el texto del recibo
      final StringBuffer buffer = StringBuffer();
      buffer.writeln('🍽️ *RESTAURANTE APP*');
      buffer.writeln('═══════════════════');
      buffer.writeln('📋 *RECIBO DE PEDIDO*');
      buffer.writeln('');
      buffer.writeln('🆔 *ID:* ${pedidoId.substring(0, 12)}...');
      buffer.writeln('${mode == 'mesa' ? '🪑 *Mesa:*' : '👤 *Cliente:*'} ${mode == 'mesa' ? tableNumber : customerName}');
      buffer.writeln('📊 *Estado:* ${_getStatusDisplayName(status)}');
      if (pagado) {
        buffer.writeln('💳 *Pago:* ✅ PAGADO');
      }
      buffer.writeln('📅 *Fecha:* ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}');
      buffer.writeln('');
      buffer.writeln('📝 *PRODUCTOS PEDIDOS:*');
      buffer.writeln('─────────────────────');
      
      int index = 1;
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final String name = item['name']?.toString() ?? 'Producto';
          final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
          final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
          final double totalItem = price * quantity;
          
          buffer.writeln('$index. *$name*');
          buffer.writeln('   Cantidad: $quantity x \$${_formatearNumero(price)}');
          buffer.writeln('   Subtotal: \$${_formatearNumero(totalItem)}');
          
          final String notes = item['notes']?.toString() ?? '';
          if (notes.isNotEmpty) {
            buffer.writeln('   📝 Nota: $notes');
          }
          
          final List<dynamic> adicionales = item['adicionales'] as List<dynamic>? ?? [];
          if (adicionales.isNotEmpty) {
            final adicionalesText = adicionales.map((a) => 
              a is Map<String, dynamic> ? a['name']?.toString() ?? 'Adicional' : a.toString()
            ).join(', ');
            buffer.writeln('   ➕ Adicionales: $adicionalesText');
          }
          buffer.writeln('');
          index++;
        }
      }
      
      buffer.writeln('═══════════════════');
      buffer.writeln('💰 *TOTAL: \$${_formatearNumero(total)}*');
      buffer.writeln('');
      buffer.writeln('¡Gracias por su preferencia! 😊');
      buffer.writeln('');
      buffer.writeln('📱 Generado por Restaurante App');
      buffer.writeln('🕐 ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
      
      // Compartir el texto usando Share.share que es más compatible
      await Share.share(
        buffer.toString(),
        subject: 'Recibo del Pedido ${pedidoId.substring(0, 8)} - Restaurante App',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recibo compartido exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<Uint8List> _generarImagenRecibo(String pedidoId, Map<String, dynamic> data) async {
    // Extraer datos de manera segura
    final String mode = data['mode']?.toString() ?? 'desconocido';
    final String tableNumber = data['tableNumber']?.toString() ?? 'N/A';
    final String customerName = data['customerName']?.toString() ?? 'Cliente';
    final String status = data['status']?.toString() ?? 'desconocido';
    final bool pagado = data['pagado'] == true;
    final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
    
    // Calcular total
    double total = 0.0;
    try {
      if (data['total'] is num) {
        total = data['total'].toDouble();
      } else if (data['total'] is String) {
        total = double.tryParse(data['total']) ?? 0.0;
      }
      
      if (total == 0.0 && items.isNotEmpty) {
        total = items.fold<double>(0.0, (acc, item) {
          if (item is Map<String, dynamic>) {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            return acc + (price * quantity);
          }
          return acc;
        });
      }
    } catch (e) {
      total = 0.0;
    }
    
    // Extraer fecha
    DateTime fecha = DateTime.now();
    try {
      if (data['createdAt'] is Timestamp) {
        fecha = (data['createdAt'] as Timestamp).toDate();
      } else if (data['timestamp'] is Timestamp) {
        fecha = (data['timestamp'] as Timestamp).toDate();
      }
    } catch (e) {
      // Mantener fecha actual
    }
    
    // Crear contenido de texto para el recibo
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('RESTAURANTE APP');
    buffer.writeln('================');
    buffer.writeln('RECIBO DE PEDIDO');
    buffer.writeln('');
    buffer.writeln('ID: ${pedidoId.substring(0, 12)}...');
    buffer.writeln('${mode == 'mesa' ? 'Mesa' : 'Cliente'}: ${mode == 'mesa' ? tableNumber : customerName}');
    buffer.writeln('Estado: ${_getStatusDisplayName(status)}');
    if (pagado) {
      buffer.writeln('Pago: ✓ PAGADO');
    }
    buffer.writeln('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}');
    buffer.writeln('');
    buffer.writeln('ITEMS:');
    buffer.writeln('------');
    
    int index = 1;
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        final String name = item['name']?.toString() ?? 'Producto';
        final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final double totalItem = price * quantity;
        
        buffer.writeln('$index. $name');
        buffer.writeln('   x$quantity @ \$${_formatearNumero(price)} = \$${_formatearNumero(totalItem)}');
        
        final String notes = item['notes']?.toString() ?? '';
        if (notes.isNotEmpty) {
          buffer.writeln('   Nota: $notes');
        }
        
        final List<dynamic> adicionales = item['adicionales'] as List<dynamic>? ?? [];
        if (adicionales.isNotEmpty) {
          buffer.writeln('   Adicionales: ${adicionales.map((a) => a is Map<String, dynamic> ? a['name']?.toString() ?? 'Adicional' : a.toString()).join(', ')}');
        }
        buffer.writeln('');
        index++;
      }
    }
    
    buffer.writeln('================');
    buffer.writeln('TOTAL: \$${_formatearNumero(total)}');
    buffer.writeln('');
    buffer.writeln('¡Gracias por su preferencia!');
    buffer.writeln('Impreso: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    
    // Generar imagen con el contenido de texto
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(400, 700);
    
    // Fondo blanco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    
    // Crear TextPainter para el contenido
    final textPainter = TextPainter(
      text: TextSpan(
        text: buffer.toString(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontFamily: 'Courier',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: size.width - 40);
    textPainter.paint(canvas, const Offset(20, 20));
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('No se pudo generar la imagen del recibo');
    }
    
    return byteData.buffer.asUint8List();
  }
}

class _BuildCustomTabBar extends ConsumerWidget {
    final int pendingCount;
    final int completedCount;
    

    const _BuildCustomTabBar({
      required this.pendingCount,
      required this.completedCount,
    });

    @override   
    Widget build(BuildContext context, WidgetRef ref) {
      final unselectedColor = Colors.white.withValues(alpha: 0.65);
      final theme = Theme.of(context);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
          ),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: theme.primaryColor,
        unselectedLabelColor: unselectedColor,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
        tabs: [
          TabLabel(
            label: 'En Curso',
            count: pendingCount,
            color: const Color(0xFFF97316),
          ),
          TabLabel(
            label: 'Completados',
            count: completedCount,
            color: const Color(0xFFF97316),
          ),
        ],
      ),
    );
  }
}
