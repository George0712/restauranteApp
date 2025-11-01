import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/controllers/mesero/carrito_controller.dart';
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
  final String orderMode;
  final String? clienteTelefono;
  final String? clienteDireccion;
  final String? clienteReferencia;

  const SeleccionProductosScreen({
    super.key,
    required this.pedidoId,
    this.mesaId,
    this.mesaNombre,
    this.clienteNombre,
    this.orderMode = 'mesa',
    this.clienteTelefono,
    this.clienteDireccion,
    this.clienteReferencia,
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
  bool _isScrolled = false;

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
      developer.log('Error cargando carrito del pedido: $e', error: e);
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
      appBar: _buildAnimatedAppBar(context, carrito),
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
        child: SafeArea(
          child: productosAsync.when(
            data: (productos) {
              final categorias = [
                'Todas',
                ...productos.map((p) => p.category).toSet().toList()
              ];
              return Column(
                children: [
                  // Header normal solo cuando NO está scrolled
                  if (!_isScrolled) ...[
                    _buildHeader(),
                    _buildSearchBar(),
                    _buildCategorias(categorias),
                  ],
                  if (_agregandoExtras) _buildExtrasBanner(),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo is ScrollUpdateNotification) {
                          final pixels = scrollInfo.metrics.pixels;
                          // Usar histéresis para evitar rebotes
                          final shouldBeScrolled = _isScrolled
                              ? pixels > 20 // threshold más bajo para volver
                              : pixels > 40; // threshold más alto para activar

                          if (shouldBeScrolled != _isScrolled) {
                            setState(() {
                              _isScrolled = shouldBeScrolled;
                            });
                          }
                        }
                        return false;
                      },
                      child: _buildProductosGrid(productos),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar productos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildCarritoBottomBar(context, carrito),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar(
      BuildContext context, List<ItemCarrito> carrito) {
    return PreferredSize(
      preferredSize: Size.fromHeight(_isScrolled ? 100 : 56),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: _isScrolled
              ? LinearGradient(
                  colors: [
                    const Color(0xFF0F0F23).withValues(alpha: 0.96),
                    const Color(0xFF1A1A2E).withValues(alpha: 0.96),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: _isScrolled
              ? Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                )
              : null,
          boxShadow: _isScrolled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: SafeArea(
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: _isScrolled
                  ? _buildCompactAppBarContent(context, carrito)
                  : _buildNormalAppBarContent(context, carrito),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalAppBarContent(
      BuildContext context, List<ItemCarrito> carrito) {
    return Padding(
      key: const ValueKey('normal'),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_outlined,
              color: Colors.white,
            ),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
                onPressed: () => _mostrarCarrito(context),
                tooltip: 'Ver carrito',
              ),
              if (carrito.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFF7C3AED),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      carrito
                          .fold(0, (total, item) => total + item.cantidad)
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
        ],
      ),
    );
  }

  Widget _buildCompactAppBarContent(
      BuildContext context, List<ItemCarrito> carrito) {
    final categoriasAsync = ref.watch(categoryDisponibleProvider);

    return categoriasAsync.when(
      data: (categoriasList) {
        final nombresCategorias = [
          'Todas',
          ...categoriasList.map((c) => c.name).toList()
        ];

        return Padding(
          key: const ValueKey('compact'),
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PRIMERA FILA: Back button + Buscador
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: _searchController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          suffixIcon: filtroTexto.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => filtroTexto = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF8B5CF6),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => filtroTexto = value),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // SEGUNDA FILA: Filtros de categorías
              SizedBox(
                height: 30,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
                            categoriaIdSeleccionada =
                                categoriasList[index - 1].id;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.only(
                          left: index == 0 ? 0 : 6,
                          right: index == nombresCategorias.length - 1 ? 0 : 6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        constraints: BoxConstraints(
                          minWidth: index == 0 ? 60 : 50, // "Todas" más ancho
                          maxWidth: 120,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF7C3AED),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            categoria.length > 9
                                ? '${categoria.substring(0, 8)}...'
                                : categoria,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.9),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 11,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Colors.white,
              ),
              onPressed: () => context.pop(),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                ),
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => _buildNormalAppBarContent(context, carrito),
    );
  }

  Widget _buildHeader() {
    final orderMode = widget.orderMode.toLowerCase();
    final clienteNombreDecoded = _decodeIfNeeded(widget.clienteNombre);
    final clienteTelefono = _decodeIfNeeded(widget.clienteTelefono);
    final clienteDireccion = _decodeIfNeeded(widget.clienteDireccion);
    final clienteReferencia = _decodeIfNeeded(widget.clienteReferencia);
    final hasClienteNombre =
        clienteNombreDecoded != null && clienteNombreDecoded.trim().isNotEmpty;
    final hasDeliveryInfo = orderMode == 'domicilio' &&
        ((clienteTelefono?.trim().isNotEmpty ?? false) ||
            (clienteDireccion?.trim().isNotEmpty ?? false) ||
            (clienteReferencia?.trim().isNotEmpty ?? false));
    final displayRecipient = hasClienteNombre
        ? clienteNombreDecoded
        : (orderMode == 'domicilio' ? 'el domicilio' : 'el pedido');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Seleccionar Productos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              if (orderMode == 'mesa' && widget.mesaNombre != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Text(
                    widget.mesaNombre!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (orderMode == 'domicilio')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delivery_dining_rounded,
                          size: 14, color: Colors.white70),
                      SizedBox(width: 6),
                      Text(
                        'Domicilio',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasClienteNombre
                ? 'Agregando productos para ${displayRecipient[0].toUpperCase()}${displayRecipient.substring(1)}'
                : (orderMode == 'domicilio'
                    ? 'Agrega productos a este domicilio'
                    : 'Agregar productos al pedido'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (hasDeliveryInfo) ...[
            const SizedBox(height: 8),
            if (clienteTelefono != null && clienteTelefono.trim().isNotEmpty)
              _buildDeliveryInfoRow(Icons.phone_rounded, clienteTelefono),
            if (clienteDireccion != null && clienteDireccion.trim().isNotEmpty)
              _buildDeliveryInfoRow(
                  Icons.location_on_rounded, clienteDireccion),
            if (clienteReferencia != null &&
                clienteReferencia.trim().isNotEmpty)
              _buildDeliveryInfoRow(Icons.push_pin_outlined, clienteReferencia),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon:
              Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
          suffixIcon: filtroTexto.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: Colors.white.withValues(alpha: 0.7)),
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
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
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFF8B5CF6), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agregando productos al pedido en preparación',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Estos artículos se sumarán al pedido ya enviado a cocina. Los productos actuales no podrán modificarse ni eliminarse.',
                    style: TextStyle(
                      color: Colors.white70,
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
                        ? const Color(0xFF8B5CF6)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8B5CF6)
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    categoria,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.8),
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
                color: Colors.grey.shade300,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade800.withValues(alpha: 0.95),
              Colors.grey.shade900.withValues(alpha: 0.98),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: producto.disponible
                ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                : const Color(0xFFEF4444).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: producto.disponible
                  ? const Color(0xFF6366F1).withValues(alpha: 0.05)
                  : Colors.transparent,
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECCIÓN DE IMAGEN - 60% del espacio
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Stack(
                  children: [
                    if (producto.photo != null && producto.photo!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6366F1)),
                                strokeWidth: 3,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6366F1)
                                        .withValues(alpha: 0.15),
                                    const Color(0xFF8B5CF6)
                                        .withValues(alpha: 0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.fastfood_rounded,
                                  size: 52,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withValues(alpha: 0.15),
                              const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.fastfood_rounded,
                            size: 52,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    // Overlay de estado no disponible
                    if (!producto.disponible)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                color: Color(0xFFEF4444),
                                size: 32,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'No Disponible',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Badge de estado disponible en la esquina
                    if (producto.disponible)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Disponible',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // SECCIÓN DE INFORMACIÓN - 40% del espacio
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NOMBRE DEL PRODUCTO
                    Expanded(
                      flex: 3,
                      child: Text(
                        _capitalizeFirstLetter(producto.name),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // FILA DE PRECIO Y BOTÓN
                    Row(
                      children: [
                        // PRECIO - Más grande y llamativo
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.attach_money_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                Flexible(
                                  child: Text(
                                    producto.price
                                        .toStringAsFixed(0)
                                        .replaceAllMapped(
                                          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                          (Match m) => '${m[1]}.',
                                        ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // BOTÓN DE AGREGAR
                        Container(
                          decoration: BoxDecoration(
                            color: producto.disponible
                                ? const Color(0xFF059669)
                                : Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: producto.disponible
                                    ? const Color(0xFF059669)
                                        .withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: producto.disponible
                                  ? () => _mostrarDetalleProducto(producto)
                                  : null,
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
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

    final total = carrito.fold<double>(0, (accumulator, item) {
      final precioBase = item.precioUnitario * item.cantidad;
      final precioAdicionales = item.adicionales?.fold<double>(
            0,
            (adicionalTotal, adicional) =>
                adicionalTotal + (adicional.price * item.cantidad),
          ) ??
          0;
      return accumulator + precioBase + precioAdicionales;
    });
    final cantidadTotal =
        carrito.fold(0, (total, item) => total + item.cantidad);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
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
                    '$cantidadTotal ${cantidadTotal == 1 ? 'artículo' : 'artículos'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
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
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _mostrarCarrito(context),
              icon: const Icon(Icons.shopping_cart, size: 20),
              label: const Text(
                'Ver Carrito',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
      builder: (context) => DetalleProductoScreen(
        producto: producto,
        pedidoId: widget.pedidoId,
      ),
    );
  }

  void _mostrarCarrito(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CarritoBottomSheet(
        pedidoId: widget.pedidoId,
        orderMode: widget.orderMode,
        onConfirmarSinPagar: () => _confirmarPedidoSinPagar(context),
        onConfirmarYPagar: () => _confirmarPedidoYPagar(context),
        onConfirmarYPagarTakeaway: () => _confirmarYPagarTakeaway(context),
        onConfirmarYPagarDelivery: () => _confirmarYPagarDelivery(context),
        onRegistrarPago: () {
          _registrarPago(context);
        },
        onModificarPedido: () => _modificarPedido(context),
        onCancelarPedido: () => _cancelarPedido(context),
        onActualizarPedido: () {
          _actualizarPedidoExistente(context);
        },
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
      if (!mounted) return;
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
      if (!mounted) return;
      final ticketInfo =
          await _generarTicketFactura(context, mostrarMensaje: false);
      await _cargarCarritoDelPedido();
      if (!mounted) return;
      context.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado y ticket generado')),
      );
      await _abrirTicketPreview(ticketId: ticketInfo?['ticketId'] as String?);
    } catch (e) {
      if (!mounted) return;
      _mostrarError(context, 'Error al confirmar y generar ticket: $e');
    }
  }

  // Método específico para pedidos para llevar: envía a cocina y procesa pago inmediatamente
  Future<void> _confirmarYPagarTakeaway(BuildContext sheetContext) async {
    final carrito = ref.read(carritoProvider);
    if (carrito.isEmpty) {
      _mostrarError(context, 'Agrega productos antes de confirmar el pedido.');
      return;
    }

    try {
      // 1. Guardar el pedido con status='pendiente' para que aparezca en cocina
      await _crearActualizarPedido(carrito, 'pendiente', false);
      await _cargarCarritoDelPedido();

      if (!mounted) return;

      // 2. Cerrar el carrito
      Navigator.of(sheetContext).pop();

      if (!mounted) return;

      // 3. Mostrar mensaje de que se envió a cocina
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado a cocina')),
      );

      // 4. Abrir el diálogo de pago inmediatamente
      final pagoCompletado = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        builder: (_) => PaymentBottomSheet(
          pedidoId: widget.pedidoId,
          onPaid: () => ref.read(carritoProvider.notifier).limpiarCarrito(),
        ),
      );

      // 5. Si el pago fue completado, generar el ticket y mostrar
      if (pagoCompletado == true && mounted) {
        await _cargarCarritoDelPedido();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado correctamente')),
        );

        // Generar y mostrar el ticket, reemplazando la pantalla actual
        // para que al cerrar el ticket se vuelva a la pantalla anterior (takeaway list)
        final ticketInfo =
            await _generarTicketFactura(context, mostrarMensaje: false);
        await _abrirTicketPreviewYCerrarPedido(ticketId: ticketInfo?['ticketId'] as String?);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError(context, 'Error al procesar el pedido: $e');
    }
  }

  // Método específico para pedidos domiciliarios: muestra opciones de pago antes de enviar a cocina
  Future<void> _confirmarYPagarDelivery(BuildContext sheetContext) async {
    final carrito = ref.read(carritoProvider);
    if (carrito.isEmpty) {
      _mostrarError(context, 'Agrega productos antes de confirmar el pedido.');
      return;
    }

    try {
      // 1. Cerrar el carrito primero
      Navigator.of(sheetContext).pop();

      if (!mounted) return;

      // 2. Mostrar las opciones de pago (cash o paga al recibir)
      final pagoResult = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        builder: (_) => _DeliveryPaymentOptionsSheet(
          pedidoId: widget.pedidoId,
          total: ref.read(carritoControllerProvider).calcularTotal(),
        ),
      );

      if (pagoResult == null || !mounted) return;

      final paymentMethod = pagoResult['method'] as String;
      final shouldProceed = pagoResult['proceed'] as bool? ?? false;

      if (!shouldProceed) return;

      // 3. Guardar el pedido con el método de pago seleccionado
      await _crearActualizarPedido(carrito, 'pendiente', false);

      if (!mounted) return;

      // 4. Actualizar el estado de pago según la selección
      final user = await ref.read(userModelProvider.future);
      final processedByName = '${user.nombre} ${user.apellidos}'.trim();

      if (paymentMethod == 'pay_on_delivery') {
        // Paga al recibir - pedido con pago pendiente
        final paymentData = <String, dynamic>{
          'method': 'pay_on_delivery',
          'status': 'pending',
          'amount': ref.read(carritoControllerProvider).calcularTotal(),
          'processedAt': FieldValue.serverTimestamp(),
        };

        paymentData['processedBy'] = user.uid;
        paymentData['processedByName'] = processedByName;

        await FirebaseFirestore.instance
            .collection('pedido')
            .doc(widget.pedidoId)
            .update({
          'pagado': false,
          'paymentStatus': 'pending',
          'payment': paymentData,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _cargarCarritoDelPedido();

        if (!mounted) return;

        SnackbarHelper.showInfo(
          'Pedido enviado a cocina - Pago pendiente al entregar',
        );

        // Volver a la pantalla anterior
        if (mounted) {
          context.pop();
        }
      } else if (paymentMethod == 'cash') {
        // Pago en efectivo - procesar pago inmediatamente
        final paymentData = <String, dynamic>{
          'method': 'cash',
          'status': 'completed',
          'amount': ref.read(carritoControllerProvider).calcularTotal(),
          'processedAt': FieldValue.serverTimestamp(),
        };

        paymentData['processedBy'] = user.uid;
        paymentData['processedByName'] = processedByName;

        await FirebaseFirestore.instance
            .collection('pedido')
            .doc(widget.pedidoId)
            .update({
          'pagado': true,
          'paymentStatus': 'paid',
          'paidAt': FieldValue.serverTimestamp(),
          'payment': paymentData,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _cargarCarritoDelPedido();

        if (!mounted) return;

        SnackbarHelper.showSuccess(
          'Pago en efectivo registrado correctamente',
        );

        // Generar y mostrar el ticket, reemplazando la pantalla actual
        // para que al cerrar el ticket se vuelva a la pantalla anterior (delivery list)
        final ticketInfo =
            await _generarTicketFactura(context, mostrarMensaje: false);
        await _abrirTicketPreviewYCerrarPedido(ticketId: ticketInfo?['ticketId'] as String?);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError(context, 'Error al procesar el pedido: $e');
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
      if (!mounted) return;
      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }
      if (!mounted) return;
      SnackbarHelper.showSuccess(
        'Pedido actualizado y enviado a cocina',
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
        if (!mounted) return;
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
        SnackbarHelper.showInfo(
          'Debes marcar el pedido como terminado antes de registrar el pago.',
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError(context, 'No se pudo preparar el pago: $e');
      return;
    }
    if (!mounted) return;
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
    try {
      if (!mounted) return;
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
        SnackbarHelper.showSuccess(
          'Pago registrado correctamente.',
        );
        if (!mounted) return;
        final ticketInfo =
            await _generarTicketFactura(context, mostrarMensaje: false);

        // Liberar mesa antes de navegar al ticket
        if (widget.orderMode.toLowerCase() == 'mesa') {
          await _liberarMesaTrasPago(pedidoData: pedidoData);
        }

        // Navegar al ticket y remover la pantalla actual del stack
        // para que al cerrar el ticket se vuelva a mesas
        if (!mounted) return;
        await _abrirTicketPreviewYCerrarPedido(ticketId: ticketInfo?['ticketId'] as String?);
      }
    } catch (e) {
      if (!mounted) return;
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
    if (!mounted) return;
    final ticketInfo =
        await _generarTicketFactura(context, mostrarMensaje: true);
    if (ticketInfo == null) {
      return;
    }
    if (!mounted) return;
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).pop();
    }
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

  /// Navega al ticket preview y cierra la pantalla actual de pedido
  /// para que al cerrar el ticket se vuelva directamente a mesas
  Future<void> _abrirTicketPreviewYCerrarPedido({String? ticketId}) async {
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

    // Usar pushReplacement para reemplazar la pantalla actual con el ticket
    // Así cuando se cierre el ticket, volverá a la pantalla anterior (mesas)
    context.pushReplacement(uri.toString());
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
    final fallbackRoute = widget.orderMode.toLowerCase() == 'domicilio'
        ? '/mesero/pedidos/domicilio'
        : '/mesero/pedidos/mesas';
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(fallbackRoute);
    }
  }

  Future<Map<String, dynamic>?> _generarTicketFactura(BuildContext context,
      {bool mostrarMensaje = true}) async {
    try {
      final pedidoRef =
          FirebaseFirestore.instance.collection('pedido').doc(widget.pedidoId);
      final pedidoSnapshot = await pedidoRef.get();
      if (!pedidoSnapshot.exists) {
        if (mostrarMensaje && context.mounted) {
          _mostrarError(
              context, 'Aun no hay un pedido para generar un ticket.');
        }
        return null;
      }
      final data = pedidoSnapshot.data() as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? [];
      if (items.isEmpty) {
        if (mostrarMensaje && context.mounted) {
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
      final ticketRef =
          await pedidoRef.collection('tickets').add(ticketForFirestore);
      await pedidoRef.set({
        'ultimoTicketGeneradoAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mostrarMensaje && mounted) {
        SnackbarHelper.showSuccess(
          'Ticket generado correctamente.',
        );
      }
      return {
        'ticketId': ticketRef.id,
      };
    } catch (e) {
      if (mostrarMensaje && context.mounted) {
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
    SnackbarHelper.showInfo(
      'Puedes agregar o quitar productos del pedido',
    );
  }

  Future<void> _cancelarPedido(BuildContext sheetContext) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content:
            const Text('Estas seguro de que quieres cancelar este pedido?'),
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
          final etiquetaMesa =
              (mesaNombre != null && mesaNombre.trim().isNotEmpty)
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
          if (!mounted) return;
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
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
          if (!mounted) return;
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
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
        if (!mounted) return;
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
    final subtotal = carrito.fold<double>(0, (accumulator, item) {
      final precioBase = item.precioUnitario * item.cantidad;
      final precioAdicionales = item.adicionales?.fold<double>(
            0,
            (adicionalTotal, adicional) =>
                adicionalTotal + (adicional.price * item.cantidad),
          ) ??
          0;
      return accumulator + precioBase + precioAdicionales;
    });
    final orderMode = widget.orderMode.toLowerCase();
    final mesaIdInt = (orderMode == 'mesa' && widget.mesaId != null)
        ? int.tryParse(widget.mesaId!)
        : null;
    final mesaNombre = _decodeIfNeeded(widget.mesaNombre);
    final clienteNombre = _decodeIfNeeded(widget.clienteNombre);
    final clienteTelefono = _decodeIfNeeded(widget.clienteTelefono);
    final clienteDireccion = _decodeIfNeeded(widget.clienteDireccion);
    final clienteReferencia = _decodeIfNeeded(widget.clienteReferencia);
    final tableNumber = orderMode == 'mesa'
        ? (mesaNombre ??
            (mesaIdInt != null ? 'Mesa $mesaIdInt' : null) ??
            widget.pedidoId)
        : null;

    final pedidoData = <String, dynamic>{
      'id': widget.pedidoId,
      'items': items,
      'subtotal': subtotal,
      'total': subtotal,
      'status': status,
      'pagado': pagado,
      'paymentStatus': pagado ? 'paid' : 'pending',
      'mode': orderMode,
      'meseroId': user?.uid,
      'meseroNombre': user != null
          ? '${user.nombre} ${user.apellidos}'
          : 'Mesero desconocido',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (tableNumber != null) {
      pedidoData['tableNumber'] = tableNumber;
    }
    if (orderMode == 'mesa' && mesaIdInt != null) {
      pedidoData['mesaId'] = mesaIdInt;
    }
    if (mesaNombre != null && mesaNombre.trim().isNotEmpty) {
      pedidoData['mesaNombre'] = mesaNombre;
    }
    if (clienteNombre != null && clienteNombre.trim().isNotEmpty) {
      pedidoData['clienteNombre'] = clienteNombre;
      pedidoData['cliente'] = clienteNombre;
    }
    if (orderMode == 'domicilio') {
      if (clienteTelefono != null && clienteTelefono.trim().isNotEmpty) {
        pedidoData['clienteTelefono'] = clienteTelefono;
        pedidoData['phone'] = clienteTelefono;
      }
      if (clienteDireccion != null && clienteDireccion.trim().isNotEmpty) {
        pedidoData['clienteDireccion'] = clienteDireccion;
        pedidoData['address'] = clienteDireccion;
      }
      if (clienteReferencia != null && clienteReferencia.trim().isNotEmpty) {
        pedidoData['clienteReferencia'] = clienteReferencia;
        pedidoData['reference'] = clienteReferencia;
      }
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
    SnackbarHelper.showInfo(
        'Funcionalidad de reporte de problemas próximamente');
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

// Widget para mostrar opciones de pago para pedidos domiciliarios
class _DeliveryPaymentOptionsSheet extends StatefulWidget {
  final String pedidoId;
  final double total;

  const _DeliveryPaymentOptionsSheet({
    required this.pedidoId,
    required this.total,
  });

  @override
  State<_DeliveryPaymentOptionsSheet> createState() =>
      _DeliveryPaymentOptionsSheetState();
}

class _DeliveryPaymentOptionsSheetState
    extends State<_DeliveryPaymentOptionsSheet> {
  String _selectedMethod = 'cash';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1B23),
            Color(0xFF2D2E37),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Seleccionar método de pago',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige cómo se procesará el pago de este pedido',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF363740).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total del pedido',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${widget.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Theme(
            data: ThemeData(
              unselectedWidgetColor: Colors.grey.shade600,
            ),
            child: RadioListTile<String>(
              value: 'cash',
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value ?? 'cash';
                });
              },
              title: const Text(
                'Pago inmediato en efectivo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'El pago se registra ahora y se envía a cocina',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              activeColor: const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(height: 12),
          Theme(
            data: ThemeData(
              unselectedWidgetColor: Colors.grey.shade600,
            ),
            child: RadioListTile<String>(
              value: 'pay_on_delivery',
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value ?? 'pay_on_delivery';
                });
              },
              title: const Text(
                'Paga al recibir',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'El cliente pagará cuando reciba el pedido',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              activeColor: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'method': _selectedMethod,
                      'proceed': true,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _selectedMethod == 'cash'
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedMethod == 'cash'
                        ? 'Confirmar y enviar'
                        : 'Enviar con pago pendiente',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
