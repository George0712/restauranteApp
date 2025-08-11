import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NumberFormat _monedaCOP = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F23),
          elevation: 0,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Historial de Pedidos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En Curso'),
              Tab(text: 'Completados'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F0F23),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: TabBarView(
            children: [
              _buildPedidosEnCurso(),
              _buildPedidosCompletados(),
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
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          
          DateTime fechaA = DateTime.now();
          DateTime fechaB = DateTime.now();
          
          try {
            if (dataA['createdAt'] is Timestamp) {
              fechaA = (dataA['createdAt'] as Timestamp).toDate();
            }
            if (dataB['createdAt'] is Timestamp) {
              fechaB = (dataB['createdAt'] as Timestamp).toDate();
            }
          } catch (e) {
            // Usar fecha actual si hay error
          }
          
          return fechaB.compareTo(fechaA);
        });

        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildPedidoCard(docs[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPedidosCompletados() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pedido')
          .where('status', whereIn: ['terminado', 'cancelado', 'completado', 'entregado', 'pagado'])
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
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          
          DateTime fechaA = DateTime.now();
          DateTime fechaB = DateTime.now();
          
          try {
            if (dataA['createdAt'] is Timestamp) {
              fechaA = (dataA['createdAt'] as Timestamp).toDate();
            }
            if (dataB['createdAt'] is Timestamp) {
              fechaB = (dataB['createdAt'] as Timestamp).toDate();
            }
          } catch (e) {
            // Usar fecha actual si hay error
          }
          
          return fechaB.compareTo(fechaA);
        });

        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildPedidoCard(docs[index]);
            },
          ),
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
      final data = pedido.data() as Map<String, dynamic>;
      
      // Manejo robusto de la fecha
      DateTime fecha;
      try {
        if (data['createdAt'] is Timestamp) {
          fecha = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          fecha = DateTime.parse(data['createdAt']);
        } else {
          fecha = DateTime.now();
        }
      } catch (e) {
        fecha = DateTime.now();
      }

      final items = data['items'] as List<dynamic>? ?? [];
      final total = data['total'] as int? ?? 0;
      final status = data['status'] as String? ?? 'desconocido';
      
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color.fromRGBO(255, 255, 255, 0.1),
        child: ListTile(
          title: Text(
            data['mode'] == 'mesa' 
                ? 'Mesa ${data['tableNumber'] ?? 'N/A'}' 
                : data['customerName'] ?? 'Cliente',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha: ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color:Color.fromRGBO(255, 255, 255, 0.7)),
              ),
              Text(
                'Total: ${_monedaCOP.format(total)}',
                style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.7)),
              ),
              Text(
                'Estado: $status',
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Items: ${items.length}',
                style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.7)),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onTap: () => _mostrarDetallesPedido(pedido.id),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color.fromRGBO(244, 67, 54, 0.1),
        child: ListTile(
          title: const Text(
            'Error al cargar pedido',
            style: TextStyle(color: Colors.red),
          ),
          subtitle: Text(
            'ID: ${pedido.id}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
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
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  void _mostrarDetallesPedido(String pedidoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Detalles del Pedido',
          style: TextStyle(color: Colors.white),
        ),
        content: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('pedido').doc(pedidoId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            try {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final items = data['items'] as List<dynamic>? ?? [];
              final total = data['total'] as int? ?? 0;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['mode'] == 'mesa' 
                          ? 'Mesa ${data['tableNumber'] ?? 'N/A'}' 
                          : 'Cliente: ${data['customerName'] ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estado: ${data['status'] ?? 'desconocido'}',
                      style: TextStyle(
                        color: _getStatusColor(data['status'] ?? ''),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Items del pedido:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          'No hay items en este pedido',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ...items.map((item) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Item sin nombre',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Cantidad: ${item['quantity'] ?? 0}',
                                    style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.7)),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _monedaCOP.format(item['price'] ?? 0),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(76, 175, 80, 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        'Total: ${_monedaCOP.format(total)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            } catch (e) {
              return const Text(
                'Error al cargar detalles del pedido',
                style: TextStyle(color: Colors.red),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}