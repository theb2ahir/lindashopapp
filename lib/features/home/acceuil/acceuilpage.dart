import 'package:flutter/material.dart';
import 'package:lindashopp/features/home/homepage.dart';
import 'package:lindashopp/features/panier/panier.dart';
import 'package:lindashopp/features/profil/profil.dart';
import 'package:lindashopp/suiviscommande.dart'; // Assure-toi que ce fichier existe

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: myIndex, children: screenList),
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 27,
        selectedIconTheme: const IconThemeData(
          color: Color.fromARGB(255, 190, 53, 49),
        ),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF02204B)),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: const Color.fromARGB(255, 190, 53, 49),
        unselectedItemColor: const Color.fromARGB(255, 11, 10, 10),
        currentIndex: myIndex,
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shop_2_sharp),
            label: 'boutique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Panier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Compte'),
        ],
      ),
    );
  }
}
