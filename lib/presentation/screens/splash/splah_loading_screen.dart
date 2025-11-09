import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashLoadingScreen extends StatelessWidget {
  const SplashLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDA3276),  Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 1.0]
          ),
        ),
        child: const Center(
          child: SplashLogo(),
        ),
      ),
    );
  }
}

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icon/default-monochrome-white.svg', 
      width: 130, 
    );
  }
}
