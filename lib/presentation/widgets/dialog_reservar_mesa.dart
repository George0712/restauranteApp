import 'package:flutter/material.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';

class ReservarMesaDialog extends StatefulWidget {
  final MesaModel mesa;
  final Future<void> Function(String, DateTime, String) onReservar;

  const ReservarMesaDialog({
    super.key,
    required this.mesa,
    required this.onReservar,
  });

  @override
  State<ReservarMesaDialog> createState() => _ReservarMesaDialogState();
}

class _ReservarMesaDialogState extends State<ReservarMesaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clienteController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _notasController;
  bool _mostrarExtras = false;
  bool _isSubmitting = false;
  late int _numeroPersonas;
  late DateTime _fechaSeleccionada;
  late TimeOfDay _horaSeleccionada;

  @override
  void initState() {
    super.initState();
    _clienteController = TextEditingController();
    _telefonoController = TextEditingController();
    _notasController = TextEditingController();
    _numeroPersonas = widget.mesa.capacidad > 1 ? 2 : 1;
    _fechaSeleccionada = DateTime.now();
    _horaSeleccionada = TimeOfDay.now();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _telefonoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const highlight = Color(0xFF38BDF8);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1F2E), Color(0xFF131325)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(highlight),
              const SizedBox(height: 20),
              _buildNombreField(),
              const SizedBox(height: 16),
              _buildFechaHoraRow(highlight),
              const SizedBox(height: 16),
              _buildPersonasSelector(highlight),
              const SizedBox(height: 16),
              _buildExtrasToggle(highlight),
              if (_mostrarExtras) ...[
                const SizedBox(height: 12),
                _buildTelefonoField(),
                const SizedBox(height: 12),
                _buildNotasField(),
              ],
              const SizedBox(height: 28),
              _buildActions(highlight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color highlight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reservar mesa ${widget.mesa.id}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: highlight.withOpacity(0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_outlined, size: 16, color: highlight),
              const SizedBox(width: 6),
              Text(
                '${widget.mesa.capacidad} personas maximo',
                style: TextStyle(
                  color: highlight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNombreField() {
    return TextFormField(
      controller: _clienteController,
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Nombre del cliente',
        icon: Icons.person_outline,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Necesitamos un nombre para la reserva';
        }
        if (value.trim().length < 2) {
          return 'Escribe al menos 2 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildFechaHoraRow(Color highlight) {
    return Row(
      children: [
        Expanded(
          child: _buildSelectorButton(
            highlight: highlight,
            icon: Icons.calendar_today_outlined,
            label: _formatearFecha(_fechaSeleccionada),
            onTap: _isSubmitting ? null : _seleccionarFecha,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSelectorButton(
            highlight: highlight,
            icon: Icons.schedule_outlined,
            label: _horaSeleccionada.format(context),
            onTap: _isSubmitting ? null : _seleccionarHora,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorButton({
    required Color highlight,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: highlight.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: highlight),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonasSelector(Color highlight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numero de comensales',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, color: Colors.white70),
                onPressed: _numeroPersonas > 1 && !_isSubmitting
                    ? () => setState(() => _numeroPersonas--)
                    : null,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_numeroPersonas',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _numeroPersonas == 1 ? 'Persona' : 'Personas',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_rounded, color: highlight),
                onPressed:
                    _numeroPersonas < widget.mesa.capacidad && !_isSubmitting
                        ? () => setState(() => _numeroPersonas++)
                        : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtrasToggle(Color highlight) {
    return TextButton.icon(
      onPressed: _isSubmitting
          ? null
          : () => setState(() => _mostrarExtras = !_mostrarExtras),
      style: TextButton.styleFrom(foregroundColor: highlight),
      icon: Icon(
        _mostrarExtras ? Icons.expand_less_rounded : Icons.expand_more_rounded,
      ),
      label: Text(
          _mostrarExtras ? 'Ocultar detalles extra' : 'Agregar detalles extra'),
    );
  }

  Widget _buildTelefonoField() {
    return TextFormField(
      controller: _telefonoController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Telefono (opcional)',
        icon: Icons.call_outlined,
      ),
    );
  }

  Widget _buildNotasField() {
    return TextFormField(
      controller: _notasController,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Notas especiales',
        icon: Icons.sticky_note_2_outlined,
      ),
    );
  }

  Widget _buildActions(Color highlight) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: highlight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.event_available_outlined),
            label: Text(_isSubmitting ? 'Reservando...' : 'Reservar'),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    return '$dia/$mes/$anio';
  }

  Future<void> _seleccionarFecha() async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (nuevaFecha != null) {
      setState(() => _fechaSeleccionada = nuevaFecha);
    }
  }

  Future<void> _seleccionarHora() async {
    final nuevaHora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );
    if (nuevaHora != null) {
      setState(() => _horaSeleccionada = nuevaHora);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nombre = _clienteController.text.trim();
    final extras = <String>[];
    extras.add('$_numeroPersonas per');

    final telefono = _telefonoController.text.trim();
    if (telefono.isNotEmpty) {
      extras.add('Tel $telefono');
    }

    final notas = _notasController.text.trim();
    if (notas.isNotEmpty) {
      extras.add(notas);
    }

    final clienteInfo =
        extras.isEmpty ? nombre : '$nombre | ${extras.join(' - ')}';

    final horaFormateada = _horaSeleccionada.format(context);

    setState(() => _isSubmitting = true);
    try {
      await widget.onReservar(clienteInfo, _fechaSeleccionada, horaFormateada);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
