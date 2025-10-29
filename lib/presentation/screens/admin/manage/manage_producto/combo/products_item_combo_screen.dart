import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';

class ProductsItemComboScreen extends ConsumerStatefulWidget {
  const ProductsItemComboScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _State();
}

class _State extends ConsumerState<ProductsItemComboScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId; // null = "Todas"
  final int _maxProducts = 5;

  @override
  void initState() {
    super.initState();
    // No limpiar los productos seleccionados al entrar, mantener los que ya estaban
  }

  void _toggleProduct(ProductModel product) {
    final selectedProducts = ref.read(selectedComboProductsProvider);

    if (selectedProducts.any((p) => p.id == product.id)) {
      // Si ya está seleccionado, quitarlo
      ref.read(selectedComboProductsProvider.notifier).state =
        selectedProducts.where((p) => p.id != product.id).toList();
    } else {
      // Si no está seleccionado, verificar límite
      if (selectedProducts.length >= _maxProducts) {
        SnackbarHelper.showWarning('Máximo $_maxProducts productos permitidos');
        return;
      }
      // Agregarlo
      ref.read(selectedComboProductsProvider.notifier).state =
        [...selectedProducts, product];
    }
  }

  void _confirmSelection() {
    final selectedProducts = ref.read(selectedComboProductsProvider);

    if (selectedProducts.isEmpty) {
      SnackbarHelper.showWarning('Selecciona al menos un producto');
      return;
    }

    // Primero regresamos a la pantalla anterior
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final productsAsync = ref.watch(productsProvider);
    final selectedProducts = ref.watch(selectedComboProductsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Productos (${selectedProducts.length}/$_maxProducts)',
          style: const TextStyle(color: Colors.white),
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
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: isTablet
              ? const EdgeInsets.symmetric(vertical: 100, horizontal: 60)
              : const EdgeInsets.fromLTRB(16, 100, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Buscador
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF34D399)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                      borderSide: BorderSide(color: Color(0xFF34D399), width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filtros de categorías
                Consumer(
                  builder: (context, ref, child) {
                    final categoriesAsync = ref.watch(categoryDisponibleProvider);

                    return categoriesAsync.when(
                      data: (categories) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // Chip "Todas"
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategoryId = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedCategoryId == null
                                          ? const Color(0xFF34D399)
                                          : Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _selectedCategoryId == null
                                            ? const Color(0xFF34D399)
                                            : Colors.white.withValues(alpha: 0.12),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Todas',
                                        style: TextStyle(
                                          color: _selectedCategoryId == null
                                            ? Colors.white
                                            : Colors.white70,
                                          fontSize: 14,
                                          fontWeight: _selectedCategoryId == null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Chips de categorías
                                  ...categories.map((category) {
                                    final isSelected = _selectedCategoryId == category.id;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedCategoryId = category.id;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                            ? const Color(0xFF34D399)
                                            : Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                              ? const Color(0xFF34D399)
                                              : Colors.white.withValues(alpha: 0.12),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          category.name,
                                          style: TextStyle(
                                            color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                            fontSize: 14,
                                            fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Selecciona los productos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Máximo $_maxProducts productos por combo',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),

                const SizedBox(height: 24),

                // Lista de productos
                productsAsync.when(
                  data: (products) {
                    final filteredProducts = products.where((product) {
                      // Filtrar por búsqueda
                      final matchesSearch = product.name.toLowerCase().contains(_searchQuery);
                      // Filtrar por categoría
                      final matchesCategory = _selectedCategoryId == null || product.category == _selectedCategoryId;
                      return matchesSearch && matchesCategory;
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            _searchQuery.isEmpty
                              ? 'No hay productos disponibles'
                              : 'No se encontraron productos',
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final isSelected = selectedProducts.any((p) => p.id == product.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                              ? const Color(0xFF34D399).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                ? const Color(0xFF34D399)
                                : Colors.white.withValues(alpha: 0.12),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: theme.primaryColor.withAlpha(100),
                              child: Text(
                                product.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (value) => _toggleProduct(product),
                              activeColor: const Color(0xFF34D399),
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            onTap: () => _toggleProduct(product),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Error al cargar productos: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Espacio para el botón flotante
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: selectedProducts.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: _confirmSelection,
            backgroundColor: const Color(0xFF8B5CF6),
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(
              'Confirmar (${selectedProducts.length})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        : null,
    );
  }
}
