// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lindashopp/features/auth/auhtcheck.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final Duration splashDuration = const Duration(seconds: 8);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: splashDuration,
    );


    _controller.forward();

    Future.delayed(splashDuration, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Auhtcheck()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/images/Animationdelivery.json',
                width: 450,
                height: 450,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 60),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
