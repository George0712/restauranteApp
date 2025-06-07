import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/presentation/widgets/dialog_ocupar_mesa.dart';
import 'package:restaurante_app/presentation/widgets/dialog_reservar_mesa.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/data/providers/mesero/pedidos_provider.dart' as pedidos;
import 'package:restaurante_app/data/models/mesa_model.dart';
import 'package:restaurante_app/data/providers/mesero/mesas_provider.dart';
import 'package:restaurante_app/presentation/widgets/build_stadistics_mesas.dart';

class MesasScreen extends ConsumerStatefulWidget {
  const MesasScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MesasScreenState();
}

class _MesasScreenState extends ConsumerState<MesasScreen> with TickerProviderStateMixin {
  int? mesaSeleccionadaId;
  String filtro = 'Todas';
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mesas = ref.watch(mesasProvider);
    final notifier = ref.read(mesasProvider.notifier);
    final mesasFiltradas = filtro == 'Todas' ? mesas : mesas.where((m) => m.estado == filtro).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(theme, notifier),
      body: Column(
        children: [
          _buildEstadisticas(notifier),
          _buildFiltros(),
          Expanded(
            child: _buildGridMesas(mesasFiltradas),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, MesasNotifier notifier) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white70),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Gestión de Mesas',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined, color: Colors.white70),
          onPressed: () => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildEstadisticas(MesasNotifier notifier) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          buildEstadisticaItem(
            'Disponibles',
            notifier.mesasDisponibles.toString(),
            Colors.green,
            Icons.check_circle_outline,
          ),
          buildEstadisticaItem(
            'Ocupadas',
            notifier.mesasOcupadas.toString(),
            Colors.orange,
            Icons.people_outline,
          ),
          buildEstadisticaItem(
            'Reservadas',
            notifier.mesasReservadas.toString(),
            Colors.blue,
            Icons.event_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final filtros = ['Todas', 'Disponible', 'Ocupada', 'Reservada'];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        itemBuilder: (context, index) {
          final filtroActual = filtros[index];
          final isSelected = filtro == filtroActual;
          
          return GestureDetector(
            onTap: () => setState(() => filtro = filtroActual),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Text(
                filtroActual,
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
  }

  Widget _buildGridMesas(List<MesaModel> mesas) {
    if (mesas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay mesas ${filtro == 'Todas' ? '' : filtro.toLowerCase()}',
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
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        controller: _scrollController,
        itemCount: mesas.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          childAspectRatio: 1,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final mesa = mesas[index];
          return _buildMesaCard(mesa);
        },
      ),
    );
  }

  Widget _buildMesaCard(MesaModel mesa) {
    final isSelected = mesa.id == mesaSeleccionadaId;
    Color colorEstado;
    IconData iconoEstado;
    Color colorFondo;

    switch(mesa.estado) {
      case 'Disponible':
        colorEstado = Colors.green;
        iconoEstado = Icons.check_circle;
        colorFondo = Colors.green.withAlpha(25);
        break;
      case 'Ocupada':
        colorEstado = Colors.orange;
        iconoEstado = Icons.people;
        colorFondo = Colors.orange.withAlpha(25);
        break;
      case 'Reservada':
        colorEstado = Colors.blue;
        iconoEstado = Icons.event;
        colorFondo = Colors.blue.withAlpha(25);
        break;
      default:
        colorEstado = Colors.grey;
        iconoEstado = Icons.help;
        colorFondo = Colors.grey.withAlpha(25);
    }

    return GestureDetector(
      onTap: () => _mostrarOpcionesMesa(mesa),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 33, 33, 36),
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header con número y estado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorFondo,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mesa ${mesa.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorEstado,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconoEstado, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          mesa.estado,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido con scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_outline, color: Colors.grey.shade600, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${mesa.capacidad} personas',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    if (mesa.estado != 'Disponible') ...[
                      const SizedBox(height: 12),
                      Text(
                        mesa.cliente ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      if (mesa.estado == 'Ocupada') ...[
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: colorEstado),
                            const SizedBox(width: 4),
                            Text(
                              mesa.tiempoTranscurrido,
                              style: TextStyle(
                                color: colorEstado,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ] else if (mesa.estado == 'Reservada') ...[
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 14, color: colorEstado),
                            const SizedBox(width: 4),
                            Text(
                              mesa.tiempo ?? '',
                              style: TextStyle(
                                color: colorEstado,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(ThemeData theme) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.blueAccent.shade700,
      foregroundColor: Colors.white,
      onPressed: () => _mostrarFormularioMesa(nueva: true),
      icon: const Icon(Icons.add),
      label: const Text('Nueva Mesa'),
    );
  }

  void _mostrarOpcionesMesa(MesaModel mesa) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildOpcionesBottomSheet(mesa),
    );
  }

  Widget _buildOpcionesBottomSheet(MesaModel mesa) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'Mesa ${mesa.id}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          
          if (mesa.cliente != null) ...[
            const SizedBox(height: 8),
            Text(
              mesa.cliente!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          ...(_buildOpcionesSegunEstado(mesa)),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildBotonOpcion(
                  'Editar',
                  Icons.edit_outlined,
                  Colors.blue,
                  () {
                    Navigator.pop(context);
                    _mostrarFormularioMesa(mesa: mesa);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonOpcion(
                  'Eliminar',
                  Icons.delete_outline,
                  Colors.red,
                  () => _confirmarEliminacion(mesa),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildOpcionesSegunEstado(MesaModel mesa) {
    switch (mesa.estado) {
      case 'Disponible':
        return [
          _buildBotonOpcion(
            'Ocupar Mesa',
            Icons.people,
            Colors.green,
            () => _ocuparMesa(mesa),
          ),
          const SizedBox(height: 12),
          _buildBotonOpcion(
            'Reservar',
            Icons.event,
            Colors.blue,
            () => _reservarMesa(mesa),
          ),
        ];
      
      case 'Ocupada':
        return [
          _buildBotonOpcion(
            'Ver Pedido',
            Icons.receipt_long,
            Colors.blue,
            () => _verPedido(mesa),
          ),
          const SizedBox(height: 12),
          _buildBotonOpcion(
            'Agregar al Pedido',
            Icons.add_shopping_cart,
            Colors.green,
            () => _agregarAlPedido(mesa),
          ),
          const SizedBox(height: 12),
          _buildBotonOpcion(
            'Liberar Mesa',
            Icons.logout,
            Colors.orange,
            () => _liberarMesa(mesa),
          ),
        ];
      
      case 'Reservada':
        return [
          _buildBotonOpcion(
            'Confirmar Llegada',
            Icons.check_circle,
            Colors.green,
            () => _confirmarLlegada(mesa),
          ),
          const SizedBox(height: 12),
          _buildBotonOpcion(
            'Cancelar Reserva',
            Icons.cancel,
            Colors.red,
            () => _cancelarReserva(mesa),
          ),
        ];
      
      default:
        return [];
    }
  }

  Widget _buildBotonOpcion(String texto, IconData icono, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: 20),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _mostrarFormularioMesa({MesaModel? mesa, bool nueva = false}) {
    showDialog(
      context: context,
      builder: (context) => _FormularioMesaDialog(
        mesa: mesa,
        esNueva: nueva,
        onGuardar: (mesaActualizada) {
          final notifier = ref.read(mesasProvider.notifier);
          if (nueva) {
            notifier.agregarMesa(mesaActualizada);
          } else {
            notifier.editarMesa(mesaActualizada);
          }
        },
      ),
    );
  }

  void _ocuparMesa(MesaModel mesa) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => OcuparMesaDialog(
        mesa: mesa,
        onOcupar: (cliente) {
          final pedidoId = const Uuid().v4();
          final nuevoPedido = Pedido(
            id: pedidoId,
            mesaId: mesa.id,
            cliente: cliente,
            fecha: DateTime.now(),
            items: [],
            estado: 'pendiente',
          );

          final mesaActualizada = mesa.copyWith(
            estado: 'Ocupada',
            cliente: cliente,
            pedidoId: pedidoId,
            horaOcupacion: DateTime.now(),
          );

          ref.read(pedidos.pedidosProvider.notifier).agregarPedido(nuevoPedido);
          ref.read(mesasProvider.notifier).editarMesa(mesaActualizada);

          context.push('/mesero/pedidos/detalle/${mesa.id}/$pedidoId');
        },
      ),
    );
  }

  void _reservarMesa(MesaModel mesa) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => ReservarMesaDialog(
        mesa: mesa,
        onReservar: (cliente, fecha, hora) {
          final mesaActualizada = mesa.copyWith(
            estado: 'Reservada',
            cliente: cliente,
            fechaReserva: fecha,
            tiempo: hora,
          );
          ref.read(mesasProvider.notifier).editarMesa(mesaActualizada);
        },
      ),
    );
  }

  void _verPedido(MesaModel mesa) {
    Navigator.pop(context);
    if (mesa.pedidoId != null) {
      context.push('/mesero/pedidos/detalle/${mesa.id}/${mesa.pedidoId}');
    }
  }

  void _agregarAlPedido(MesaModel mesa) {
    Navigator.pop(context);
    if (mesa.pedidoId != null) {
      context.push('/mesero/pedidos/agregar-item/${mesa.pedidoId}');
    }
  }

  void _liberarMesa(MesaModel mesa) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liberar Mesa'),
        content: Text('¿Está seguro que desea liberar la Mesa ${mesa.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final mesaActualizada = mesa.copyWith(
                estado: 'Disponible',
                cliente: null,
                tiempo: null,
                pedidoId: null,
                horaOcupacion: null,
                total: null,
              );
              ref.read(mesasProvider.notifier).editarMesa(mesaActualizada);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Liberar'),
          ),
        ],
      ),
    );
  }

