import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/presentation/providers/login/auth_service.dart';
import 'package:restaurante_app/presentation/widgets/dialog_ocupar_mesa.dart';
import 'package:restaurante_app/presentation/widgets/dialog_reservar_mesa.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart'
    as pedidos;
import 'package:restaurante_app/data/models/mesa_model.dart';
import 'package:restaurante_app/presentation/providers/mesero/mesas_provider.dart';
import 'package:restaurante_app/presentation/widgets/build_stadistics_mesas.dart';

class MesasScreen extends ConsumerStatefulWidget {
  const MesasScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MesasScreenState();
}

class _MesasScreenState extends ConsumerState<MesasScreen>
    with TickerProviderStateMixin {
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
    final mesasAsync = ref.watch(mesasStreamProvider);
    final notifier = ref.read(mesasMeseroProvider.notifier);

    return mesasAsync.when(
      data: (mesas) {
        final mesasFiltradas = filtro == 'Todas'
            ? mesas
            : mesas.where((m) => m.estado == filtro).toList();

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: _buildAppBar(notifier),
          body: Column(
            children: [
              _buildEstadisticas(notifier, mesas),
              _buildFiltros(),
              Expanded(
                child: _buildGridMesas(mesasFiltradas),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
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
        ),
        body: Center(
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
                'Error al cargar las mesas',
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.refresh(mesasStreamProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
        );
  }

  PreferredSizeWidget _buildAppBar(MesasNotifier notifier) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_outlined,
            color: Colors.white70),
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
          onPressed: () => ref.refresh(mesasStreamProvider),
        ),
      ],
    );
  }

  Widget _buildEstadisticas(MesasNotifier notifier, List<MesaModel> mesas) {
    final disponibles = mesas.where((m) => m.estado == 'disponible').length;
    final ocupadas = mesas.where((m) => m.estado == 'ocupada').length;
    final reservadas = mesas.where((m) => m.estado == 'reservada').length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.07),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard_outlined, color: Colors.white70, size: 24),
              SizedBox(width: 8),
              Text(
                'Estadísticas de Mesas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              buildEstadisticaItem(
                'Disponibles',
                disponibles.toString(),
                Colors.green,
                Icons.check_circle_outline,
              ),
              buildEstadisticaItem(
                'Ocupadas',
                ocupadas.toString(),
                Colors.orange,
                Icons.people_outline,
              ),
              buildEstadisticaItem(
                'Reservadas',
                reservadas.toString(),
                Colors.blue,
                Icons.event_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    final filtros = ['Todas', 'disponible', 'ocupada', 'reservada'];

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
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Color.fromRGBO(
                            Theme.of(context).primaryColor.red,
                            Theme.of(context).primaryColor.green,
                            Theme.of(context).primaryColor.blue,
                            0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
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
            if (filtro == 'Todas') ...[
              const SizedBox(height: 8),
              Text(
                'Contacta al administrador para crear mesas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
          childAspectRatio: 0.85,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
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

    switch (mesa.estado) {
      case 'disponible':
        colorEstado = Colors.green;
        iconoEstado = Icons.check_circle;
        break;
      case 'ocupada':
        colorEstado = Colors.orange;
        iconoEstado = Icons.people;
        break;
      case 'reservada':
        colorEstado = Colors.blue;
        iconoEstado = Icons.event;
        break;
      default:
        colorEstado = Colors.grey;
        iconoEstado = Icons.help;
    }

    return GestureDetector(
      onTap: () => _mostrarOpcionesMesa(mesa),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Color.fromRGBO(
            colorEstado.red,
            colorEstado.green,
            colorEstado.blue,
            0.1,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Color.fromRGBO(
                    colorEstado.red,
                    colorEstado.green,
                    colorEstado.blue,
                    0.3,
                  ),
            width: isSelected ? 2 : 1,
          ),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(colorEstado.red, colorEstado.green, colorEstado.blue, 0.3),
                    Color.fromRGBO(colorEstado.red, colorEstado.green, colorEstado.blue, 0.2),
                  ],
                ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorEstado.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconoEstado, color: colorEstado, size: 16),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_outline,
                            color: Colors.grey.shade600, size: 14),
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
                                         if (mesa.estado != 'disponible') ...[
                       Text(
                         mesa.cliente ?? '',
                         style: const TextStyle(
                           fontWeight: FontWeight.w600,
                           fontSize: 13,
                           color: Colors.white70,
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                       if (mesa.estado == 'ocupada') ...[
                         Row(
                           children: [
                             Icon(Icons.access_time,
                                 size: 12, color: colorEstado),
                             const SizedBox(width: 4),
                             Text(
                               mesa.tiempoTranscurrido,
                               style: TextStyle(
                                 color: colorEstado,
                                 fontSize: 11,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ],
                         ),
                       ] else if (mesa.estado == 'reservada') ...[
                         Row(
                           children: [
                             Icon(Icons.schedule, size: 12, color: colorEstado),
                             const SizedBox(width: 4),
                             Text(
                               mesa.tiempo ?? '',
                               style: TextStyle(
                                 color: colorEstado,
                                 fontSize: 11,
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
          Text(
            '${mesa.capacidad} personas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          if (mesa.cliente != null) ...[
            const SizedBox(height: 8),
            Text(
              mesa.cliente!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 24),
          ...(_buildOpcionesSegunEstado(mesa)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildOpcionesSegunEstado(MesaModel mesa) {
    switch (mesa.estado) {
      case 'disponible':
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

      case 'ocupada':
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

      case 'reservada':
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

  Widget _buildBotonOpcion(
      String texto, IconData icono, Color color, VoidCallback onPressed) {
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

  void _ocuparMesa(MesaModel mesa) {
  Navigator.pop(context);
  showDialog(
    context: context,
    builder: (context) => OcuparMesaDialog(
      mesa: mesa,
      onOcupar: (cliente) async {
        final pedidoId = const Uuid().v4();
        final tableUuid = const Uuid().v4();
        
        try {
          // ✅ OBTENER INFORMACIÓN DEL MESERO ACTUAL correctamente
          final userAsync = await ref.read(userModelProvider.future); // ✅ Usar .future
          
          print("🔧 OCUPANDO MESA:");
          print("   - Mesa ID: ${mesa.id}");
          print("   - Pedido ID: $pedidoId");
          print("   - Mesero: ${userAsync.nombre} ${userAsync.apellidos}"); // ✅ Ahora funciona
          
          final nuevoPedido = Pedido(
            id: pedidoId,
            status: 'pendiente',
            mode: 'mesa',
            subtotal: 0.0,
            total: 0.0,
            tableNumber: tableUuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            items: [],
            cliente: cliente,
            notas: null,
            meseroId: userAsync.uid,                           // ✅ Usar userAsync
            meseroNombre: '${userAsync.nombre} ${userAsync.apellidos}', // ✅ Usar userAsync
          );

          final mesaActualizada = mesa.copyWith(
            estado: 'ocupada',
            cliente: cliente,
            pedidoId: pedidoId,
            horaOcupacion: DateTime.now(),
          );

          ref.read(pedidos.pedidosProvider.notifier).agregarPedido(nuevoPedido);
          ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);

          context.push('/mesero/pedidos/detalle/${mesa.id}/$pedidoId');
        } catch (e) {
          // ✅ Crear pedido sin mesero si falla
          final nuevoPedido = Pedido(
            id: pedidoId,
            status: 'pendiente',
            mode: 'mesa',
            subtotal: 0.0,
            total: 0.0,
            tableNumber: tableUuid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            items: [],
            cliente: cliente,
            notas: null,
            meseroId: null,
            meseroNombre: 'Mesero desconocido',
          );

          final mesaActualizada = mesa.copyWith(
            estado: 'ocupada',
            cliente: cliente,
            pedidoId: pedidoId,
            horaOcupacion: DateTime.now(),
          );

          ref.read(pedidos.pedidosProvider.notifier).agregarPedido(nuevoPedido);
          ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);

          context.push('/mesero/pedidos/detalle/${mesa.id}/$pedidoId');
        }
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
             estado: 'reservada',
             cliente: cliente,
             fechaReserva: fecha,
             tiempo: hora,
           );
          ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);
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
      context.push('/mesero/pedidos/detalle/${mesa.id}/${mesa.pedidoId}');
    }
  }

  void _liberarMesa(MesaModel mesa) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Liberar Mesa',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Está seguro que desea liberar la Mesa ${mesa.id}?\n\nEsta acción finalizará el pedido actual.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
                             final mesaActualizada = mesa.copyWith(
                 estado: 'disponible',
                 cliente: null,
                 tiempo: null,
                 pedidoId: null,
                 horaOcupacion: null,
                 total: null,
               );
              ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Liberar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarLlegada(MesaModel mesa) async {
  Navigator.pop(context);

  final pedidoId = const Uuid().v4();
  final tableUuid = const Uuid().v4();
  
  try {
    // ✅ OBTENER INFORMACIÓN DEL MESERO ACTUAL correctamente
    final userAsync = await ref.read(userModelProvider.future); // ✅ Usar .future
    
    final nuevoPedido = Pedido(
      id: pedidoId,
      status: 'pendiente',
      mode: 'mesa',
      subtotal: 0.0,
      total: 0.0,
      tableNumber: tableUuid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
      cliente: mesa.cliente,
      notas: null,
      meseroId: userAsync.uid,                           // ✅ Usar userAsync
      meseroNombre: '${userAsync.nombre} ${userAsync.apellidos}', // ✅ Usar userAsync
    );

    final mesaActualizada = mesa.copyWith(
      estado: 'ocupada',
      horaOcupacion: DateTime.now(),
      pedidoId: pedidoId,
    );

    ref.read(pedidos.pedidosProvider.notifier).agregarPedido(nuevoPedido);
    ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);

    context.push('/mesero/pedidos/detalle/${mesa.id}/$pedidoId');
  } catch (e) {
    print("🚨 ERROR OBTENIENDO USUARIO: $e");
    // Crear pedido sin mesero si falla
    final nuevoPedido = Pedido(
      id: pedidoId,
      status: 'pendiente',
      mode: 'mesa',
      subtotal: 0.0,
      total: 0.0,
      tableNumber: tableUuid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
      cliente: mesa.cliente,
      notas: null,
      meseroId: null,
      meseroNombre: 'Mesero desconocido',
    );

    final mesaActualizada = mesa.copyWith(
      estado: 'ocupada',
      horaOcupacion: DateTime.now(),
      pedidoId: pedidoId,
    );

    ref.read(pedidos.pedidosProvider.notifier).agregarPedido(nuevoPedido);
    ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);

    context.push('/mesero/pedidos/detalle/${mesa.id}/$pedidoId');
  }
}



  void _cancelarReserva(MesaModel mesa) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cancelar Reserva',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Está seguro que desea cancelar la reserva de la Mesa ${mesa.id} para ${mesa.cliente}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
                             final mesaActualizada = mesa.copyWith(
                 estado: 'disponible',
                 cliente: null,
                 tiempo: null,
                 fechaReserva: null,
               );
              ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar Reserva',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
