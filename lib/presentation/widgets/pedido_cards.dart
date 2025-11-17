import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/data/models/pedido.dart';
import 'package:restaurante_app/presentation/providers/cocina/cocina_provider.dart';

class PedidoCard extends ConsumerWidget {
  final Pedido pedido;
  final bool isCompact;
  final bool isStackBackground;

  const PedidoCard({
    super.key,
    required this.pedido,
    this.isCompact = false,
    this.isStackBackground = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(cocinaNotifierProvider);
    final statusColor = _getStatusColor(pedido.status);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 2 : 4,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(statusColor),
              const SizedBox(height: 12),
              _buildMetaInfo(),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemsList(statusColor, ref),
                      if (pedido.notas != null && pedido.notas!.trim().isNotEmpty && !isStackBackground) ...[
                        const SizedBox(height: 12),
                        _buildNotes(),
                      ],
                    ],
                  ),
                ),
              ),
              // Botones siempre en la parte inferior
              if (!isStackBackground) ...[
                const SizedBox(height: 12),
                _buildActionButtons(context, ref, isProcessing),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Pedido #${_generateFriendlyId(pedido.id)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            _StatusPill(label: _getStatusText(pedido.status), color: statusColor),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _getTimeDisplay(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.white.withValues(alpha: 0.45)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _getCreatedDisplay(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaInfo() {
    final chips = <Widget>[
      _InfoChip(
        icon: _getModeIcon(pedido.mode),
        label: _getModeText(pedido.mode),
        color: const Color(0xFF38BDF8),
      ),
    ];

    final location = _getLocationDisplay();
    if (location != null && location.trim().isNotEmpty) {
      chips.add(
        _InfoChip(
          icon: Icons.location_on_outlined,
          label: location.trim(),
          color: const Color(0xFFFACC15),
        ),
      );
    }

    if (pedido.meseroNombre != null &&
        pedido.meseroNombre!.trim().isNotEmpty) {
      chips.add(
        _InfoChip(
          icon: Icons.person_outline,
          label: pedido.meseroNombre!.trim(),
          color: const Color(0xFF60A5FA),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }


  Widget _buildItemsList(Color statusColor, WidgetRef ref) {
    final baseItems =
        pedido.initialItems.isNotEmpty ? pedido.initialItems : pedido.items;
    final extras = pedido.extras;
    final hasExtras = extras.isNotEmpty;

    final baseContainer = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu,
                    size: 18, color: statusColor.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Text(
                  hasExtras
                      ? 'Pedido inicial (${baseItems.length})'
                      : 'Productos (${baseItems.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.timer_outlined,
                    size: 16, color: Colors.white.withValues(alpha: 0.55)),
                const SizedBox(width: 4),
                Text(
                  '${_getTotalPreparationTime()} min',
                  style: const TextStyle(
                    color: Color(0xFFCBD5F5),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ...baseItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildItemRow(item, statusColor, ref, itemIndex: index);
          }).toList(),
        ],
      ),
    );

    if (!hasExtras) {
      return baseContainer;
    }

    return Column(
      children: [
        baseContainer,
        ...List.generate(
          extras.length,
          (index) => _buildExtraSection(extras[index], index, ref),
        ),
      ],
    );
  }

  Widget _buildItemRow(ItemPedido item, Color statusColor, WidgetRef ref,
      {bool isExtra = false, int? itemIndex}) {
    final accent = isExtra ? const Color(0xFF2563EB) : statusColor;
    // Permitir interacción si no es extra, tiene índice y el pedido no está cancelado/terminado
    final canInteract = !isExtra && itemIndex != null &&
                        (pedido.status == 'pendiente' || pedido.status == 'preparando');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: item.isPrepared
            ? const Color(0xFF10B981).withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.isPrepared
                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                  : accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: item.isPrepared
                  ? const Icon(Icons.check, color: Color(0xFF10B981), size: 18)
                  : Text(
                      '${item.cantidad}x',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: item.isPrepared
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                if (item.adicionales != null && item.adicionales!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.adicionales!
                          .map((adicional) {
                            final nombre = adicional['name']?.toString() ??
                                adicional['nombre']?.toString() ??
                                'Adicional';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      size: 13, color: accent.withValues(alpha: 0.9)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      nombre,
                                      style: TextStyle(
                                        color: accent.withValues(alpha: 0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                if (item.tiempoPreparacion != null &&
                    item.tiempoPreparacion! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.timer,
                            size: 13, color: accent.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '${item.tiempoPreparacion} min',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item.notas != null && item.notas!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 13,
                            color: isExtra
                                ? const Color(0xFFBFDBFE)
                                : Colors.white.withValues(alpha: 0.6)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.notas!,
                            style: TextStyle(
                              color: isExtra
                                  ? const Color(0xFFDBEAFE)
                                  : const Color(0xFFE2E8F0),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Botón de preparación individual - con play o check
          if (canInteract) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: () async {
                // Si el pedido está pendiente, auto-iniciar preparación
                if (pedido.status == 'pendiente') {
                  await ref
                      .read(cocinaNotifierProvider.notifier)
                      .startPreparation(pedido.id);
                }
                // Luego marcar el item como preparado
                await ref
                    .read(cocinaNotifierProvider.notifier)
                    .toggleItemPreparation(pedido.id, itemIndex);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.isPrepared
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: item.isPrepared
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  item.isPrepared
                      ? Icons.check_circle
                      : (pedido.status == 'pendiente'
                          ? Icons.play_arrow_rounded
                          : Icons.radio_button_unchecked),
                  color: item.isPrepared ? const Color(0xFF10B981) : accent,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtraSection(PedidoAdicion extra, int index, WidgetRef ref) {
    const accent = Color(0xFF2563EB);
    final titulo = 'Agregado ${index + 1} (${extra.items.length})';
    final momento = _formatExtraTime(extra.createdAt);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline,
                    size: 18, color: accent.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (extra.meseroNombre != null &&
                          extra.meseroNombre!.trim().isNotEmpty)
                        Text(
                          extra.meseroNombre!,
                          style: const TextStyle(
                            color: Color(0xFFBFDBFE),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.timer_outlined,
                    size: 16, color: Colors.white.withValues(alpha: 0.55)),
                const SizedBox(width: 4),
                Text(
                  momento,
                  style: const TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ...extra.items
              .map((item) => _buildItemRow(item, accent, ref, isExtra: true))
              .toList(),
        ],
      ),
    );
  }

  String _formatExtraTime(DateTime? createdAt) {
    if (createdAt == null) return 'Hace instantes';

    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) {
      return 'Hace instantes';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      final minutes = diff.inMinutes % 60;
      return 'Hace ${diff.inHours}h ${minutes}m';
    }

    return DateFormat('dd MMM, HH:mm', 'es').format(createdAt);
  }


  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF97316).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes_rounded,
              size: 18, color: Color(0xFFF97316)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pedido.notas!.trim(),
              style: const TextStyle(
                color: Color(0xFFFFD9A8),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _areAllItemsPrepared() {
    // Verificar si todos los items están preparados
    for (final item in pedido.items) {
      if (!item.isPrepared) {
        return false;
      }
    }
    return true;
  }

  int _getPreparedItemsCount() {
    return pedido.items.where((item) => item.isPrepared).length;
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, bool isProcessing) {
    if (isProcessing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: CircularProgressIndicator(color: Color(0xFFF97316)),
        ),
      );
    }

    switch (pedido.status.toLowerCase()) {
      case 'pendiente':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Iniciar preparación del pedido
                  await ref
                      .read(cocinaNotifierProvider.notifier)
                      .startPreparation(pedido.id);
                  // Marcar todos los items como preparados
                  await ref
                      .read(cocinaNotifierProvider.notifier)
                      .prepareAllItems(pedido.id, pedido.items.length);
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Preparar todo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: IconButton(
                onPressed: () => _showReportDialog(context, ref),
                icon: const Icon(Icons.warning_rounded, size: 22),
                color: Colors.redAccent,
                tooltip: 'Reportar problema',
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        );
      case 'preparando':
        final allPrepared = _areAllItemsPrepared();
        final preparedCount = _getPreparedItemsCount();
        final totalCount = pedido.items.length;

        return Column(
          children: [
            if (!allPrepared)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF97316).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFF97316), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Items preparados: $preparedCount de $totalCount',
                        style: const TextStyle(
                          color: Color(0xFFFFD9A8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: allPrepared
                        ? () => ref
                            .read(cocinaNotifierProvider.notifier)
                            .finishOrder(pedido.id, ref)
                        : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marcar terminado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          Colors.grey.withValues(alpha: 0.3),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    onPressed: () => _showReportDialog(context, ref),
                    icon: const Icon(Icons.warning_rounded, size: 22),
                    color: Colors.redAccent,
                    tooltip: 'Reportar problema',
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ],
        );
      case 'cancelado':
        // Solo mostrar botón de reactivar si fue cancelado por cocina
        final canReactivate = pedido.cancelledBy == 'cocina';

        if (canReactivate) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ref
                  .read(cocinaNotifierProvider.notifier)
                  .reactivateOrder(pedido.id),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reactivar pedido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );
        } else {
          // Si fue cancelado por el mesero, mostrar mensaje informativo
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.block_rounded,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pedido cancelado por el mesero',
                    style: TextStyle(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      default:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.45)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'Pedido completado',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
    }
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text(
              'Opciones del pedido',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido #${_generateFriendlyId(pedido.id)}',
              style: const TextStyle(
                color: Color(0xFFCBD5F5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Qué acción deseas realizar?',
              style: TextStyle(
                color: Color(0xFFCBD5F5),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          // Botón de reportar problema
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showReportIssueDialog(context, ref);
            },
            icon: const Icon(Icons.report_problem_outlined, size: 18),
            label: const Text('Reportar problema'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
          ),
          // Botón de cancelar pedido
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showCancelConfirmDialog(context, ref);
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancelar pedido'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          ),
          // Botón de cerrar
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showReportIssueDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController reportController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_outlined, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text(
              'Reportar problema',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Describe el problema con el pedido #${_generateFriendlyId(pedido.id)}:',
              style: const TextStyle(
                color: Color(0xFFCBD5F5),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reportController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Faltan ingredientes, cliente canceló, problema con la cocina...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (reportController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                // Aquí se puede implementar la lógica para enviar el reporte
              }
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Enviar reporte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text(
              'Cancelar pedido',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas cancelar el pedido #${_generateFriendlyId(pedido.id)}?\n\nEsta acción notificará al equipo y no se puede deshacer.',
          style: const TextStyle(
            color: Color(0xFFCBD5F5),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(cocinaNotifierProvider.notifier).cancelOrder(pedido.id);
            },
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Sí, cancelar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _generateFriendlyId(String? fullId) {
    if (fullId == null || fullId.isEmpty) return 'N/A';
    final hash = fullId.hashCode.abs();
    return (hash % 10000).toString().padLeft(4, '0');
  }

  String? _getLocationDisplay() {
    final mode = pedido.mode.toLowerCase();
    if (mode == 'mesa') {
      String? mesa;
      if (pedido.mesaNombre != null && pedido.mesaNombre!.trim().isNotEmpty) {
        mesa = pedido.mesaNombre!.trim();
      } else if (pedido.mesaId != null && pedido.mesaId! > 0) {
        mesa = 'Mesa ${pedido.mesaId}';
      } else if (pedido.tableNumber != null &&
          pedido.tableNumber!.trim().isNotEmpty) {
        mesa = 'Mesa ${pedido.tableNumber!.trim()}';
      }

      final cliente = pedido.clienteNombre ?? pedido.cliente;
      final clienteLimpio = cliente?.trim();

      if (mesa != null && clienteLimpio != null && clienteLimpio.isNotEmpty) {
        return '$mesa · $clienteLimpio';
      }

      return mesa ?? clienteLimpio;
    }

    final cliente = pedido.clienteNombre ?? pedido.cliente;
    return cliente?.trim().isNotEmpty == true ? cliente!.trim() : null;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFF97316);
      case 'preparando':
        return const Color(0xFFF59E0B);
      case 'terminado':
        return const Color(0xFF10B981);
      case 'cancelado':
        return const Color(0xFF94A3B8);
      case 'pagado':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparando':
        return 'En preparación';
      case 'terminado':
        return 'Terminado';
      case 'cancelado':
        return 'Cancelado';
      case 'pagado':
        return 'Pagado';
      default:
        return 'Actualizado';
    }
  }

  IconData _getModeIcon(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'mesa':
        return Icons.table_restaurant;
      case 'domicilio':
        return Icons.delivery_dining;
      case 'parallevar':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.restaurant;
    }
  }

  String _getModeText(String mode) {
    switch (mode.toLowerCase()) {
      case 'mesa':
        return 'Mesa';
      case 'domicilio':
        return 'Domicilio';
      case 'parallevar':
        return 'Para llevar';
      default:
        return 'Sin definir';
    }
  }

  String _getTimeDisplay() {
    final now = DateTime.now();
    // Usar SOLO createdAt para mantener el tiempo de llegada original
    final reference = pedido.createdAt ?? now;
    final difference = now.difference(reference);

    if (difference.inMinutes < 1) {
      return 'Hace instantes';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      final minutes = difference.inMinutes % 60;
      return 'Hace ${difference.inHours}h ${minutes}m';
    } else {
      final days = difference.inDays;
      return 'Hace ${days}d';
    }
  }

  String _getCreatedDisplay() {
    final date = pedido.createdAt ?? pedido.updatedAt ?? DateTime.now();
    return DateFormat('dd MMM • HH:mm', 'es').format(date);
  }


  int _getTotalPreparationTime() {
    int totalTime = 0;
    for (final item in pedido.items) {
      if (item.tiempoPreparacion != null && item.tiempoPreparacion! > 0) {
        totalTime += (item.tiempoPreparacion! * item.cantidad).toInt();
      } else {
        totalTime += (15 * item.cantidad).toInt();
      }
    }
    return totalTime;
  }
}

class _InfoChip extends ConsumerWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


class _StatusPill extends ConsumerWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
