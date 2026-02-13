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
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .get();
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
    final size = MediaQuery.of(context).size;
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
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 0.5,
        ),
        itemBuilder: (context, index) {
          final produit =
              filteredProducts[index].data() as Map<String, dynamic>;

          final nom = produit['name'] ?? 'Sans nom';
          final prix = produit['prix']?.toString() ?? '0';
          final imageUrl = produit['imageURL'] ?? '';
          double getMoyenneAvis(List avis) {
            if (avis.isEmpty) return 0;

            final double total = avis
                .map((e) {
                  if (e is num) return e.toDouble(); // OK si c’est un nombre
                  return double.tryParse(e.toString()) ??
                      0.0; // Convertit la string "5" → 5.0
                })
                .reduce((a, b) => a + b);

            return total / avis.length;
          }

          final moyenne = getMoyenneAvis(produit['avis'] ?? []);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(
                    produit: produit,
                    produitId: filteredProducts[index].id, // 👈 ID du document
                    collectionName: filteredProducts[index]
                        .reference
                        .parent
                        .id, // 👈 Nom de la collection
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Color.fromRGBO(
                              255,
                              255,
                              255,
                              0.102,
                            ).withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: size.height > 800 ? 150 : 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(Icons.image_not_supported),
                                  ),
                            ),
                            // Row de la note en haut à droite
                            Positioned(
                              bottom: 3,
                              right: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: size.width > 400 ? 12 : 10,
                                      color: moyenne > 3
                                          ? Colors.yellow
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      moyenne.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: size.width > 400 ? 12 : 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: size.height > 800 ? 6 : 4),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        nom,
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: GoogleFonts.poppins(
                          fontSize: size.width > 400 ? 14 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Row(
                        children: [
                          Text(
                            "$prix F",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: size.width > 400 ? 12 : 10,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
