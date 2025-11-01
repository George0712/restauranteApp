import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/presentation/providers/login/auth_service.dart';
import 'package:restaurante_app/presentation/widgets/payment_bottom_sheet.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/presentation/providers/mesero/pedidos_provider.dart'
    as pedidos;
import 'package:restaurante_app/data/models/mesa_model.dart';
import 'package:restaurante_app/presentation/providers/mesero/mesas_provider.dart';
import 'package:restaurante_app/presentation/providers/notification/notification_provider.dart';

class MesasScreen extends ConsumerStatefulWidget {
  const MesasScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MesasScreenState();
}

class _MesasScreenState extends ConsumerState<MesasScreen> {
  static const Duration _limiteSinConsumo = Duration(minutes: 10);
  static const Duration _limiteAlertaConsumo = Duration(hours: 2);

  int? mesaSeleccionadaId;
  String filtro = 'Todas';
  final ScrollController _scrollController = ScrollController();
  Timer? _tiempoTicker;
  DateTime _relojActual = DateTime.now();
  final Map<int, DateTime> _ocupacionesProcesadas = {};
  final Set<int> _mesasEnProceso = {};

  @override
  void initState() {
    super.initState();
    _iniciarTickerTiempo();
  }

  @override
  void dispose() {
    _tiempoTicker?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _iniciarTickerTiempo() {
    _tiempoTicker?.cancel();
    _tiempoTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _relojActual = DateTime.now();
      });
    });
  }

  Future<void> _onRefresh() async {
    try {
      ref.invalidate(mesasStreamProvider);
      await ref.read(mesasStreamProvider.future);
    } catch (_) {
      // Ignorar errores de refresco
    }
  }

  @override
  Widget build(BuildContext context) {
    final mesasAsync = ref.watch(mesasStreamProvider);

    return mesasAsync.when(
      data: (mesas) {
        final mesasFiltradas = _filtrarMesas(mesas);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _verificarMesasExpiradas(mesas);
        });

        return Scaffold(
          appBar: _buildAppBar(),
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
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildResumenMesas(mesas),
                      Expanded(
                        child: _buildGridMesas(mesasFiltradas),
                      ),
                    ],
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
        tooltip: 'Volver',
      ),
    );
  }

  Widget _buildResumenMesas(List<MesaModel> mesas) {
    final total = mesas.length;
    final disponibles = mesas.where((m) => m.estado == 'disponible').length;
    final ocupadas = mesas.where((m) => m.estado == 'ocupada').length;
    final reservadas = mesas.where((m) => m.estado == 'reservada').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Mesas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
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
                  '$total en sala',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Controla el estado del salón en tiempo real.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatChip(
                  label: 'Todas',
                  value: total,
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.table_restaurant,
                  selected: filtro == 'Todas',
                  onTap: () => setState(() => filtro = 'Todas'),
                ),
                const SizedBox(width: 10),
                _buildStatChip(
                  label: 'Disponibles',
                  value: disponibles,
                  color: const Color(0xFF34D399),
                  icon: Icons.event_available,
                  selected: filtro == 'disponible',
                  onTap: () => setState(() => filtro = 'disponible'),
                ),
                const SizedBox(width: 10),
                _buildStatChip(
                  label: 'Ocupadas',
                  value: ocupadas,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.groups_outlined,
                  selected: filtro == 'ocupada',
                  onTap: () => setState(() => filtro = 'ocupada'),
                ),
                const SizedBox(width: 10),
                _buildStatChip(
                  label: 'Reservadas',
                  value: reservadas,
                  color: const Color(0xFF60A5FA),
                  icon: Icons.event_note_outlined,
                  selected: filtro == 'reservada',
                  onTap: () => setState(() => filtro = 'reservada'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final backgroundColor = selected
        ? color.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.08);
    final borderColor = selected
        ? color.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.14);
    final valueColor = selected ? Colors.white : color;
    final iconColor = selected ? Colors.white : color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.4)
                    : color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        Colors.white.withValues(alpha: selected ? 0.9 : 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<MesaModel> _filtrarMesas(List<MesaModel> mesas) {
    if (filtro == 'Todas') {
      return mesas;
    }
    return mesas.where((m) => m.estado == filtro).toList();
  }

  void _mostrarOpcionesMesa(MesaModel mesa) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AccionesRapidasMesaSheet(
        mesa: mesa,
        onCrearPedidoRapido: () => _crearPedidoRapido(mesa, closeSheet: true),
        onReservarMesa: () => _reservarMesa(mesa, closeSheet: true),
        onVerPedido: () => _verPedido(mesa, closeSheet: true),
        onCobrarMesa: () => _cobrarMesa(mesa, closeSheet: true),
        onLiberarMesa: () => _liberarMesa(mesa, closeSheet: true),
        onConfirmarLlegada: () => _confirmarLlegada(mesa, closeSheet: true),
        onCancelarReserva: () => _cancelarReserva(mesa, closeSheet: true),
      ),
    );
  }

  Future<void> _crearPedidoRapido(MesaModel mesa, {bool closeSheet = true}) async {
    if (closeSheet && mounted) {
      Navigator.pop(context);
    }

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

    // Primero cerramos cualquier overlay/sheet y navegamos
    if (mesaSeleccionadaId == mesa.id) {
      setState(() => mesaSeleccionadaId = null);
    }

    // Navegamos inmediatamente para evitar ver cambios de UI
    _irADetallePedido(mesaActualizada, pedidoId, clienteVisible);

    // Luego actualizamos el estado en segundo plano
    // Usamos addPostFrameCallback para asegurar que la navegación ya inició
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(pedidos.pedidosProvider.notifier).agregarPedido(nuevoPedido);
      await ref.read(mesasMeseroProvider.notifier).editarMesa(mesaActualizada);
    });
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

  void _ejecutarAccionPrincipal(MesaModel mesa) {
    switch (mesa.estado) {
      case 'disponible':
        _crearPedidoRapido(mesa, closeSheet: false);
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
    final sinFiltro = filtro == 'Todas';
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _gridColumnCount(width);
    final childAspectRatio = width >= 1100
        ? 1.05
        : width >= 900
            ? 0.95
            : 0.8;

    return RefreshIndicator(
      color: const Color(0xFF8B5CF6),
      backgroundColor: Colors.transparent,
      onRefresh: _onRefresh,
      child: mesas.isEmpty
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 120,
              ),
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_restaurant_outlined,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        sinFiltro
                            ? 'No hay mesas registradas'
                            : 'No hay mesas ${filtro.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        sinFiltro
                            ? 'Contacta al administrador para crear mesas.'
                            : 'Desliza hacia abajo para actualizar.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : GridView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              itemCount: mesas.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
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
    final colorEstado = _colorPorEstado(mesa.estado);
    final iconoEstado = _iconoPorEstado(mesa.estado);
    final estadoTexto = _estadoCapitalizado(mesa.estado);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            mesaSeleccionadaId = null;
          } else {
            mesaSeleccionadaId = mesa.id;
          }
          _mostrarOpcionesMesa(mesa);
        });
      },
      onDoubleTap: () {
        setState(() => mesaSeleccionadaId = mesa.id);
        _ejecutarAccionPrincipal(mesa);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isSelected ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : Colors.white.withValues(alpha: 0.18),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.28 : 0.18),
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorEstado.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: colorEstado.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconoEstado, color: colorEstado, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        estadoTexto,
                        style: TextStyle(
                          color: colorEstado,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Mesa ${mesa.id.toString()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${mesa.capacidad} personas',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            if (mesa.cliente != null && mesa.cliente!.trim().isNotEmpty) ...[
              Text(
                mesa.cliente!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (mesa.estado == 'ocupada') ...[
              const Spacer(),
              _buildTiempoActivoChip(colorEstado, mesa),
            ] else if (mesa.estado == 'reservada') ...[
              const Spacer(),
              _buildReservaChip(colorEstado, mesa),
            ] else ...[
              Text(
                'Disponible para asignar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const Spacer(),
            Divider(color: Colors.white.withValues(alpha: 0.12)),
            Text(
              isSelected ? 'Acciones rápidas' : 'Toca para gestionar',
              style: TextStyle(
                color: Colors.white70.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiempoActivoChip(Color colorEstado, MesaModel mesa) {
    final tiempo = _formatearTiempoActivo(mesa);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, color: colorEstado, size: 16),
        const SizedBox(width: 6),
        Text(
          tiempo,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.4,
            color: colorEstado,
          ),
        ),
      ],
    );
  }

  Widget _buildReservaChip(Color colorEstado, MesaModel mesa) {
    final resumen = _textoReserva(mesa);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_outlined, color: colorEstado, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            resumen,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorEstado,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  String _textoReserva(MesaModel mesa) {
    final fecha = mesa.fechaReserva;
    final hora = mesa.tiempo;

    if (fecha == null) {
      if (hora != null && hora.trim().isNotEmpty) {
        return 'Hoy • $hora';
      }
      return 'Horario por confirmar';
    }

    final fechaFormateada = DateFormat('dd MMM', 'es').format(fecha);
    if (hora != null && hora.trim().isNotEmpty) {
      return '$fechaFormateada • $hora';
    }
    return fechaFormateada;
  }

  int _gridColumnCount(double width) {
    if (width >= 1200) {
      return 4;
    }
    if (width >= 900) {
      return 3;
    }
    return 2;
  }

  String _formatearTiempoActivo(MesaModel mesa) {
    final inicio = mesa.horaOcupacion;
    if (inicio == null) {
      return '00:00:00';
    }

    final diferencia = _relojActual.difference(inicio);
    if (diferencia.isNegative) {
      return '00:00:00';
    }

    final horas = diferencia.inHours;
    final minutos = diferencia.inMinutes % 60;
    final segundos = diferencia.inSeconds % 60;

    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  void _notificarLiberacionAutomatica(
    MesaModel mesa, {
    required String motivo,
    required Duration duracion,
    String? estadoPedido,
    String? pedidoId,
  }) {
    ref.read(notificationCenterProvider.notifier).notifyMesaAutoRelease(
          mesaId: mesa.id,
          cliente: mesa.cliente,
          motivo: motivo,
          tiempoOcupacion: duracion,
          estadoPedido: estadoPedido,
          pedidoId: pedidoId,
        );
  }

  void _verificarMesasExpiradas(List<MesaModel> mesas) {
    for (final mesa in mesas) {
      final hora = mesa.horaOcupacion;

      if (mesa.estado != 'ocupada' || hora == null) {
        _ocupacionesProcesadas.remove(mesa.id);
        _mesasEnProceso.remove(mesa.id);
        continue;
      }

      final procesada = _ocupacionesProcesadas[mesa.id];
      if (procesada != null && !procesada.isAtSameMomentAs(hora)) {
        _ocupacionesProcesadas.remove(mesa.id);
        _mesasEnProceso.remove(mesa.id);
      }

      final duracion = _relojActual.difference(hora);
      if (duracion < _limiteSinConsumo) {
        _ocupacionesProcesadas.remove(mesa.id);
        _mesasEnProceso.remove(mesa.id);
        continue;
      }

      if (_ocupacionesProcesadas[mesa.id]?.isAtSameMomentAs(hora) ?? false) {
        continue;
      }

      if (_mesasEnProceso.contains(mesa.id)) {
        continue;
      }

      _mesasEnProceso.add(mesa.id);
      unawaited(_manejarMesaExpirada(mesa));
    }
  }

  Future<void> _manejarMesaExpirada(MesaModel mesa) async {
    final hora = mesa.horaOcupacion;
    if (hora == null) {
      _mesasEnProceso.remove(mesa.id);
      return;
    }

    final duracion = _relojActual.difference(hora);
    if (duracion < _limiteSinConsumo) {
      _mesasEnProceso.remove(mesa.id);
      return;
    }

    try {
      final pedidoId = mesa.pedidoId;
      if (pedidoId == null || pedidoId.isEmpty) {
        final liberada = await _liberarMesaPorInactividad(mesa);
        if (liberada) {
          _ocupacionesProcesadas[mesa.id] = hora;
          _notificarLiberacionAutomatica(
            mesa,
            motivo: 'Sin pedido asignado',
            duracion: duracion,
            pedidoId: pedidoId,
          );
        }
        return;
      }

      final pedidoRef =
          FirebaseFirestore.instance.collection('pedido').doc(pedidoId);
      final pedidoSnapshot = await pedidoRef.get();

      if (!pedidoSnapshot.exists) {
        final liberada = await _liberarMesaPorInactividad(mesa);
        if (liberada) {
          _ocupacionesProcesadas[mesa.id] = hora;
          _notificarLiberacionAutomatica(
            mesa,
            motivo: 'Pedido no encontrado en el sistema',
            duracion: duracion,
            pedidoId: pedidoId,
          );
        }
        return;
      }

      final pedidoData = pedidoSnapshot.data();
      final statusRaw = (pedidoData?['status'] as String?)?.toLowerCase() ?? '';
      final List<dynamic> items =
          (pedidoData?['items'] as List?)?.cast<dynamic>() ?? const [];
      final List<dynamic> extrasHistory =
          (pedidoData?['extrasHistory'] as List?)?.cast<dynamic>() ?? const [];

      final bool tieneConsumoRegistrado =
          items.isNotEmpty || extrasHistory.isNotEmpty;

      const estadosLiberables = {
        'cancelado',
        'pagado',
        'cerrado',
        'finalizado'
      };

      if (!tieneConsumoRegistrado) {
        final liberada = await _liberarMesaPorInactividad(mesa);
        if (liberada) {
          _ocupacionesProcesadas[mesa.id] = hora;
          _notificarLiberacionAutomatica(
            mesa,
            motivo: 'Pedido sin consumo registrado',
            duracion: duracion,
            estadoPedido: statusRaw.isEmpty ? null : statusRaw,
            pedidoId: pedidoId,
          );
        }
        return;
      }

      if (estadosLiberables.contains(statusRaw)) {
        final liberada = await _liberarMesaPorInactividad(mesa);
        if (liberada) {
          _ocupacionesProcesadas[mesa.id] = hora;
          _notificarLiberacionAutomatica(
            mesa,
            motivo: 'Pedido en estado $statusRaw',
            duracion: duracion,
            estadoPedido: statusRaw.isEmpty ? null : statusRaw,
            pedidoId: pedidoId,
          );
        }
        return;
      }

      if (duracion < _limiteAlertaConsumo) {
        return;
      }

      const estadosActivos = {'pendiente', 'preparando', 'terminado'};
      const estadosPendientesDeCobro = {'entregado', 'completado'};

      final bool pedidoActivo = estadosActivos.contains(statusRaw);
      final bool posiblePendienteCobro =
          estadosPendientesDeCobro.contains(statusRaw) ||
              (!pedidoActivo && !estadosLiberables.contains(statusRaw));

      if (!mounted) {
        return;
      }

      _ocupacionesProcesadas[mesa.id] = hora;

      if (pedidoActivo) {
        SnackbarHelper.showInfo(
          'Mesa ${mesa.id} tiene un pedido activo por mas de 2 horas. Verificar con el cliente.',
        );
      } else if (posiblePendienteCobro) {
        SnackbarHelper.showInfo(
          'Mesa ${mesa.id} registra consumo pendiente de cobro tras 2 horas. Validar antes de liberar.',
        );
      } else {
        SnackbarHelper.showInfo(
          'Mesa ${mesa.id} requiere verificacion manual antes de liberar.',
        );
      }
      return;
    } catch (e) {
      debugPrint(
        'Error al verificar la mesa ${mesa.id} por tiempo excedido: $e',
      );
      _ocupacionesProcesadas.remove(mesa.id);
    } finally {
      _mesasEnProceso.remove(mesa.id);
    }
  }

  Future<bool> _liberarMesaPorInactividad(MesaModel mesa) async {
    final hora = mesa.horaOcupacion;
    if (hora == null) {
      return false;
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

      if (!mounted) {
        return true;
      }

      if (mesaSeleccionadaId == mesa.id) {
        setState(() {
          mesaSeleccionadaId = null;
        });
      }

      SnackbarHelper.showInfo(
        'Mesa ${mesa.id} liberada automaticamente por inactividad.',
      );
      return true;
    } catch (e) {
      debugPrint(
        'Error al liberar automaticamente la mesa ${mesa.id}: $e',
      );
      return false;
    }
  }

  void _reservarMesa(MesaModel mesa, {bool closeSheet = true}) {
    if (closeSheet) {
      context.pop();
    }
  }

  void _verPedido(MesaModel mesa, {bool closeSheet = true}) {
    if (closeSheet) {
      context.pop();
    }
    if (mesa.pedidoId != null && mounted) {
      context.push('/mesero/pedidos/detalle/${mesa.id}/${mesa.pedidoId}');
    }
  }

  Future<void> _cobrarMesa(MesaModel mesa, {bool closeSheet = true}) async {
    if (closeSheet && mounted) {
      context.pop();
    }

    final pedidoId = mesa.pedidoId;
    if (pedidoId == null || pedidoId.isEmpty) {
      SnackbarHelper.showError('No hay un pedido activo para esta mesa.');
      return;
    }

    try {
      final pedidoSnapshot = await FirebaseFirestore.instance
          .collection('pedido')
          .doc(pedidoId)
          .get();

      if (!pedidoSnapshot.exists) {
        SnackbarHelper.showError('No encontramos informacion del pedido.');
        return;
      }

      final data = pedidoSnapshot.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase().trim();
      final pagado = data['pagado'] == true;
      const estadosPermitidos = {'terminado', 'entregado', 'completado'};

      if (pagado) {
        SnackbarHelper.showInfo('El pedido ya fue cobrado.');
        return;
      }

      if (!estadosPermitidos.contains(status)) {
        SnackbarHelper.showInfo(
          'Debes marcar el pedido como terminado antes de cobrar.',
        );
        return;
      }

      if (!mounted) return;
      final cobroCompletado = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaymentBottomSheet(pedidoId: pedidoId),
      );

      if (cobroCompletado == true && mounted) {
        setState(() => mesaSeleccionadaId = null);
        SnackbarHelper.showSuccess('Pago registrado correctamente.');

        // Liberar la mesa después del pago
        await _liberarMesaTrasPago(mesa, pedidoId);

        // Navegar al ticket para mostrar el comprobante
        if (mounted) {
          _navegarAlTicket(mesa, pedidoId);
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      SnackbarHelper.showError(
        'No se pudo iniciar el cobro. Intentalo nuevamente.',
      );
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
      developer.log('Error al cancelar pedido $pedidoId: $e');
    } finally {
      ref.read(pedidos.pedidosProvider.notifier).eliminarPedido(pedidoId);
    }
  }

  Future<void> _liberarMesa(MesaModel mesa, {bool closeSheet = true}) async {
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
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
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

    if (shouldRelease != true || !mounted) return;

    if (closeSheet && mounted) {
      Navigator.pop(context);
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

      SnackbarHelper.showSuccess('Mesa liberada y pedido cancelado.');
    } catch (e) {
      developer.log('Error liberando mesa ${mesa.id}: $e');
      if (!mounted) {
        return;
      }
      SnackbarHelper.showError(
          'No se pudo liberar la mesa. Inténtalo nuevamente.');
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

  /// Libera la mesa después de completar el pago
  Future<void> _liberarMesaTrasPago(MesaModel mesa, String pedidoId) async {
    try {
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

      if (mounted) {
        SnackbarHelper.showInfo(
          'Mesa ${mesa.id} liberada automáticamente después del pago.',
        );
      }
    } catch (e) {
      developer.log('Error al liberar mesa tras pago: $e');
    }
  }

  /// Navega a la pantalla del ticket después de completar el pago
  void _navegarAlTicket(MesaModel mesa, String pedidoId) {
    if (!mounted) return;

    final queryParams = <String, String>{};

    if (mesa.id.toString().isNotEmpty) {
      queryParams['mesaId'] = mesa.id.toString();
    }

    final mesaNombre = 'Mesa ${mesa.id}';
    if (mesaNombre.isNotEmpty) {
      queryParams['mesaNombre'] = mesaNombre;
    }

    if (mesa.cliente != null && mesa.cliente!.isNotEmpty) {
      queryParams['clienteNombre'] = mesa.cliente!;
    }

    final uri = Uri(
      path: '/mesero/pedidos/ticket/$pedidoId',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    context.push(uri.toString());
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
}

/// Widget separado para las acciones rápidas de la mesa
/// Se actualiza automáticamente cuando cambia el estado del pedido
class _AccionesRapidasMesaSheet extends ConsumerWidget {
  final MesaModel mesa;
  final VoidCallback onCrearPedidoRapido;
  final VoidCallback onReservarMesa;
  final VoidCallback onVerPedido;
  final VoidCallback onCobrarMesa;
  final VoidCallback onLiberarMesa;
  final VoidCallback onConfirmarLlegada;
  final VoidCallback onCancelarReserva;

  const _AccionesRapidasMesaSheet({
    required this.mesa,
    required this.onCrearPedidoRapido,
    required this.onReservarMesa,
    required this.onVerPedido,
    required this.onCobrarMesa,
    required this.onLiberarMesa,
    required this.onConfirmarLlegada,
    required this.onCancelarReserva,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorEstado = _colorPorEstado(mesa.estado);
    final iconoEstado = _iconoPorEstado(mesa.estado);
    final estadoTexto = _estadoCapitalizado(mesa.estado);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF14162B),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
              color: Colors.white70,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorEstado.withValues(alpha: 0.18),
                child: Icon(
                  iconoEstado,
                  color: colorEstado,
                  size: 24,
                ),
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
            ],
          ),
          const SizedBox(height: 24),
          ..._accionesRapidasPorEstado(ref),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _accionesRapidasPorEstado(WidgetRef ref) {
    switch (mesa.estado) {
      case 'disponible':
        return [
          _buildAccionPrincipal(
            titulo: 'Tomar pedido rápido',
            icono: Icons.flash_on,
            color: const Color(0xFF8B5CF6),
            onPressed: onCrearPedidoRapido,
          ),
          const SizedBox(height: 10),
          _buildAccionSecundaria(
            titulo: 'Reservar mesa',
            icono: Icons.event_available,
            onPressed: onReservarMesa,
          ),
        ];

      case 'ocupada':
        final puedeCobrar = _puedeCobrarMesa(ref);
        final acciones = <Widget>[
          _buildAccionPrincipal(
            titulo: 'Abrir pedido',
            icono: Icons.receipt_long,
            color: Colors.green,
            onPressed: onVerPedido,
          ),
          const SizedBox(height: 10),
        ];

        if (puedeCobrar) {
          acciones
            ..add(
              _buildAccionSecundaria(
                titulo: 'Cobrar mesa',
                icono: Icons.attach_money,
                color: Colors.tealAccent.shade400,
                onPressed: onCobrarMesa,
              ),
            )
            ..add(const SizedBox(height: 10));
        }

        acciones.add(
          _buildAccionSecundaria(
            titulo: 'Liberar mesa',
            icono: Icons.logout,
            color: Colors.orange,
            onPressed: onLiberarMesa,
          ),
        );

        return acciones;

      case 'reservada':
        return [
          _buildAccionPrincipal(
            titulo: 'Confirmar llegada',
            icono: Icons.check_circle,
            color: Colors.green,
            onPressed: onConfirmarLlegada,
          ),
          const SizedBox(height: 10),
          _buildAccionSecundaria(
            titulo: 'Cancelar reserva',
            icono: Icons.cancel_schedule_send,
            color: Colors.red,
            onPressed: onCancelarReserva,
          ),
        ];

      default:
        return [];
    }
  }

  bool _puedeCobrarMesa(WidgetRef ref) {
    final pedidoId = mesa.pedidoId;
    if (pedidoId == null || pedidoId.isEmpty) {
      return false;
    }

    final pedidoAsync = ref.watch(pedidos.pedidoPorIdProvider(pedidoId));
    return pedidoAsync.maybeWhen(
      data: (pedido) {
        if (pedido == null) {
          return false;
        }

        final status =
            (pedido['status'] as String?)?.toLowerCase().trim() ?? '';
        final pagado = pedido['pagado'] == true;
        const estadosPermitidos = {'terminado', 'entregado', 'completado'};

        return !pagado && estadosPermitidos.contains(status);
      },
      orElse: () => false,
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
          side:
              BorderSide(color: borderColor.withValues(alpha: 0.8), width: 1.5),
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
}
