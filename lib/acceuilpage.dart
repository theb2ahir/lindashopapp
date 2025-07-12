import 'package:flutter/material.dart';
import 'package:lindashopp/homepage.dart';
import 'package:lindashopp/panier.dart';
import 'package:lindashopp/profil.dart';

class AcceuilPage extends StatefulWidget {
  const AcceuilPage({super.key});

  @override
  State<AcceuilPage> createState() => AcceuilPageState();
}

class AcceuilPageState extends State<AcceuilPage> {
  List <Widget> screenList = [
    MyHomePage(),
    PanierPage(),
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
        selectedIconTheme: IconThemeData(color:Colors.white),
        unselectedIconTheme: IconThemeData(color: const Color.fromARGB(255, 79, 79, 79)),
        backgroundColor:  const Color.fromARGB(255, 1, 15, 41),
        showSelectedLabels: false,
        showUnselectedLabels: false,
          onTap: (index) {
            setState(() {
              myIndex = index;
            });
          },
          currentIndex:myIndex ,
          items:  const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Acceuil'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Panier'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil'
            ),
          ]
        ),
    );
  }
}

