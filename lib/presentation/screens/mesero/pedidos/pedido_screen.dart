import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/providers/login/auth_service.dart';
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart';
import 'package:restaurante_app/presentation/screens/mesero/pedidos/detalle_producto_screen.dart';
import 'package:restaurante_app/presentation/widgets/carrito_bottom.dart';
import 'package:restaurante_app/presentation/widgets/payment_bottom_sheet.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';
import 'package:restaurante_app/presentation/providers/mesero/mesas_provider.dart';
import 'package:uuid/uuid.dart';

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
  TabController? _tabController;
  String categoriaSeleccionada = 'Todas';
  String categoriaIdSeleccionada = '';
  String filtroTexto = '';
  final TextEditingController _searchController = TextEditingController();
  bool pedidoConfirmado = false;
  bool _agregandoExtras = false;

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
      _tabController?.dispose();
      _tabController =
          TabController(length: nombresCategorias.length, vsync: this);
    });
  }

  // ✅ NUEVO: Metodo para cargar el carrito desde Firestore
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
    _tabController?.dispose();
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
              if (_agregandoExtras) _buildExtrasBanner(),
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

  Widget _buildExtrasBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.add_circle_outline,
                color: Color(0xFF2563EB), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agregando productos al pedido en preparacion',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Estos articulos se sumaran al pedido ya enviado a cocina. Los productos actuales no podran modificarse ni eliminarse.',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 12,
                      height: 1.35,
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
        onRegistrarPago: () { _registrarPago(context); },
        onModificarPedido: () => _modificarPedido(context),
        onCancelarPedido: () => _cancelarPedido(context),
        onActualizarPedido: () { _actualizarPedidoExistente(context); },
        onReportIssue: () => _reportarProblema(context),
        onGenerarTicket: () => _mostrarTicketDesdeCarrito(context),
      ),
    );
  }
  Future<void> _confirmarPedidoSinPagar(BuildContext sheetContext) async {
    final carrito = ref.read(carritoProvider);
    if (carrito.isEmpty) {
      _mostrarError(context, 'Agrega productos antes de enviar el pedido.');
      return;
    }
    try {
      await _crearActualizarPedido(carrito, 'pendiente', false);
      await _cargarCarritoDelPedido();
      Navigator.of(sheetContext).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado a cocina')),
      );
    } catch (e) {
      _mostrarError(context, 'Error al confirmar pedido: $e');
    }
  }
  Future<void> _confirmarPedidoYPagar(BuildContext sheetContext) async {
    final carrito = ref.read(carritoProvider);
    if (carrito.isEmpty) {
      _mostrarError(context, 'Agrega productos antes de generar el ticket.');
      return;
    }
    try {
      await _crearActualizarPedido(carrito, 'pendiente', false);
      final ticketInfo =
          await _generarTicketFactura(context, mostrarMensaje: false);
      await _cargarCarritoDelPedido();
      Navigator.of(sheetContext).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado y ticket generado')),
      );
      await _abrirTicketPreview(ticketId: ticketInfo?['ticketId'] as String?);
    } catch (e) {
      _mostrarError(context, 'Error al confirmar y generar ticket: $e');
    }
  }
  Future<void> _actualizarPedidoExistente(BuildContext sheetContext) async {
    final carrito = ref.read(carritoProvider);
    if (carrito.isEmpty) {
      _mostrarError(context, 'No hay cambios para enviar a cocina.');
      return;
    }
    try {
      final pedidoDoc = await FirebaseFirestore.instance
          .collection('pedido')
          .doc(widget.pedidoId)
          .get();
      final data = pedidoDoc.data();
      final estadoActual = (data?['status'] ?? 'pendiente').toString();
      final pagadoActual = data?['pagado'] == true;
      await _crearActualizarPedido(carrito, estadoActual, pagadoActual);
      await _cargarCarritoDelPedido();
      Navigator.of(sheetContext).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido actualizado y enviado a cocina')),
      );
    } catch (e) {
      _mostrarError(context, 'Error al actualizar el pedido: $e');
    }
  }
  Future<void> _registrarPago(BuildContext sheetContext) async {
    Map<String, dynamic>? pedidoData;
    try {
      final pedidoSnapshot = await FirebaseFirestore.instance
          .collection('pedido')
          .doc(widget.pedidoId)
          .get();
      if (!pedidoSnapshot.exists) {
        _mostrarError(context, 'No encontramos informacion del pedido.');
        return;
      }
      pedidoData = pedidoSnapshot.data() as Map<String, dynamic>;
      final estado =
          (pedidoData['status'] ?? 'pendiente').toString().toLowerCase();
      final estadoNormalizado = estado.replaceAll(' ', '_');
      final pagado = pedidoData['pagado'] == true;
      final esEstadoTerminado = estadoNormalizado == 'terminado' ||
          estadoNormalizado == 'entregado' ||
          estadoNormalizado == 'completado';
      if (!pagado && !esEstadoTerminado) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debes marcar el pedido como terminado antes de registrar el pago.',
            ),
          ),
        );
        return;
      }
    } catch (e) {
      _mostrarError(context, 'No se pudo preparar el pago: $e');
      return;
    }
    Navigator.of(sheetContext).pop();
    try {
      final pagoCompletado = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentBottomSheet(
          pedidoId: widget.pedidoId,
          onPaid: () => ref.read(carritoProvider.notifier).limpiarCarrito(),
        ),
      );
      if (pagoCompletado == true) {
        await _cargarCarritoDelPedido();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado correctamente.')),
        );
        final ticketInfo =
            await _generarTicketFactura(context, mostrarMensaje: false);
        await _abrirTicketPreview(ticketId: ticketInfo?['ticketId'] as String?);
        final mesaLiberada =
            await _liberarMesaTrasPago(pedidoData: pedidoData);
        if (mesaLiberada && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La mesa se liberó automaticamente después del pago.',
              ),
            ),
          );
          _volverAPantallaDeMesas();
        }
      }
    } catch (e) {
      _mostrarError(context, 'Error al registrar el pago: $e');
    }
  }

  Future<bool> _liberarMesaTrasPago({Map<String, dynamic>? pedidoData}) async {
    try {
      Map<String, dynamic>? data = pedidoData;
      if (data == null) {
        final pedidoSnapshot = await FirebaseFirestore.instance
            .collection('pedido')
            .doc(widget.pedidoId)
            .get();
        data = pedidoSnapshot.data();
      }
      final mesaIdRaw = widget.mesaId ?? data?['mesaId']?.toString();
      final mesaIdInt = mesaIdRaw is String
          ? int.tryParse(mesaIdRaw)
          : (mesaIdRaw is int ? mesaIdRaw : null);
      if (mesaIdInt == null) {
        return false;
      }
      MesaModel? mesaActual;
      final mesas = ref.read(mesasMeseroProvider);
      for (final mesa in mesas) {
        if (mesa.id == mesaIdInt) {
          mesaActual = mesa;
          break;
        }
      }
      mesaActual ??= await _obtenerMesaDesdeFirestore(mesaIdInt);
      if (mesaActual == null) {
        return false;
      }
      final mesaActualizada = mesaActual.copyWith(
        estado: 'disponible',
        cliente: null,
        tiempo: null,
        total: null,
        pedidoId: null,
        horaOcupacion: null,
        fechaReserva: null,
      );
      await ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);
      return true;
    } catch (e) {
      debugPrint('No se pudo liberar la mesa tras el pago: $e');
      return false;
    }
  }
  Future<MesaModel?> _obtenerMesaDesdeFirestore(int mesaId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('mesa')
          .where('id', isEqualTo: mesaId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return null;
      }
      final doc = query.docs.first;
      return MesaModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      debugPrint('No se encontro la mesa $mesaId para liberar: $e');
      return null;
    }
  }

  Future<void> _mostrarTicketDesdeCarrito(BuildContext sheetContext) async {
    final ticketInfo =
        await _generarTicketFactura(context, mostrarMensaje: true);
    if (ticketInfo == null) {
      return;
    }
    Navigator.of(sheetContext).pop();
    await _abrirTicketPreview(ticketId: ticketInfo['ticketId'] as String?);
  }

  Future<void> _abrirTicketPreview({String? ticketId}) async {
    if (!mounted) return;
    final queryParams = <String, String>{};
    if (widget.mesaId != null && widget.mesaId!.isNotEmpty) {
      queryParams['mesaId'] = widget.mesaId!;
    }
    final mesaNombre = _decodeIfNeeded(widget.mesaNombre);
    final clienteNombre = _decodeIfNeeded(widget.clienteNombre);
    if (mesaNombre != null && mesaNombre.isNotEmpty) {
      queryParams['mesaNombre'] = mesaNombre;
    }
    if (clienteNombre != null && clienteNombre.isNotEmpty) {
      queryParams['clienteNombre'] = clienteNombre;
    }
    if (ticketId != null && ticketId.isNotEmpty) {
      queryParams['ticketId'] = ticketId;
    }
    final uri = Uri(
      path: '/mesero/pedidos/ticket/${widget.pedidoId}',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    context.push(uri.toString());
  }

  Future<void> _actualizarMesaTrasCancelacion({
    required int mesaIdInt,
    required String nuevoPedidoId,
    String? clienteNombre,
  }) async {
    try {
      final mesas = ref.read(mesasMeseroProvider);
      MesaModel? mesaActual;
      for (final mesa in mesas) {
        if (mesa.id == mesaIdInt) {
          mesaActual = mesa;
          break;
        }
      }
      if (mesaActual == null) {
        return;
      }
      final mesaActualizada = mesaActual.copyWith(
        estado: 'ocupada',
        pedidoId: nuevoPedidoId,
        cliente: clienteNombre ?? mesaActual.cliente,
        horaOcupacion: mesaActual.horaOcupacion ?? DateTime.now(),
      );
      await ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);
    } catch (e) {
      debugPrint('No se pudo actualizar la mesa tras cancelacion: $e');
    }
  }

  void _volverAPantallaDeMesas() {
    if (!mounted) {
      return;
    }
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/mesero/pedidos/mesas');
    }
  }

  Future<Map<String, dynamic>?> _generarTicketFactura(
      BuildContext context, {bool mostrarMensaje = true}) async {
    try {
      final pedidoRef = FirebaseFirestore.instance
          .collection('pedido')
          .doc(widget.pedidoId);
      final pedidoSnapshot = await pedidoRef.get();
      if (!pedidoSnapshot.exists) {
        if (mostrarMensaje) {
          _mostrarError(context, 'Aun no hay un pedido para generar un ticket.');
        }
        return null;
      }
      final data = pedidoSnapshot.data() as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? [];
      if (items.isEmpty) {
        if (mostrarMensaje) {
          _mostrarError(
            context,
            'Agrega productos al pedido antes de generar un ticket.',
          );
        }
        return null;
      }
      final totalPedido = _asDouble(data['total'] ?? data['subtotal'] ?? 0);
      final subtotalPedido = _asDouble(data['subtotal'] ?? totalPedido);
      final pagado = data['pagado'] == true;
      final estado = (data['status'] ?? 'pendiente').toString();
      final numeroTicket =
          '${widget.pedidoId}-${DateTime.now().millisecondsSinceEpoch}';
      final ticketForFirestore = {
        'numeroTicket': numeroTicket,
        'pedidoId': widget.pedidoId,
        'createdAt': FieldValue.serverTimestamp(),
        'mesaId': data['mesaId'],
        'mesaNombre': data['mesaNombre'],
        'clienteNombre': data['clienteNombre'],
        'subtotal': subtotalPedido,
        'total': totalPedido,
        'pagado': pagado,
      'paymentStatus': pagado ? 'paid' : 'pending',
        'estadoPedido': estado,
        'items': items,
      };
      final ticketRef = await pedidoRef.collection('tickets').add(ticketForFirestore);
      await pedidoRef.set({
        'ultimoTicketGeneradoAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mostrarMensaje && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket generado correctamente')),
        );
      }
      return {
        'ticketId': ticketRef.id,
      };
    } catch (e) {
      if (mostrarMensaje) {
        _mostrarError(context, 'Error al generar ticket: $e');
      } else {
        debugPrint('Error al generar ticket: $e');
      }
      return null;
    }
  }

  void _modificarPedido(BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    if (!mounted) return;
    setState(() {
      _agregandoExtras = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Puedes agregar o quitar productos del pedido'),
      ),
    );
  }

  Future<void> _cancelarPedido(BuildContext sheetContext) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('Estas seguro de que quieres cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Si, cancelar'),
          ),
        ],
      ),
    );
    if (shouldCancel == true) {
      try {
        final pedidoRef = FirebaseFirestore.instance
            .collection('pedido')
            .doc(widget.pedidoId);
        final pedidoSnapshot = await pedidoRef.get();
        final pedidoData = pedidoSnapshot.data();
        UserModel? user;
        try {
          user = await ref.read(userModelProvider.future);
        } catch (_) {
          user = null;
        }
        final updateData = <String, dynamic>{
          'status': 'cancelado',
          'pagado': false,
          'paymentStatus': 'void',
          'updatedAt': FieldValue.serverTimestamp(),
          'cancelledAt': FieldValue.serverTimestamp(),
        };
        if (user != null) {
          updateData['cancelledBy'] = user.uid;
          updateData['cancelledByName'] =
              '${user.nombre} ${user.apellidos}'.trim();
        }
        updateData['payment'] = FieldValue.delete();
        updateData['paidAt'] = FieldValue.delete();
        await pedidoRef.update(updateData);
        ref.read(carritoProvider.notifier).limpiarCarrito();
        final mesaIdInt = widget.mesaId != null
            ? int.tryParse(widget.mesaId!)
            : pedidoData?['mesaId'] as int?;
        final mesaNombre = _decodeIfNeeded(
          widget.mesaNombre ?? pedidoData?['mesaNombre']?.toString(),
        );
        final clienteNombre = _decodeIfNeeded(
          widget.clienteNombre ?? pedidoData?['clienteNombre']?.toString(),
        );
        if (mesaIdInt != null) {
          final nuevoPedidoId = const Uuid().v4();
          final etiquetaMesa = (mesaNombre != null && mesaNombre.trim().isNotEmpty)
              ? mesaNombre
              : 'Mesa $mesaIdInt';
          final nuevoPedidoData = <String, dynamic>{
            'id': nuevoPedidoId,
            'items': const [],
            'initialItems': const [],
            'subtotal': 0,
            'total': 0,
            'status': 'nuevo',
            'pagado': false,
            'paymentStatus': 'pending',
            'mode': pedidoData?['mode'] ?? 'mesa',
            'tableNumber': etiquetaMesa,
            'meseroId': user?.uid ?? pedidoData?['meseroId'],
            'meseroNombre': user != null
                ? '${user.nombre} ${user.apellidos}'.trim()
                : pedidoData?['meseroNombre'],
            'mesaId': mesaIdInt,
            'mesaNombre': etiquetaMesa,
            'clienteNombre': clienteNombre,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          await FirebaseFirestore.instance
              .collection('pedido')
              .doc(nuevoPedidoId)
              .set(nuevoPedidoData);
          await _actualizarMesaTrasCancelacion(
            mesaIdInt: mesaIdInt,
            nuevoPedidoId: nuevoPedidoId,
            clienteNombre: clienteNombre,
          );
          Navigator.of(sheetContext).pop();
          if (!mounted) return;
          setState(() {
            _agregandoExtras = false;
            pedidoConfirmado = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pedido cancelado. Se creo un nuevo pedido para la mesa.',
              ),
            ),
          );
        } else {
          Navigator.of(sheetContext).pop();
          if (!mounted) return;
          setState(() {
            _agregandoExtras = false;
            pedidoConfirmado = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido cancelado.')),
          );
        }
        if (!mounted) return;
        _volverAPantallaDeMesas();
      } catch (e) {
        _mostrarError(context, 'Error al cancelar pedido: $e');
      }
    }
  }

   Future<void> _crearActualizarPedido(
      List<ItemCarrito> carrito, String status, bool pagado) async {
    final adicionalesAsync = await ref.read(additionalProvider.future);
    // Obtener informacion del mesero
    UserModel? user;
    try {
      user = await ref.read(userModelProvider.future);
    } catch (e) {
      user = null;
    }
    // ... codigo de items y totales igual ...
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
    final mesaIdInt =
        widget.mesaId != null ? int.tryParse(widget.mesaId!) : null;
    final mesaNombre = _decodeIfNeeded(widget.mesaNombre);
    final clienteNombre = _decodeIfNeeded(widget.clienteNombre);
    final tableNumber = mesaNombre ??
        (mesaIdInt != null ? 'Mesa $mesaIdInt' : null) ??
        widget.pedidoId;

    final pedidoData = <String, dynamic>{
      'id': widget.pedidoId,
      'items': items,
      'subtotal': subtotal,
      'total': subtotal,
      'status': status,
      'pagado': pagado,
      'paymentStatus': pagado ? 'paid' : 'pending',
      'mode': 'mesa',
      'tableNumber': tableNumber,
      'meseroId': user?.uid,
      'meseroNombre': user != null
          ? '${user.nombre} ${user.apellidos}'
          : 'Mesero desconocido',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (mesaIdInt != null) {
      pedidoData['mesaId'] = mesaIdInt;
    }
    if (mesaNombre != null && mesaNombre.trim().isNotEmpty) {
      pedidoData['mesaNombre'] = mesaNombre;
    }
    if (clienteNombre != null && clienteNombre.trim().isNotEmpty) {
      pedidoData['clienteNombre'] = clienteNombre;
    }

    await FirebaseFirestore.instance
        .collection('pedido')
        .doc(widget.pedidoId)
        .set(pedidoData, SetOptions(merge: true));
    setState(() {
      pedidoConfirmado = status != 'nuevo';
    });
  }
  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String? _decodeIfNeeded(String? value) {
    if (value == null) return null;
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  void _mostrarError(BuildContext context, String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  Future<void> _reportarProblema(BuildContext context) async {
    // TODO: Implement report issue functionality
    SnackbarHelper.showInfo('Funcionalidad de reporte de problemas próximamente');
   
  }
}


