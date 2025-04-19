import 'package:go_router/go_router.dart';

import 'package:restaurante_app/presentation/screens/admin/home_admin.dart';
import 'package:restaurante_app/presentation/screens/cocina/home_cocinero.dart';
import 'package:restaurante_app/presentation/screens/login/login.dart';
import 'package:restaurante_app/presentation/screens/mesero/home_mesero.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/mesero/home',
      builder: (context, state) => const HomeMeseroScreen(),
    ),
    GoRoute(
      path: '/cocina/home',
      builder: (context, state) => const HomeCocineroScreen(),
    ),
    GoRoute(
      path: '/admin/home',
      builder: (context, state) => const HomeAdminScreen(),
    ),
  ],
);