import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/data/models/incidencia_model.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _asuntoController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _tipoSeleccionado = 'cocina';
  String _categoriaSeleccionada = 'normal';
  bool _isLoading = false;

  static const Map<String, IconData> _tipoIcons = {
    'cocina': Icons.restaurant_rounded,
    'administracion': Icons.admin_panel_settings_rounded,
    'tecnica': Icons.settings_rounded,
    'otra': Icons.help_outline_rounded,
  };

  static const Map<String, Color> _tipoColors = {
    'cocina': Color(0xFFF97316),
    'administracion': Color(0xFF6366F1),
    'tecnica': Color(0xFF22D3EE),
    'otra': Color(0xFF71717A),
  };

  static const Map<String, Color> _categoriaColors = {
    'urgente': Color(0xFFEF4444),
    'normal': Color(0xFFF59E0B),
    'baja': Color(0xFF22C55E),
  };

  @override
  void dispose() {
    _asuntoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Volver',
          ),
        ),
        body: Stack(
          children: [
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
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 20,
                  vertical: isTablet ? 24 : 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isTablet),
                      const SizedBox(height: 24),
                      _buildTipoSection(isTablet),
                      const SizedBox(height: 24),
                      _buildCategoriaSection(isTablet),
                      const SizedBox(height: 24),
                      _buildAsuntoField(isTablet),
                      const SizedBox(height: 20),
                      _buildDescripcionField(isTablet),
                      const SizedBox(height: 32),
                      _buildSubmitButton(isTablet),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reporta una incidencia',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Por favor completa el formulario para reportar una incidencia.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: isTablet ? 16 : 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTipoSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de incidencia',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            _buildTipoCard(
              tipo: 'cocina',
              label: 'Cocina',
              icon: _tipoIcons['cocina']!,
              color: _tipoColors['cocina']!,
            ),
            _buildTipoCard(
              tipo: 'administracion',
              label: 'Administración',
              icon: _tipoIcons['administracion']!,
              color: _tipoColors['administracion']!,
            ),
            _buildTipoCard(
              tipo: 'tecnica',
              label: 'Técnica',
              icon: _tipoIcons['tecnica']!,
              color: _tipoColors['tecnica']!,
            ),
            _buildTipoCard(
              tipo: 'otra',
              label: 'Otra',
              icon: _tipoIcons['otra']!,
              color: _tipoColors['otra']!,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipoCard({
    required String tipo,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _tipoSeleccionado == tipo;

    return InkWell(
      onTap: () => setState(() => _tipoSeleccionado = tipo),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF1F233A),
          border: Border.all(
            color: isSelected
                ? color
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white.withValues(alpha: 0.7),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nivel de prioridad',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCategoriaChip(
                categoria: 'urgente',
                label: 'Urgente',
                icon: Icons.warning_rounded,
                color: _categoriaColors['urgente']!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoriaChip(
                categoria: 'normal',
                label: 'Normal',
                icon: Icons.info_outline_rounded,
                color: _categoriaColors['normal']!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoriaChip(
                categoria: 'baja',
                label: 'Baja',
                icon: Icons.check_circle_outline,
                color: _categoriaColors['baja']!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriaChip({
    required String categoria,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _categoriaSeleccionada == categoria;

    return InkWell(
      onTap: () => setState(() => _categoriaSeleccionada = categoria),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF1F233A),
          border: Border.all(
            color: isSelected
                ? color
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsuntoField(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asunto',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _asuntoController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Ej: Pedido sin confirmar, Problema técnico...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
            ),
            filled: true,
            fillColor: const Color(0xFF1F233A),
            prefixIcon: Icon(
              Icons.subject_rounded,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa un asunto';
            }
            if (value.trim().length < 3) {
              return 'El asunto debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescripcionField(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción detallada',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descripcionController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Describe el problema con el mayor detalle posible...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
            ),
            filled: true,
            fillColor: const Color(0xFF1F233A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor describe el problema';
            }
            if (value.trim().length < 10) {
              return 'La descripción debe tener al menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitIncidencia,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 20 : 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Enviar reporte',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitIncidencia() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Obtener información del mesero
      final userDoc = await FirebaseFirestore.instance
          .collection('usuario')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final nombre = userData?['nombre'] ?? '';
      final apellidos = userData?['apellidos'] ?? '';
      final meseroNombre = (nombre.isNotEmpty || apellidos.isNotEmpty)
          ? '${nombre.trim()} ${apellidos.trim()}'.trim()
          : 'Usuario desconocido';

      // Crear la incidencia
      final incidencia = Incidencia(
        tipo: _tipoSeleccionado,
        categoria: _categoriaSeleccionada,
        asunto: _asuntoController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        meseroId: user.uid,
        meseroNombre: meseroNombre,
        createdAt: DateTime.now(),
      );

      // Guardar en Firebase
      await FirebaseFirestore.instance
          .collection('incidencia')
          .add(incidencia.toJson());

      if (!mounted) return;

      // Limpiar formulario
      _asuntoController.clear();
      _descripcionController.clear();
      setState(() {
        _tipoSeleccionado = 'cocina';
        _categoriaSeleccionada = 'normal';
        _isLoading = false;
      });

      // Mostrar diálogo de éxito
      await _showSuccessDialog();

      if (!mounted) return;

      // Volver a la pantalla anterior
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Mostrar diálogo de error
      await _showErrorDialog(e.toString());
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F233A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Incidencia reportada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tu reporte ha sido enviado exitosamente. El equipo te contactará pronto.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showErrorDialog(String error) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F233A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Error al reportar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
