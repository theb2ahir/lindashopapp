// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/achats/paiement/viamoov/PaiementPageFlooz.dart';
import 'package:lindashopp/features/achats/paiement/viayas/PaiementPageYas.dart';
import 'package:lindashopp/features/achats/buyall/buyallpage.dart';
import 'package:intl/intl.dart';
import 'package:lindashopp/features/profil/editprofil/editprofile.dart';

class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  Future<int> getNumberOfCommandes() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('commandes')
        .get();

    return querySnapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(body: Center(child: Text("Utilisateur non connecté")));
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              'Mon Panier',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            FutureBuilder<int>(
              future: getNumberOfCommandes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // rien pendant le chargement
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == 0) {
                  return const SizedBox.shrink(); // pas de badge si erreur ou 0 favoris
                }
                return Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${snapshot.data}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          
          
          
          ],
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
                var dateAjoutValue = data['dateAjout'];
                DateTime parsedDate;

                if (dateAjoutValue is Timestamp) {
                  // Cas normal Firestore
                  parsedDate = dateAjoutValue.toDate();
                } else if (dateAjoutValue is String) {
                  // Cas chaîne en "yy-MM-dd HH:mm"
                  parsedDate = DateFormat(
                    "yy-MM-dd HH:mm",
                  ).parse(dateAjoutValue);
                } else {
                  throw Exception("Format de dateAjout inconnu");
                }

                final displayDate = DateFormat(
                  'dd-MM-yy HH:mm',
                ).format(parsedDate);

                return Container(
                  padding: const EdgeInsets.all(9),
                  margin: EdgeInsets.all(4),
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
                              displayDate,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$quantity x $price FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'Acheter') {
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .get();

                            final userData = userDoc.data();

                            // 🔹 Vérifier si le numéro et l'adresse sont présents
                            if (userData == null ||
                                userData['phone'] == null ||
                                userData['phone'].toString().isEmpty ||
                                userData['adresse'] == null ||
                                userData['adresse'].toString().isEmpty) {
                              if (!mounted) return;
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
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const EditProfile(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const EditProfile(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          "Veuillez compléter votre profil",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 9),
                                    ],
                                  ),
                                ),
                              );
                              return; // Stoppe le paiement
                            }
                            if (!mounted) return;
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
                                        if (!mounted) return;
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
                                        if (!mounted) return;
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
                          } else if (value == 'modifier') {
                            // ✏️ Modifier la quantité
                            final TextEditingController qtyController =
                                TextEditingController(
                                  text: data['quantity'].toString(),
                                );

                            final newQty = await showDialog<int>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Modifier la quantité"),
                                content: TextField(
                                  controller: qtyController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Nouvelle quantité",
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Annuler"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final val = int.tryParse(
                                        qtyController.text,
                                      );
                                      Navigator.pop(context, val);
                                    },
                                    child: const Text("Confirmer"),
                                  ),
                                ],
                              ),
                            );

                            if (newQty != null && newQty > 0) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('commandes')
                                  .doc(commandes[index].id)
                                  .update({'quantity': newQty});
                            }
                          } else if (value == 'supprimer') {
                            // 🗑️ Supprimer l’article
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
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Acheter',
                            child: Text('Acheter le produit'),
                          ),
                          const PopupMenuItem(
                            value: 'modifier',
                            child: Text('Modifier quantité'),
                          ),
                          const PopupMenuItem(
                            value: 'supprimer',
                            child: Text('Supprimer du panier'),
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
