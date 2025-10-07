// ignore_for_file: file_names, unnecessary_to_list_in_spreads, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/avis/avis.dart';
import 'package:lindashopp/features/home/acceuil/acceuilpage.dart';
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              duration: const Duration(seconds: 3),
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.lightGreenAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Commande ajoutée au panier avec succès!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
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
    final avis = widget.produit['avis'] ?? '';

    final List<dynamic> caracteristiqueTechnique = widget.produit['ct'] ?? [];
    final List<dynamic> avantageEtUtilsation = widget.produit['au'] ?? [];
    final List<dynamic> contenuDuPackage = widget.produit['cp'] ?? [];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _getLocation,
            icon: const Icon(Icons.location_on, color: Colors.red),
            tooltip: 'Partager ma position',
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SafeArea(
          child: Column(
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
                              child: Image.network(imageUrl, height: 350),
                            ),
                          )
                        : const Icon(Icons.image, size: 200),

                    const SizedBox(height: 35),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          nom,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            StarRating(rating: avis.toDouble()),
                            const SizedBox(width: 10),
                            Text.rich(
                              TextSpan(
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Text(
                                      avis.toString(),
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: " avis",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),
                          ],
                        ),

                        Row(
                          children: [
                            Icon(
                              Icons.local_offer,
                              color: livraison ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            Text(
                              livraison
                                  ? "Livraison gratuite"
                                  : "Livraison payante",
                              style: TextStyle(
                                fontSize: 15,
                                color: livraison ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$prix fcfa',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          "- ${pourcentage.toString()} %",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Text(
                          "Description",
                          style: const TextStyle(
                            fontSize: 21,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                description ?? '',
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Informations supplémentaires ➡️",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => DraggableScrollableSheet(
                            expand: false,
                            initialChildSize: 0.6,
                            minChildSize: 0.4,
                            maxChildSize: 0.95,
                            builder: (context, scrollController) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: ListView(
                                  controller: scrollController,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 50,
                                        height: 5,
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 📌 Caractéristiques Techniques
                                    const Text(
                                      "Caractéristiques Techniques",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...caracteristiqueTechnique.map(
                                      (e) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.blue,
                                        ),
                                        title: Text(
                                          e.toString(),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 30, thickness: 1.5),

                                    // 📌 Avantages et Utilisation
                                    const Text(
                                      "Avantages & Utilisation",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...avantageEtUtilsation.map(
                                      (e) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green,
                                        ),
                                        title: Text(
                                          e.toString(),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 30, thickness: 1.5),

                                    // 📌 Contenu du Package
                                    const Text(
                                      "Contenu du Package",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...contenuDuPackage.map(
                                      (e) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.inbox_outlined,
                                          color: Colors.deepPurple,
                                        ),
                                        title: Text(
                                          e.toString(),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.info, color: Colors.blue),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.black12),
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
                        SizedBox(
                          width: 130,
                          child: Row(
                            children: [
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
                              const SizedBox(width: 15),
                              IconButton(
                                onPressed: () {
                                  _ajouterAuPanier();
                                },
                                icon: Icon(
                                  Icons.add_shopping_cart,
                                  color: const Color.fromARGB(255, 50, 193, 55),
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
