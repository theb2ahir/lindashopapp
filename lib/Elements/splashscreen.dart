// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lindashopp/auhtcheck.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  final Duration splashDuration = const Duration(seconds: 6);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: splashDuration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/articlesImages/LindaLogo2.png',
                height: 230,
              ),
              const SizedBox(height: 24),
              const Text(
                "Bienvenue sur Linda Shop",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Votre boutique de confiance, en un clic.",
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Lottie.asset(
                'assets/images/Animationdelivery.json',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _animation.value,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE0E0E0),
                    color: const Color(0xFF6C63FF),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Préparez-vous à une expérience de shopping unique !",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pacifico',
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
