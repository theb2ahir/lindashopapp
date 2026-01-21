// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/sellerspace/selleracceuil.dart';
import 'package:lindashopp/sellerspace/subscription.dart';
import 'package:lottie/lottie.dart';

class CheckRemainingTime extends StatefulWidget {
  const CheckRemainingTime({super.key});

  @override
  State<CheckRemainingTime> createState() => _CheckRemainingTimeState();
}

class _CheckRemainingTimeState extends State<CheckRemainingTime>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final uid = FirebaseAuth.instance.currentUser!.uid;
  final Duration splashDuration = const Duration(seconds: 4);

  DateTime? endedAt;
  Duration? remainingTime;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: splashDuration)
      ..forward();

    _loadAndCheck();
  }

  Future<void> _loadAndCheck() async {
    await _getUserData();

    await Future.delayed(splashDuration);

    _checkRemainingTime();
  }

  Future<void> _getUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    endedAt = (doc.data()!['endedAt'] as Timestamp).toDate();
  }

  void _checkRemainingTime() {
    if (endedAt == null) return;

    final now = DateTime.now();

    if (now.isAfter(endedAt!)) {
      _showExpiredDialog();
    } else {
      remainingTime = endedAt!.difference(now);
      _showNotExpiredDialog();
    }
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Forfait expiré'),
        content: const Text(
          'Votre abonnement est arrivé à échéance.\nVeuillez le renouveler.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionPage()),
              );
            },
            child: const Text('Renouveler mon abonnement'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('fermer'),
          ),
        ],
      ),
    );
  }

  void _showNotExpiredDialog() {
    final days = remainingTime!.inDays;
    final hours = remainingTime!.inHours % 24;
    final minutes = remainingTime!.inMinutes % 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Forfait actif'),
        content: Text('Temps restant :\n$days jours $hours h $minutes min'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SellerAcceuil()),
              );
            },
            child: const Text('Ouvrir ma boutique'),
          ),
        ],
      ),
    );
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/images/Animationdelivery.json',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              "Vérification de votre abonnement...",
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
      ),
    );
  }
}
