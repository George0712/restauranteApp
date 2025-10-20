import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/presentation/controllers/mesero/carrito_controller.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/presentation/providers/login/auth_service.dart';
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart';
import 'package:uuid/uuid.dart';

class QuickOrderScreen extends ConsumerStatefulWidget {
  const QuickOrderScreen({super.key});

  @override
  ConsumerState<QuickOrderScreen> createState() => _QuickOrderScreenState();
}

class _QuickOrderScreenState extends ConsumerState<QuickOrderScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'Todas';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(carritoProvider.notifier).limpiarCarrito();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _aliasController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productsProvider);
    final carrito = ref.watch(carritoProvider);
    final carritoController = ref.watch(carritoControllerProvider);
    final total = carritoController.calcularTotal();
    final totalItems =
        carrito.fold<int>(0, (total, item) => total + item.cantidad);
    final isTablet = MediaQuery.of(context).size.width > 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text(
            'Pedido rápido',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            if (carrito.isNotEmpty)
              TextButton(
                onPressed: () {
                  ref.read(carritoProvider.notifier).limpiarCarrito();
                },
                child: const Text(
                  'Vaciar',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 28 : 20,
              vertical: isTablet ? 18 : 14,
            ),
            child: productosAsync.when(
              data: (productos) {
                final filtered = _filteredProducts(productos);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(),
                    const SizedBox(height: 16),
                    _buildAliasAndNotes(isTablet),
                    const SizedBox(height: 18),
                    _buildSearchField(),
                    const SizedBox(height: 14),
                    _buildCategorySelector(productos),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : _buildProductList(
                              filtered,
                              carrito,
                              isTablet,
                            ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 70),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              ),
              error: (error, _) => _buildError(error),
            ),
          ),
        ),
        bottomNavigationBar: _buildSummaryBar(
          totalItems: totalItems,
          total: total,
          carrito: carrito,
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crea y envía pedidos en segundos.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Selecciona productos, agrega un alias opcional y mándalo directo a cocina.',
          style: TextStyle(
            color: Color(0xFFCBD5F5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildAliasAndNotes(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _aliasController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: 'Alias del pedido (opcional)',
                  icon: Icons.bolt_rounded,
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            if (isTablet) const SizedBox(width: 16),
            if (isTablet)
              Expanded(
                child: _buildNotesField(),
              ),
          ],
        ),
        if (!isTablet) ...[
          const SizedBox(height: 12),
          _buildNotesField(),
        ],
      ],
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 2,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Notas para cocina',
        icon: Icons.sticky_note_2_outlined,
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      prefixIcon: Icon(icon, color: const Color(0xFF818CF8)),
      filled: true,
      fillColor: const Color(0xFF111827),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
        hintText: 'Buscar productos...',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List<ProductModel> productos) {
    final categories = <String>{'Todas'};
    categories.addAll(productos.map((product) => product.category).where((c) => c.trim().isNotEmpty));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: const Color(0xFF111827),
              selectedColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductList(
    List<ProductModel> productos,
    List<ItemCarrito> carrito,
    bool isTablet,
  ) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final product = productos[index];
        final quantity = _quantityForProduct(product, carrito);
        return _ProductQuickTile(
          product: product,
          quantity: quantity,
          onAdd: () => _addProduct(product),
          onRemove: () => _removeProduct(product),
          isTablet: isTablet,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: productos.length,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fastfood_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            const Text(
              'Sin coincidencias',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
                  Text(
                    'Ajusta el filtro o busca por otro término.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              color: Colors.redAccent.withValues(alpha: 0.7), size: 48),
          const SizedBox(height: 12),
          const Text(
            'No pudimos cargar los productos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '$error',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar({
    required int totalItems,
    required double total,
    required List<ItemCarrito> carrito,
  }) {
    if (carrito.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalItems ${totalItems == 1 ? 'producto' : 'productos'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatCurrency(total),
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _submitOrder(carrito),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.local_fire_department_rounded),
                label: Text(
                  _isSubmitting ? 'Enviando...' : 'Enviar a cocina',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ProductModel> _filteredProducts(List<ProductModel> productos) {
    final query = _searchController.text.trim().toLowerCase();
    return productos.where((product) {
      final matchesCategory = _selectedCategory == 'Todas' ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  int _quantityForProduct(ProductModel product, List<ItemCarrito> carrito) {
    for (final item in carrito) {
      if (item.producto.id == product.id &&
          item.modificacionesSeleccionadas.isEmpty) {
        return item.cantidad;
      }
    }
    return 0;
  }

  void _addProduct(ProductModel product) {
    if (!product.disponible) {
      SnackbarHelper.showInfo('Producto no disponible temporalmente.');
      return;
    }

    final item = ItemCarrito(
      producto: product,
      cantidad: 1,
      precioUnitario: product.price,
      modificacionesSeleccionadas: const [],
    );
    ref.read(carritoProvider.notifier).agregarItem(item);
  }

  void _removeProduct(ProductModel product) {
    final carritoActual = ref.read(carritoProvider);
    final index = carritoActual.indexWhere(
      (item) =>
          item.producto.id == product.id &&
          item.modificacionesSeleccionadas.isEmpty,
    );

    if (index == -1) {
      return;
    }

    final item = carritoActual[index];
    ref
        .read(carritoProvider.notifier)
        .actualizarCantidad(index, item.cantidad - 1);
  }

  Future<void> _submitOrder(List<ItemCarrito> carrito) async {
    if (carrito.isEmpty) {
      SnackbarHelper.showInfo('Añade al menos un producto antes de enviar.');
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      FocusScope.of(context).unfocus();
      final user = await ref.read(userModelProvider.future);
      final alias = _aliasController.text.trim();
      final notes = _notesController.text.trim();
      final displayName = alias.isNotEmpty ? alias : 'Pedido rápido';
      final carritoController = ref.read(carritoControllerProvider);
      final total = carritoController.calcularTotal();

      final items = carrito.map((item) {
        return {
          'productId': item.producto.id,
          'name': item.producto.name,
          'price': item.precioUnitario,
          'quantity': item.cantidad,
          if ((item.notas ?? '').trim().isNotEmpty) 'notes': item.notas,
          'adicionales': (item.adicionales ?? [])
              .map((adicional) => {
                    'id': adicional.id,
                    'name': adicional.name,
                    'price': adicional.price,
                  })
              .toList(),
          'tiempoPreparacion': item.producto.tiempoPreparacion,
        };
      }).toList();

      final pedidoId = const Uuid().v4();
      final payload = {
        'id': pedidoId,
        'status': 'pendiente',
        'mode': 'rapido',
        'items': items,
        'initialItems': items,
        'subtotal': total,
        'total': total,
        'pagado': false,
        'paymentStatus': 'pending',
        'clienteNombre': alias.isNotEmpty ? alias : null,
        'cliente': alias.isNotEmpty ? alias : null,
        'mesaNombre': displayName,
        if (notes.isNotEmpty) 'notas': notes,
        'meseroId': user.uid,
        'meseroNombre': '${user.nombre} ${user.apellidos}'.trim(),
        'quickOrder': true,
        'source': 'quickOrder',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('pedido')
          .doc(pedidoId)
          .set(payload);

      ref.read(carritoProvider.notifier).limpiarCarrito();
      _searchController.clear();
      _aliasController.clear();
      _notesController.clear();
      setState(() {
        _selectedCategory = 'Todas';
      });

      if (!mounted) {
        return;
      }

      SnackbarHelper.showSuccess('Pedido enviado a cocina');
      Navigator.of(context).maybePop();
    } catch (e) {
      debugPrint('Error al enviar pedido rápido: $e');
      if (mounted) {
        SnackbarHelper.showError(
          'No pudimos enviar el pedido. Revisa tu conexión e inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(0);
    return '\$${formatted.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }
}

class _ProductQuickTile extends StatelessWidget {
  const _ProductQuickTile({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.isTablet,
  });

  final ProductModel product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final unavailable = !product.disponible;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unavailable
              ? Colors.redAccent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF312E81),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatCurrency(product.price),
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product.tiempoPreparacion > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.timer_outlined,
                          color: Colors.white.withValues(alpha: 0.5), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${product.tiempoPreparacion} min',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                if (unavailable) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.report_problem_rounded,
                          color: Colors.redAccent.withValues(alpha: 0.8), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'No disponible temporalmente',
                        style: TextStyle(
                          color: Colors.redAccent.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ] else if (product.ingredientes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    product.ingredientes,
                    maxLines: isTablet ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          _QuantityStepper(
            quantity: quantity,
            onAdd: onAdd,
            onRemove: onRemove,
            isDisabled: unavailable,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(0);
    return '\$${formatted.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.isDisabled,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: isDisabled ? null : onAdd,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            disabledBackgroundColor:
                const Color(0xFF4F46E5).withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            quantity.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        IconButton(
          onPressed: quantity == 0 || isDisabled ? null : onRemove,
          icon: const Icon(Icons.remove_rounded, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ],
    );
  }
}
