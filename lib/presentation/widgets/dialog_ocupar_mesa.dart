import 'package:flutter/material.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';

class OcuparMesaDialog extends StatefulWidget {
  final MesaModel mesa;
  final Future<void> Function(String) onOcupar;

  const OcuparMesaDialog({
    super.key,
    required this.mesa,
    required this.onOcupar,
  });

  @override
  State<OcuparMesaDialog> createState() => _OcuparMesaDialogState();
}

class _OcuparMesaDialogState extends State<OcuparMesaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clienteController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _notasController;
  bool _mostrarExtras = false;
  bool _isSubmitting = false;
  late int _numeroPersonas;

  @override
  void initState() {
    super.initState();
    _clienteController = TextEditingController();
    _telefonoController = TextEditingController();
    _notasController = TextEditingController();
    _numeroPersonas = widget.mesa.capacidad > 1 ? 2 : 1;
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
    const highlight = Color(0xFF8B5CF6);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF202033), Color(0xFF141321)],
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
          'Mesa ${widget.mesa.id}',
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
            color: highlight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_alt_rounded, size: 16, color: highlight),
              const SizedBox(width: 6),
              Text(
                '${widget.mesa.capacidad} personas',
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
          return 'Necesitamos un nombre para identificar la mesa';
        }
        if (value.trim().length < 2) {
          return 'Escribe al menos 2 caracteres';
        }
        return null;
      },
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_numeroPersonas',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _numeroPersonas == 1 ? 'persona' : 'personas',
                      style: const TextStyle(color: Colors.white54),
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
        label: 'Notas para cocina o bar',
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
                : const Icon(Icons.play_arrow_rounded),
            label: Text(_isSubmitting ? 'Asignando...' : 'Ocupar mesa'),
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
        borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nombre = _clienteController.text.trim();
    final extras = <String>[];
    extras.add('$_numeroPersonas pax');

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

    setState(() => _isSubmitting = true);
    try {
      await widget.onOcupar(clienteInfo);
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
