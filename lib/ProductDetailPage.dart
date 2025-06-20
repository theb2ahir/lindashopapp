// ignore_for_file: file_names, unnecessary_to_list_in_spreads, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/customtextfields.dart';
import 'package:lindashopp/Elements/favoriteProdvider.dart';
import 'package:lindashopp/Elements/favs.dart';
import 'package:lindashopp/Elements/items.dart';
import 'package:lindashopp/Elements/panierprovider.dart';
import 'package:lindashopp/panier.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> produit;

  const ProductDetailPage({super.key, required this.produit});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController quatityController = TextEditingController();
  final TextEditingController addressLivraisonCtrl = TextEditingController();

  Future<void> _ajouterAuPanier() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && _formKey.currentState!.validate()) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      setState(() {
        userData = doc.data();
        if (userData != null) {
          final newItem = Item(
            dateAjout: DateTime.now(),
            longitude: longitude ?? 0,
            latitude: latitude ?? 0,
            addressLivraison: addressLivraisonCtrl.text.trim().isEmpty
                ? 'jai partager ma position'
                : addressLivraisonCtrl.text.trim(),
            username: userData!['name'] ?? '',
            email: userData!['email'] ?? '',
            phone: userData!['phone'] ?? '',
            quantity: int.tryParse(quatityController.text.trim()) ?? 1,
            productName: widget.produit['name'],
            productPrice: widget.produit['prix'].toString(),
            productImageUrl: widget.produit['imageURL'],
            livraison: widget.produit['livraison'].toString(),
          );

          //Provider pour ajouter l’item
          Provider.of<PanierProvider>(
            context,
            listen: false,
          ).ajouterItem(newItem);

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
                      'Produit ajouté au panier!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    }
    Navigator.pop(context);
  }

  void _ajouterAuFavoris() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_formKey.currentState!.validate() && uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      setState(() {
        userData = doc.data();
        if (userData != null) {
          final newItem = Fav(
            dateAjout: DateTime.now(),
            longitude: longitude,
            latitude: latitude,
            addressLivraison: addressLivraisonCtrl.text.trim(),
            username: userData!['name'] ?? '',
            email: userData!['email'] ?? '',
            phone: userData!['phone'] ?? '',
            quantity: int.tryParse(quatityController.text.trim()) ?? 1,
            productName: widget.produit['name'],
            productPrice: widget.produit['prix'].toString(),
            productImageUrl: widget.produit['imageURL'],
            livraison: widget.produit['livraison'].toString(),
          );
          Provider.of<FavoriteProvider>(
            context,
            listen: false,
          ).ajouterFav(newItem);

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
                      'Produit ajouté au Favoris!',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    }
    quatityController.clear();
    latitude = null;
    longitude = null;
    Navigator.pop(context);
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

    final List<dynamic> caracteristiqueTechnique = widget.produit['ct'] ?? [];
    final List<dynamic> avantageEtUtilsation = widget.produit['au'] ?? [];
    final List<dynamic> contenuDuPackage = widget.produit['cp'] ?? [];

    return Scaffold(
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PanierPage()),
              );
            },
            icon: const Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    imageUrl.isNotEmpty
                        ? Center(
                            child: Image.asset(
                              '$imageUrl',
                              height: 400,
                            ),
                          )
                        : const Icon(Icons.image, size: 100),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              '$prix FCFA',
                              style: const TextStyle(
                                fontSize: 19,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Livraison incluse? : $livraison',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),

                        IconButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _ajouterAuFavoris();
                            }
                          },
                          icon: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Inforamtions du prduit",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              height: 250,
                              width: 350,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(31, 0, 0, 0),
                                    blurRadius: 10,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Text("$description"),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Container(
                              height: 250,
                              width: 350,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Padding(
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
                                              fontSize: 20,
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
                            ),
                            const SizedBox(width: 20),
                            Container(
                              height: 250,
                              width: 350,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                                              fontSize: 20,
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
                            ),
                            const SizedBox(width: 20),
                            Container(
                              height: 250,
                              width: 350,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                            fontSize: 20,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Information utilisateur",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Form(
                      key: _formKey,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Informations utilisateur",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "👤 Nom : ${userData?['name'] ?? ''}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  "📧 Email : ${userData?['email'] ?? ''}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  "📱 Téléphone : ${userData?['phone'] ?? ''}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text("Entrez votre adresse ou partagez votre position pour la livraison", 
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 50,
                            child: CustomTextField(
                              controller: addressLivraisonCtrl,
                              label: "Adresse de livraison",
                            ),
                          ),
                      
                          IconButton(
                            onPressed: _getLocation,
                            icon: const Icon(Icons.location_on),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 50,
                          width: 130,
                          child: CustomTextField(
                            controller: quatityController,
                            label: "quantité",
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _ajouterAuPanier();
                            }
                          },
                          icon: Icon(
                            Icons.add_shopping_cart,
                            color: const Color.fromARGB(255, 50, 193, 55),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
