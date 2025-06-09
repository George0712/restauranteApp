import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialMeseroScreen extends StatefulWidget {
  const HistorialMeseroScreen({super.key});

  @override
  State<HistorialMeseroScreen> createState() => _HistorialMeseroScreenState();
}

class _HistorialMeseroScreenState extends State<HistorialMeseroScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _verificarMeseroId();
  }

  void _verificarMeseroId() {
    final meseroId = _auth.currentUser?.uid;
    print('ID del mesero actual: $meseroId');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
        extendBodyBehindAppBar: true,
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
    final meseroId = _auth.currentUser?.uid;
    print('Consultando pedidos en curso para mesero: $meseroId');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pedido')
          .where('meseroId', isEqualTo: meseroId)
          .where('status', whereIn: ['pendiente', 'preparando'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error en pedidos en curso: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar los pedidos: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, color: Colors.white54, size: 48),
                SizedBox(height: 16),
                Text(
                  'No hay pedidos en curso',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        print('Pedidos encontrados: ${snapshot.data!.docs.length}');
        return ListView.builder(
          padding: const EdgeInsets.only(top: 100),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final pedido = snapshot.data!.docs[index];
            print('Pedido ${index + 1}: ${pedido.data()}');
            return _buildPedidoCard(pedido);
          },
        );
      },
    );
  }

  Widget _buildPedidosCompletados() {
    final meseroId = _auth.currentUser?.uid;
    print('Consultando pedidos completados para mesero: $meseroId');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('pedido')
          .where('meseroId', isEqualTo: meseroId)
          .where('status', whereIn: ['terminado', 'cancelado'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error en pedidos completados: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar los pedidos: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, color: Colors.white54, size: 48),
                SizedBox(height: 16),
                Text(
                  'No hay pedidos completados',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        print('Pedidos completados encontrados: ${snapshot.data!.docs.length}');
        return ListView.builder(
          padding: const EdgeInsets.only(top: 100),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final pedido = snapshot.data!.docs[index];
            print('Pedido completado ${index + 1}: ${pedido.data()}');
            return _buildPedidoCard(pedido);
          },
        );
      },
    );
  }

  Widget _buildPedidoCard(DocumentSnapshot pedido) {
    try {
      final data = pedido.data() as Map<String, dynamic>;
      final fecha = (data['createdAt'] as Timestamp).toDate();
      final items = data['items'] as List<dynamic>;
      final total = data['total'] as int;
      
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white.withOpacity(0.1),
        child: ListTile(
          title: Text(
            data['mode'] == 'mesa' ? 'Mesa ${data['tableNumber']}' : data['customerName'] ?? 'Cliente',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha: ${fecha.toString().split('.')[0]}',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              Text(
                'Total: \$${(total / 100).toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              Text(
                'Estado: ${data['status']}',
                style: TextStyle(
                  color: _getStatusColor(data['status']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onTap: () => _mostrarDetallesPedido(pedido.id),
        ),
      );
    } catch (e) {
      print('Error al construir tarjeta de pedido: $e');
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.red.withOpacity(0.1),
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
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'preparando':
        return Colors.blue;
      case 'terminado':
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
              return const Center(child: CircularProgressIndicator());
            }

            try {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final items = data['items'] as List<dynamic>;
              final total = data['total'] as int;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['mode'] == 'mesa' ? 'Mesa ${data['tableNumber']}' : 'Cliente: ${data['customerName']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estado: ${data['status']}',
                      style: TextStyle(
                        color: _getStatusColor(data['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Items:',
                      style: TextStyle(color: Colors.white),
                    ),
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        '• ${item['name']} x${item['quantity']} - \$${(item['price'] / 100).toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    )),
                    const SizedBox(height: 8),
                    Text(
                      'Total: \$${(total / 100).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            } catch (e) {
              print('Error al mostrar detalles: $e');
              return Text(
                'Error al cargar detalles: $e',
                style: const TextStyle(color: Colors.red),
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
