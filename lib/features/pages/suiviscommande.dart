// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lindashopp/features/pages/products/produitrecommander.dart';

class AcrListPage extends StatefulWidget {
  const AcrListPage({super.key});

  @override
  State<AcrListPage> createState() => _AcrListPageState();
}

class _AcrListPageState extends State<AcrListPage> {
  Future<int> getNumberOfAcr() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('acr')
        .get();

    return querySnapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Utilisateur non connecté",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      );
    }
    // ✅ Fonction pour supprimer un ACR par son ID
    Future<void> supprimerAcr(
      String docId,
      String referencePaiement,
      String productname,
      BuildContext context,
    ) async {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('acr')
            .doc(docId)
            .delete();

        final infouserCollection = FirebaseFirestore.instance.collection(
          'infouser',
        );

        final query = await infouserCollection
            .where('ref', isEqualTo: referencePaiement)
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'achats',
          style: GoogleFonts.poppins(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    "Vos  achats",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // Liste des achats
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('acr')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Aucun achat trouvé.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final imageUrl = data['imageUrl']?.toString() ?? '';
                    final productName = data['productname']?.toString() ?? '';
                    final quantity = data['quantity']?.toString() ?? '';
                    final ref = data['reference']?.toString() ?? '';
                    final status = data['status']?.toString() ?? '';
                    final timestamp = data['date'] as Timestamp?;
                    final parsedDate = timestamp?.toDate();
                    final price = data['productprice']?.toString() ?? '';

                    // Si parsedDate est non null, on formate ; sinon, on affiche "Date inconnue"
                    final displayDate = parsedDate != null
                        ? DateFormat('dd-MM-yy HH:mm').format(parsedDate)
                        : 'Date inconnue';

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(productName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Réf de paiement: $ref'),
                            Text('$quantity x $price FCFA'),
                            Text(displayDate),
                            Text(
                              status,
                              style: TextStyle(
                                color: const Color.fromARGB(255, 10, 176, 5),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
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
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Non"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Oui"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              supprimerAcr(doc.id, ref, productName, context);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    "Produits qui pourraient vous intéresser",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ProduitsRecommandes(),
          ],
        ),
      ),
    );
  }
}
