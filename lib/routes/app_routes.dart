import 'package:go_router/go_router.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/cocinero/create_cocinero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/cocinero/create_credentials_cocinero.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/cocinero/manage_cocinero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesero/create_credentials_mesero.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesero/create_mesero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/mesero/manage_mesero_screen.dart';
import 'package:restaurante_app/presentation/screens/admin/manage/producto/create_producto_screen.dart';

import 'package:restaurante_app/presentation/screens/admin/home/home_admin.dart';
import 'package:restaurante_app/presentation/screens/cocina/home_cocinero.dart';
import 'package:restaurante_app/presentation/screens/login/login.dart';
import 'package:restaurante_app/presentation/screens/mesero/home_mesero.dart';
import 'package:restaurante_app/presentation/screens/settings/not_found_screen.dart';
import 'package:restaurante_app/presentation/screens/settings/settings_user_screen.dart';
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
      path: '/cocinero/home',
      builder: (context, state) => const HomeCocineroScreen(),
    ),

    GoRoute(path: '/admin/manage/mesero',
      builder: (context, state) => const ManageMeseroScreen(),
    ),
    GoRoute(path: '/admin/manage/cocinero',
      builder: (context, state) => const ManageCocineroScreen(),
    ),
    
    GoRoute(path: '/admin/manage/mesero/create-mesero',
      builder: (context, state) => const CreateMeseroScreen(),
    ),
    GoRoute(path: '/admin/manage/cocinero/create-cocinero',
      builder: (context, state) => const CreateCocineroScreen(),
    ),
    GoRoute(path: '/admin/manage/producto',
      builder: (context, state) => const CreateProductoScreen(),
    ),
    GoRoute(path: '/admin/settings',
      builder: (context, state) => const SettingsUserScreen(),
    ),

    GoRoute(path: '/admin/manage/mesero/create-credentials',
      builder: (context, state) => const CreateCredentialsMesero(),
    ),
    GoRoute(path: '/admin/manage/cocinero/create-credentials',
      builder: (context, state) => const CreateCredentialsCocinero(),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);