import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/data/models/incidencia_model.dart';
import 'package:restaurante_app/presentation/providers/admin/incidencias_provider.dart';

class ManageIncidenciasScreen extends ConsumerStatefulWidget {
  const ManageIncidenciasScreen({super.key});

  @override
  ConsumerState<ManageIncidenciasScreen> createState() => _ManageIncidenciasScreenState();
}

class _ManageIncidenciasScreenState extends ConsumerState<ManageIncidenciasScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _estadoFilter = 'all';
  String _tipoFilter = 'all';

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
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidenciasAsync = ref.watch(incidenciasStreamProvider);
    final stats = ref.watch(incidenciasStatsProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: incidenciasAsync.when(
        data: (incidencias) {
          final filtered = _applyFilters(incidencias);

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
              title: const Text(
                'Gestión de incidencias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 20,
                      vertical: isTablet ? 24 : 16,
                    ),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildHeader(isTablet, stats),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        SliverToBoxAdapter(
                          child: _buildStats(isTablet, stats),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        SliverToBoxAdapter(
                          child: _buildFilters(isTablet),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 18)),
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final incidencia = filtered[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == filtered.length - 1 ? 28 : 18,
                                  ),
                                  child: _IncidenciaCard(
                                    incidencia: incidencia,
                                    isTablet: isTablet,
                                    onTap: () => _openIncidenciaDetail(incidencia),
                                  ),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: _ScrollToTopButton(controller: _scrollController),
                ),
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
          ),
        ),
        error: (error, _) => Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: _buildErrorState(error),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Administra y responde a las incidencias reportadas por el equipo.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(bool isTablet, Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF121429),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                'Estadísticas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CompactStat(
                  label: 'Total',
                  value: stats['total'].toString(),
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStat(
                  label: 'Pendientes',
                  value: stats['pendiente'].toString(),
                  color: _estadoColors['pendiente']!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStat(
                  label: 'Revisión',
                  value: stats['en_revision'].toString(),
                  color: _estadoColors['en_revision']!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CompactStat(
                  label: 'Resueltas',
                  value: stats['resuelta'].toString(),
                  color: _estadoColors['resuelta']!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStat(
                  label: 'Urgentes',
                  value: stats['urgente'].toString(),
                  color: _categoriaColors['urgente']!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStat(
                  label: 'Cerradas',
                  value: stats['cerrada'].toString(),
                  color: _estadoColors['cerrada']!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8B5CF6)),
            hintText: 'Buscar por asunto o mesero',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFF111827),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Estado',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              _buildFilterChip('Todos', 'all', _estadoFilter, const Color(0xFF71717A), isEstado: true),
              _buildFilterChip('Pendiente', 'pendiente', _estadoFilter, _estadoColors['pendiente']!, isEstado: true),
              _buildFilterChip('En revisión', 'en_revision', _estadoFilter, _estadoColors['en_revision']!, isEstado: true),
              _buildFilterChip('Resuelta', 'resuelta', _estadoFilter, _estadoColors['resuelta']!, isEstado: true),
              _buildFilterChip('Cerrada', 'cerrada', _estadoFilter, _estadoColors['cerrada']!, isEstado: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tipo',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Todos', 'all', _tipoFilter, const Color(0xFF71717A), isTipo: true),
              _buildFilterChip('Cocina', 'cocina', _tipoFilter, _tipoColors['cocina']!, isTipo: true),
              _buildFilterChip('Administración', 'administracion', _tipoFilter, _tipoColors['administracion']!, isTipo: true),
              _buildFilterChip('Técnica', 'tecnica', _tipoFilter, _tipoColors['tecnica']!, isTipo: true),
              _buildFilterChip('Otra', 'otra', _tipoFilter, _tipoColors['otra']!, isTipo: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, String selectedValue, Color color, {bool isEstado = false, bool isTipo = false}) {
    final isSelected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            if (isEstado) {
              _estadoFilter = value;
            } else if (isTipo) {
              _tipoFilter = value;
            }
          });
        },
        selectedColor: color.withValues(alpha: 0.7),
        backgroundColor: const Color(0xFF1F233A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
    );
  }

  List<Incidencia> _applyFilters(List<Incidencia> incidencias) {
    final query = _searchController.text.trim().toLowerCase();

    return incidencias.where((incidencia) {
      if (_estadoFilter != 'all' && incidencia.estado.toLowerCase() != _estadoFilter) {
        return false;
      }

      if (_tipoFilter != 'all' && incidencia.tipo.toLowerCase() != _tipoFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final asunto = incidencia.asunto.toLowerCase();
      final mesero = incidencia.meseroNombre.toLowerCase();
      final descripcion = incidencia.descripcion.toLowerCase();

      return asunto.contains(query) || mesero.contains(query) || descripcion.contains(query);
    }).toList();
  }

  void _openIncidenciaDetail(Incidencia incidencia) {
    context.push('/admin/incidencias/detalle/${incidencia.id}');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: const Icon(Icons.report_off_rounded,
                size: 46, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay incidencias',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajusta los filtros de búsqueda.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 12),
        const Text(
          'Error al cargar incidencias',
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
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _IncidenciaCard extends StatelessWidget {
  const _IncidenciaCard({
    required this.incidencia,
    required this.isTablet,
    required this.onTap,
  });

  final Incidencia incidencia;
  final bool isTablet;
  final VoidCallback onTap;

  static const Map<String, Color> _estadoColors = {
    'pendiente': Color(0xFFF97316),
    'en_revision': Color(0xFFF59E0B),
    'resuelta': Color(0xFF22C55E),
    'cerrada': Color(0xFF71717A),
  };

  static const Map<String, Color> _categoriaColors = {
    'urgente': Color(0xFFEF4444),
    'normal': Color(0xFFF59E0B),
    'baja': Color(0xFF22C55E),
  };

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColors[incidencia.estado.toLowerCase()] ?? const Color(0xFF6366F1);
    final categoriaColor = _categoriaColors[incidencia.categoria.toLowerCase()] ?? const Color(0xFF71717A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF121429),
          border: Border.all(color: estadoColor.withValues(alpha: 0.35), width: 1.2),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incidencia.asunto,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _ChipInfo(
                            icon: Icons.priority_high_rounded,
                            color: categoriaColor,
                            label: _categoriaLabel(incidencia.categoria),
                          ),
                          _ChipInfo(
                            icon: Icons.person_outline,
                            color: Colors.white.withValues(alpha: 0.7),
                            label: incidencia.meseroNombre,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: estadoColor.withValues(alpha: 0.18),
                    border: Border.all(color: estadoColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _estadoLabel(incidencia.estado),
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              incidencia.descripcion,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    color: Colors.white.withValues(alpha: 0.6), size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatDate(incidencia.createdAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.5), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Hace instantes';
    }
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    }
    if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    }
    return DateFormat('dd MMM yyyy', 'es').format(date);
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollToTopButton extends StatefulWidget {
  const _ScrollToTopButton({required this.controller});

  final ScrollController controller;

  @override
  State<_ScrollToTopButton> createState() => _ScrollToTopButtonState();
}

class _ScrollToTopButtonState extends State<_ScrollToTopButton> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    final shouldBeVisible = widget.controller.offset > 400;
    if (shouldBeVisible != _isVisible) {
      setState(() {
        _isVisible = shouldBeVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: _isVisible ? Offset.zero : const Offset(0, 1.5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isVisible ? 1 : 0,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () {
            widget.controller.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
          child: const Icon(Icons.arrow_upward_rounded),
        ),
      ),
    );
  }
}
