import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/pages/products/ProductDetailPage.dart';

class ProductColumn extends StatefulWidget {
  final String collectionName;
  final String searchQuery; // 👈 Ajout du paramètre de recherche

  const ProductColumn({
    super.key,
    required this.collectionName,
    required this.searchQuery,
  });

  @override
  State<ProductColumn> createState() => _ProductColumnState();
}

class _ProductColumnState extends State<ProductColumn> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(widget.collectionName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final produits = snapshot.data!.docs;

        // 🔍 Filtrer selon le champ `name`
        final filteredProduits = produits.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          final query = widget.searchQuery.toLowerCase();
          return name.contains(query);
        }).toList();

        if (filteredProduits.isEmpty) {
          return const Center(child: Text('Aucun produit trouvé.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredProduits.length,
          itemBuilder: (context, index) {
            final produit =
                filteredProduits[index].data() as Map<String, dynamic>;
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
                      produitId:
                          filteredProduits[index].id, // 👈 ID du document
                      collectionName:
                          filteredProduits[index].reference.parent.id,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.transparent
                            : Color.fromRGBO(255, 255, 255, 0.102),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        // 🖼️ Image du produit
                        Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                        const SizedBox(height: 6),

                        // 🧾 Détails du produit
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nom,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$prix F",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: moyenne > 3
                                          ? Colors.yellow
                                          : Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(moyenne.toStringAsFixed(1)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
