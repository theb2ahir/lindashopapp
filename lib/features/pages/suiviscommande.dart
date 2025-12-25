// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lindashopp/features/pages/products/produitrecommander.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
          style: GoogleFonts.poppins(fontSize: 25, fontWeight: FontWeight.bold),
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
                      style: GoogleFonts.poppins(fontSize: 14),
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
                    final transactionId =
                        data['transactionId']?.toString() ?? '';
                    final qrJson = data['Qrjson']?.toString() ?? '';
                    final status = data['status']?.toString() ?? '';
                    final timestamp = data['date'] as Timestamp?;
                    final parsedDate = timestamp?.toDate();
                    final price = data['productprice']?.toString() ?? '';

                    // Si parsedDate est non null, on formate ; sinon, on affiche "Date inconnue"
                    final displayDate = parsedDate != null
                        ? DateFormat('dd-MM-yy HH:mm').format(parsedDate)
                        : 'Date inconnue';
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                            // IMAGE PRODUIT
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

                            // INFOS PRODUIT
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

                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            "Copier la reference de paiement dans le presse papier",
                                            style: GoogleFonts.poppins(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(
                                            ref,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                // Copier le ref dans le presse papier
                                                Clipboard.setData(
                                                  ClipboardData(text: ref),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Reference de paiement copié dans le presse papier",
                                                    ),
                                                  ),
                                                );
                                              },

                                              child: const Text(
                                                "Copier",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Ref : $ref',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            "Copier la transaction Id dans le presse papier",
                                            style: GoogleFonts.poppins(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(
                                            transactionId,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                // Copier la transaction dans le presse papier
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: transactionId,
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Transaction id copié dans le presse papier",
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                "Copier",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'T_Id : $transactionId',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

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
                                      supprimerAcr(
                                        doc.id,
                                        ref,
                                        productName,
                                        context,
                                      );
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code),
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          "QR code",
                                          style: GoogleFonts.poppins(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: SizedBox(
                                          width: 250,
                                          height: 250,
                                          child: QrImageView(
                                            data: qrJson,
                                            version: QrVersions.auto,
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              "Fermer",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ],
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

Widget _statusBadge(String status, BuildContext context) {
  Color color;

  switch (status.toLowerCase()) {
    case 'Paiement validé , en attente de livraison':
      color = Colors.green;
      break;
    case 'en verification':
      color = Colors.orange;
      break;
    case 'Paiement refusé, ref incorrecte' ||
        "Paiement refusé, référence d'achat incorrecte":
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
