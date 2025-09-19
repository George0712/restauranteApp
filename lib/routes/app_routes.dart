import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/splash-screen',
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: '/admin/home',
      builder: (context, state) => const HomeAdminScreen(),
    ),
    GoRoute(
      path: '/mesero/home',
      builder: (context, state) => const HomeMeseroScreen(),
    ),
    GoRoute(
      path: '/cocinero/home',
      builder: (context, state) => const HomeCocineroScreen(),
    ),

    GoRoute(
      path: '/admin/manage/mesero',
      builder: (context, state) => const ManageMeseroScreen(),
    ),
    GoRoute(
      path: '/admin/manage/cocinero',
      builder: (context, state) => const ManageCocineroScreen(),
    ),
    GoRoute(
      path: '/admin/manage/mesas',
      builder: (context, state) => const AdminMesasScreen(),
    ),

    GoRoute(
      path: '/admin/manage/mesero/create-mesero',
      builder: (context, state) => const CreateMeseroScreen(),
    ),
    GoRoute(
      path: '/admin/manage/cocinero/create-cocinero',
      builder: (context, state) => const CreateCocineroScreen(),
    ),

    GoRoute(
      path: '/admin/manage/mesa/create-mesa',
      builder: (context, state) => const CreateMesaScreen(),
    ),
    GoRoute(
      path: '/admin/manage/manage-productos',
      builder: (context, state) => const ManageProductoScreen(),
    ),
    GoRoute(
      path: '/admin/manage/producto/manage-categorys',
      builder: (context, state) => const ManageCategoryScreen(),
    ),
    GoRoute(
      path: '/admin/manage/producto/manage-additionals',
      builder: (context, state) => const ManageAdditionalScreen(),
    ),
    GoRoute(
      path: '/admin/manage/producto/manage-combos',
      builder: (context, state) => const ManageComboScreen(),
    ),

    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const SettingsUserScreen(),
    ),

    GoRoute(
      path: '/admin/manage/mesero/create-credentials',
      builder: (context, state) => const CreateCredentialsMesero(),
    ),
    GoRoute(
      path: '/admin/manage/cocinero/create-credentials',
      builder: (context, state) => const CreateCredentialsCocinero(),
    ),

    GoRoute(
      path: '/admin/manage/producto/productos',
      builder: (context, state) => const CreateProductoScreen(),
    ),

    GoRoute(
      path: '/admin/manage/producto/create-item-productos',
      builder: (context, state) => const CreateItemProductScreen(),
    ),
    GoRoute(
      path: '/admin/manage/category/create-item-categorys',
      builder: (context, state) => const CreateItemCategoryScreen(),
    ),
    GoRoute(
      path: '/admin/manage/additional/create-item-Additionals',
      builder: (context, state) => const CreateItemAdditionalScreen(),
    ),
    GoRoute(
      path: '/admin/manage/combo/create-item-Combos',
      builder: (context, state) => const CreateItemComboScreen(),
    ),
    GoRoute(
      path: '/admin/manage/combo/create-item-combo/products-item-combo',
      builder: (context, state) => const ProductsItemComboScreen(),
    ),

    GoRoute(
      path: '/mesero/pedidos/mesas',
      builder: (context, state) => const MesasScreen(),
    ),

    GoRoute(
      path: '/mesero/pedidos/detalle/:mesaId/:pedidoId',
      builder: (context, state) => SeleccionProductosScreen(
        pedidoId: state.pathParameters['pedidoId']!,
      ),
    ),

    GoRoute(
      path: '/mesero/historial',
      builder: (context, state) => const HistorialScreen(),
    ),

    GoRoute(
      path: '/admin/manage/producto/detalle/:id',
      builder: (context, state) => ProductDetailScreen(
        productId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/admin/manage/producto/editar/:id',
      builder: (context, state) => CreateItemProductScreen(
        productId: state.pathParameters['id']!,
      ),
    ),

    GoRoute(
      path: '/admin/manage/category/edit',
      builder: (context, state) {
        final category = state.extra as CategoryModel?;
        return CreateItemCategoryScreen(category: category);
      },
    ),

    GoRoute(
      path: '/admin/manage/additional/edit',
      builder: (context, state) {
        final additional = state.extra as AdditionalModel?;
        return CreateItemAdditionalScreen(additional: additional);
      },
    ),

    GoRoute(
      path: '/admin/manage/user/edit',
      builder: (context, state) {
        final user = state.extra as UserModel;

        if (user.rol == 'mesero') {
          return CreateMeseroScreen(user: user);
        } else if (user.rol == 'cocinero') {
          return CreateCocineroScreen(user: user);
        } else {
          // Ruta fallback, por si no es ninguno de estos roles
          return Scaffold(
            body: Center(
              child: Text('Rol no soportado: ${user.rol}'),
            ),
          );
        }
      },
    ),
    GoRoute(
      path: '/admin/manage/user/detail/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return UserDetailScreen(userId: userId);
      },
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);
