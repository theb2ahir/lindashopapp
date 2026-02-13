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
    final size = MediaQuery.of(context).size;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Utilisateur non connecté",
            style: GoogleFonts.poppins(
              fontSize: size.width > 400 ? 16 : 14,
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
            .where('userid', isEqualTo: uid)
            .where('acrid', isEqualTo: docId)
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

    Future<void> viderListeAcr() async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur non connecté")),
        );
        return;
      }

      //dialog de confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirmation"),
          content: const Text(
            "Voulez-vous vraiment vider votre liste d'achats ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Vider"),
            ),
          ],
        ),
      );
      if (confirm == true) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('acr')
              .get()
              .then((snapshot) {
                if (snapshot.docs.isNotEmpty) {
                  for (var doc in snapshot.docs) {
                    supprimerAcr(
                      doc.id,
                      doc.data()['reference'] ?? '',
                      context,
                    );
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Liste vidée avec succès")),
                );
              });
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur de suppression : $e')));
        }
      } else {
        return;
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'achats',
          style: GoogleFonts.poppins(
            fontSize: size.width > 400 ? 25 : 20,
            fontWeight: FontWeight.bold,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Vos  achats",
                    style: GoogleFonts.poppins(
                      fontSize: size.width > 400 ? 18 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => viderListeAcr(),
                    child: Text(
                      "Vider la liste",
                      style: GoogleFonts.poppins(
                        fontSize: size.width > 400 ? 15 : 13,
                      ),
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
                  .orderBy('date', descending: true)
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
                      "Vous n'avez malheureusement rien acheté pour le moment 😔",
                      style: GoogleFonts.poppins(
                        fontSize: size.width > 400 ? 14 : 12,
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
                    final ref = data['reference']?.toString() ?? '';
                    final total = data['prixTotal'] ?? 0;
                    final transactionId =
                        data['transactionId']?.toString() ?? '';
                    final qrJson = data['Qrjson']?.toString() ?? '';
                    final status = data['status']?.toString() ?? '';
                    final timestamp = data['date'] as Timestamp?;
                    final parsedDate = timestamp?.toDate();
                    final deliveryPrice = data['deliveryPrice'] ?? 0.0;

                    // Si parsedDate est non null, on formate ; sinon, on affiche "Date inconnue"
                    final displayDate = parsedDate != null
                        ? DateFormat('dd-MM-yy HH:mm').format(parsedDate)
                        : 'Date inconnue';

                    final items = data['items'] as List<dynamic>? ?? [];
                    Color badgeColor = Colors.blueGrey;

                    if (items.length == 2) {
                      badgeColor = Colors.orangeAccent;
                    } else if (items.length >= 3 && items.length <= 100) {
                      badgeColor = Colors.green;
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: size.width > 400 ? 12 : 6,
                        vertical: size.height > 800 ? 6 : 4,
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
                              child: Container(
                                width: size.width > 400 ? 70 : 50,
                                height: size.height > 800 ? 70 : 50,
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image,
                                  size: size.width > 400 ? 30 : 20,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            SizedBox(width: size.width > 400 ? 12 : 6),

                            // INFOS PRODUIT
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) {
                                              return DraggableScrollableSheet(
                                                initialChildSize: 0.6,
                                                minChildSize: 0.4,
                                                maxChildSize: 0.9,
                                                builder: (context, scrollController) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(
                                                        context,
                                                      ).cardColor,
                                                      borderRadius:
                                                          const BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  24,
                                                                ),
                                                          ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        /// 🔹 Drag handle
                                                        Container(
                                                          width: 40,
                                                          height: 4,
                                                          margin:
                                                              const EdgeInsets.only(
                                                                bottom: 16,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? Colors.white38
                                                                : Colors
                                                                      .black26,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  2,
                                                                ),
                                                          ),
                                                        ),

                                                        /// 🔹 Titre
                                                        Text(
                                                          "Détails de la commande",
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),

                                                        const SizedBox(
                                                          height: 16,
                                                        ),

                                                        /// 🔹 Liste des produits
                                                        Expanded(
                                                          child: ListView.builder(
                                                            controller:
                                                                scrollController,
                                                            itemCount:
                                                                items.length,
                                                            itemBuilder: (context, index) {
                                                              final item =
                                                                  items[index];
                                                              final String
                                                              productname =
                                                                  item['productname'] ??
                                                                  '';
                                                              final int
                                                              quantity =
                                                                  item['quantity'] ??
                                                                  0;
                                                              final String
                                                              productprice =
                                                                  item['productprice'] ??
                                                                  "";
                                                              final bool
                                                              livraison =
                                                                  item['livraison'] ==
                                                                  true;
                                                              final String
                                                              imageurl =
                                                                  item['imageurl'] ??
                                                                  '';

                                                              return Container(
                                                                margin:
                                                                    const EdgeInsets.only(
                                                                      bottom:
                                                                          12,
                                                                    ),
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      12,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      Theme.of(
                                                                            context,
                                                                          ).brightness ==
                                                                          Brightness
                                                                              .dark
                                                                      ? Colors
                                                                            .white10
                                                                      : Colors
                                                                            .grey
                                                                            .shade100,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        16,
                                                                      ),
                                                                ),
                                                                child: Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    /// Image
                                                                    ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                      child: Image.network(
                                                                        imageurl,
                                                                        width:
                                                                            70,
                                                                        height:
                                                                            70,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),

                                                                    const SizedBox(
                                                                      width: 12,
                                                                    ),

                                                                    /// Infos produit
                                                                    Expanded(
                                                                      child: Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            productname,
                                                                            maxLines:
                                                                                2,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            style: GoogleFonts.poppins(
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                4,
                                                                          ),
                                                                          Text(
                                                                            "Quantité : $quantity",
                                                                            style: GoogleFonts.poppins(
                                                                              fontSize: 13,
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            "Prix : $productprice FCFA",
                                                                            style: GoogleFonts.poppins(
                                                                              fontSize: 13,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                6,
                                                                          ),

                                                                          Text(
                                                                            "Frais de livraison : ${livraison == true ? 0 : deliveryPrice.toString()} FCFA",
                                                                            style: GoogleFonts.poppins(
                                                                              fontSize: 13,
                                                                            ),
                                                                          ),

                                                                          /// Badge livraison
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Container(
                                                                                padding: const EdgeInsets.symmetric(
                                                                                  horizontal: 10,
                                                                                  vertical: 4,
                                                                                ),
                                                                                decoration: BoxDecoration(
                                                                                  color: livraison
                                                                                      ? Colors.green.withValues(
                                                                                          alpha: 0.15,
                                                                                        )
                                                                                      : Colors.orange.withValues(
                                                                                          alpha: 0.15,
                                                                                        ),
                                                                                  borderRadius: BorderRadius.circular(
                                                                                    20,
                                                                                  ),
                                                                                ),
                                                                                child: Text(
                                                                                  livraison
                                                                                      ? "Livraison gratuite"
                                                                                      : "Livraison payante",
                                                                                  style: GoogleFonts.poppins(
                                                                                    fontSize: 11,
                                                                                    fontWeight: FontWeight.w500,
                                                                                    color: livraison
                                                                                        ? Colors.green
                                                                                        : Colors.orange,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                        child: Text(
                                          '${items.length} produit(s)',
                                          style: GoogleFonts.poppins(
                                            fontSize: size.width > 400
                                                ? 14
                                                : 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      _statusBadge(status, context),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            "Copier la reference de paiement dans le presse papier",
                                            style: GoogleFonts.poppins(
                                              fontSize: size.width > 400
                                                  ? 19
                                                  : 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(
                                            ref,
                                            style: GoogleFonts.poppins(
                                              fontSize: size.width > 400
                                                  ? 13
                                                  : 11,
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

                                              child: Text(
                                                "Copier",
                                                style: TextStyle(
                                                  fontSize: size.width > 400
                                                      ? 16
                                                      : 14,
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
                                        fontSize: size.width > 400 ? 14 : 12,
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
                                              fontSize: size.width > 400
                                                  ? 19
                                                  : 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(
                                            transactionId,
                                            style: GoogleFonts.poppins(
                                              fontSize: size.width > 400
                                                  ? 13
                                                  : 11,
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
                                              child: Text(
                                                "Copier",
                                                style: TextStyle(
                                                  fontSize: size.width > 400
                                                      ? 16
                                                      : 14,
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
                                        fontSize: size.width > 400 ? 14 : 12,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: size.height > 800 ? 4 : 3),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        displayDate,
                                        style: GoogleFonts.poppins(
                                          fontSize: size.width > 400 ? 13 : 10,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      _totalBadge(total, context),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ACTIONS
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: size.width > 400 ? 24 : 18,
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
                                      supprimerAcr(doc.id, ref, context);
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
                                            fontSize: size.width > 400
                                                ? 19
                                                : 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: SizedBox(
                                          width: size.width > 400 ? 250 : 200,
                                          height: size.height > 800 ? 250 : 200,
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
                                            child: Text(
                                              "Fermer",
                                              style: TextStyle(
                                                fontSize: size.width > 400
                                                    ? 16
                                                    : 14,
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

            SizedBox(height: size.height > 800 ? 20 : 16),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text(
                    "Produits qui pourraient vous intéresser",
                    style: GoogleFonts.poppins(
                      fontSize: size.width > 400 ? 17 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height > 800 ? 10 : 6),
            ProduitsRecommandes(),
          ],
        ),
      ),
    );
  }
}

Widget _statusBadge(String status, BuildContext context) {
  Color color;

  final size = MediaQuery.of(context).size;
  switch (status.toLowerCase()) {
    case 'Paiement validé , en attente de livraison' || 'livrer':
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
    padding: EdgeInsets.symmetric(
      horizontal: size.width > 400 ? 10 : 8,
      vertical: size.height > 800 ? 4 : 2,
    ),
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
                fontSize: size.width > 400 ? 24 : 18,
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
          fontSize: size.width > 400 ? 11 : 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ),
  );
}

Widget _totalBadge(int total, BuildContext context) {
  final size = MediaQuery.of(context).size;
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: size.width > 400 ? 10 : 8,
      vertical: size.height > 800 ? 4 : 2,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.red,
      borderRadius: BorderRadius.circular(20),
    ),
    constraints: const BoxConstraints(
      maxWidth: 90, // ajuste selon ton UI
    ),
    child: Text(
      "${total.toString()} FCFA",
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: GoogleFonts.poppins(
        fontSize: size.width > 400 ? 11 : 9,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.red
            : Colors.white,
      ),
    ),
  );
}
