import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/pages/products/ProductDetailPage.dart';

class Allproduct extends StatefulWidget {
  final String searchQuery; // 👈 mot-clé de recherche envoyé depuis HomePage
  const Allproduct({super.key, required this.searchQuery});

  @override
  State<Allproduct> createState() => _AllproductState();
}

class _AllproductState extends State<Allproduct> {
  List<QueryDocumentSnapshot> allProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllCollections();
  }

  Future<void> _fetchAllCollections() async {
    setState(() => isLoading = true);

    final collections = [
      'construction',
      'electronique',
      'fring',
      'produit-mode-et-enfant',
      'produit-sport-et-bien-etre',
      'produit-électro-ménagé',
    ];

    List<QueryDocumentSnapshot> allDocs = [];

    for (var collectionName in collections) {
      final snapshot =
          await FirebaseFirestore.instance.collection(collectionName).get();
      allDocs.addAll(snapshot.docs);
    }
    if (!mounted) return;
    setState(() {
      allProducts = allDocs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 🔍 Appliquer le filtre selon searchQuery
    final filteredProducts = allProducts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      return name.contains(widget.searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredProducts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 2,
          childAspectRatio: 0.5,
        ),
        itemBuilder: (context, index) {
          final produit =
              filteredProducts[index].data() as Map<String, dynamic>;

          final nom = produit['name'] ?? 'Sans nom';
          final prix = produit['prix']?.toString() ?? '0';
          final imageUrl = produit['imageURL'] ?? '';
          final avis = (produit['avis'] ?? 0).toDouble();

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(produit: produit),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(255, 255, 255, 0.102),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nom,
                      textAlign: TextAlign.start,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$prix F",
                          style:GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          )
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color:
                                  avis > 3 ? Colors.yellow : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(avis.toStringAsFixed(1)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
