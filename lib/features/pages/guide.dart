// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lindashopp/features/pages/acceuilpage.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const darkRed = Color(0xFF8B0000);
  static const lightRed = Color(0xFFFF4D4D);
  static const darkBlue = Color(0xFF00224D);
  static const lightBlue = Color(0xFF4DA6FF);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}

class UserGuideLottie extends StatefulWidget {
  const UserGuideLottie({super.key});

  @override
  State<UserGuideLottie> createState() => _UserGuideLottieState();
}

class _UserGuideLottieState extends State<UserGuideLottie> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  String role = "";
  bool setrole = false;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    if (uid == null) {
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final userData = userDoc.data();

    if (userData == null ||
        userData['role'] == null ||
        userData['role'].toString().isEmpty) {
      return;
    }

    setState(() {
      role = userData['role'];
    });
  }

  _updateUserRole(String role) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final userData = userDoc.data();

    if (userData == null ||
        userData['role'] == null ||
        userData['role'].toString().isEmpty) {
      return;
    }
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': role,
    });

    setState(() {
      setrole = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.lightGreenAccent),
            const SizedBox(width: 12),
            Text("role mis à jour avec succès"),
          ],
        ),
      ),
    );
  }

  Widget buildAnimation(String file, Color bgColor) {
    return Center(
      child: Container(
        height: 260,
        width: 260,
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Lottie.asset(file, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        // ------------- PAGE 1 -------------
        PageViewModel(
          title: "Bienvenue sur Linda-Shop",
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bienvenue dans l’univers Linda-Shop, votre nouvelle boutique digitale conçue pour vous offrir une expérience d’achat moderne, fluide et accessible à tout moment.",
                style: GoogleFonts.poppins(fontSize: 17),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.darkBlue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Commandez facilement depuis n’importe où.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.lightBlue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Profitez d’une interface moderne et intuitive.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          image: buildAnimation("assets/lottie/shop.json", AppColors.lightBlue),
          decoration: PageDecoration(
            titleTextStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ------------- PAGE 2 -------------
        PageViewModel(
          title: "Explorez nos produits",
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Découvrez un large catalogue d’articles soigneusement organisés pour vous permettre de trouver rapidement ce qui vous correspond : electronique, fring, construction,sport et bien etre , mode enfant,… tout y passe !",
                style: GoogleFonts.poppins(fontSize: 17),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.darkRed,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Des catégories variées et bien structurées.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.recommend,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.lightRed,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Trouvez ce que vous cherchez en quelques secondes.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          image: buildAnimation(
            "assets/lottie/categories.json",
            AppColors.lightRed,
          ),
          decoration: PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.darkRed,
            ),
          ),
        ),

        // ------------- PAGE 3 -------------
        PageViewModel(
          title: "Panier & Paiement Sécurisé",
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ajoutez vos articles preferees à votre panier ou au favoris pour un achat ultelieur et passez votre commande facilement. Linda-Shop garantit des paiements fiables et sécurisés pour vous offrir une tranquillité totale.",
                style: GoogleFonts.poppins(fontSize: 17),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.darkBlue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Paiement 100% sécurisé et protégé.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.lightBlue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Commande simple, rapide et sans stress.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          image: buildAnimation(
            "assets/lottie/payment.json",
            AppColors.lightBlue,
          ),
          decoration: PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.darkBlue,
            ),
          ),
        ),

        // ------------- PAGE 4 -------------
        PageViewModel(
          title: "Suivi de commande",
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Suivez votre commande étape par étape, depuis la validation jusqu’à la livraison finale. Recevez des mises à jour précises du statut de votre commande et restez informé en temps réel.",
                style: GoogleFonts.poppins(fontSize: 17),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.darkRed,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Suivi clair rapide et totalement transparent.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.lightRed,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Votre colis livré rapidement et en toute sécurité.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Color.fromARGB(255, 34, 28, 28),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Contactez notre service client pour toute assistance.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          image: buildAnimation(
            "assets/images/Animationdelivery.json",
            AppColors.lightRed,
          ),
          decoration: PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.darkRed,
            ),
          ),
        ),

        // ------------- PAGE 5 -------------
        PageViewModel(
          title: "Dernière étape",
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Que souhaitez-vous faire ?",
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Choisissez votre rôle pour profiter pleinement de l’expérience Lindashop.",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.black.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// Bouton choix du rôle
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            "Choisissez votre rôle",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _roleTile(
                                context,
                                icon: Icons.shopping_cart_outlined,
                                title: "Client",
                                subtitle: "Acheter des produits",
                                onTap: () {
                                  _updateUserRole("client");
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(height: 12),
                              _roleTile(
                                context,
                                icon: Icons.storefront_outlined,
                                title: "Vendeur",
                                subtitle: "Vendre vos produits",
                                onTap: () {
                                  _updateUserRole("seller");
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Text(
                    "Choisir un rôle",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          image: ClipRRect(
            borderRadius: BorderRadius.circular(70),
            child: Image.asset(
              "assets/articlesImages/LindaLogo2.png",
              fit: BoxFit.contain,
              height: 250,
            ),
          ),
          decoration: PageDecoration(
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.darkBlue,
            ),
          ),
        ),
      ],

      // pagination
      skip: Text(
        "Passer",
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      next: Icon(
        Icons.arrow_forward,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.darkBlue,
      ),
      done: Text(
        "Commencer",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.darkBlue,
        ),
      ),

      // quand tout est ok
      onDone: () async {
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool("onboardingSeen", true);
        Future.delayed(const Duration(seconds: 2), () {
          if (setrole != true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Vous devez choisir un rôle avant de pouvoir commencer",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AcceuilPage()),
              (Route<dynamic> route) => false,
            );
          }
        });
      },

      dotsDecorator: DotsDecorator(
        activeColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.darkBlue,
        color: AppColors.darkBlue.withValues(alpha: 0.3),
        activeSize: const Size(20, 10),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }
}

Widget _roleTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkRed, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
