import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';
import 'package:restaurante_app/presentation/widgets/search_text.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'all';
  String _modeFilter = 'all';
  late DateTime _selectedDay;

  static const Map<String, Color> _statusColors = {
    'pendiente': Color(0xFFF97316),
    'preparando': Color(0xFFF59E0B),
    'terminado': Color(0xFF22C55E),
    'entregado': Color(0xFF38BDF8),
    'pagado': Color(0xFF8B5CF6),
    'cancelado': Color(0xFFEF4444),
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDate(DateTime.now());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedidosAsync = ref.watch(pedidosStreamProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: pedidosAsync.when(
        data: (pedidos) {
          final availableDays = _computeAvailableDays(pedidos);
          final effectiveDay = _resolveSelectedDay(availableDays);
          final dayFiltered = _filterByDay(pedidos, effectiveDay);
          final stats = _computeStats(dayFiltered);
          final filtered = _applyFilters(dayFiltered, effectiveDay);

          return Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
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
                          child: _buildHeader(
                            isTablet: isTablet,
                            stats: stats,
                            availableDays: availableDays,
                            selectedDay: effectiveDay,
                            totalForDay: dayFiltered.length,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        SliverToBoxAdapter(
                          child: _buildSearchSection(isTablet),
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
                                final pedido = filtered[index];
                                final statusColor = _statusColors[
                                        pedido.status.toLowerCase()] ??
                                    const Color(0xFF6366F1);
                                final isPriority = _isPriority(pedido);
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index == filtered.length - 1 ? 28 : 18,
                                  ),
                                  child: _TrackingCard(
                                    pedido: pedido,
                                    isTablet: isTablet,
                                    statusColor: statusColor,
                                    isPriority: isPriority,
                                    onTogglePriority: () =>
                                        _togglePriority(pedido, isPriority),
                                    onSendNote: () =>
                                        _openKitchenNoteDialog(pedido),
                                    onTap: () => _showOrderDetails(pedido),
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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
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
              Center(child: _buildErrorState(error)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isTablet,
    required _TrackingStats stats,
    required List<DateTime> availableDays,
    required DateTime selectedDay,
    required int totalForDay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seguimiento de pedidos',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 32 : 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Consulta el estado y avanza pedidos en cocina.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _buildDaySelector(availableDays, selectedDay),
        const SizedBox(height: 16),
        _buildStatusFilters(stats: stats, total: totalForDay),
      ],
    );
  }

  Widget _buildStatusFilters({
    required _TrackingStats stats,
    required int total,
  }) {
    final filters = <_StatusFilterData>[
      _StatusFilterData(
        key: 'all',
        label: 'Todos',
        count: total,
        color: const Color(0xFF71717A),
        icon: Icons.all_inclusive_rounded,
      ),
      _StatusFilterData(
        key: 'pendiente',
        label: 'Pendientes',
        count: stats.pendingCount,
        color: _statusColors['pendiente']!,
        icon: Icons.timer_outlined,
      ),
      _StatusFilterData(
        key: 'preparando',
        label: 'En cocina',
        count: stats.preparingCount,
        color: _statusColors['preparando']!,
        icon: Icons.local_fire_department_outlined,
      ),
      _StatusFilterData(
        key: 'terminado',
        label: 'Listos',
        count: stats.completedCount,
        color: _statusColors['terminado']!,
        icon: Icons.inventory_2_outlined,
      ),
      _StatusFilterData(
        key: 'entregado',
        label: 'Entregados',
        count: stats.deliveredCount,
        color: _statusColors['entregado']!,
        icon: Icons.delivery_dining,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          for (var i = 0; i < filters.length; i++) ...[
            _StatusChip(
              data: filters[i],
              isSelected: _statusFilter == filters[i].key,
              onTap: () => setState(() => _statusFilter = filters[i].key),
            ),
            if (i != filters.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector(List<DateTime> days, DateTime selectedDay) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              color: Color(0xFF93C5FD), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateTime>(
                value: selectedDay,
                isExpanded: true,
                dropdownColor: const Color(0xFF1F233A),
                borderRadius: BorderRadius.circular(14),
                icon:
                    const Icon(Icons.expand_more_rounded, color: Colors.white),
                items: days
                    .map(
                      (day) => DropdownMenuItem<DateTime>(
                        value: day,
                        child: Text(
                          _formatDay(day),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedDay = _normalizeDate(value);
                  });
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBarText(
          onChanged: (value) {
            _searchController.text = value;
            setState(() {});
          },
          hintText: 'Buscar por mesa, cliente o codigo',
          margin: const EdgeInsets.only(bottom: 12),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildModeChip(
                label: 'Todos los modos',
                value: 'all',
                selectedValue: _modeFilter,
                color: const Color(0xFF38BDF8),
              ),
              _buildModeChip(
                label: 'Solo mesas',
                value: 'mesa',
                selectedValue: _modeFilter,
                color: const Color(0xFF4F46E5),
              ),
              _buildModeChip(
                label: 'Domicilios',
                value: 'domicilio',
                selectedValue: _modeFilter,
                color: const Color(0xFF22D3EE),
              ),
              _buildModeChip(
                label: 'Para llevar',
                value: 'parallevar',
                selectedValue: _modeFilter,
                color: const Color(0xFF34D399),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required String label,
    required String value,
    required String selectedValue,
    required Color color,
  }) {
    final isSelected = selectedValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _modeFilter = value),
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

  List<Pedido> _filterByDay(List<Pedido> pedidos, DateTime selectedDay) {
    final normalizedDay = _normalizeDate(selectedDay);
    return pedidos.where((pedido) {
      final reference = pedido.createdAt ?? pedido.updatedAt;
      if (reference == null) return false;
      return _normalizeDate(reference) == normalizedDay;
    }).toList();
  }

  List<Pedido> _applyFilters(List<Pedido> pedidos, DateTime selectedDay) {
    final query = _searchController.text.trim().toLowerCase();
    final normalizedDay = _normalizeDate(selectedDay);

    final result = pedidos.where((pedido) {
      if (_modeFilter != 'all' && pedido.mode.toLowerCase() != _modeFilter) {
        return false;
      }

      if (_statusFilter != 'all' &&
          pedido.status.toLowerCase() != _statusFilter) {
        return false;
      }

      final reference = pedido.createdAt ?? pedido.updatedAt;
      if (reference == null) return false;
      if (_normalizeDate(reference) != normalizedDay) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final mesa = (pedido.mesaNombre ?? '').toLowerCase();
      final cliente =
          (pedido.clienteNombre ?? pedido.cliente ?? '').toLowerCase();
      final identifier = pedido.id.toLowerCase();

      return mesa.contains(query) ||
          cliente.contains(query) ||
          identifier.contains(query);
    }).toList();

    result.sort((a, b) {
      final dateA =
          a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return result;
  }

  _TrackingStats _computeStats(List<Pedido> pedidos) {
    int pendingCount = 0;
    int preparingCount = 0;
    int completedCount = 0;
    int deliveredCount = 0;

    for (final pedido in pedidos) {
      switch (pedido.status.toLowerCase()) {
        case 'pendiente':
          pendingCount++;
          break;
        case 'preparando':
          preparingCount++;
          break;
        case 'terminado':
        case 'listo':
          completedCount++;
          break;
        case 'entregado':
          deliveredCount++;
          break;
      }
    }

    return _TrackingStats(
      pendingCount: pendingCount,
      preparingCount: preparingCount,
      completedCount: completedCount,
      deliveredCount: deliveredCount,
    );
  }

  bool _isPriority(Pedido pedido) {
    final notas = (pedido.notas ?? '').toLowerCase();
    if (notas.contains('[prioridad]')) {
      return true;
    }
    if (pedido.extras.isNotEmpty) {
      final lastItems = pedido.extras.last.items;
      if (lastItems.any(
          (item) => (item.notas ?? '').toLowerCase().contains('prioridad'))) {
        return true;
      }
    }
    final priorityLevel =
        (pedido.toJson()['priorityLevel'] ?? '').toString().toLowerCase();
    return priorityLevel == 'alta';
  }

  Future<void> _togglePriority(Pedido pedido, bool currentPriority) async {
    try {
      final db = FirebaseFirestore.instance;
      final newPriority = !currentPriority;

      await db.collection('pedidos').doc(pedido.id).update({
        'priorityLevel': newPriority ? 'alta' : 'normal',
      });
    } catch (e) {
      SnackbarHelper.showError('Error al actualizar prioridad: $e');
    }
  }

  void _showOrderDetails(Pedido pedido) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _OrderDetailsSheet(pedido: pedido),
    );
  }

  Future<void> _openKitchenNoteDialog(Pedido pedido) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F233A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Nota para cocina',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Escribe una nota para el equipo de cocina...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: const Color(0xFF111827),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final db = FirebaseFirestore.instance;
        await db.collection('pedidos').doc(pedido.id).update({
          'kitchenNote': result,
          'kitchenNoteTimestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        SnackbarHelper.showError('Error al enviar nota: $e');
      }
    }
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
            child: const Icon(Icons.receipt_long_rounded,
                size: 46, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay pedidos para seguir',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona otro día o ajusta los filtros de búsqueda.',
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
          'Error al cargar pedidos',
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

  List<DateTime> _computeAvailableDays(List<Pedido> pedidos) {
    final today = _normalizeDate(DateTime.now());
    final earliest = today.subtract(const Duration(days: 6));
    final set = <DateTime>{};

    for (final pedido in pedidos) {
      final reference = pedido.createdAt ?? pedido.updatedAt;
      if (reference == null) continue;
      final normalized = _normalizeDate(reference);
      if (normalized.isBefore(earliest)) continue;
      set.add(normalized);
    }

    final days = set.toList()..sort((a, b) => b.compareTo(a));
    if (days.isEmpty) {
      days.add(today);
    }
    return days.take(7).toList();
  }

  DateTime _resolveSelectedDay(List<DateTime> days) {
    final normalizedSelected = _normalizeDate(_selectedDay);
    if (days.isEmpty) {
      final today = _normalizeDate(DateTime.now());
      if (normalizedSelected != today) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedDay = today);
          }
        });
      }
      return today;
    }

    final exists = days.any((day) => day == normalizedSelected);
    if (!exists) {
      final fallback = days.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedDay = fallback);
        }
      });
      return fallback;
    }

    return normalizedSelected;
  }

  String _formatDay(DateTime date) {
    final today = _normalizeDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Hoy';
    if (date == yesterday) return 'Ayer';
    return DateFormat('EEE d MMM', 'es').format(date);
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _TrackingStats {
  const _TrackingStats({
    required this.pendingCount,
    required this.preparingCount,
    required this.completedCount,
    required this.deliveredCount,
  });

  final int pendingCount;
  final int preparingCount;
  final int completedCount;
  final int deliveredCount;
}

class _StatusFilterData {
  final String key;
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusFilterData({
    required this.key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _StatusFilterData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? data.color.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.08);
    final borderColor = isSelected
        ? data.color.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.14);
    final valueColor = isSelected ? Colors.white : data.color;
    final iconColor = isSelected ? Colors.white : data.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
                color: isSelected
                    ? data.color.withValues(alpha: 0.4)
                    : data.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.count.toString(),
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.pedido,
    required this.isTablet,
    required this.statusColor,
    required this.isPriority,
    required this.onTogglePriority,
    required this.onSendNote,
    required this.onTap,
  });

  final Pedido pedido;
  final bool isTablet;
  final Color statusColor;
  final bool isPriority;
  final VoidCallback onTogglePriority;
  final VoidCallback onSendNote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemsCount =
        pedido.items.fold<int>(0, (total, item) => total + item.cantidad);
    final priorityLabel = isPriority ? 'Prioridad' : 'Normal';
    final priorityColor =
        isPriority ? const Color(0xFFEF4444) : const Color(0xFF38BDF8);
    final statusLabel = _statusText(pedido.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF121429),
          border:
              Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
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
                            _locationLabel(pedido),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _ChipInfo(
                                icon: Icons.priority_high_rounded,
                                color: priorityColor,
                                label: priorityLabel,
                              ),
                              if ((pedido.meseroNombre ?? '').trim().isNotEmpty)
                                _ChipInfo(
                                  icon: Icons.person_outline,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  label: (pedido.meseroNombre ?? '').trim(),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: statusColor.withValues(alpha: 0.18),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    _MetaItem(
                      icon: Icons.inventory_2_outlined,
                      label: '$itemsCount ${itemsCount == 1 ? 'ítem' : 'ítems'}',
                    ),
                    _MetaItem(
                      icon: Icons.schedule_rounded,
                      label: _timeAgo(pedido.updatedAt ?? pedido.createdAt),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _OrderTimeline(status: pedido.status.toLowerCase()),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTogglePriority,
                        icon: Icon(
                          isPriority ? Icons.bookmark_remove : Icons.bookmark_add,
                          size: 18,
                        ),
                        label: Text(
                            isPriority ? 'Quitar prioridad' : 'Marcar prioridad'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side:
                              BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onSendNote,
                        icon: const Icon(Icons.message_rounded, size: 18),
                        label: const Text('Nota a cocina'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
        ],
      ),
      ),
    );
  }

  static String _locationLabel(Pedido pedido) {
    final mesaNombre = (pedido.mesaNombre ?? '').trim();
    if (mesaNombre.isNotEmpty) {
      return mesaNombre;
    }
    final clienteNombre = (pedido.clienteNombre ?? '').trim();
    if (clienteNombre.isNotEmpty) {
      return clienteNombre;
    }
    final tableNumber = (pedido.tableNumber ?? '').trim();
    if (tableNumber.isNotEmpty) {
      return 'Mesa $tableNumber';
    }
    return 'Pedido sin nombre';
  }

  static String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Sin registro';
    }
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Hace instantes';
    }
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      final minutes = difference.inMinutes % 60;
      return 'Hace ${difference.inHours}h ${minutes}m';
    }
    if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} d';
    }
    return DateFormat('dd MMM • HH:mm', 'es').format(dateTime);
  }

  static String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparando':
        return 'En cocina';
      case 'terminado':
      case 'listo':
        return 'Listo';
      case 'entregado':
        return 'Entregado';
      case 'pagado':
        return 'Pagado';
      default:
        return status;
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return content;
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

