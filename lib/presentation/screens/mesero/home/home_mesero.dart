import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:iconify_flutter/icons/ri.dart';
import 'package:restaurante_app/presentation/widgets/navbar_item.dart';

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
                  context.push('/admin/settings');
                },
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
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
              child: IconButton(
                onPressed: () {
                  // Añadir funcionalidad de notificaciones
                },
                icon: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Fondo con gradiente y overlay de imagen
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

            // Contenido principal
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y bienvenida
                  Padding(
                    padding: EdgeInsets.only(
                      left: isTablet ? 40 : 24,
                      right: isTablet ? 40 : 24,
                      top: 20,
                      bottom: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Bienvenido!',
                          style: TextStyle(
                            fontSize: isTablet ? 36 : 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Color.fromRGBO(0, 0, 0, 0.5),
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Organiza tu turno y atiende pedidos en segundos.',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: const Color.fromRGBO(255, 255, 255, 0.9),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 36 : 20,
                        vertical: 10,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShiftOverview(isTablet),
                          const SizedBox(height: 24),
                          _buildQuickActions(context, isTablet),
                          const SizedBox(height: 28),
                          _buildWorkflowShortcuts(context, isTablet),
                          const SizedBox(height: 28),
                          _buildSupportSection(isTablet),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Barra de navegación inferior
                  if (!isTablet)
                    Container(
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.7),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          navbarItem(Icons.home_rounded, true, context),
                          navbarItem(Icons.fastfood_rounded, false, context),
                          navbarItem(Icons.assignment_rounded, false, context),
                          navbarItem(Icons.settings_rounded, false, context),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftOverview(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28 : 20,
        vertical: isTablet ? 22 : 18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color.fromRGBO(255, 255, 255, 0.12),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.18),
          width: 1.2,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Turno en curso',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 420;
              final stats = [
                _ShiftStat(
                  title: 'Mesas activas',
                  value: '8',
                  icon: Icons.table_bar_rounded,
                  color: const Color(0xFF38BDF8),
                ),
                _ShiftStat(
                  title: 'Pedidos pendientes',
                  value: '5',
                  icon: Icons.timelapse_rounded,
                  color: const Color(0xFFF59E0B),
                ),
                _ShiftStat(
                  title: 'Entregas listas',
                  value: '2',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF34D399),
                ),
              ];

              return Wrap(
                spacing: isWide ? 18 : 12,
                runSpacing: 14,
                children: stats
                    .map(
                      (stat) => _ShiftOverviewItem(
                        stat: stat,
                        width: isWide
                            ? (constraints.maxWidth - (isWide ? 36 : 24)) /
                                (isWide ? 3 : 2)
                            : constraints.maxWidth,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isTablet) {
    final actions = [
      _QuickAction(
        title: 'Mesas',
        subtitle: 'Abrir o continuar pedidos en mesa',
        color: const Color(0xFF8B5CF6),
        icon: const Iconify(Ri.restaurant_2_fill, size: 38, color: Colors.white),
        onTap: () => context.push('/mesero/pedidos/mesas'),
      ),
      _QuickAction(
        title: 'Domicilios',
        subtitle: 'Gestionar pedidos para entrega',
        color: const Color(0xFF22D3EE),
        icon: const Iconify(Ri.motorbike_fill, size: 38, color: Colors.white),
        onTap: () {},
      ),
      _QuickAction(
        title: 'Para llevar',
        subtitle: 'Crear pedido para recoger en barra',
        color: const Color(0xFF34D399),
        icon: const Iconify(Ion.fast_food, size: 38, color: Colors.white),
        onTap: () {},
      ),
      _QuickAction(
        title: 'Historial',
        subtitle: 'Revisar pedidos realizados',
        color: const Color(0xFFF97316),
        icon: const Iconify(Ri.history_fill, size: 38, color: Colors.white),
        onTap: () => context.push('/mesero/historial'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rápidos',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: isTablet ? 190 : 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _QuickActionCard(action: action, isTablet: isTablet);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowShortcuts(BuildContext context, bool isTablet) {
    final workflows = [
      _WorkflowAction(
        title: 'Pedido rápido',
        description:
            'Registra en segundos un pedido directo desde la barra.',
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
        description: 'Cierra cuentas y genera recibos de forma ágil.',
        icon: Icons.attach_money_rounded,
        color: const Color(0xFF22C55E),
        onTap: () {},
      ),
      _WorkflowAction(
        title: 'Reportar incidencia',
        description: 'Comunica problemas a cocina o administración.',
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
        vertical: isTablet ? 22 : 20,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '¿Necesitas ayuda?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Comunícate con el administrador o revisa los tutoriales para resolver dudas durante tu turno.',
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
              'Ver guía',
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
  final double width;

  const _ShiftOverviewItem({
    required this.stat,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color.fromRGBO(15, 23, 42, 0.6),
        border: Border.all(
          color: stat.color.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stat.color.withOpacity(0.18),
            ),
            child: Icon(stat.icon, color: stat.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.title,
                  style: const TextStyle(
                    color: Color.fromRGBO(255, 255, 255, 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final Color color;
  final Widget icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  final bool isTablet;

  const _QuickActionCard({
    required this.action,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: isTablet ? 240 : 210,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              action.color.withOpacity(0.95),
              action.color.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: action.color.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
              ),
              child: Center(child: action.icon),
            ),
            const SizedBox(height: 16),
            Text(
              action.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              action.subtitle,
              style: const TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.85),
                fontSize: 13,
                height: 1.3,
              ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
