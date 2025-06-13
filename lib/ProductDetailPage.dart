// ignore_for_file: file_names, unnecessary_to_list_in_spreads, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/customtextfields.dart';
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
  String position = 'Appuyez pour obtenir la position';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController quatityController = TextEditingController();

  void _ajouterAuPanier() {
    if (_formKey.currentState!.validate()) {
      final newItem = Item(
        dateAjout: DateTime.now(),
        longitude: longitude,
        latitude: latitude,
        username: nameController.text.trim(),
        prenom: prenomController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        quantity: int.tryParse(quatityController.text.trim()) ?? 1,
        productName: widget.produit['name'],
        productPrice: widget.produit['prix'].toString(),
        productImageUrl: widget.produit['imageURL'],
        livraison: widget.produit['livraison'].toString(),
      );

      //Provider pour ajouter l’item
      Provider.of<PanierProvider>(context, listen: false).ajouterItem(newItem);

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

      prenomController.clear();
      phoneController.clear();
      emailController.clear();
      quatityController.clear();
      nameController.clear();
      latitude = null;
      longitude = null;
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
      body: Padding(
        padding: const EdgeInsets.all(13),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              imageUrl.isNotEmpty
                  ? Center(
                      child: Image.asset(
                        'assets/${imageUrl.replaceAll(r'\', '/')}',
                        height: 200,
                      ),
                    )
                  : const Icon(Icons.image, size: 100),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Livraison incluse? : $livraison',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$prix FCFA',
                    style: const TextStyle(fontSize: 15, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                "Inforamtion du prduit",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
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
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Carctéristiques technique",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text(
                                  "Avantage et utilisation",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Contenu du package",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
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
                "Formualire d'ajout au panier",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(controller: nameController, label: "Nom"),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: prenomController,
                      label: "Prenom",
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: phoneController,
                      label: "Numero de tel",
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: emailController,
                      label: "Email",
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: quatityController,
                      label: "Quantité",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _getLocation,
                child: Text('Partager ma position'),
              ),

              SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Latitude: ${latitude ?? "Inconnue"}'),
                  Text('Longitude: ${longitude ?? "Inconnue"}'),
                ],
              ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _ajouterAuPanier();
                      }
                    },
                    child: const Text('Ajouter au Panier'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Ajouter au Favoris'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
