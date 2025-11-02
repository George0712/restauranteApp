import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/data/models/incidencia_model.dart';

class IncidenciaDetailScreen extends StatefulWidget {
  final String incidenciaId;

  const IncidenciaDetailScreen({
    super.key,
    required this.incidenciaId,
  });

  @override
  State<IncidenciaDetailScreen> createState() => _IncidenciaDetailScreenState();
}

class _IncidenciaDetailScreenState extends State<IncidenciaDetailScreen> {
  final TextEditingController _resolucionController = TextEditingController();
  bool _isLoading = false;

  static const Map<String, Color> _estadoColors = {
    'pendiente': Color(0xFFF97316),
    'en_revision': Color(0xFFF59E0B),
    'resuelta': Color(0xFF22C55E),
    'cerrada': Color(0xFF71717A),
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
    _resolucionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('incidencias')
            .doc(widget.incidenciaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: _buildErrorState(snapshot.error)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              ),
            );
          }

          final incidencia = Incidencia.fromJson(
            snapshot.data!.data() as Map<String, dynamic>,
            docId: snapshot.data!.id,
          );

          return Scaffold(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle de incidencia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Gestiona el seguimiento y resolución de la incidencia.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildStatusHeader(incidencia),
                        const SizedBox(height: 20),
                        _buildInfoSection(incidencia),
                        const SizedBox(height: 20),
                        _buildDescriptionSection(incidencia),
                        const SizedBox(height: 20),
                        if (incidencia.resolucion != null)
                          _buildResolutionSection(incidencia),
                        if (incidencia.resolucion != null) const SizedBox(height: 20),
                        if (incidencia.estado != 'cerrada') _buildActionsSection(incidencia),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(Incidencia incidencia) {
    final estadoColor = _estadoColors[incidencia.estado.toLowerCase()] ?? const Color(0xFF6366F1);
    final categoriaColor = _categoriaColors[incidencia.categoria.toLowerCase()] ?? const Color(0xFF71717A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF121429),
        border: Border.all(color: estadoColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: estadoColor.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: estadoColor.withValues(alpha: 0.2),
                  border: Border.all(color: estadoColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getEstadoIcon(incidencia.estado), color: estadoColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _estadoLabel(incidencia.estado),
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: categoriaColor.withValues(alpha: 0.2),
                  border: Border.all(color: categoriaColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.priority_high_rounded, color: categoriaColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _categoriaLabel(incidencia.categoria),
                      style: TextStyle(
                        color: categoriaColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            incidencia.asunto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Incidencia incidencia) {
    final tipoColor = _tipoColors[incidencia.tipo.toLowerCase()] ?? const Color(0xFF6366F1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.category_rounded,
            label: 'Tipo',
            value: _tipoLabel(incidencia.tipo),
            color: tipoColor,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.person_rounded,
            label: 'Reportado por',
            value: incidencia.meseroNombre,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Fecha de reporte',
            value: DateFormat('dd MMM yyyy • HH:mm', 'es').format(incidencia.createdAt),
            color: const Color(0xFF22D3EE),
          ),
          if (incidencia.resolvedAt != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.check_circle_rounded,
              label: 'Fecha de resolución',
              value: DateFormat('dd MMM yyyy • HH:mm', 'es').format(incidencia.resolvedAt!),
              color: const Color(0xFF22C55E),
            ),
          ],
          if (incidencia.resolvidaPorNombre != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Resuelto por',
              value: incidencia.resolvidaPorNombre!,
              color: const Color(0xFF22C55E),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(Incidencia incidencia) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción del problema',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            incidencia.descripcion,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionSection(Incidencia incidencia) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF22C55E),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Resolución',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            incidencia.resolucion!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(Incidencia incidencia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón principal según el estado
        if (incidencia.estado == 'pendiente') ...[
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _updateEstado(incidencia, 'en_revision'),
            icon: const Icon(Icons.rate_review_rounded, size: 20),
            label: const Text('Marcar en revisión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _openResolverDialog(incidencia),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('Marcar como resuelta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ] else if (incidencia.estado == 'en_revision') ...[
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _openResolverDialog(incidencia),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('Marcar como resuelta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ] else if (incidencia.estado == 'resuelta') ...[
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _updateEstado(incidencia, 'cerrada'),
            icon: const Icon(Icons.lock_rounded, size: 20),
            label: const Text('Cerrar incidencia', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF71717A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _updateEstado(Incidencia incidencia, String nuevoEstado) async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('incidencias')
          .doc(incidencia.id)
          .update({
        'estado': nuevoEstado,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await _showSuccessDialog('Estado actualizado correctamente');
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Error al actualizar estado: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openResolverDialog(Incidencia incidencia) async {
    _resolucionController.clear();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F233A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Resolución de incidencia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Describe cómo se resolvió esta incidencia:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resolucionController,
              autofocus: true,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Explica la solución aplicada...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFF111827),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_resolucionController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _resolverIncidencia(incidencia, result);
    }
  }

  Future<void> _resolverIncidencia(Incidencia incidencia, String resolucion) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final adminNombre = userData?['nombre'] ?? 'Administrador';

      await FirebaseFirestore.instance
          .collection('incidencias')
          .doc(incidencia.id)
          .update({
        'estado': 'resuelta',
        'resolucion': resolucion,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvidaPorId': user.uid,
        'resolvidaPorNombre': adminNombre,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await _showSuccessDialog('Incidencia resuelta exitosamente');
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Error al resolver incidencia: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showSuccessDialog(String message) async {
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
                color: const Color(0xFF22C55E).withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
                child: const Text('Entendido'),
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
            Text(
              error,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
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
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 12),
        const Text(
          'Error al cargar incidencia',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.pending_actions_rounded;
      case 'en_revision':
        return Icons.rate_review_rounded;
      case 'resuelta':
        return Icons.check_circle_rounded;
      case 'cerrada':
        return Icons.lock_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _estadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_revision':
        return 'En revisión';
      case 'resuelta':
        return 'Resuelta';
      case 'cerrada':
        return 'Cerrada';
      default:
        return estado;
    }
  }

  String _tipoLabel(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'cocina':
        return 'Cocina';
      case 'administracion':
        return 'Administración';
      case 'tecnica':
        return 'Técnica';
      case 'otra':
        return 'Otra';
      default:
        return tipo;
    }
  }

  String _categoriaLabel(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'urgente':
        return 'Urgente';
      case 'normal':
        return 'Normal';
      case 'baja':
        return 'Baja';
      default:
        return categoria;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