  void _confirmarLlegada(MesaModel mesa) {
    Navigator.pop(context);
    final mesaActualizada = mesa.copyWith(
      estado: 'Ocupada',
      horaOcupacion: DateTime.now(),
    );
    ref.read(mesasProvider.notifier).editarMesa(mesaActualizada);
  }

  void _cancelarReserva(MesaModel mesa) {
    Navigator.pop(context);
    final mesaActualizada = mesa.copyWith(
      estado: 'Disponible',
      cliente: null,
      tiempo: null,
      fechaReserva: null,
    );
    ref.read(mesasProvider.notifier).editarMesa(mesaActualizada);
  }

  void _confirmarEliminacion(MesaModel mesa) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Mesa'),
        content: Text('¿Está seguro que desea eliminar la Mesa ${mesa.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(mesasProvider.notifier).eliminarMesa(mesa.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// Dialog para formulario de mesa
class _FormularioMesaDialog extends ConsumerStatefulWidget {
  final MesaModel? mesa;
  final bool esNueva;
  final Function(MesaModel) onGuardar;

  const _FormularioMesaDialog({
    this.mesa,
    required this.esNueva,
    required this.onGuardar,
  });

  @override
  ConsumerState<_FormularioMesaDialog> createState() => _FormularioMesaDialogState();
}

class _FormularioMesaDialogState extends ConsumerState<_FormularioMesaDialog> {
  late TextEditingController _idController;
  late TextEditingController _capacidadController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(
      text: widget.mesa?.id.toString() ?? ''
    );
    _capacidadController = TextEditingController(
      text: widget.mesa?.capacidad.toString() ?? ''
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        widget.esNueva ? 'Nueva Mesa' : 'Editar Mesa',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white70,
        ),
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: 'Número de Mesa',
                prefixIcon: const Icon(Icons.table_restaurant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Ingrese el número de mesa';
                if (int.tryParse(value!) == null) return 'Ingrese un número válido';
                if (int.parse(value) <= 0) return 'El número debe ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacidadController,
              decoration: InputDecoration(
                labelText: 'Capacidad (personas)',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Ingrese la capacidad';
                final capacidad = int.tryParse(value!);
                if (capacidad == null) return 'Ingrese un número válido';
                if (capacidad <= 0) return 'La capacidad debe ser mayor a 0';
                if (capacidad > 20) return 'La capacidad máxima es 20 personas';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardarMesa,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.blueAccent.shade700,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.esNueva ? 'Crear Mesa' : 'Actualizar'),
        ),
      ],
    );
  }

  void _guardarMesa() {
    if (_formKey.currentState!.validate()) {
      final mesa = MesaModel(
        id: int.parse(_idController.text),
        capacidad: int.parse(_capacidadController.text),
        estado: widget.mesa?.estado ?? 'Disponible',
        cliente: widget.mesa?.cliente,
        tiempo: widget.mesa?.tiempo,
        total: widget.mesa?.total,
        pedidoId: widget.mesa?.pedidoId,
        fechaReserva: widget.mesa?.fechaReserva,
        horaOcupacion: widget.mesa?.horaOcupacion,
      );
      
      widget.onGuardar(mesa);
      Navigator.of(context).pop();
    }
  }
}