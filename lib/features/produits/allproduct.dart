import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lindashopp/features/produits/details/ProductDetailPage.dart';
// Assurez-vous que ce fichier existe

class Allproduct extends StatelessWidget {
  const Allproduct({super.key});

  Future<List<QueryDocumentSnapshot>> _fetchAllCollections() async {
    final construction = await FirebaseFirestore.instance
        .collection('construction')
        .get();
    final electronique = await FirebaseFirestore.instance
        .collection('electronique')
        .get();
    final fring = await FirebaseFirestore.instance.collection('fring').get();
    final modegosse = await FirebaseFirestore.instance
        .collection('produit-mode-et-enfant')
        .get();
    final sportbienetre = await FirebaseFirestore.instance
        .collection('produit-sport-et-bien-etre')
        .get();
    final electromenager = await FirebaseFirestore.instance
        .collection('produit-électro-ménagé')
        .get();

    // Combine tous les documents
    return [
      ...electronique.docs,
      ...construction.docs,
      ...fring.docs,
      ...sportbienetre.docs,
      ...electromenager.docs,
      ...modegosse.docs,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchAllCollections(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!;

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 colonnes
              crossAxisSpacing: 4,
              mainAxisSpacing: 2,
              childAspectRatio: 0.5,
            ),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final produit = products[index].data() as Map<String, dynamic>;
              final nom = produit['name'] ?? 'Sans nom';
              final prix = produit['prix']?.toString() ?? '0';
              final imageUrl = produit['imageURL'] ?? '';
              final avis = produit['avis'] ?? 0;

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
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              nom,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$prix fcfa",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      size: 12,
                                      Icons.star,
                                      color: avis > 3
                                          ? Colors.yellow
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      avis.toStringAsFixed(1),
                                    ), // ✅ affiche "3.5"2
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
              );
            },
          ),
        );
      },
    );
  }
}
