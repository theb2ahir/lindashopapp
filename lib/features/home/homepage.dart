import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/produits/allproduct.dart';
import 'package:lindashopp/features/favoris/favoris.dart';
import 'package:lindashopp/features/notifications/notifications.dart';
import 'package:lindashopp/features/produits/promotions/promopage.dart';
import 'package:lindashopp/productcolumn.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  String promoEleve = "";
  final List<String> tabTitles = [
    "Tous",
    "Électronique",
    "Construction",
    "Habillement",
    "Mode enfants",
    "Sports & bien-être",
    "Électro-ménager",
  ];
  Future<void> fetchPromotionMax() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('promotions')
        .get();
    double max = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      double pourcentage = 0;

      if (data.containsKey('pourcentage')) {
        pourcentage = (data['pourcentage'] as num).toDouble();
      } else if (data.containsKey('discount')) {
        final raw = data['discount'].toString().replaceAll('%', '');
        pourcentage = double.tryParse(raw) ?? 0;
      }
      if (pourcentage > max) {
        max = pourcentage;
      }
    }
    setState(() {
      promoEleve = "${max.toInt()}% ";
    });
  }

  Future<int> getNumberOfFavorites() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favoris')
        .get();

    return querySnapshot.docs.length;
  }

  Future<int> getNumberOffNotif() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .get();

    return querySnapshot.docs.length;
  }

  int? selectedIndex; // null = aucune sélection
  late TabController _tabController;
  String searchQuery = '';
  @override
  void initState() {
    super.initState();
    fetchPromotionMax();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text("Lindashopp", style: GoogleFonts.roboto(fontSize: 24)),
          actions: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Color.fromARGB(255, 255, 18, 1),
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Favoris()),
                    );
                  },
                ),
                FutureBuilder<int>(
                  future: getNumberOfFavorites(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == 0) {
                      return const SizedBox.shrink(); // ne rien afficher
                    }

                    return Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${snapshot.data}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
          leading: Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color: Color.fromARGB(255, 15, 14, 14),
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                },
              ),
              FutureBuilder<int>(
                future: getNumberOffNotif(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == 0) {
                    return const SizedBox.shrink(); // ne rien afficher
                  }

                  return Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(255, 4, 4, 4),
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${snapshot.data}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
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
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: "Rechercher un produit...",
                        filled: true,
                        fillColor: const Color.fromARGB(131, 224, 162, 160),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black,
                        ),
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
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 131, 131, 131),
                      blurRadius: 10,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        "assets/images/promo.jpg",
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PromoPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                8,
                                95,
                                37,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Voir les promotions",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: EdgeInsets.symmetric(horizontal: 20),
              controller: _tabController,
              tabs: const [
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.all_inclusive, size: 24, color: Colors.blue),
                      Text("La totalité"),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.devices, size: 24, color: Colors.blue),
                      Text("Electronique"),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.construction, size: 24, color: Colors.orange),
                      Text("Construction"),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checkroom, size: 24, color: Colors.pink),
                      Text("Habillement"),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.child_care, size: 24, color: Colors.green),
                      Text("Mode enfants"),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center, size: 24, color: Colors.red),
                      Text("Sports & bien-être"),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.kitchen, size: 24, color: Colors.purple),
                      Text("Électro-ménager"),
                    ],
                  ),
                ),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Allproduct(),
                  ProductColumn(collectionName: 'electronique'),
                  ProductColumn(collectionName: 'construction'),
                  ProductColumn(collectionName: 'fring'),
                  ProductColumn(collectionName: 'produit-mode-et-enfant'),
                  ProductColumn(collectionName: 'produit-sport-et-bien-etre'),
                  ProductColumn(collectionName: 'produit-électro-ménagé'),
                
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
