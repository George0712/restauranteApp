import 'package:go_router/go_router.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/create_cocinero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/create_mesero_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/home/home_admin.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/create_producto_screen.dart';
import 'package:restaurante_app/presentation/screens/cocina/home_cocinero.dart';
import 'package:restaurante_app/presentation/screens/login/login.dart';
import 'package:restaurante_app/presentation/screens/mesero/home_mesero.dart';
import 'package:restaurante_app/presentation/screens/settings/settings_admin_screen.dart';
import 'package:restaurante_app/presentation/screens/splash/splash_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(path: '/splash-screen',
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
      path: '/cocina/home',
      builder: (context, state) => const HomeCocineroScreen(),
    ),
    
    GoRoute(path: '/admin/manage/mesero',
      builder: (context, state) => const CreateMeseroScreen(),
    ),
    GoRoute(path: '/admin/manage/cocinero',
      builder: (context, state) => const CreateCocineroScreen(),
    ),
    GoRoute(path: '/admin/manage/producto',
      builder: (context, state) => const CreateProductoScreen(),
    ),
    GoRoute(path: '/admin/settings',
      builder: (context, state) => const SettingsAdminScreen(),
    ),
  ],
);