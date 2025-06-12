import 'package:flutter/material.dart';

class Favoris extends StatefulWidget {
  const Favoris({super.key});

  @override
  State<Favoris> createState() => _FavorisState();
}

class _FavorisState extends State<Favoris> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Nombre d'onglets
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(
            color: Colors.white, // couleur de l’icône retour
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF02204B),
          title: const Text("Favoris", style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            unselectedLabelStyle: TextStyle(color: Colors.white),
            labelStyle: TextStyle(fontSize: 13),
            tabs: [
              Tab(text: "Produits"),
              Tab(text: "Dans la meme catégorie"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Onglet Produits
            ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.shopping_cart),
                  title: Text("Produit A"),
                  subtitle: Text("Description du produit A"),
                ),
                ListTile(
                  leading: Icon(Icons.shopping_cart),
                  title: Text("Produit B"),
                  subtitle: Text("Description du produit B"),
                ),
              ],
            ),

            // Onglet Catégories
            ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.category),
                  subtitle:
                      Text("description du produit de la meme categorie 1"),
                  title: Text("produit de la meme categorie 1"),
                ),
                ListTile(
                  leading: Icon(Icons.category),
                  subtitle:
                      Text("description du produit de la meme categorie 2"),
                  title: Text("produit de la meme categorie 2"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
