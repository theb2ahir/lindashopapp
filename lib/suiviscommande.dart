// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AcrListPage extends StatefulWidget {
  const AcrListPage({super.key});

  @override
  State<AcrListPage> createState() => _AcrListPageState();
}

class _AcrListPageState extends State<AcrListPage> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(body: Center(child: Text("Utilisateur non connecté")));
    }
    // ✅ Fonction pour supprimer un ACR par son ID
    Future<void> supprimerAcr(String docId, BuildContext context) async {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('acr')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ACR supprimé avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de suppression : $e')));
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF02204B),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'mes achats',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(child: Text('Aucun ACR trouvé.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final imageUrl = data['imageUrl']?.toString() ?? '';
              final productName = data['productname']?.toString() ?? '';
              final quantity = data['quantity']?.toString() ?? '';
              final ref = data['reference']?.toString() ?? '';
              final status = data['status']?.toString() ?? '';

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
                      Text('Référence: $ref'),
                      Text('Quantité: $quantity'),
                      Row(
                        children: [
                          Text(
                            "Statut : ",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
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
                                  Navigator.of(context).pop(false), // Annuler
                              child: const Text("Non"),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true), // Confirmer
                              child: const Text("Oui"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        supprimerAcr(doc.id, context);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
