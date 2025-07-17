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
        backgroundColor: const Color.fromARGB(255, 1, 15, 41),
        title: const Text(
          'Mon Panier',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: commandes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) {
              final data = commandes[index].data() as Map<String, dynamic>;
              final int price =
                  int.tryParse(data['productprice'].toString()) ?? 0;
              final int quantity = data['quantity'] is int
                  ? data['quantity']
                  : int.tryParse(data['quantity'].toString()) ?? 1;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['productImageUrl'] ?? '',
                          width: double.infinity,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['productname'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('$price FCFA'), Text('Qté: $quantity')],
                      ),
                      Text(
                        "Total à payer : ${price * quantity} FCFA",
                        style: const TextStyle(fontSize: 12),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Confirmation"),
                                  content: const Text(
                                    "Voulez-vous vraiment supprimer cette commande ?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        context,
                                      ).pop(false), // Annuler
                                      child: const Text("Non"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        context,
                                      ).pop(true), // Confirmer
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

                          IconButton(
                            icon: const Icon(
                              Icons.payment,
                              size: 20,
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
                                      Row(
                                        children: [
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
                ),
              );
            },
          );
        },
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
