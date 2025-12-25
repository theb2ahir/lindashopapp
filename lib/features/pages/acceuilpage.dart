import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/pages/homepage.dart';
import 'package:lindashopp/features/pages/panier.dart';
import 'package:lindashopp/features/pages/profil/profil.dart';
import 'package:lindashopp/features/pages/suiviscommande.dart'; // Assure-toi que ce fichier existe

class AcceuilPage extends StatefulWidget {
  const AcceuilPage({super.key});

  @override
  State<AcceuilPage> createState() => AcceuilPageState();
}

class AcceuilPageState extends State<AcceuilPage> {
  List<Widget> screenList = [
    MyHomePage(),
    PanierPage(),
    AcrListPage(),
    Profile(),
  ];

  int myIndex = 0;

  Future<int> getNumberOfPanierItems() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('commandes')
        .get();

    return querySnapshot.docs.length;
  }

  Future<int> getNumberOfAcr() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('acr')
        .get();

    return querySnapshot.docs.length;
  }

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
            icon: Icon(Icons.shop_2_sharp),
            label: 'boutique',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior:
                  Clip.none, // important pour laisser dépasser le badge
              children: [
                const Icon(Icons.shopping_cart),

                // Badge positionné en haut à droite
                Positioned(
                  right: -6,
                  top: -2,
                  child: FutureBuilder<int>(
                    future: getNumberOfPanierItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == 0) {
                        return const SizedBox.shrink(); // ne rien afficher si 0
                      }

                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${snapshot.data}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            label: 'Panier',
          ),

          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior:
                  Clip.none, // important pour laisser dépasser le badge
              children: [
                const Icon(Icons.receipt_long),

                // Badge positionné en haut à droite
                Positioned(
                  right: -6,
                  top: -2,
                  child: FutureBuilder<int>(
                    future: getNumberOfAcr(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == 0) {
                        return const SizedBox.shrink(); // ne rien afficher si 0
                      }

                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${snapshot.data}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            label: 'Commandes',
          ),

          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Compte'),
        ],
      ),
    );
  }
}
