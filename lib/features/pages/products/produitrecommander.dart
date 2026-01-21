import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/pages/products/ProductDetailPage.dart';
// Assurez-vous que ce fichier existe

class ProduitsRecommandes extends StatelessWidget {
  const ProduitsRecommandes({super.key});

  Future<List<QueryDocumentSnapshot>> _fetchAllCollections() async {
    final electronique = await FirebaseFirestore.instance
        .collection('electronique')
        .get();
    final modegosse = await FirebaseFirestore.instance
        .collection('produit-mode-et-enfant')
        .get();
    final fring = await FirebaseFirestore.instance.collection('fring').get();

    // Combine tous les documents
    return [...electronique.docs, ...modegosse.docs, ...fring.docs];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchAllCollections(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur de chargement',
              style: GoogleFonts.poppins(
                fontSize: size.width > 400 ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final produit = products[index].data() as Map<String, dynamic>;
            final nom = produit['name'] ?? 'Sans nom';
            final prix = produit['prix']?.toString() ?? '0';
            final imageUrl = produit['imageURL'] ?? '';
            final livraison = produit['livraison'] ?? 0;
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

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width > 400 ? 8 : 6,
                vertical: size.height > 800 ? 4 : 2,
              ),
              child: Card(
                elevation: size.height > 800 ? 6 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: size.width > 400 ? 70 : 50,
                      height: size.height > 800 ? 70 : 50,
                    ),
                  ),
                  title: Text(
                    nom,
                    style: GoogleFonts.poppins(
                      fontSize: size.width > 400 ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$prix F",
                        style: GoogleFonts.poppins(
                          fontSize: size.width > 400 ? 12 : 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: size.height > 800 ? 4 : 2),
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: livraison ? Colors.green : Colors.redAccent,
                            size: size.width > 400 ? 16 : 14,
                          ),
                          SizedBox(width: size.width > 400 ? 4 : 2),
                          Text(
                            livraison
                                ? "Livraison gratuite"
                                : "livraison payante",
                            style: GoogleFonts.poppins(
                              fontSize: size.width > 400 ? 12 : 10,
                              fontWeight: FontWeight.bold,
                              color: livraison
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: size.width > 400 ? 16 : 14,
                          ),
                          const SizedBox(width: 2),
                          Text(moyenne.toStringAsFixed(1)),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(
                          produit: produit,
                          produitId: products[index].id, // 👈 ID du document
                          collectionName: products[index].reference.parent.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
