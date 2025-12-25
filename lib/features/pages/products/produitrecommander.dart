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
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchAllCollections(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur de chargement',
              style: GoogleFonts.poppins(
                fontSize: 16,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Card(
                elevation: 3,
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
                      width: 70,
                      height: 70,
                    ),
                  ),
                  title: Text(
                    nom,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$prix F",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: livraison ? Colors.green : Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            livraison
                                ? "Livraison gratuite"
                                : "livraison payante",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: livraison
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
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
