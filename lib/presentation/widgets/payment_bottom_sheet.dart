import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:restaurante_app/data/models/user_model.dart';
import 'package:restaurante_app/presentation/providers/login/auth_service.dart';

final NumberFormat _paymentFormatter = NumberFormat('#,##0', 'es_CO');

class PaymentBottomSheet extends ConsumerStatefulWidget {
  final String pedidoId;
  final VoidCallback? onPaid;

  const PaymentBottomSheet({
    super.key,
    required this.pedidoId,
    this.onPaid,
  });

  @override
  ConsumerState<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<PaymentBottomSheet> {
  String _selectedMethod = 'cash';
  bool _processing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: SafeArea(
        top: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('pedido')
              .doc(widget.pedidoId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final pedidoSnapshot = snapshot.data!;
            if (!pedidoSnapshot.exists) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No encontramos este pedido.')),
              );
            }

            final data = pedidoSnapshot.data() ?? {};
            final total = (data['total'] as num?)?.toDouble() ?? 0.0;
            final subtotal = (data['subtotal'] as num?)?.toDouble() ?? total;
            final extras = (total - subtotal).clamp(0.0, double.infinity);
            final pagado = data['pagado'] == true;
            final paymentInfo = data['payment'] as Map<String, dynamic>?;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Registrar pago',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Confirma el cobro para completar el pedido.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  _buildResumenCard(
                    subtotal: subtotal,
                    extras: extras,
                    total: total,
                    pagado: pagado,
                    paymentInfo: paymentInfo,
                  ),
                  const SizedBox(height: 20),
                  _buildMetodoPagoSelector(pagado: pagado),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _processing
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: pagado || _processing
                              ? null
                              : () => _registrarPago(total),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _processing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Confirmar pago'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResumenCard({
    required double subtotal,
    required double extras,
    required double total,
    required bool pagado,
    Map<String, dynamic>? paymentInfo,
  }) {
    final metodo = (paymentInfo?['method'] ?? '').toString();
    final procesadoPor = (paymentInfo?['processedByName'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalle del cobro',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildResumenRow('Subtotal', _formatCurrency(subtotal)),
          if (extras > 0) ...[
            const SizedBox(height: 6),
            _buildResumenRow('Extras agregados', _formatCurrency(extras)),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildResumenRow(
            pagado ? 'Total cobrado' : 'Total a cobrar',
            _formatCurrency(total),
            highlight: true,
          ),
          if (pagado) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Este pedido ya fue pagado.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (metodo.isNotEmpty)
                    Text(
                      'Metodo: $metodo',
                      style: const TextStyle(color: Colors.green),
                    ),
                  if (procesadoPor.isNotEmpty)
                    Text(
                      'Registrado por: $procesadoPor',
                      style: const TextStyle(color: Colors.green),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: highlight ? 16 : 14,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            color: highlight ? Colors.black87 : Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 18 : 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? Colors.black : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMetodoPagoSelector({required bool pagado}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Metodo de pago',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        RadioListTile<String>(
          value: 'cash',
          groupValue: _selectedMethod,
          onChanged: pagado || _processing
              ? null
              : (value) {
                  setState(() {
                    _selectedMethod = value ?? 'cash';
                    _errorMessage = null;
                  });
                },
          title: const Text('Efectivo'),
          subtitle: const Text('Registrar pago en efectivo'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          activeColor: Colors.green,
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          value: 'card',
          groupValue: _selectedMethod,
          onChanged: null,
          title: const Text('Tarjeta'),
          subtitle: const Text('Disponible proximamente'),
          secondary: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pronto',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ],
    );
  }

  Future<void> _registrarPago(double total) async {
    if (_selectedMethod != 'cash') {
      setState(() {
        _errorMessage = 'Por ahora solo es posible cobrar en efectivo.';
      });
      return;
    }

    setState(() {
      _processing = true;
      _errorMessage = null;
    });

    try {
      UserModel? user;
      try {
        user = await ref.read(userModelProvider.future);
      } catch (_) {
        user = null;
      }

      final processedByName = user != null
          ? '${user.nombre} ${user.apellidos}'.trim()
          : null;

      final paymentData = <String, dynamic>{
        'method': 'cash',
        'status': 'completed',
        'amount': total,
        'processedAt': FieldValue.serverTimestamp(),
      };

      if (user != null) {
        paymentData['processedBy'] = user.uid;
        paymentData['processedByName'] = processedByName;
      }

      await FirebaseFirestore.instance
          .collection('pedido')
          .doc(widget.pedidoId)
          .update({
        'pagado': true,
        'paymentStatus': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'payment': paymentData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      widget.onPaid?.call();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'No pudimos registrar el pago. Intenta nuevamente.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar pago: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  String _formatCurrency(double value) {
    return r'$' + _paymentFormatter.format(value);
  }
}
