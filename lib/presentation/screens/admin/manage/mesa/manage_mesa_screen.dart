// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';

class AdminMesasScreen extends ConsumerStatefulWidget {
  const AdminMesasScreen({super.key});

  @override
  ConsumerState<AdminMesasScreen> createState() => _AdminMesasScreenState();
}

class _AdminMesasScreenState extends ConsumerState<AdminMesasScreen>
    with TickerProviderStateMixin {
  String filtro = 'Todas';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mesasAsync = ref.watch(mesasProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return mesasAsync.when(
      data: (mesas) {
        final mesasFiltradas = filtro == 'Todas'
            ? mesas
            : mesas.where((m) => m.estado == filtro).toList();

        return Scaffold(
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
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: isTablet
                    ? const EdgeInsets.symmetric(vertical: 100, horizontal: 80)
                    : const EdgeInsets.fromLTRB(16, 100, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Administrar Mesas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gestiona las mesas del restaurante, crea nuevas mesas y edita la información existente.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          context.push('/admin/manage/mesa/create-mesa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Nueva Mesa',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGridMesas(mesasFiltradas, isTablet),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
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
                  onPressed: () => ref.refresh(mesasProvider),
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
      ),
    );
  }

  Widget _buildGridMesas(List<MesaModel> mesas, bool isTablet) {
    return GridView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: mesas.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        childAspectRatio: 1,
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
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorEstado.withOpacity(0.3),
            width: 1,
          ),
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
                        const Icon(Icons.people_outline,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${mesa.capacidad} personas',
                          style: const TextStyle(
                            color: Colors.white70,
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
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (mesa.estado == 'ocupada') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorEstado.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                        ),
                      ] else if (mesa.estado == 'reservada') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorEstado.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule,
                                  size: 12, color: colorEstado),
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
    Color colorEstado;
    switch (mesa.estado) {
      case 'disponible':
        colorEstado = Colors.green;
        break;
      case 'ocupada':
        colorEstado = Colors.orange;
        break;
      case 'reservada':
        colorEstado = Colors.blue;
        break;
      default:
        colorEstado = Colors.grey;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.table_restaurant,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${mesa.capacidad} personas • ${mesa.estado}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (mesa.cliente != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorEstado.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: colorEstado, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    mesa.cliente!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildBotonOpcionAdmin(
                  'Editar',
                  Icons.edit_outlined,
                  const Color(0xFF8B5CF6),
                  () {
                    Navigator.pop(context);
                    _mostrarFormularioMesa(mesa: mesa);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonOpcionAdmin(
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

  Widget _buildBotonOpcionAdmin(
      String texto, IconData icono, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
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
        elevation: 4,
      ),
    );
  }

  void _mostrarFormularioMesa({MesaModel? mesa, bool nueva = false}) {
    showDialog(
      context: context,
      builder: (context) => _FormularioMesaDialog(
        mesa: mesa,
        esNueva: nueva,
        onGuardar: (mesaActualizada) async {
          final mesaController = ref.read(mesaControllerProvider);
          String? error;

          if (nueva) {
            // Crear nueva mesa
            error = await mesaController.crearMesa(
              numeroMesa: mesaActualizada.id,
              capacidad: mesaActualizada.capacidad,
            );
          } else {
            // Actualizar mesa
            if (mesa != null) {
              error = await mesaController.actualizarMesa(
                documentId: mesa.docId!,
                numeroMesa: mesaActualizada.id,
                capacidad: mesaActualizada.capacidad,
              );
            } else {
              error = 'Datos de mesa inválidos';
            }
          }

          if (error != null) {
            _mostrarError(error);
            return;
          }
          Navigator.of(context).pop(); 
        },
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _confirmarEliminacion(MesaModel mesa) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              'Eliminar Mesa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro que desea eliminar la Mesa ${mesa.id}?',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (mesa.estado != 'disponible') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La mesa está ${mesa.estado}. Esta acción liberará la mesa.',
                        style: TextStyle(
                            color: Colors.orange.shade300, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final mesaController = ref.read(mesaControllerProvider);

              final error = await mesaController.eliminarMesa(mesa.docId!);
              if (error != null) {
                _mostrarError(error);
                return;
              }
              Navigator.pop(context); // Cierra confirmación
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog para formulario de mesa - ADMIN VERSION
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
  ConsumerState<_FormularioMesaDialog> createState() =>
      _FormularioMesaDialogState();
}

class _FormularioMesaDialogState extends ConsumerState<_FormularioMesaDialog> {
  late TextEditingController _idController;
  late TextEditingController _capacidadController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _idController =
        TextEditingController(text: widget.mesa?.id.toString() ?? '');
    _capacidadController =
        TextEditingController(text: widget.mesa?.capacidad.toString() ?? '');
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
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.esNueva ? Icons.add : Icons.edit,
              color: const Color(0xFF8B5CF6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.esNueva ? 'Nueva Mesa' : 'Editar Mesa',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1A1A2E),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: 'Número de Mesa',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.table_restaurant,
                    color: Color(0xFF8B5CF6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Ingrese el número de mesa';
                if (int.tryParse(value!) == null) {
                  return 'Ingrese un número válido';
                }
                if (int.parse(value) <= 0) {
                  return 'El número debe ser mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacidadController,
              decoration: InputDecoration(
                labelText: 'Capacidad (personas)',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.people, color: Color(0xFF8B5CF6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              style: const TextStyle(color: Colors.white),
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
            foregroundColor: Colors.white70,
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
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            elevation: 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.esNueva ? Icons.add : Icons.save, size: 20),
              const SizedBox(width: 8),
              Text(widget.esNueva ? 'Crear Mesa' : 'Actualizar'),
            ],
          ),
        ),
      ],
    );
  }

  void _guardarMesa() {
    if (_formKey.currentState!.validate()) {
      final mesa = MesaModel(
        id: int.parse(_idController.text),
        capacidad: int.parse(_capacidadController.text),
        estado: widget.mesa?.estado ?? 'disponible',
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
