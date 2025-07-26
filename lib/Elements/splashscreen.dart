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

  final Duration splashDuration = const Duration(seconds: 8);

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
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _animation.value,
                    minHeight: 6,
                    backgroundColor: const Color.fromARGB(255, 194, 52, 52),
                    color: const Color.fromARGB(255, 4, 1, 68),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "l'application se charge veillez patienter!",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pacifico',
                  color: Colors.black,
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
