import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/data/models/additonal_model.dart';
import 'package:restaurante_app/data/models/category_model.dart';
import 'package:restaurante_app/data/models/user_model.dart';

import 'package:restaurante_app/presentation/screens/admin/manage/cocinero/create_cocinero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/cocinero/create_credentials_cocinero.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/cocinero/manage_cocinero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/producto/view_detail_product_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesa/create_mesa_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesa/manage_mesa_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesero/view_detail_user.dart';
import 'package:restaurante_app/presentation/screens/mesero/historial/historial_mesero_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/additional/create_item_additional_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/additional/manage_additional_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/combo/create_item_combo_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/combo/manage_combo_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/combo/products_item_combo_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/combo/view_detail_combo_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/manage/mesero/create_credentials_mesero.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesero/create_mesero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesero/manage_mesero_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/category/create_item_category_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/category/manage_category_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/producto/create_item_producto_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/producto/create_producto_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/manage_producto/manage_producto_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/home/home_admin.dart';
import 'package:restaurante_app/presentation/screens/cocina/home_cocinero.dart';
import 'package:restaurante_app/presentation/screens/login/login.dart';
import 'package:restaurante_app/presentation/screens/mesero/home/home_mesero.dart';
import 'package:restaurante_app/presentation/screens/mesero/mesas/mesa_screen.dart';
import 'package:restaurante_app/presentation/screens/settings/not_found_screen.dart';
import 'package:restaurante_app/presentation/screens/settings/settings_user_screen.dart';
import 'package:restaurante_app/presentation/screens/splash/splash_screen.dart';
import 'package:restaurante_app/presentation/screens/mesero/pedidos/pedido_screen.dart';
import 'package:restaurante_app/presentation/screens/mesero/pedidos/ticket_preview_screen.dart';
import 'package:restaurante_app/presentation/screens/mesero/pedidos/table_checkout_screen.dart';
import 'package:restaurante_app/presentation/screens/mesero/pedidos/delivery_orders_screen.dart';
import 'package:restaurante_app/presentation/screens/mesero/pedidos/order_tracking_screen.dart';
import 'package:restaurante_app/presentation/screens/mesero/incidencias/report_incident_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/incidencias/manage_incidencias_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/incidencias/incidencia_detail_screen.dart';
import 'package:restaurante_app/presentation/screens/mesero/pedidos/takeaway_orders_screen.dart';

