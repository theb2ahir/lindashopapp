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
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.8,
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
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Image produit
                          Image.network(
                            imageUrl,
                            fit: BoxFit.fill,
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

                          // Overlay flouté
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                color: Colors.white30,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      nom,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$prix FCFA',
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              51,
                                              110,
                                              6,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    "${avis.toDouble()} ", // conversion en string + petit espace
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const TextSpan(
                                                text: "⭐",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ), // Tu peux rendre ça dynamique
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
