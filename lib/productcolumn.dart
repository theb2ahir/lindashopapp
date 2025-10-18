import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/produits/details/ProductDetailPage.dart';

class ProductColumn extends StatefulWidget {
  final String collectionName;
  const ProductColumn({super.key, required this.collectionName});

  @override
  State<ProductColumn> createState() => _ProductColumnState();
}

class _ProductColumnState extends State<ProductColumn> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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

              return GridView.builder(
                padding: EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 0.9,
                ),
                itemCount: produits.length,
                itemBuilder: (context, index) {
                  final produit =
                      produits[index].data() as Map<String, dynamic>;
                  final nom = produit['name'] ?? 'Sans nom';
                  final prix = produit['prix']?.toString() ?? '0';
                  final imageUrl = produit['imageURL'] ?? '';
                  final avis = produit['avis'] ?? 0;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(produit: produit),
                          ),
                        );
                      });
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              // Image produit
                              Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(Icons.image_not_supported),
                                    ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                              ),

                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    nom,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$prix fcfa",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
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

                              // Overlay flouté
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
