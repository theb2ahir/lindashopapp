import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/sellerspace/sellerpages/addproductsteps.dart';
import 'package:lindashopp/sellerspace/sellerpages/dashboard.dart';
import 'package:lindashopp/sellerspace/sellerpages/sellercommandes.dart';
import 'package:lindashopp/sellerspace/sellerpages/sellerproductchecking.dart';
import 'package:lindashopp/sellerspace/sellerpages/sellerprouct.dart'; // Assure-toi que ce fichier existe

class SellerAcceuil extends StatefulWidget {
  const SellerAcceuil({super.key});

  @override
  State<SellerAcceuil> createState() => SellerAcceuilState();
}

class SellerAcceuilState extends State<SellerAcceuil> {
  List<Widget> screenList = [
    const SellerDashboard(),
    const SellerProduct(),
    const AddProductSteps(),
    const SellerCommandes(),
    const CheckProductPage(),
  ];

  int myIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: myIndex, children: screenList),
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 27,
        selectedIconTheme: const IconThemeData(
          color: Color.fromARGB(255, 190, 53, 49),
          size: 30,
        ),
        unselectedIconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF02204B),
          size: 27,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        selectedItemColor: const Color.fromARGB(255, 190, 53, 49),
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color.fromARGB(255, 11, 10, 10),
        currentIndex: myIndex,
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_rounded),
            label: 'Produits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Ajouter',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart_checkout_rounded),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_rounded),
            label: 'Vérification',
          ),
        ],
      ),
    );
  }
}
