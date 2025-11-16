import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/product_model.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';
import 'package:restaurante_app/data/models/item_carrito_model.dart';
import 'package:restaurante_app/presentation/controllers/mesero/carrito_controller.dart';
import 'package:restaurante_app/presentation/widgets/cantidad_selector.dart';

class DetalleProductoScreen extends ConsumerStatefulWidget {
  final ProductModel producto;
  final String? pedidoId;

  const DetalleProductoScreen({
    super.key,
    required this.producto,
    this.pedidoId,
  });

  @override
  ConsumerState<DetalleProductoScreen> createState() =>
      _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends ConsumerState<DetalleProductoScreen> {
  int cantidad = 1;
  List<String> adicionalesSeleccionados = [];
  final TextEditingController _notasController = TextEditingController();
  bool _pedidoFinalizado = false;
  String _mensajeEstado = '';

  @override
  void initState() {
    super.initState();
    _verificarEstadoPedido();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _verificarEstadoPedido() async {
    if (widget.pedidoId == null) {
      setState(() {
        _pedidoFinalizado = false;
        _mensajeEstado = '';
      });
      return;
    }

    try {
      final pedidoDoc = await FirebaseFirestore.instance
          .collection('pedido')
          .doc(widget.pedidoId)
          .get();

      if (pedidoDoc.exists) {
        final pedidoData = pedidoDoc.data() as Map<String, dynamic>;
        final estado = (pedidoData['status'] ?? 'pendiente').toString().toLowerCase();
        final estadoNormalizado = estado.replaceAll(' ', '_');
        const estadosFinalizados = {
          'terminado',
          'entregado',
          'completado',
          'pagado',
          'finalizado',
          'cerrado',
          'listo_para_pago',
        };

        setState(() {
          _pedidoFinalizado = estadosFinalizados.contains(estadoNormalizado);
          if (_pedidoFinalizado) {
            switch (estadoNormalizado) {
              case 'entregado':
                _mensajeEstado = 'Este pedido ya fue entregado';
                break;
              case 'pagado':
                _mensajeEstado = 'Este pedido ya está pagado';
                break;
              case 'terminado':
              case 'completado':
              case 'finalizado':
                _mensajeEstado = 'Este pedido ya está finalizado';
                break;
              case 'listo_para_pago':
                _mensajeEstado = 'Este pedido está listo para pago';
                break;
              default:
                _mensajeEstado = 'No se pueden agregar más productos';
            }
          } else {
            _mensajeEstado = '';
          }
        });
      }
    } catch (e) {
      // En caso de error, permitir agregar productos
      setState(() {
        _pedidoFinalizado = false;
        _mensajeEstado = '';
      });
    }
  }

  void _agregarAlCarrito() async {
    try {
      // Validar estado del pedido antes de agregar
      if (widget.pedidoId != null) {
        final pedidoDoc = await FirebaseFirestore.instance
            .collection('pedido')
            .doc(widget.pedidoId)
            .get();
        
        if (pedidoDoc.exists) {
          final pedidoData = pedidoDoc.data() as Map<String, dynamic>;
          final estado = (pedidoData['status'] ?? 'pendiente').toString().toLowerCase();
          final estadoNormalizado = estado.replaceAll(' ', '_');
          const estadosFinalizados = {
            'terminado',
            'entregado',
            'completado',
            'pagado',
            'finalizado',
            'cerrado',
            'listo_para_pago',
          };
          
          if (estadosFinalizados.contains(estadoNormalizado)) {
            if (mounted) {
              SnackbarHelper.showInfo('No se pueden agregar productos a un pedido que ya está finalizado');
            }
            return;
          }
        }
      }
      
      final adicionalesAsync = await ref.read(additionalProvider.future);
      final adicionalesDisponibles = {
        for (final adicional in adicionalesAsync.where((a) => a.disponible))
          adicional.id: adicional,
      };
      final idsValidos = <String>[];
      final adicionales = <AdditionalModel>[];

      for (final id in adicionalesSeleccionados) {
        final adicional = adicionalesDisponibles[id];
        if (adicional != null) {
          idsValidos.add(id);
          adicionales.add(adicional);
        }
      }

      final item = ItemCarrito(
        producto: widget.producto,
        cantidad: cantidad,
        modificacionesSeleccionadas: idsValidos,
        notas: _notasController.text,
        precioUnitario: widget.producto.price,
        adicionales: adicionales.isEmpty ? null : adicionales,
      );
      ref.read(carritoControllerProvider).agregarItem(item);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError('Error al agregar al carrito: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adicionalesAsync = ref.watch(additionalProvider);
    final precioTotal = _calcularPrecioTotal();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1B23),
            Color(0xFF2D2E37),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // HANDLE BAR
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER COMPACTO DEL PRODUCTO
                  _buildProductHeader(),
                  const SizedBox(height: 24),
                  
                  // INGREDIENTES
                  if (widget.producto.ingredientes.isNotEmpty) ...[
                    _buildIngredientesSection(),
                    const SizedBox(height: 20),
                  ],
                  
                  // ADICIONALES
                  adicionalesAsync.when(
                    data: (adicionales) => _buildAdicionalesSection(adicionales),
                    loading: () => _buildLoadingSection(),
                    error: (error, stack) => _buildErrorSection(error.toString()),
                  ),
                  const SizedBox(height: 20),
                  
                  // NOTAS
                  _buildNotasSection(),
                  const SizedBox(height: 20),
                  
                  // CANTIDAD Y TOTAL
                  _buildCantidadSection(precioTotal),
                ],
              ),
            ),
          ),
          // BOTÓN DE AGREGAR
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Row(
      children: [
        // IMAGEN DEL PRODUCTO
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
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
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          strokeWidth: 2,
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
        // INFORMACIÓN DEL PRODUCTO
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.producto.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '\$${widget.producto.price.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.producto.disponible
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.producto.disponible ? 'Disponible' : 'No disponible',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.producto.ingredientes,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdicionalesSection(List<AdditionalModel> adicionales) {
    final disponibles = adicionales
        .where((adicional) => adicional.disponible)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    if (disponibles.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adicionales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No hay adicionales disponibles en este momento.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adicionales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...disponibles.map((adicional) => _buildAdicionalTile(adicional)).toList(),
      ],
    );
  }

  Widget _buildAdicionalTile(AdditionalModel adicional) {
    final isSelected = adicionalesSeleccionados.contains(adicional.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(
          adicional.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '+\$${adicional.price.toStringAsFixed(0).replaceAllMapped(
                RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              )}',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        value: isSelected,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  Widget _buildNotasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas especiales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notasController,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Instrucciones especiales para la cocina...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.grey.shade800.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildCantidadSection(double precioTotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cantidad',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CantidadSelector(
              cantidad: cantidad,
              onCantidadChanged: (value) => setState(() => cantidad = value),
              enabled: widget.producto.disponible,
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${precioTotal.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      )}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final puedeAgregar = widget.producto.disponible && !_pedidoFinalizado;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pedidoFinalizado) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade700.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade700.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mensajeEstado,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No se pueden agregar más productos a este pedido',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: puedeAgregar ? _agregarAlCarrito : null,
              icon: Icon(
                _pedidoFinalizado ? Icons.block : Icons.add_shopping_cart,
              ),
              label: Text(
                _pedidoFinalizado 
                    ? 'Pedido finalizado'
                    : !widget.producto.disponible
                        ? 'Producto no disponible'
                        : 'Agregar al carrito',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: puedeAgregar
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
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

  Widget _buildLoadingSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adicionales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildErrorSection(String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adicionales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Error: $error',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  double _calcularPrecioTotal() {
    double total = widget.producto.price * cantidad;
    
    // Agregar precio de adicionales
    final adicionalesAsync = ref.read(additionalProvider);
    adicionalesAsync.whenData((adicionales) {
      for (final adicionalId in adicionalesSeleccionados) {
        final adicional = adicionales.firstWhere(
          (a) => a.id == adicionalId,
          orElse: () => AdditionalModel(
            id: '',
            name: '',
            price: 0,
            disponible: false,
          ),
        );
        total += adicional.price * cantidad;
      }
    });
    
    return total;
  }
}
