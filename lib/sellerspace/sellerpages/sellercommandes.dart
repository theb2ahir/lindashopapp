// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SellerCommandes extends StatefulWidget {
  const SellerCommandes({super.key});

  @override
  State<SellerCommandes> createState() => _SellerCommandesState();
}

class _SellerCommandesState extends State<SellerCommandes> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // ✅ Fonction pour supprimer un ACR par son ID
  Future<void> supprimercommande(
    String docId,
    String productname,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sellercommandes')
          .doc(docId)
          .delete();

      final infouserCollection = FirebaseFirestore.instance.collection(
        'infouser',
      );

      final query = await infouserCollection
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where('productname', isEqualTo: productname)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await infouserCollection.doc(query.docs.first.id).delete();
      }

      // ✅ Vérifie que le widget est encore monté avant d’utiliser le context
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande supprimée avec succès ✅')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de suppression : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Commandes",
          style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sellercommandes')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de chargement'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final commandes = snapshot.data!.docs;

          if (commandes.isEmpty) {
            return Center(
              child: Text(
                'Aucune commande pour le moment.',
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            );
          }
          return ListView.builder(
            itemCount: commandes.length,
            itemBuilder: (context, index) {
              final doc = commandes[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final status = data['status']?.toString() ?? '';
              final timestamp = data['date'] as Timestamp?;
              final parsedDate = timestamp?.toDate();
              final displayDate = parsedDate != null
                  ? DateFormat('dd-MM-yy HH:mm').format(parsedDate)
                  : 'Date inconnue';

              final produits = (data['produits'] as List<dynamic>? ?? []);

              return Column(
                children: produits.map((prod) {
                  final product = prod as Map<String, dynamic>;
                  final imageUrl = product['imageurl'] ?? '';
                  final productName = product['productname'] ?? 'Sans nom';
                  final quantity = product['quantity'] ?? 0;
                  final price = product['productprice'] ?? 0;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IMAGE
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image, size: 30),
                                  ),
                          ),
                          const SizedBox(width: 12),

                          // INFOS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // NOM + STATUT
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        productName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    _statusBadge(status, context),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$quantity x $price FCFA',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  displayDate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ACTIONS
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Supprimer"),
                                      content: const Text(
                                        "Voulez-vous vraiment supprimer cette commande ?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Annuler"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Supprimer"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    // Supprime le produit du tableau produits
                                    final List produitsList = List.from(
                                      doc['produits'],
                                    );
                                    produitsList.removeWhere(
                                      (p) => p['productname'] == productName,
                                    );
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .collection('sellercommandes')
                                        .doc(doc.id)
                                        .update({'produits': produitsList});
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

Widget _statusBadge(String status, BuildContext context) {
  Color color;

  switch (status.toLowerCase()) {
    case 'en attente de livraison' || 'livrer' || 'payer':
      color = Colors.green;
      break;
    case 'en verification':
      color = Colors.orange;
      break;
    case 'Paiement refusé' || 'commande rejeter':
      color = Colors.red;
      break;
    default:
      color = Colors.blueGrey;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    constraints: const BoxConstraints(
      maxWidth: 90, // ajuste selon ton UI
    ),
    child: GestureDetector(
      onTap: () {
        // Afficher le popup de confirmation
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Fermer"),
              ),
            ],
          ),
        );
      },
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ),
  );
}
