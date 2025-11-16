import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';
import 'package:restaurante_app/presentation/controllers/admin/manage_products_controller.dart';
import 'package:restaurante_app/presentation/providers/admin/admin_provider.dart';

class ListCardsAdditionals extends ConsumerStatefulWidget {
  const ListCardsAdditionals({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ListCardsAdditionalsState();
}

class _ListCardsAdditionalsState extends ConsumerState<ListCardsAdditionals> {
  @override
  Widget build(BuildContext context) {
    final additionalsAsync = ref.watch(additionalProvider);

    return additionalsAsync.when(
      data: (additionals) {
        if (additionals.isEmpty) {
          return const Text('No hay adicionales disponibles.');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: additionals.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
          ),
          itemBuilder: (context, index) {
            final additional = additionals[index];
            return GestureDetector(
              onTap: () => _showAdditionalOptions(context, ref, additional),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: additional.disponible
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        additional.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Badge de disponibilidad
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: additional.disponible
                                ? [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ]
                                : [
                                    const Color(0xFFEF4444),
                                    const Color(0xFFDC2626),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (additional.disponible
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              additional.disponible
                                  ? 'Disponible'
                                  : 'No disponible',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  void _showAdditionalOptions(
      BuildContext context, WidgetRef ref, AdditionalModel additional) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AdditionalOptionsSheet(additional: additional, ref: ref),
    );
  }
}

class AdditionalOptionsSheet extends ConsumerStatefulWidget {
  final AdditionalModel additional;
  final WidgetRef ref;

  const AdditionalOptionsSheet(
      {super.key, required this.additional, required this.ref});

  @override
  ConsumerState<AdditionalOptionsSheet> createState() =>
      _AdditionalOptionsSheetState();
}

class _AdditionalOptionsSheetState
    extends ConsumerState<AdditionalOptionsSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final additional = widget.additional;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const Icon(Icons.category_rounded,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        additional.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '\$${widget.additional.price.toStringAsFixed(0).replaceAllMapped(
                                  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]}.',
                                )}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.additional.disponible
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.additional.disponible
                                  ? 'Disponible'
                                  : 'No disponible',
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.additional.disponible
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Editar
                  _buildOptionTile(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Editar Adicional',
                    subtitle: 'Modificar detalles del adicional',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      // Prepara el controlador para editar y navega
                      widget.ref
                          .read(registerAdditionalController)
                          .initializeForEditing(additional);
                      widget.ref.read(profileImageProvider.notifier).clear();
                      context.push('/admin/manage/additional/edit',
                          extra: additional);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Activar/desactivar
                  _buildOptionTile(
                    context,
                    icon: additional.disponible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    title: additional.disponible
                        ? 'Desactivar Adicional'
                        : 'Activar Adicional',
                    subtitle: additional.disponible
                        ? 'Ocultar el adicional'
                        : 'Hacer visible el adicional',
                    color: additional.disponible ? Colors.orange : Colors.green,
                    onTap: _toggleAvailability,
                  ),
                  const SizedBox(height: 16),
                  // Eliminar
                  _buildOptionTile(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Eliminar Adicional',
                    subtitle: 'Eliminar permanentemente',
                    color: Colors.red,
                    onTap: _confirmDelete,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAvailability() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final controller = ref.read(registerAdditionalController);
    final result = await controller.actualizarAdditional(
      ref,
      id: widget.additional.id,
      name: widget.additional.name,
      price: widget.additional.price,
      disponible: !widget.additional.disponible,
      photo: widget.additional.photo,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }

    if (result == null) {
    } else {
      SnackbarHelper.showError(result);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Eliminar categoría',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de eliminar este adicional? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Cerrar diálogo
              Navigator.pop(context); // Cerrar bottom sheet
              await _deleteAdditional();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAdditional() async {
    // No llamar setState aquí porque el bottom sheet ya fue cerrado
    final controller = ref.read(registerAdditionalController);
    final result =
        await controller.eliminarAdditional(ref, id: widget.additional.id);

    // Mostrar mensaje de resultado
    if (result != null) {
      SnackbarHelper.showError(result);
    }
  }
}
