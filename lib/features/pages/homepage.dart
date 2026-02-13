// ignore_for_file: unrelated_type_equality_checks

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/pages/guide.dart';
import 'package:lindashopp/features/pages/products/allproduct.dart';
import 'package:lindashopp/features/pages/favoris.dart';
import 'package:lindashopp/features/pages/notifications.dart';
import 'package:lindashopp/features/pages/products/promopage.dart';
import 'package:lindashopp/features/pages/utils/banners.dart';
import 'package:lindashopp/features/pages/utils/productcolumn.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  String promoEleve = "";
  final uid = FirebaseAuth.instance.currentUser!.uid;
  int _currentIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.95);

  final List<String> tabTitles = [
    "Tous",
    "Électronique",
    "Construction",
    "Habillement",
    "Mode enfants",
    "Sports & bien-être",
    "Électro-ménager",
  ];
  @override
  void initState() {
    super.initState();
    fetchPromotionMax();
    saveFcmToken();
    _tabController = TabController(length: 7, vsync: this);
  }

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
    if (!mounted) return;

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

  Future<void> saveFcmToken() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }
  }

  int? selectedIndex; // null = aucune sélection
  late TabController _tabController;
  String searchQuery = '';

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final List<PromoBanner> promoBanners = [
      PromoBanner(
        tag: "🔥 PROMOTIONS",
        title: "Économisez malin, sans compromis",
        subtitle: "Des offres exclusives pensées pour votre quotidien.",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PromoPage()),
          );
        },
      ),
      PromoBanner(
        tag: "⏳ ÉVÉNEMENT",
        title: "Offres limitées, impact maximal",
        subtitle: "Ne ratez pas les meilleures opportunités du moment.",
        onTap: () {},
      ),
      PromoBanner(
        tag: "✨ NOUVEAUTÉS",
        title: "Plus de choix. Plus de qualité.",
        subtitle: "Découvrez les dernières nouveautés sélectionnées.",
        onTap: () {},
      ),
    ];

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            "Lindashop",
            style: GoogleFonts.poppins(
              fontSize: size.width > 400 ? 33 : 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: Color.fromARGB(255, 255, 18, 1),
                    size: size.width > 400 ? 24 : 18,
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
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red),
                        ),
                        constraints: BoxConstraints(
                          minWidth: size.width > 400 ? 20 : 16,
                          minHeight: size.height > 800 ? 20 : 16,
                        ),
                        child: Text(
                          '${snapshot.data}',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: size.width > 400 ? 12 : 10,
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
                icon: Icon(
                  Icons.notifications,
                  size: size.width > 400 ? 24 : 18,
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
                      constraints: BoxConstraints(
                        minWidth: size.width > 400 ? 20 : 16,
                        minHeight: size.height > 800 ? 20 : 16,
                      ),
                      child: Text(
                        '${snapshot.data}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: size.width > 400 ? 12 : 10,
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
            // 🔍 Barre de recherche
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    height: size.height > 800 ? 40 : 28,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      style: TextStyle(fontSize: size.width > 400 ? 18 : 13),
                      decoration: InputDecoration(
                        hintStyle: GoogleFonts.poppins(
                          fontSize: size.width > 400 ? 18 : 15,
                        ),
                        hintText: "Rechercher un produit...",
                        filled: true,
                        fillColor: const Color.fromARGB(72, 224, 162, 160),
                        prefixIcon: Icon(
                          Icons.search,
                          size: size.width > 400 ? 18 : 15,
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
            SizedBox(
              height: size.height > 800 ? 180 : 140,
              child: PageView.builder(
                controller: _pageController,
                itemCount: promoBanners.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final promo = promoBanners[index];
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  return GestureDetector(
                    onTap: promo.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF1E1E2C),
                                    const Color(0xFF2A2A40),
                                  ]
                                : [
                                    const Color(0xFFF8F9FF),
                                    const Color(0xFFEDEFFF),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      promo.tag,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.deepPurpleAccent
                                            : Colors.indigo,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      promo.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: size.width > 400 ? 18 : 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      promo.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.deepPurpleAccent
                                      : Colors.indigo,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                promoBanners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 22 : 8,
                  height: size.height > 800 ? 8 : 6,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.darkRed
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            SizedBox(height: size.height > 800 ? 12 : 6),
            // 🧭 Onglets
            TabBar(
              isScrollable: true,
              dividerColor: Colors.transparent,
              tabAlignment: TabAlignment.start,
              labelPadding: EdgeInsets.symmetric(
                horizontal: size.width > 400 ? 20 : 12,
              ),
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.all_inclusive, color: Colors.blue),
                  text: "Tous",
                ),
                Tab(
                  icon: Icon(Icons.devices, color: Colors.blue),
                  text: "Electronique",
                ),
                Tab(
                  icon: Icon(Icons.construction, color: Colors.orange),
                  text: "Construction",
                ),
                Tab(
                  icon: Icon(Icons.checkroom, color: Colors.pink),
                  text: "Habillement",
                ),
                Tab(
                  icon: Icon(Icons.child_care, color: Colors.green),
                  text: "Mode enfants",
                ),
                Tab(
                  icon: Icon(Icons.fitness_center, color: Colors.red),
                  text: "Sports & bien-être",
                ),
                Tab(
                  icon: Icon(Icons.kitchen, color: Colors.purple),
                  text: "Électro-ménager",
                ),
              ],
            ),

            // ✅ Le point clé : donner une hauteur au contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Allproduct(searchQuery: searchQuery),
                  ProductColumn(
                    collectionName: 'electronique',
                    searchQuery: searchQuery,
                  ),
                  ProductColumn(
                    collectionName: 'construction',
                    searchQuery: searchQuery,
                  ),
                  ProductColumn(
                    collectionName: 'fring',
                    searchQuery: searchQuery,
                  ),
                  ProductColumn(
                    collectionName: 'produit-mode-et-enfant',
                    searchQuery: searchQuery,
                  ),
                  ProductColumn(
                    collectionName: 'produit-sport-et-bien-etre',
                    searchQuery: searchQuery,
                  ),
                  ProductColumn(
                    collectionName: 'produit-électro-ménagé',
                    searchQuery: searchQuery,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
