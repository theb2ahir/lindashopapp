// ignore_for_file: file_names, unnecessary_to_list_in_spreads, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/acceuilpage.dart';
import 'package:geolocator/geolocator.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> produit;

  const ProductDetailPage({super.key, required this.produit});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;

  void increment() => setState(() => quantity++);
  void decrement() {
    if (quantity > 1) setState(() => quantity--);
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    setState(() {
      userData = doc.data()!;
    });
  }

  Map<String, dynamic>? userData;

  String position = 'Appuyez pour obtenir la position';

  Future<void> _ajouterAuPanier() async {
    // Affiche un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        // Récupérer les données utilisateur
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final userData = doc.data();

        if (userData != null) {
          final prix =
              double.tryParse(widget.produit['prix']?.toString() ?? '0') ?? 0;
          final pourcentage =
              double.tryParse(
                widget.produit['pourcentage']?.toString() ?? '0',
              ) ??
              0;

          final prixFinal = pourcentage > 0
              ? (prix - (prix * (pourcentage / 100))).toStringAsFixed(0)
              : prix.toStringAsFixed(0);

          final commandeData = {
            'dateAjout': DateTime.now(),
            'longitude': longitude ?? 0,
            'latitude': latitude ?? 0,
            'addressLivraison': userData['adresse'] ?? '',
            'username': userData['name'] ?? '',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'quantity': quantity,
            'productname': widget.produit['name'],
            'productprice': prixFinal,
            'productImageUrl': widget.produit['imageURL'],
            'livraison': widget.produit['livraison'].toString(),
          };

          // Ajouter la commande à Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('commandes')
              .add(commandeData);

          // Fermer le loading dialog
          Navigator.of(context).pop();

          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              duration: const Duration(seconds: 5),
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.lightGreenAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Produit ajouté au panier!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );

          // Naviguer vers la page d’accueil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AcceuilPage()),
          );
        } else {
          Navigator.of(context).pop(); // Fermer le dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erreur : données utilisateur introuvables"),
            ),
          );
        }
      } catch (e) {
        Navigator.of(context).pop(); // Fermer le dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
      }
    } else {
      Navigator.of(context).pop(); // Fermer le dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun utilisateur connecté.")),
      );
    }
  }


  Future<void> _ajouterAuFavoris() async {
    // Affiche un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        // Récupérer les données utilisateur
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final userData = doc.data();

        if (userData != null) {
          final prix =
              double.tryParse(widget.produit['prix']?.toString() ?? '0') ?? 0;
          final pourcentage =
              double.tryParse(
                widget.produit['pourcentage']?.toString() ?? '0',
              ) ??
              0;

          final prixFinal = pourcentage > 0
              ? (prix - (prix * (pourcentage / 100))).toStringAsFixed(0)
              : prix.toStringAsFixed(0);

          final commandeData = {
            'dateAjout': DateTime.now(),
            'longitude': longitude ?? 0,
            'latitude': latitude ?? 0,
            'addressLivraison': userData['adresse'] ?? '',
            'username': userData['name'] ?? '',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'quantity': quantity,
            'productname': widget.produit['name'],
            'productprice': prixFinal,
            'productImageUrl': widget.produit['imageURL'],
            'livraison': widget.produit['livraison'].toString(),
          };

          // Ajouter la commande à Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('favoris')
              .add(commandeData);

          // Fermer le loading dialog
          Navigator.of(context).pop();

          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              duration: const Duration(seconds: 5),
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.lightGreenAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Produit ajouté au favoris!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );

          // Naviguer vers la page d’accueil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AcceuilPage()),
          );
        } else {
          Navigator.of(context).pop(); // Fermer le dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erreur : données utilisateur introuvables"),
            ),
          );
        }
      } catch (e) {
        Navigator.of(context).pop(); // Fermer le dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
      }
    } else {
      Navigator.of(context).pop(); // Fermer le dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun utilisateur connecté.")),
      );
    }
  }

  
  double? latitude;
  double? longitude;

  Future<void> _getLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: Duration(seconds: 5),
        content: Row(
          children: [
            Icon(Icons.lock_clock, color: Colors.blueGrey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recherche de la position...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission de localisation refusée.")),
      );
      return;
    }

    try {
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'obtention de la position : $e"),
        ),
      );
    } finally {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 5),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.lightGreenAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Position trouvée!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nom = widget.produit['name'] ?? 'Sans nom';
    final prix = widget.produit['prix']?.toString() ?? '0';
    final livraison = widget.produit['livraison'] ?? 'non spécifiée';
    final description = widget.produit['description'] ?? 'indisponible';
    final imageUrl = widget.produit['imageURL'] ?? '';
    final pourcentage = widget.produit['pourcentage'] ?? '';

    final List<dynamic> caracteristiqueTechnique = widget.produit['ct'] ?? [];
    final List<dynamic> avantageEtUtilsation = widget.produit['au'] ?? [];
    final List<dynamic> contenuDuPackage = widget.produit['cp'] ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF02204B),
          iconTheme: const IconThemeData(
            color: Colors.white, // couleur de l’icône retour
          ),
          centerTitle: true,
          title: Text(
            nom,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _getLocation,
              icon: const Icon(Icons.location_on, color: Colors.red),
              tooltip: 'Partager ma position',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  imageUrl.isNotEmpty
                      ? Center(
                          child: ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(23),
                            child: Image.network(imageUrl, height: 280),
                          ),
                        )
                      : const Icon(Icons.image, size: 150),
                ],
              ),
            ),

            const TabBar(
              tabs: [
                Tab(text: 'Partie Achat'),
                Tab(text: 'Information du produit'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black,
            ),

            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    Text(
                                      '$prix FCFA${pourcentage != '' ? ' - $pourcentage%' : ''}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      'Livraison incluse? : $livraison',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),

                                IconButton(
                                  onPressed: () {
                                    _ajouterAuFavoris();
                                  },
                                  icon: Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 23,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 55),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(),
                                  ),
                                  height: 50,

                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: decrement,
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.black12,
                                          ),
                                        ),
                                        child: Text(
                                          "$quantity",
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: increment,
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: () {
                                    _ajouterAuPanier();
                                  },
                                  icon: Icon(
                                    Icons.add_shopping_cart,
                                    color: const Color.fromARGB(
                                      255,
                                      50,
                                      193,
                                      55,
                                    ),
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(13.0),
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.description,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              "Description",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          "$description",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.build,
                                                color: Colors.black,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              const Text(
                                                "Carctéristiques technique",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          ...caracteristiqueTechnique
                                              .map((item) => Text('• $item'))
                                              .toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.thumb_up_alt,
                                                color: Colors.black,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              const Text(
                                                "Avantage et utilisation",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          ...avantageEtUtilsation
                                              .map((item) => Text('• $item'))
                                              .toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              "Contenu du package",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        ...contenuDuPackage
                                            .map((item) => Text('• $item'))
                                            .toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Offstage(
                              offstage: true,
                              child: Form(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 20),
                                          Text(
                                            "👤 Nom : ${userData?['name'] ?? ''}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          Text(
                                            "📧 Email : ${userData?['email'] ?? ''}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          Text(
                                            "📱 Téléphone : ${userData?['phone'] ?? ''}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
