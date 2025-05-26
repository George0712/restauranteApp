import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurante_app/data/models/mesa_model.dart';

class ReservarMesaDialog extends ConsumerStatefulWidget {
  final MesaModel mesa;
  final Function(String, DateTime, String) onReservar;

  const ReservarMesaDialog({super.key, 
    required this.mesa,
    required this.onReservar,
  });

  @override
  ConsumerState<ReservarMesaDialog> createState() => _ReservarMesaDialogState();
}

class _ReservarMesaDialogState extends ConsumerState<ReservarMesaDialog> {
  late TextEditingController _clienteController;
  late TextEditingController _telefonoController;
  late TextEditingController _notasController;
  final _formKey = GlobalKey<FormState>();
  DateTime _fechaSeleccionada = DateTime.now();
  TimeOfDay _horaSeleccionada = TimeOfDay.now();
  int _numeroPersonas = 1;

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

  Future<void> _seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );
    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Reservar Mesa ${widget.mesa.id}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white70,
        ),
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de la mesa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.table_restaurant, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Capacidad: ${widget.mesa.capacidad} personas',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Nombre del cliente
              TextFormField(
                controller: _clienteController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Cliente *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Ingrese el nombre del cliente';
                  if (value!.length < 2) return 'El nombre debe tener al menos 2 caracteres';
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Teléfono (opcional)
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 16),
              
              // Fecha y hora
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _seleccionarFecha,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        child: Text(
                          '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _seleccionarHora,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hora',
                          prefixIcon: const Icon(Icons.access_time),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        child: Text(
                          _horaSeleccionada.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Número de personas
              Text(
                'Número de Personas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _numeroPersonas > 1 
                          ? () => setState(() => _numeroPersonas--) 
                          : null,
                      icon: const Icon(Icons.remove),
                      color: Colors.blue.shade700,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_numeroPersonas ${_numeroPersonas == 1 ? 'persona' : 'personas'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _numeroPersonas < widget.mesa.capacidad 
                          ? () => setState(() => _numeroPersonas++) 
                          : null,
                      icon: const Icon(Icons.add),
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notas adicionales
              TextFormField(
                controller: _notasController,
                decoration: InputDecoration(
                  labelText: 'Notas adicionales (opcional)',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
                minLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            textStyle: const TextStyle(fontSize: 16),
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _reservarMesa,
          icon: const Icon(Icons.event),
          label: const Text('Reservar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _reservarMesa() {
    if (_formKey.currentState!.validate()) {
      String clienteInfo = _clienteController.text;
      
      // Agregar información adicional si existe
      if (_telefonoController.text.isNotEmpty) {
        clienteInfo += ' (${_telefonoController.text})';
      }
      
      if (_notasController.text.isNotEmpty) {
        clienteInfo += ' - ${_notasController.text}';
      }
      
      final hora = _horaSeleccionada.format(context);
      widget.onReservar(clienteInfo, _fechaSeleccionada, hora);
      Navigator.of(context).pop();
    }
  }
} 