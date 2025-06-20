import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/items.dart';
import 'package:lindashopp/Elements/mydrawer.dart';
import 'package:lindashopp/ProductDetailPage.dart';
import 'package:lindashopp/panier.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int? selectedIndex; // null = aucune sélection
  late TabController _tabController;
  String searchQuery = '';
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Item> items = [];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              padding: EdgeInsets.zero,
              iconSize: 30,
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Column(
            children: [
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Rechercher un produit...",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            controller: _tabController,
            unselectedLabelStyle: const TextStyle(color: Colors.white),
            labelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(text: "Electronique"),
              Tab(text: "Construction"),
              Tab(text: "habillement"),
              Tab(text: "Mode pour enfants"),
              Tab(text: "Sports et bien être"),
              Tab(text: "Electro-ménager"),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 1, 15, 41),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PanierPage()),
                );
              },
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
          ],
        ),

        drawer: const MyDrawer(),
        body: TabBarView(
          controller: _tabController,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('electronique')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Erreur de chargement'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final produits = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nom =
                            data['name']?.toString().toLowerCase() ?? '';
                        return nom.contains(searchQuery.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        itemCount: produits.length,
                        itemBuilder: (context, index) {
                          final produit =
                              produits[index].data() as Map<String, dynamic>;
                          final nom = produit['name'] ?? 'Sans nom';
                          final livrasion =
                              produit['livraison'] ?? 'non spécifier';
                          final prix = produit['prix']?.toString() ?? '0';
                          final imageUrl = produit['imageURL'] ?? '';
                          final cleanPath = imageUrl.replaceAll(r'\', '/');

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(produit: produit),
                                  ),
                                );
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.asset(
                                              'assets/$cleanPath',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nom,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '$prix FCFA',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Livraison incluse? : $livrasion',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('construction')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Erreur de chargement'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final produits = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nom =
                            data['name']?.toString().toLowerCase() ?? '';
                        return nom.contains(searchQuery.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        itemCount: produits.length,
                        itemBuilder: (context, index) {
                          final produit =
                              produits[index].data() as Map<String, dynamic>;
                          final nom = produit['name'] ?? 'Sans nom';
                          final livrasion =
                              produit['livraison'] ?? 'non spécifier';
                          final prix = produit['prix']?.toString() ?? '0';
                          final imageUrl = produit['imageURL'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(produit: produit),
                                  ),
                                );
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.asset(
                                              '$imageUrl' ,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nom,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '$prix FCFA',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Livraison incluse? : $livrasion',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('fring')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Erreur de chargement'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final produits = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nom =
                            data['name']?.toString().toLowerCase() ?? '';
                        return nom.contains(searchQuery.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        itemCount: produits.length,
                        itemBuilder: (context, index) {
                          final produit =
                              produits[index].data() as Map<String, dynamic>;
                          final nom = produit['name'] ?? 'Sans nom';
                          final livrasion =
                              produit['livraison'] ?? 'non spécifier';
                          final prix = produit['prix']?.toString() ?? '0';
                          final imageUrl = produit['imageURL'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(produit: produit),
                                  ),
                                );
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.asset(
                                              '$imageUrl',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nom,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '$prix FCFA',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Livraison incluse? : $livrasion',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('produit-mode-et-enfant')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Erreur de chargement'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final produits = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nom =
                            data['name']?.toString().toLowerCase() ?? '';
                        return nom.contains(searchQuery.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        itemCount: produits.length,
                        itemBuilder: (context, index) {
                          final produit =
                              produits[index].data() as Map<String, dynamic>;
                          final nom = produit['name'] ?? 'Sans nom';
                          final livrasion =
                              produit['livraison'] ?? 'non spécifier';
                          final prix = produit['prix']?.toString() ?? '0';
                          final imageUrl = produit['imageURL'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(produit: produit),
                                  ),
                                );
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.asset(
                                              '$imageUrl',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nom,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '$prix FCFA',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Livraison incluse? : $livrasion',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('produit-sport-et-bien-etre')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Erreur de chargement'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final produits = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nom =
                            data['name']?.toString().toLowerCase() ?? '';
                        return nom.contains(searchQuery.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        itemCount: produits.length,
                        itemBuilder: (context, index) {
                          final produit =
                              produits[index].data() as Map<String, dynamic>;
                          final nom = produit['name'] ?? 'Sans nom';
                          final livrasion =
                              produit['livraison'] ?? 'non spécifier';
                          final prix = produit['prix']?.toString() ?? '0';
                          final imageUrl = produit['imageURL'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(produit: produit),
                                  ),
                                );
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.asset(
                                              '$imageUrl',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nom,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '$prix FCFA',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Livraison incluse? : $livrasion',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('produit-électro-ménagé')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Erreur de chargement'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final produits = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: produits.length,
                        itemBuilder: (context, index) {
                          final produit =
                              produits[index].data() as Map<String, dynamic>;
                          final nom = produit['name'] ?? 'Sans nom';
                          final livrasion =
                              produit['livraison'] ?? 'non spécifier';
                          final prix = produit['prix']?.toString() ?? '0';
                          final imageUrl = produit['imageURL'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(produit: produit),
                                  ),
                                );
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.all(10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.asset(
                                              '$imageUrl',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nom,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '$prix FCFA',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Livraison incluse? : $livrasion',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Increment',
          child: const Icon(Icons.arrow_upward),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
