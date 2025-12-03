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

class UserGuideLottie extends StatelessWidget {
  const UserGuideLottie({super.key});

  Widget buildAnimation(String file, Color bgColor) {
    return Center(
      child: Container(
        height: 260,
        width: 260,
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.15),
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
      globalBackgroundColor: AppColors.white,

      pages: [
        // ------------- PAGE 1 -------------
        PageViewModel(
          title: "Bienvenue sur Linda-Shop",
          bodyWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bienvenue dans l’univers Linda-Shop, votre nouvelle boutique digitale conçue pour vous offrir une expérience d’achat moderne, fluide et accessible à tout moment.",
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Icon(Icons.shopping_cart, color: AppColors.darkBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Commandez facilement depuis n’importe où.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.lightBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Profitez d’une interface moderne et intuitive.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
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
              color: AppColors.darkBlue,
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
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Icon(Icons.category, color: AppColors.darkRed),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Des catégories variées et bien structurées.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.recommend, color: AppColors.lightRed),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Trouvez ce que vous cherchez en quelques secondes.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
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
            titleTextStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.darkRed,
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
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Icon(Icons.lock, color: AppColors.darkBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Paiement 100% sécurisé et protégé.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shopping_bag, color: AppColors.lightBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Commande simple, rapide et sans stress.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
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
            titleTextStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
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
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Icon(Icons.local_shipping, color: AppColors.darkRed),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Suivi clair rapide et totalement transparent.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.lightRed),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Votre colis livré rapidement et en toute sécurité.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Icon(Icons.phone, color: Color.fromARGB(255, 34, 28, 28)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Contactez notre service client pour toute assistance.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.black,
                      ),
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
            titleTextStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.darkRed,
            ),
          ),
        ),
      ],

      // ------------- BOUTONS -------------
      skip: const Text(
        "Passer",
        style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
      ),
      next: const Icon(Icons.arrow_forward, color: AppColors.darkBlue),
      done: const Text(
        "Commencer",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkBlue,
        ),
      ),

      onDone: () async {
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool("onboardingSeen", true);
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AcceuilPage()),
            (Route<dynamic> route) => false,
          );
        });
      },

      dotsDecorator: DotsDecorator(
        activeColor: AppColors.darkBlue,
        color: AppColors.darkBlue.withOpacity(.3),
        activeSize: const Size(20, 10),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }
}
