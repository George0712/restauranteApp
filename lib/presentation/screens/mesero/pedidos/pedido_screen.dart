import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/providers/login/auth_service.dart';
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart';
import 'package:restaurante_app/presentation/screens/mesero/pedidos/detalle_producto_screen.dart';
import 'package:restaurante_app/presentation/widgets/carrito_bottom.dart';

class SeleccionProductosScreen extends ConsumerStatefulWidget {
  final String pedidoId;
  final String? mesaId;
  final String? mesaNombre;
  final String? clienteNombre;

  const SeleccionProductosScreen({
    super.key,
    required this.pedidoId,
    this.mesaId,
    this.mesaNombre,
    this.clienteNombre,
  });

  @override
  ConsumerState<SeleccionProductosScreen> createState() =>
      _SeleccionProductosScreenState();
}

class _SeleccionProductosScreenState
    extends ConsumerState<SeleccionProductosScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String categoriaSeleccionada = 'Todas';
  String categoriaIdSeleccionada = '';
  String filtroTexto = '';
  final TextEditingController _searchController = TextEditingController();
  bool pedidoConfirmado = false;

  @override
  void initState() {
    super.initState();

    // Cargar carrito cuando se inicia la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarCarritoDelPedido();
    });

    final categoriasAsync = ref.read(categoryDisponibleProvider);
    categoriasAsync.whenData((categorias) {
      final nombresCategorias = [
        'Todas',
        ...categorias.map((c) => c.name).toList()
      ];
      _tabController =
          TabController(length: nombresCategorias.length, vsync: this);
    });
  }

  // ✅ NUEVO: Método para cargar el carrito desde Firestore
  Future<void> _cargarCarritoDelPedido() async {
    try {
      final productos = await ref.read(productsProvider.future);
      final adicionales = await ref.read(additionalProvider.future);

      await ref.read(carritoProvider.notifier).cargarDesdeFirestore(
            widget.pedidoId,
            productos,
            adicionales,
          );
    } catch (e) {
      print('Error cargando carrito del pedido: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productsProvider);
    final carrito = ref.watch(carritoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, carrito),
      body: productosAsync.when(
        data: (productos) {
          final categorias = [
            'Todas',
            ...productos.map((p) => p.category).toSet().toList()
          ];
          return Column(
            children: [
              _buildSearchBar(),
              _buildCategorias(categorias),
              Expanded(
                child: _buildProductosGrid(productos),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: _buildCarritoBottomBar(context, carrito),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, List<ItemCarrito> carrito) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_outlined,
            color: Colors.black54),
        onPressed: () => context.pop(),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccionar Productos',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          Text(
            'Agregar al pedido',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: Colors.black54),
              onPressed: () => _mostrarCarrito(context),
            ),
            if (carrito.isNotEmpty)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    carrito
                        .fold(0, (sum, item) => sum + item.cantidad)
                        .toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          suffixIcon: filtroTexto.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => filtroTexto = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) => setState(() => filtroTexto = value),
      ),
    );
  }

  Widget _buildCategorias(List<String> categorias) {
    final categoriasAsync = ref.watch(categoryDisponibleProvider);

    return categoriasAsync.when(
      data: (categoriasList) {
        final nombresCategorias = [
          'Todas',
          ...categoriasList.map((c) => c.name).toList()
        ];

        return Container(
          height: 50,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: nombresCategorias.length,
            itemBuilder: (context, index) {
              final categoria = nombresCategorias[index];
              final isSelected = categoriaSeleccionada == categoria;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    categoriaSeleccionada = categoria;
                    if (index == 0) {
                      categoriaIdSeleccionada = '';
                    } else {
                      categoriaIdSeleccionada = categoriasList[index - 1].id;
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Color.fromRGBO(
                                Theme.of(context).primaryColor.red,
                                Theme.of(context).primaryColor.green,
                                Theme.of(context).primaryColor.blue,
                                0.3,
                              )
                            : const Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    categoria,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildProductosGrid(List<ProductModel> productos) {
    final productosFiltrados = productos.where((producto) {
      final matchesCategoria = categoriaIdSeleccionada.isEmpty ||
          producto.category == categoriaIdSeleccionada;
      final matchesTexto = filtroTexto.isEmpty ||
          producto.name.toLowerCase().contains(filtroTexto.toLowerCase());
      return matchesCategoria && matchesTexto;
    }).toList();

    if (productosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        itemCount: productosFiltrados.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          childAspectRatio: 0.8,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final producto = productosFiltrados[index];
          return _buildProductoCard(producto);
        },
      ),
    );
  }

  Widget _buildProductoCard(ProductModel producto) {
    return GestureDetector(
      onTap: () => _mostrarDetalleProducto(producto),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    if (producto.photo != null && producto.photo!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          producto.photo!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.fastfood,
                                size: 48,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Center(
                        child: Icon(
                          Icons.fastfood,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    if (!producto.disponible)
                      Container(
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.6),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'No Disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        producto.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${producto.price.toStringAsFixed(0).replaceAllMapped(
                                RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]}.',
                              )}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: producto.disponible
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildCarritoBottomBar(
      BuildContext context, List<ItemCarrito> carrito) {
    if (carrito.isEmpty) return null;

    final total = carrito.fold<double>(0, (sum, item) {
      final precioBase = item.precioUnitario * item.cantidad;
      final precioAdicionales = item.adicionales?.fold<double>(
            0,
            (sum, adicional) => sum + (adicional.price * item.cantidad),
          ) ??
          0;
      return sum + precioBase + precioAdicionales;
    });
    final cantidadTotal = carrito.fold(0, (sum, item) => sum + item.cantidad);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$cantidadTotal ${cantidadTotal == 1 ? 'item' : 'items'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _mostrarCarrito(context),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Ver Carrito'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalleProducto(ProductModel producto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetalleProductoScreen(producto: producto),
    );
  }

  void _mostrarCarrito(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CarritoBottomSheet(
        pedidoId: widget.pedidoId, // Pasar el ID del pedido
        onConfirmarSinPagar: () => _confirmarPedidoSinPagar(context),
        onConfirmarYPagar: () => _confirmarPedidoYPagar(context),
        onProcederPago: () => _procederAlPago(context),
        onModificarPedido: () => _modificarPedido(context),
        onCancelarPedido: () => _cancelarPedido(context),
      ),
    );
  }

  void _confirmarPedidoSinPagar(BuildContext context) async {
    try {
      final carrito = ref.read(carritoProvider);

      // ✅ Verificar estado actual
      final pedidoDoc = await FirebaseFirestore.instance
          .collection('pedido')
          .doc(widget.pedidoId)
          .get();

      if (pedidoDoc.exists) {
        final pedidoData = pedidoDoc.data() as Map<String, dynamic>;
        final estadoActual = pedidoData['status'] ?? 'nuevo';
        final items = pedidoData['items'] as List?;

        if (estadoActual != 'nuevo' && items != null && items.isNotEmpty) {
          // Ya está confirmado
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El pedido ya está confirmado')),
            );
            Navigator.pop(context);
          }
          return;
        }
      }

      // Proceder con la confirmación
      await _crearActualizarPedido(carrito, 'pendiente', false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido confirmado sin pagar')),
        );
      }
    } catch (e) {
      _mostrarError(context, 'Error al confirmar pedido: $e');
    }
  }

  void _confirmarPedidoYPagar(BuildContext context) async {
    try {
      final carrito = ref.read(carritoProvider);
      _crearActualizarPedido(carrito, 'pagado', true);

      // Limpiar carrito después del pago
      ref.read(carritoProvider.notifier).limpiarCarrito();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pedido confirmado y pagado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _mostrarError(context, 'Error al confirmar y pagar: $e');
    }
  }

  void _procederAlPago(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('pedido')
          .doc(widget.pedidoId)
          .update({
        'status': 'pagado',
        'pagado': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Limpiar carrito después del pago
      ref.read(carritoProvider.notifier).limpiarCarrito();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago procesado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _mostrarError(context, 'Error al procesar pago: $e');
    }
  }

  void _modificarPedido(BuildContext context) {
    Navigator.pop(context); // Cerrar el carrito y permitir modificaciones
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Puedes agregar o quitar productos del pedido')),
    );
  }

  void _cancelarPedido(BuildContext context) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content:
            const Text('¿Estás seguro de que quieres cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      try {
        await FirebaseFirestore.instance
            .collection('pedido')
            .doc(widget.pedidoId)
            .update({
          'status': 'cancelado',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Limpiar carrito
        ref.read(carritoProvider.notifier).limpiarCarrito();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido cancelado')),
          );
          Navigator.pop(context);
          context.pop(); // Volver a la pantalla anterior
        }
      } catch (e) {
        _mostrarError(context, 'Error al cancelar pedido: $e');
      }
    }
  }

  Future<void> _crearActualizarPedido(
      List<ItemCarrito> carrito, String status, bool pagado) async {
    final adicionalesAsync = await ref.read(additionalProvider.future);

    // Obtener información del mesero

    UserModel? user;
    try {
      user = await ref.read(userModelProvider.future);
      user = await ref.read(userModelProvider.future);
    } catch (e) {
      user = null;
    }

    // ... código de items y totales igual ...

    final items = carrito.map((item) {
      final adicionales = item.modificacionesSeleccionadas
          .map((id) => adicionalesAsync.firstWhere((a) => a.id == id))
          .toList();

      return {
        'productId': item.producto.id,
        'name': item.producto.name,
        'price': item.precioUnitario,
        'quantity': item.cantidad,
        'notes': item.notas,
        'adicionales': adicionales.map((a) => a.toMap()).toList(),
      };
    }).toList();

    final subtotal = carrito.fold<double>(0, (sum, item) {
      final precioBase = item.precioUnitario * item.cantidad;
      final precioAdicionales = item.adicionales?.fold<double>(
            0,
            (sum, adicional) => sum + (adicional.price * item.cantidad),
          ) ??
          0;
      return sum + precioBase + precioAdicionales;
    });

    // ✅ USAR LOS PARÁMETROS PASADOS DESDE LA URL:
    final mesaIdInt =
        widget.mesaId != null ? int.tryParse(widget.mesaId!) : null;

    print("🔧 DATOS DE MESA RECIBIDOS:");
    print("   - Mesa ID: $mesaIdInt");
    print("   - Mesa Nombre: ${widget.mesaNombre}");
    print("   - Cliente: ${widget.clienteNombre}");

    // Crear documento con toda la información
    // ✅ IMPORTANTE: Solo crear/actualizar cuando realmente se confirma
    await FirebaseFirestore.instance
        .collection('pedido')
        .doc(widget.pedidoId)
        .set({
      'id': widget.pedidoId,
      'items': items,
      'subtotal': subtotal,
      'total': subtotal,
      'status': 'pendiente',
      'mode': 'mesa',
      'tableNumber': widget.pedidoId,
      'meseroId': user?.uid,
      'meseroNombre': user != null
          ? '${user.nombre} ${user.apellidos}'
          : 'Mesero desconocido',
      // ✅ USAR LOS DATOS PASADOS:
      'mesaId': mesaIdInt,
      'mesaNombre': widget.mesaNombre,
      'clienteNombre': widget.clienteNombre,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      pedidoConfirmado = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido confirmado exitosamente')),
      );
      Navigator.pop(context);
    }
  }

  void _mostrarError(BuildContext context, String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }
}