// Timeline widget showing order progress
class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final stages = [
      const _TimelineStage(label: 'Pendiente', key: 'pendiente', icon: Icons.access_time),
      const _TimelineStage(label: 'Cocina', key: 'preparando', icon: Icons.restaurant),
      const _TimelineStage(label: 'Listo', key: 'terminado', icon: Icons.check_circle),
      const _TimelineStage(label: 'Entregado', key: 'entregado', icon: Icons.delivery_dining),
    ];

    final currentIndex = _getCurrentStageIndex(status);

    return Row(
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          Expanded(
            child: _TimelineStageItem(
              stage: stages[i],
              isActive: i <= currentIndex,
              isCompleted: i < currentIndex,
            ),
          ),
          if (i < stages.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: i < currentIndex
                        ? [const Color(0xFF22C55E), const Color(0xFF22C55E)]
                        : [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.2)],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  int _getCurrentStageIndex(String status) {
    switch (status) {
      case 'pendiente':
      case 'nuevo':
        return 0;
      case 'preparando':
        return 1;
      case 'terminado':
      case 'listo':
        return 2;
      case 'entregado':
      case 'pagado':
        return 3;
      default:
        return 0;
    }
  }
}

class _TimelineStage {
  final String label;
  final String key;
  final IconData icon;

