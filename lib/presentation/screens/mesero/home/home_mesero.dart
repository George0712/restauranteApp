import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:restaurante_app/data/models/notification_model.dart';
import 'package:restaurante_app/presentation/widgets/notification_bell.dart';
import 'package:restaurante_app/presentation/providers/cocina/order_provider.dart';
import 'package:restaurante_app/presentation/providers/mesero/mesas_provider.dart';

class HomeMeseroScreen extends ConsumerStatefulWidget {
  const HomeMeseroScreen({super.key});

  @override
  ConsumerState<HomeMeseroScreen> createState() => _HomeMeseroScreenState();
}

class _HomeMeseroScreenState extends ConsumerState<HomeMeseroScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
            child: Hero(
              tag: 'profile_avatar',
              child: GestureDetector(
                onTap: () {
                  context.push('/settings');
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Color.fromRGBO(
                      theme.primaryColor.red,
                      theme.primaryColor.green,
                      theme.primaryColor.blue,
                      0.8,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 20),
              child: const NotificationBell(role: NotificationRole.waiter),
            ),
          ],
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
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'lib/core/assets/bg-mesero.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 36 : 20,
                  vertical: isTablet ? 24 : 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(context, isTablet),
                    const SizedBox(height: 24),
                    _buildShiftOverview(isTablet),
                    const SizedBox(height: 24),
                    _buildWorkflowShortcuts(context, isTablet),
                    const SizedBox(height: 24),
                    _buildSupportSection(isTablet),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftOverview(bool isTablet) {
    final mesasAsync = ref.watch(mesasStreamProvider);
    final orderStats = ref.watch(orderStatsProvider);

    final mesasActivas = mesasAsync.when(
      data: (mesas) {
        const activeStates = {
          'ocupada',
          'reservada',
          'en uso',
          'en servicio',
          'activo',
          'asignada'
        };
        return mesas.where((mesa) {
          final estado = mesa.estado.toLowerCase();
          final hasPedido = (mesa.pedidoId?.isNotEmpty ?? false);
          return hasPedido || activeStates.contains(estado);
        }).length;
      },
      loading: () => 0,
      error: (_, __) => 0,
    );

    const pendingKeys = [
      'pendiente',
      'preparando',
      'nuevo',
      'enPreparacion',
      'en_preparacion',
      'processing'
    ];
    const readyKeys = [
      'terminado',
      'entregado',
      'listo',
      'completado',
      'ready'
    ];

    int ordenesPendientes = 0;
    for (final key in pendingKeys) {
      ordenesPendientes += orderStats[key] ?? 0;
    }

    int entregasListas = 0;
    for (final key in readyKeys) {
      entregasListas += orderStats[key] ?? 0;
    }

    final stats = [
      _ShiftStat(
        title: 'Mesas activas',
        value: mesasActivas.toString(),
        icon: Icons.table_bar_rounded,
        color: const Color(0xFF38BDF8),
      ),
      _ShiftStat(
        title: 'Ordenes pendientes',
        value: ordenesPendientes.toString(),
        icon: Icons.timelapse_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _ShiftStat(
        title: 'Entregas listas',
        value: entregasListas.toString(),
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF34D399),
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 18,
        vertical: isTablet ? 18 : 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color.fromRGBO(255, 255, 255, 0.08),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.12),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.18),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.4),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: Color(0xFF22C55E),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Turno activo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Turno en curso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '10:00 - 18:00',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                Expanded(
                  child: _ShiftOverviewItem(
                    stat: stats[i],
                    isTablet: isTablet,
                  ),
                ),
                if (i < stats.length - 1)
                  Container(
                    width: 1,
                    height: isTablet ? 60 : 54,
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 6 : 4,
                    ),
                    color: const Color.fromRGBO(255, 255, 255, 0.12),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isTablet) {
    final actions = [
      _QuickAction(
        title: 'Mesas',
        color: const Color(0xFF8B5CF6),
        icon:
            const Iconify(Ri.restaurant_2_fill, size: 34, color: Colors.white),
        onTap: () => context.push('/mesero/pedidos/mesas'),
      ),
      _QuickAction(
        title: 'Domicilios',
        color: const Color(0xFF22D3EE),
        icon: const Iconify(Ri.motorbike_fill, size: 34, color: Colors.white),
        onTap: () {},
      ),
      _QuickAction(
        title: 'Para llevar',
        color: const Color(0xFF34D399),
        icon: const Iconify(Ion.fast_food, size: 34, color: Colors.white),
        onTap: () {},
      ),
      _QuickAction(
        title: 'Historial',
        color: const Color(0xFFF97316),
        icon: const Iconify(Ri.history_fill, size: 34, color: Colors.white),
        onTap: () => context.push('/mesero/historial'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos directos',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount;

            if (isTablet) {
              crossAxisCount = 4;
            } else if (width >= 540) {
              crossAxisCount = 3;
            } else if (width >= 360) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }

            final bool isCompact = !isTablet && crossAxisCount >= 3;
            final bool isSingleColumn = crossAxisCount == 1;

            final double aspectRatio;
            if (isTablet) {
              aspectRatio = 2.6;
            } else if (isSingleColumn) {
              aspectRatio = 3.4;
            } else if (isCompact) {
              aspectRatio = 2.4;
            } else {
              aspectRatio = 2.7;
            }

            return GridView.builder(
              itemCount: actions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: aspectRatio,
              ),
              itemBuilder: (context, index) {
                return _QuickActionCard(
                  action: actions[index],
                  isTablet: isTablet,
                  isCompact: isCompact,
                  isSingleColumn: isSingleColumn,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkflowShortcuts(BuildContext context, bool isTablet) {
    final workflows = [
      _WorkflowAction(
        title: 'Pedido rapido',
        description: 'Registra en segundos un pedido desde la barra.',
        icon: Icons.bolt_rounded,
        color: const Color(0xFF6366F1),
        onTap: () {},
      ),
      _WorkflowAction(
        title: 'Seguir pedidos',
        description: 'Consulta el estado y avanza pedidos en cocina.',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF0EA5E9),
        onTap: () => context.push('/mesero/pedidos/mesas'),
      ),
      _WorkflowAction(
        title: 'Cobrar mesa',
        description: 'Cierra cuentas y genera recibos de forma agil.',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF22C55E),
        onTap: () {},
      ),
      _WorkflowAction(
        title: 'Reportar incidencia',
        description: 'Comunicate con cocina o administracion al instante.',
        icon: Icons.support_agent_rounded,
        color: const Color(0xFFF97316),
        onTap: () {},
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flujos de trabajo',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: workflows
              .map((workflow) => _WorkflowCard(
                    workflow: workflow,
                    isTablet: isTablet,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSupportSection(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28 : 22,
        vertical: isTablet ? 20 : 18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.18),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withOpacity(0.2),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.5),
              ),
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Necesitas ayuda?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Comunicate con el administrador o revisa los tutoriales para resolver dudas durante tu turno.',
                  style: TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 0.85),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 18,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () {},
            child: const Text(
              'Ver guia',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftStat {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ShiftStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ShiftOverviewItem extends StatelessWidget {
  final _ShiftStat stat;
  final bool isTablet;

  const _ShiftOverviewItem({
    required this.stat,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = isTablet ? 26 : 23;
    final double circleSize = isTablet ? 42 : 38;
    final TextStyle valueStyle = TextStyle(
      color: Colors.white,
      fontSize: isTablet ? 24 : 20,
      fontWeight: FontWeight.bold,
    );
    final TextStyle labelStyle = TextStyle(
        color: const Color.fromRGBO(255, 255, 255, 0.75),
        fontSize: isTablet ? 13 : 12,
        letterSpacing: 0.2,
        overflow: TextOverflow.ellipsis);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: circleSize,
                width: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stat.color.withOpacity(0.18),
                ),
                child: Icon(stat.icon, color: stat.color, size: iconSize),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(stat.value, style: valueStyle),
            ],
          ),
          const SizedBox(height: 4),
          Text(stat.title, style: labelStyle),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final Color color;
  final Widget icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  final bool isTablet;
  final bool isCompact;
  final bool isSingleColumn;

  const _QuickActionCard({
    required this.action,
    required this.isTablet,
    required this.isCompact,
    required this.isSingleColumn,
  });

  @override
  Widget build(BuildContext context) {
    final double minHeight;
    if (isTablet) {
      minHeight = 122;
    } else if (isSingleColumn) {
      minHeight = 110;
    } else if (isCompact) {
      minHeight = 96;
    } else {
      minHeight = 104;
    }

    final double iconScale = isCompact ? 0.9 : 1.0;
    final double spacing = isTablet ? 14 : 12;

    final TextStyle titleStyle = TextStyle(
      color: Colors.white,
      fontSize: isTablet
          ? 18
          : isCompact
              ? 15
              : 16,
      fontWeight: FontWeight.w700,
    );

    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet || isSingleColumn ? 18 : 14,
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              action.color.withOpacity(0.95),
              action.color.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1.1,
          ),
        ),
        child: Row(
          children: [
            Center(
              child: Transform.scale(
                scale: iconScale,
                child: action.icon,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Text(
                action.title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.9),
              size: isCompact ? 16 : 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowAction {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WorkflowAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _WorkflowCard extends StatelessWidget {
  final _WorkflowAction workflow;
  final bool isTablet;

  const _WorkflowCard({
    required this.workflow,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final width = isTablet ? 260.0 : double.infinity;

    return InkWell(
      onTap: workflow.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromRGBO(17, 25, 40, 0.8),
          border: Border.all(color: workflow.color.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: workflow.color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: workflow.color.withOpacity(0.2),
              ),
              child: Icon(workflow.icon, color: workflow.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workflow.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    workflow.description,
                    style: const TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.8),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
