import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class _MesasScreenState extends ConsumerState<MesasScreen> {
  int? mesaSeleccionadaId;
  String filtro = 'Todas';
  String searchTerm = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mesasAsync = ref.watch(mesasStreamProvider);
    final notifier = ref.read(mesasMeseroProvider.notifier);

    return mesasAsync.when(
      data: (mesas) {
        final mesasFiltradas = _filtrarMesas(mesas);
        final mesaSeleccionada =
            _obtenerMesaSeleccionada(mesasFiltradas, mesaSeleccionadaId);

        return Scaffold(
          appBar: _buildAppBar(notifier),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Contenido principal
              Container(
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
                child: Column(
                  children: [
                    const SizedBox(height: 90),
                    _buildEstadisticas(notifier, mesas),
                    _buildFiltros(),
                    _buildBuscador(),
                    Expanded(
                      child: _buildGridMesas(mesasFiltradas),
                    ),
                  ],
                ),
              ),

              // Overlay semi-transparente (SEPARADO del panel)
              if (mesaSeleccionada != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        mesaSeleccionadaId = null;
                      });
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),

              // Panel de acciones (ENCIMA del overlay)
              if (mesaSeleccionada != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {}, // Previene que el tap en el panel lo cierre
                    child: Align(
                      child: _buildAccionesRapidas(mesaSeleccionada),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
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
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B5CF6),
            ),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined,
                color: Colors.white),
            onPressed: () => context.pop(),
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(MesasNotifier notifier) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
      height: 45,
      margin: const EdgeInsets.all(16),
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
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : Colors.white.withOpacity(0.3),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filtroActual,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
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

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        onChanged: (value) => setState(() => searchTerm = value.trim()),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por mesa, cliente o capacidad',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: searchTerm.isNotEmpty
              ? IconButton(
                  onPressed: () => setState(() => searchTerm = ''),
                  icon: const Icon(Icons.clear, color: Colors.white54),
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
          ),
        ),
      ),
    );
  }

  List<MesaModel> _filtrarMesas(List<MesaModel> mesas) {
    final filtradasPorEstado = filtro == 'Todas'
        ? mesas
        : mesas.where((m) => m.estado == filtro).toList();

    if (searchTerm.isEmpty) {
      return filtradasPorEstado;
    }

    final termino = searchTerm.toLowerCase();
    return filtradasPorEstado.where((mesa) {
      final numeroMesa = 'mesa ${mesa.id}'.toLowerCase();
      final cliente = (mesa.cliente ?? '').toLowerCase();
      final capacidad = mesa.capacidad.toString();

      return numeroMesa.contains(termino) ||
          mesa.id.toString().contains(termino) ||
          cliente.contains(termino) ||
          capacidad.contains(termino);
    }).toList();
  }

  MesaModel? _obtenerMesaSeleccionada(List<MesaModel> mesas, int? seleccionId) {
    if (seleccionId == null) return null;
    for (final mesa in mesas) {
      if (mesa.id == seleccionId) {
        return mesa;
      }
    }
    return null;
  }

  Widget _buildAccionesRapidas(MesaModel mesa) {
    final colorEstado = _colorPorEstado(mesa.estado);
    final iconoEstado = _iconoPorEstado(mesa.estado);
    final estadoTexto = _estadoCapitalizado(mesa.estado);

    return Container(
      key:
          ValueKey('acciones-${mesa.id}-${mesa.estado}-${mesa.pedidoId ?? ''}'),
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 0),
      decoration: const  BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          left: BorderSide(color: Colors.white24),
          right: BorderSide(color: Colors.white24),
          top: BorderSide(color: Colors.white24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorEstado.withOpacity(0.18),
                child: Icon(iconoEstado, color: colorEstado),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mesa ${mesa.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$estadoTexto · ${mesa.capacidad} personas',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (mesa.cliente != null && mesa.cliente!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Cliente: ${mesa.cliente}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (mesa.estado == 'ocupada')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 16, color: colorEstado),
                            const SizedBox(width: 6),
                            Text(
                              mesa.tiempoTranscurrido,
                              style: TextStyle(
                                color: colorEstado,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (mesa.estado == 'reservada' &&
                        mesa.tiempo != null &&
                        mesa.tiempo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: colorEstado),
                            const SizedBox(width: 6),
                            Text(
                              mesa.tiempo!,
                              style: TextStyle(
                                color: colorEstado,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => mesaSeleccionadaId = null),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._accionesRapidasPorEstado(mesa),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _mostrarOpcionesMesa(mesa),
              icon: const Icon(Icons.more_horiz, color: Colors.white70),
              label: const Text(
                'Más opciones',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _accionesRapidasPorEstado(MesaModel mesa) {
    switch (mesa.estado) {
      case 'disponible':
        return [
          _buildAccionPrincipal(
            titulo: 'Tomar pedido rápido',
            icono: Icons.flash_on,
            color: const Color(0xFF8B5CF6),
            onPressed: () {
              _crearPedidoRapido(mesa);
            },
          ),
          const SizedBox(height: 10),
          _buildAccionSecundaria(
            titulo: 'Reservar mesa',
            icono: Icons.event_available,
            onPressed: () {
              _reservarMesa(mesa, closeSheet: false);
            },
          ),
        ];

      case 'ocupada':
        return [
          _buildAccionPrincipal(
            titulo: 'Abrir pedido',
            icono: Icons.receipt_long,
            color: Colors.green,
            onPressed: () {
              _verPedido(mesa, closeSheet: false);
            },
          ),
          const SizedBox(height: 10),
          _buildAccionSecundaria(
            titulo: 'Agregar productos',
            icono: Icons.add_circle_outline,
            onPressed: () {
              _agregarAlPedido(mesa, closeSheet: false);
            },
          ),
          const SizedBox(height: 10),
          _buildAccionSecundaria(
            titulo: 'Liberar mesa',
            icono: Icons.logout,
            color: Colors.orange,
            onPressed: () {
              _liberarMesa(mesa, closeSheet: false);
            },
          ),
        ];

      case 'reservada':
        return [
          _buildAccionPrincipal(
            titulo: 'Confirmar llegada',
            icono: Icons.check_circle,
            color: Colors.green,
            onPressed: () {
              _confirmarLlegada(mesa, closeSheet: false);
            },
          ),
          const SizedBox(height: 10),
          _buildAccionSecundaria(
            titulo: 'Cancelar reserva',
            icono: Icons.cancel_schedule_send,
            color: Colors.red,
            onPressed: () {
              _cancelarReserva(mesa, closeSheet: false);
            },
          ),
        ];

      default:
        return [];
    }
  }

  Future<void> _crearPedidoRapido(MesaModel mesa) async {
    await _crearPedidoParaMesa(
      mesa,
      clienteMesa: 'Pedido rapido',
      etiquetaPedido: 'Pedido rapido',
    );
  }

  Future<void> _crearPedidoParaMesa(
    MesaModel mesa, {
    required String? clienteMesa,
    String? etiquetaPedido,
  }) async {
    final pedidoId = const Uuid().v4();
    final tableUuid = const Uuid().v4();

    final clienteCrudo = clienteMesa?.trim();
    final etiquetaCruda = etiquetaPedido?.trim();
    final clienteParaMesa =
        (clienteCrudo == null || clienteCrudo.isEmpty) ? null : clienteCrudo;
    final clienteVisible = (etiquetaCruda != null && etiquetaCruda.isNotEmpty)
        ? etiquetaCruda
        : (clienteParaMesa ?? 'Cliente');

    String? meseroId;
    String meseroNombre = 'Mesero desconocido';

    try {
      final user = await ref.read(userModelProvider.future);
      meseroId = user.uid;
      meseroNombre = '${user.nombre} ${user.apellidos}'.trim();
    } catch (e) {
      debugPrint('Error obteniendo mesero: $e');
    }

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
      cliente: clienteParaMesa,
      notas: null,
      meseroId: meseroId,
      meseroNombre: meseroNombre,
      mesaId: mesa.id,
      mesaNombre: 'Mesa ${mesa.id}',
      clienteNombre: clienteVisible,
    );

    final mesaActualizada = mesa.copyWith(
      estado: 'ocupada',
      cliente: clienteParaMesa,
      pedidoId: pedidoId,
      horaOcupacion: DateTime.now(),
    );

    ref.read(pedidos.pedidosProvider.notifier).agregarPedido(nuevoPedido);
    await ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);

    _irADetallePedido(mesaActualizada, pedidoId, clienteVisible);
  }

  void _irADetallePedido(
    MesaModel mesa,
    String pedidoId,
    String clienteNombre,
  ) {
    if (!mounted) return;
    final mesaNombreEncoded = Uri.encodeComponent('Mesa ${mesa.id}');
    final clienteNombreEncoded = Uri.encodeComponent(clienteNombre);
    context.push(
      '/mesero/pedidos/detalle/${mesa.id}/$pedidoId?mesaId=${mesa.id}&mesaNombre=$mesaNombreEncoded&clienteNombre=$clienteNombreEncoded',
    );
  }

  Widget _buildAccionPrincipal({
    required String titulo,
    required IconData icono,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: 22),
        label: Text(
          titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAccionSecundaria({
    required String titulo,
    required IconData icono,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final borderColor = color ?? Colors.white54;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, size: 20, color: color ?? Colors.white),
        label: Text(
          titulo,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: borderColor.withOpacity(0.8), width: 1.5),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'disponible':
        return Colors.green;
      case 'ocupada':
        return Colors.orange;
      case 'reservada':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _iconoPorEstado(String estado) {
    switch (estado) {
      case 'disponible':
        return Icons.check_circle;
      case 'ocupada':
        return Icons.people;
      case 'reservada':
        return Icons.event_available;
      default:
        return Icons.help_outline;
    }
  }

  String _estadoCapitalizado(String estado) {
    if (estado.isEmpty) return 'Sin estado';
    return estado[0].toUpperCase() + estado.substring(1);
  }

  void _ejecutarAccionPrincipal(MesaModel mesa) {
    switch (mesa.estado) {
      case 'disponible':
        _crearPedidoRapido(mesa);
        break;
      case 'ocupada':
        _verPedido(mesa, closeSheet: false);
        break;
      case 'reservada':
        _confirmarLlegada(mesa, closeSheet: false);
        break;
      default:
        break;
    }
  }

  Widget _buildGridMesas(List<MesaModel> mesas) {
    if (mesas.isEmpty) {
      final buscando = searchTerm.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              buscando
                  ? 'No encontramos resultados para "$searchTerm"'
                  : 'No hay mesas ${filtro == 'Todas' ? '' : filtro.toLowerCase()}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (buscando) ...[
              const SizedBox(height: 8),
              Text(
                'Verifica el número de mesa o el nombre del cliente',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (filtro == 'Todas') ...[
              const SizedBox(height: 8),
              Text(
                'Contacta al administrador para crear mesas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildMesaCard(MesaModel mesa) {
    final isSelected = mesa.id == mesaSeleccionadaId;
    final colorEstado = _colorPorEstado(mesa.estado);
    final iconoEstado = _iconoPorEstado(mesa.estado);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          if (isSelected) {
            mesaSeleccionadaId = null;
          } else {
            mesaSeleccionadaId = mesa.id;
          }
        });
      },
      onDoubleTap: () {
        setState(() => mesaSeleccionadaId = mesa.id);
        _ejecutarAccionPrincipal(mesa);
      },
      onLongPress: () => _mostrarOpcionesMesa(mesa),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
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
                    colorEstado.withOpacity(0.3),
                    colorEstado.withOpacity(0.2),
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
                            color: Colors.white.withOpacity(0.6), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${mesa.capacidad} personas',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
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
    setState(() => mesaSeleccionadaId = mesa.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildOpcionesBottomSheet(mesa),
    );
  }

  Widget _buildOpcionesBottomSheet(MesaModel mesa) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mesa ${mesa.id}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '${mesa.capacidad} personas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
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
            const Color(0xFF8B5CF6),
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
            () {
              _liberarMesa(mesa);
            },
          ),
        ];

      case 'reservada':
        return [
          _buildBotonOpcion(
            'Confirmar Llegada',
            Icons.check_circle,
            Colors.green,
            () {
              _confirmarLlegada(mesa);
            },
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

  void _ocuparMesa(MesaModel mesa, {bool closeSheet = true}) {
    if (closeSheet) {
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => OcuparMesaDialog(
        mesa: mesa,
        onOcupar: (cliente) async {
          await _crearPedidoParaMesa(
            mesa,
            clienteMesa: cliente,
            etiquetaPedido: cliente,
          );
        },
      ),
    );
  }

  void _reservarMesa(MesaModel mesa, {bool closeSheet = true}) {
    if (closeSheet) {
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => ReservarMesaDialog(
        mesa: mesa,
        onReservar: (cliente, fecha, hora) async {
          final mesaActualizada = mesa.copyWith(
            estado: 'reservada',
            cliente: cliente,
            fechaReserva: fecha,
            tiempo: hora,
          );
          await ref
              .read(mesasMeseroProvider.notifier)
              .editarMesa(mesaActualizada);
        },
      ),
    );
  }

  void _verPedido(MesaModel mesa, {bool closeSheet = true}) {
    if (closeSheet) {
      Navigator.pop(context);
    }
    if (mesa.pedidoId != null && mounted) {
      context.push('/mesero/pedidos/detalle/${mesa.id}/${mesa.pedidoId}');
    }
  }

  void _agregarAlPedido(MesaModel mesa, {bool closeSheet = true}) {
    if (closeSheet) {
      Navigator.pop(context);
    }
    if (mesa.pedidoId != null && mounted) {
      context.push('/mesero/pedidos/detalle/${mesa.id}/${mesa.pedidoId}');
    }
  }

  Future<void> _cancelarPedidoActivo(MesaModel mesa) async {
    final pedidoId = mesa.pedidoId;
    if (pedidoId == null || pedidoId.isEmpty) {
      return;
    }

    try {
      final pedidoRef =
          FirebaseFirestore.instance.collection('pedido').doc(pedidoId);
      final snapshot = await pedidoRef.get();
      if (snapshot.exists) {
        await pedidoRef.update({
          'status': 'cancelado',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error al cancelar pedido $pedidoId: $e');
    } finally {
      ref.read(pedidos.pedidosProvider.notifier).eliminarPedido(pedidoId);
    }
  }

  Future<void> _liberarMesa(MesaModel mesa, {bool closeSheet = true}) async {
    if (closeSheet && mounted) {
      Navigator.pop(context);
    }

    final shouldRelease = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

    if (shouldRelease != true || !mounted) {
      return;
    }

    try {
      await _cancelarPedidoActivo(mesa);

      final mesaActualizada = mesa.copyWith(
        estado: 'disponible',
        cliente: null,
        tiempo: null,
        pedidoId: null,
        horaOcupacion: null,
        total: null,
        fechaReserva: null,
      );

      await ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);

      setState(() => mesaSeleccionadaId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesa liberada y pedido cancelado.')),
      );
    } catch (e) {
      print('Error liberando mesa ${mesa.id}: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo liberar la mesa. Inténtalo nuevamente.'),
        ),
      );
    }
  }

  Future<void> _confirmarLlegada(MesaModel mesa,
      {bool closeSheet = true}) async {
    if (closeSheet) {
      Navigator.pop(context);
    }

    await _crearPedidoParaMesa(
      mesa,
      clienteMesa: mesa.cliente,
      etiquetaPedido: mesa.cliente,
    );
  }

  void _cancelarReserva(MesaModel mesa, {bool closeSheet = true}) {
    if (closeSheet) {
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
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
              ref
                  .read(mesasMeseroProvider.notifier)
                  .editarMesa(mesaActualizada);
              setState(() => mesaSeleccionadaId = null);
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
