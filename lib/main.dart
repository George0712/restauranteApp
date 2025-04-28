import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';          // Agregado
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';
import 'package:restaurante_app/core/theme/app_theme.dart';
import 'presentation/routes/app_routes.dart';
import 'firebase_options.dart';                             // Agregado

void main() async {
  WidgetsFlutterBinding.ensureInitialized();                // Agregado
  await Firebase.initializeApp(                             // Agregado
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Restaurante App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      scaffoldMessengerKey: SnackbarHelper.key,
    );
  }
}
