// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/PaiementPageFlooz.dart';
import 'package:lindashopp/PaiementPageYas.dart';
import 'package:lindashopp/buyallpage.dart';

class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(body: Center(child: Text("Utilisateur non connecté")));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Mon Panier',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('commandes')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Aucun article dans le panier'));
            }

            final commandes = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: commandes.length,
              itemBuilder: (context, index) {
                final data = commandes[index].data() as Map<String, dynamic>;
                final int price =
                    int.tryParse(data['productprice'].toString()) ?? 0;
                final int quantity = data['quantity'] is int
                    ? data['quantity']
                    : int.tryParse(data['quantity'].toString()) ?? 1;
                final String productName = data['productname'] ?? '';
                final String imageUrl = data['productImageUrl'] ?? '';
                final date =( data['dateAjout'] as Timestamp).toDate().toString().substring(0, 16);

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🖼 Image du produit
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 📄 Détails du produit
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Ajouté le : $date',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '\$$price',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text('Qté: $quantity'),
                          ],
                        ),
                      ),

                      // 🛒 Icônes d’action
                      Column(
                        children: [
                          // Supprimer
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Confirmation"),
                                  content: const Text(
                                    "Supprimer cette commande ?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Non"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Oui"),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .collection('commandes')
                                    .doc(commandes[index].id)
                                    .delete();
                              }
                            },
                          ),
                          // Acheter
                          IconButton(
                            icon: const Icon(
                              Icons.payment,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Color(0xFF02204B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  duration: Duration(seconds: 3),
                                  content: Row(
                                    children: [
                                      Icon(Icons.phone, color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Choisissez un operateur',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PaiementPage2(data: data),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Flooz",
                                          style: TextStyle(
                                            color: Colors.lightGreenAccent,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PaiementPage(data: data),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Yas",
                                          style: TextStyle(
                                            color: Colors.yellowAccent,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    
                    
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('commandes')
              .get();

          final List<Map<String, dynamic>> commandes = snapshot.docs
              .map((doc) => doc.data())
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BuyAllPage(commandes: commandes)),
          );
        },
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