  const _TimelineStage({
    required this.label,
    required this.key,
    required this.icon,
  });
}

class _TimelineStageItem extends StatelessWidget {
  const _TimelineStageItem({
    required this.stage,
    required this.isActive,
    required this.isCompleted,
  });

  final _TimelineStage stage;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (isCompleted ? const Color(0xFF22C55E) : const Color(0xFF6366F1))
        : Colors.white.withValues(alpha: 0.3);

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : stage.icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stage.label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Order details sheet
class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final itemsCount = pedido.items.fold<int>(0, (total, item) => total + item.cantidad);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalles del Pedido',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${pedido.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(pedido.status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(pedido.status).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _formatStatus(pedido.status),
                        style: TextStyle(
                          color: _getStatusColor(pedido.status),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Order info cards
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.table_restaurant, 'Ubicación', _getLocation(pedido)),
                      if (pedido.mode.toLowerCase() == 'domicilio' && pedido.clienteDireccion != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.location_on, 'Dirección', pedido.clienteDireccion!),
                      ],
                      if (pedido.clienteTelefono != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.phone, 'Teléfono', pedido.clienteTelefono!),
                      ],
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.person, 'Mesero', pedido.meseroNombre ?? 'Sin asignar'),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.access_time,
                        'Hora',
                        _formatTime(pedido.createdAt ?? pedido.updatedAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Items list
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Productos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$itemsCount ${itemsCount == 1 ? 'ítem' : 'ítems'}',
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...pedido.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.cantidad}x',
                                    style: const TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nombre,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (item.adicionales != null && item.adicionales!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.adicionales!
                                            .map((a) => a['name'] ?? a['nombre'] ?? '')
                                            .where((n) => n.isNotEmpty)
                                            .join(', '),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'es_CO',
                                  symbol: r'$',
                                  decimalDigits: 0,
                                ).format(item.precio * item.cantidad),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (item.notas != null && item.notas!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.note_alt, color: Color(0xFFF59E0B), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.notas!,
                                      style: const TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  // Total
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'es_CO',
                            symbol: r'$',
                            decimalDigits: 0,
                          ).format(pedido.total),
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getLocation(Pedido pedido) {
    if (pedido.mesaNombre != null && pedido.mesaNombre!.isNotEmpty) {
      return pedido.mesaNombre!;
    }
    if (pedido.clienteNombre != null && pedido.clienteNombre!.isNotEmpty) {
      return pedido.clienteNombre!;
    }
    return 'Sin asignar';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFF97316);
      case 'preparando':
        return const Color(0xFFF59E0B);
      case 'terminado':
      case 'listo':
        return const Color(0xFF22C55E);
      case 'entregado':
        return const Color(0xFF38BDF8);
      case 'pagado':
        return const Color(0xFF8B5CF6);
      case 'cancelado':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'preparando':
        return 'EN COCINA';
      case 'terminado':
      case 'listo':
        return 'LISTO';
      case 'entregado':
        return 'ENTREGADO';
      case 'pagado':
        return 'PAGADO';
      case 'cancelado':
        return 'CANCELADO';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Sin registro';
    return DateFormat('HH:mm • dd/MM/yyyy', 'es').format(dateTime);
  }
}
