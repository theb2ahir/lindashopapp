import 'package:flutter/material.dart';
import 'package:lindashopp/homepage.dart';
import 'package:lindashopp/panier.dart';
import 'package:lindashopp/profil.dart';
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
      
      body: IndexedStack(
        index: myIndex,
        children: screenList,
      ),
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 27,
        selectedIconTheme: const IconThemeData(color: Color.fromARGB(255, 1, 31, 56)),
        unselectedIconTheme: const IconThemeData(color: Color.fromARGB(255, 79, 78, 78)),
        showSelectedLabels: true, 
        backgroundColor:  const Color(0xFF02204B),
        showUnselectedLabels: true, 
        selectedItemColor: const Color.fromARGB(255, 2, 32, 57),
        unselectedItemColor: const Color.fromARGB(255, 11, 10, 10),
        currentIndex: myIndex,
        onTap: (index) {
          setState(() {
            myIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Panier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
