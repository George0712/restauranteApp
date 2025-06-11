import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/data/providers/admin/admin_provider.dart';
import 'package:restaurante_app/data/providers/mesero/pedidos_provider.dart';

class SeleccionProductosScreen extends ConsumerStatefulWidget {
  final String pedidoId;

  const SeleccionProductosScreen({
    super.key,
    required this.pedidoId,
  });

  @override
  ConsumerState<SeleccionProductosScreen> createState() => _SeleccionProductosScreenState();
}

class _SeleccionProductosScreenState extends ConsumerState<SeleccionProductosScreen>
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
    final categoriasAsync = ref.read(categoryDisponibleProvider);
    
    categoriasAsync.whenData((categorias) {
      final nombresCategorias = ['Todas', ...categorias.map((c) => c.name).toList()];
      _tabController = TabController(length: nombresCategorias.length, vsync: this);
    });
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
          final categorias = ['Todas', ...productos.map((p) => p.category).toSet().toList()];
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

  PreferredSizeWidget _buildAppBar(BuildContext context, List<ItemCarrito> carrito) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black54),
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
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black54),
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
                    carrito.fold(0, (sum, item) => sum + item.cantidad).toString(),
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
        final nombresCategorias = ['Todas', ...categoriasList.map((c) => c.name).toList()];
        
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? Theme.of(context).primaryColor.withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    categoria,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                                value: loadingProgress.expectedTotalBytes != null
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
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: const BorderRadius.only(
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
                          '\$${producto.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
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

  Widget? _buildCarritoBottomBar(BuildContext context, List<ItemCarrito> carrito) {
    if (carrito.isEmpty) return null;

    final total = carrito.fold<double>(0, (sum, item) {
      final precioBase = item.precioUnitario * item.cantidad;
      final precioAdicionales = item.adicionales?.fold<double>(
        0,
        (sum, adicional) => sum + (adicional.price * item.cantidad),
      ) ?? 0;
      return sum + precioBase + precioAdicionales;
    });
    final cantidadTotal = carrito.fold(0, (sum, item) => sum + item.cantidad);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
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
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      builder: (context) => _DetalleProductoBottomSheet(producto: producto),
    );
  }

  void _mostrarCarrito(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CarritoBottomSheet(
        onConfirmar: () => _confirmarPedido(context, ref.read(carritoProvider)),
        onPagar: () => _procesarPago(context, ref.read(carritoProvider)),
        pedidoConfirmado: pedidoConfirmado,
      ),
    );
  }

  void _confirmarPedido(BuildContext context, List<ItemCarrito> carrito) async {
    try {
      final adicionalesAsync = await ref.read(additionalProvider.future);
      
      // Crear los items del pedido con sus adicionales
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

      // Calcular totales
      final subtotal = carrito.fold<double>(0, (sum, item) {
        final precioBase = item.precioUnitario * item.cantidad;
        final precioAdicionales = item.adicionales?.fold<double>(
          0,
          (sum, adicional) => sum + (adicional.price * item.cantidad),
        ) ?? 0;
        return sum + precioBase + precioAdicionales;
      });
      final total = subtotal;

      // Crear el pedido en Firestore
      final pedidoRef = await FirebaseFirestore.instance.collection('pedido').add({
        'mode': 'mesa',
        'tableNumber': widget.pedidoId,
        'items': items,
        'subtotal': subtotal,
        'total': total,
        'status': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Actualizar estado
      setState(() {
        pedidoConfirmado = true;
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido confirmado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar el pedido: $e')),
        );
      }
    }
  }

  void _procesarPago(BuildContext context, List<ItemCarrito> carrito) async {
    try {
      // Simular proceso de pago
      await Future.delayed(const Duration(seconds: 2));

      // Calcular total
      final total = carrito.fold<double>(0, (sum, item) {
        final precioBase = item.precioUnitario * item.cantidad;
        final precioAdicionales = item.adicionales?.fold<double>(
          0,
          (sum, adicional) => sum + (adicional.price * item.cantidad),
        ) ?? 0;
        return sum + precioBase + precioAdicionales;
      });

      // Actualizar estado del pedido en Firestore
      final pedidoRef = await FirebaseFirestore.instance.collection('pedido')
          .where('tableNumber', isEqualTo: widget.pedidoId)
          .where('status', isEqualTo: 'pendiente')
          .get();

      if (pedidoRef.docs.isNotEmpty) {
        await pedidoRef.docs.first.reference.update({
          'status': 'pagado',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Limpiar carrito después del pago exitoso
      ref.read(carritoProvider.notifier).limpiarCarrito();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago procesado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el pago: $e')),
        );
      }
    }
  }
}

class _DetalleProductoBottomSheet extends ConsumerStatefulWidget {
  final ProductModel producto;

  const _DetalleProductoBottomSheet({required this.producto});

  @override
  ConsumerState<_DetalleProductoBottomSheet> createState() => _DetalleProductoBottomSheetState();
}

class _DetalleProductoBottomSheetState extends ConsumerState<_DetalleProductoBottomSheet> {
  int cantidad = 1;
  List<String> adicionalesSeleccionados = [];
  final TextEditingController _notasController = TextEditingController();

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  void _agregarAlCarrito() async {
    try {
      final adicionalesAsync = await ref.read(additionalProvider.future);
      final adicionales = adicionalesSeleccionados
          .map((id) => adicionalesAsync.firstWhere((a) => a.id == id))
          .toList();

      final item = ItemCarrito(
        producto: widget.producto,
        cantidad: cantidad,
        modificacionesSeleccionadas: adicionalesSeleccionados,
        notas: _notasController.text,
        precioUnitario: widget.producto.price,
        adicionales: adicionales,
      );
      ref.read(carritoProvider.notifier).agregarItem(item);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar al carrito: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adicionalesAsync = ref.watch(additionalProvider);
    final precioTotal = widget.producto.price * cantidad;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: widget.producto.photo != null && widget.producto.photo!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.producto.photo!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
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
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.fastfood,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.producto.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${widget.producto.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (widget.producto.ingredientes.isNotEmpty) ...[
                    const Text(
                      'Ingredientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.producto.ingredientes,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 24),
                  adicionalesAsync.when(
                    data: (adicionales) {
                      if (adicionales.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adicionales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...adicionales.map((adicional) =>
                            CheckboxListTile(
                              title: Text(adicional.name),
                              subtitle: Text('+\$${adicional.price.toStringAsFixed(2)}'),
                              value: adicionalesSeleccionados.contains(adicional.id),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    adicionalesSeleccionados.add(adicional.id);
                                  } else {
                                    adicionalesSeleccionados.remove(adicional.id);
                                  }
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Notas especiales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notasController,
                    decoration: InputDecoration(
                      hintText: 'Instrucciones especiales para la cocina...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Cantidad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: cantidad > 1 
                                  ? () => setState(() => cantidad--) 
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                cantidad.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => cantidad++),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Total: \$${precioTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.producto.disponible ? _agregarAlCarrito : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Agregar al carrito'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarritoBottomSheet extends ConsumerWidget {
  final VoidCallback onConfirmar;
  final VoidCallback onPagar;
  final bool pedidoConfirmado;

  const _CarritoBottomSheet({
    required this.onConfirmar,
    required this.onPagar,
    required this.pedidoConfirmado,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(carritoProvider);
    final adicionalesAsync = ref.watch(additionalProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            pedidoConfirmado ? 'Pedido Confirmado' : 'Tu carrito',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: carrito.isEmpty
                ? const Center(child: Text('Tu carrito está vacío.'))
                : ListView.builder(
                    itemCount: carrito.length,
                    itemBuilder: (context, index) {
                      final item = carrito[index];
                      return adicionalesAsync.when(
                        data: (adicionales) {
                          final adicionalesSeleccionados = item.modificacionesSeleccionadas
                              .map((id) => adicionales.firstWhere((a) => a.id == id))
                              .toList();
                          final modsPrecio = adicionalesSeleccionados.fold(
                            0.0,
                            (sum, adicional) => sum + adicional.price,
                          );
                          final totalItem = (item.precioUnitario + modsPrecio) * item.cantidad;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(item.producto.photo ?? '🍽️'),
                              ),
                              title: Text('${item.producto.name} x${item.cantidad}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (adicionalesSeleccionados.isNotEmpty)
                                    Text('Adicionales: ${adicionalesSeleccionados.map((a) => a.name).join(", ")}'),
                                  if (item.notas?.isNotEmpty ?? false)
                                    Text('Nota: ${item.notas}'),
                                ],
                              ),
                              trailing: Text(
                                '\$${totalItem.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Text('Error: $error'),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${carrito.fold<double>(0, (sum, item) {
                  final precioBase = item.precioUnitario * item.cantidad;
                  final precioAdicionales = item.adicionales?.fold<double>(
                    0,
                    (sum, adicional) => sum + (adicional.price * item.cantidad),
                  ) ?? 0;
                  return sum + precioBase + precioAdicionales;
                }).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: carrito.isEmpty ? null : (pedidoConfirmado ? onPagar : onConfirmar),
              icon: Icon(pedidoConfirmado ? Icons.payment : Icons.check_circle),
              label: Text(pedidoConfirmado ? 'Proceder al Pago' : 'Confirmar Pedido'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: pedidoConfirmado ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