final GoRouter router = GoRouter(
  navigatorKey: SnackbarHelper.navigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/splash-screen',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/home',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HomeAdminScreen(),
      ),
    ),
    GoRoute(
      path: '/mesero/home',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HomeMeseroScreen(),
      ),
    ),
    GoRoute(
      path: '/cocinero/home',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HomeCocineroScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/mesero',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ManageMeseroScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/cocinero',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ManageCocineroScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/mesas',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AdminMesasScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/incidencias',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ManageIncidenciasScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/incidencias/detalle/:incidenciaId',
      pageBuilder: (context, state) {
        final incidenciaId = state.pathParameters['incidenciaId']!;
        return NoTransitionPage(
          child: IncidenciaDetailScreen(incidenciaId: incidenciaId),
        );
      },
    ),
    GoRoute(
      path: '/admin/manage/mesero/create-mesero',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateMeseroScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/cocinero/create-cocinero',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateCocineroScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/mesa/create-mesa',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateMesaScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/manage-productos',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ManageProductoScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/producto/manage-categorys',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ManageCategoryScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/producto/manage-additionals',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ManageAdditionalScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/producto/manage-combos',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ManageComboScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SettingsUserScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/mesero/create-credentials',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateCredentialsMesero(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/cocinero/create-credentials',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateCredentialsCocinero(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/producto/productos',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateProductoScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/producto/create-item-productos',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateItemProductScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/category/create-item-categorys',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateItemCategoryScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/additional/create-item-Additionals',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateItemAdditionalScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/combo/create-item-Combos',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: CreateItemComboScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/combo/create-item-combo/products-item-combo',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ProductsItemComboScreen(),
      ),
    ),
    GoRoute(
      path: '/mesero/pedidos/mesas',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: MesasScreen(),
      ),
    ),
    GoRoute(
      path: '/mesero/pedidos/domicilio',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: DeliveryOrdersScreen(),
      ),
    ),
    GoRoute(
      path: '/mesero/pedidos/seguimiento',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: OrderTrackingScreen(),
      ),
    ),
    GoRoute(
      path: '/mesero/pedidos/cobrar',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: TableCheckoutScreen(),
      ),
    ),
    GoRoute(
      path: '/mesero/reportar-incidencia',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ReportIncidentScreen(),
      ),
    ),
    GoRoute(
      path: '/mesero/pedidos/para-llevar',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: TakeawayOrdersScreen(),
      ),
    ),
    GoRoute(
      path: '/mesero/pedidos/detalle/:mesaId/:pedidoId',
      pageBuilder: (context, state) {
        final pedidoId = state.pathParameters['pedidoId']!;
        final mesaIdFromPath = state.pathParameters['mesaId'];

        String? decodeParam(String? value) {
          if (value == null) return null;
          try {
            return Uri.decodeComponent(value);
          } catch (_) {
            return value;
          }
        }

        final queryParams = state.uri.queryParameters;

        return NoTransitionPage(
          child: SeleccionProductosScreen(
            pedidoId: pedidoId,
            mesaId: mesaIdFromPath ?? queryParams['mesaId'],
            mesaNombre: decodeParam(queryParams['mesaNombre']),
            clienteNombre: decodeParam(queryParams['clienteNombre']),
            orderMode: (queryParams['orderMode'] ?? 'mesa').toLowerCase(),
            clienteTelefono: decodeParam(queryParams['clienteTelefono']),
            clienteDireccion: decodeParam(queryParams['clienteDireccion']),
            clienteReferencia: decodeParam(queryParams['clienteReferencia']),
          ),
        );
      },
    ),
    GoRoute(
      path: '/mesero/pedidos/ticket/:pedidoId',
      pageBuilder: (context, state) {
        final pedidoId = state.pathParameters['pedidoId']!;
        final query = state.uri.queryParameters;
        return NoTransitionPage(
          child: TicketPreviewScreen(
            pedidoId: pedidoId,
            ticketId: query['ticketId'],
            mesaId: query['mesaId'],
            mesaNombre: query['mesaNombre'],
            clienteNombre: query['clienteNombre'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/mesero/historial',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HistorialScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/manage/producto/detalle/:id',
      pageBuilder: (context, state) => NoTransitionPage(
        child: ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
    ),
    GoRoute(
      path: '/admin/manage/producto/editar/:id',
      pageBuilder: (context, state) => NoTransitionPage(
        child: CreateItemProductScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
    ),
    GoRoute(
      path: '/admin/manage/combo/detalle/:id',
      pageBuilder: (context, state) => NoTransitionPage(
        child: ComboDetailScreen(
          comboId: state.pathParameters['id']!,
        ),
      ),
    ),
    GoRoute(
      path: '/admin/manage/combo/editar/:id',
      pageBuilder: (context, state) => NoTransitionPage(
        child: CreateItemComboScreen(
          comboId: state.pathParameters['id']!,
        ),
      ),
    ),
    GoRoute(
      path: '/admin/manage/category/edit',
      pageBuilder: (context, state) {
        final category = state.extra as CategoryModel?;
        return NoTransitionPage(
          child: CreateItemCategoryScreen(category: category),
        );
      },
    ),
    GoRoute(
      path: '/admin/manage/additional/edit',
      pageBuilder: (context, state) {
        final additional = state.extra as AdditionalModel?;
        return NoTransitionPage(
          child: CreateItemAdditionalScreen(additional: additional),
        );
      },
    ),
    GoRoute(
      path: '/admin/manage/user/edit',
      pageBuilder: (context, state) {
        final user = state.extra as UserModel?;
        final Widget page;
        if (user == null) {
          page = const Scaffold(
            body: Center(
              child: Text('Usuario no proporcionado'),
            ),
          );
        } else if (user.rol == 'mesero') {
          page = CreateMeseroScreen(user: user);
        } else if (user.rol == 'cocinero') {
          page = CreateCocineroScreen(user: user);
        } else {
          // Ruta fallback, por si no es ninguno de estos roles
          page = Scaffold(
            body: Center(
              child: Text('Rol no soportado: ${user.rol}'),
            ),
          );
        }

        return NoTransitionPage(child: page);
      },
    ),
    GoRoute(
      path: '/admin/manage/user/detail/:userId',
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return NoTransitionPage(
          child: UserDetailScreen(userId: userId),
        );
      },
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);
