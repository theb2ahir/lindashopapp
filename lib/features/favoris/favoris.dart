// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lindashopp/features/achats/paiement/viamoov/PaiementPageFlooz.dart';
import 'package:lindashopp/features/achats/paiement/viayas/PaiementPageYas.dart';
import 'package:lindashopp/features/achats/buyall/buyallpage.dart';
import 'package:lindashopp/features/profil/editprofil/editprofile.dart';

class Favoris extends StatefulWidget {
  const Favoris({super.key});

  @override
  State<Favoris> createState() => _FavorisState();
}

class _FavorisState extends State<Favoris> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(body: Center(child: Text("Utilisateur non connecté", style:  GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.black,
      ),)));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title:  Text(
          'Mes favoris',
          style:  GoogleFonts.poppins(
            fontSize: 23,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favoris')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return  Center(child: Text('Aucun article dans le panier', style:  GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black,
            ),));
          }

          final commandes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: commandes.length,
            itemBuilder: (context, index) {
              final data = commandes[index].data() as Map<String, dynamic>;
              var dateAjoutValue = data['dateAjout'];
              DateTime parsedDate;

              if (dateAjoutValue is Timestamp) {
                // Cas normal Firestore
                parsedDate = dateAjoutValue.toDate();
              } else if (dateAjoutValue is String) {
                // Cas chaîne en "yy-MM-dd HH:mm"
                parsedDate = DateFormat("yy-MM-dd HH:mm").parse(dateAjoutValue);
              } else {
                throw Exception("Format de dateAjout inconnu");
              }

              final displayDate = DateFormat(
                'dd-MM-yy HH:mm',
              ).format(parsedDate);

              return Container(
                padding: const EdgeInsets.all(12),
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['productImageUrl'] ?? '',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            data['productname'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            displayDate,
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${data['quantity']} x ${data['productprice']} FCFA',
                            style:  GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
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
                            final snack =  ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Color(0xFF02204B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                duration: Duration(seconds: 3),
                                content: Text("Veuillez renseigné votre numero de telephone et votre adresse", style:  GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),)
                              ),
                            );
                            snack.closed.then((_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfile(),
                                ),
                              );
                            });
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
                              content: const Text("Supprimer cette commande ?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Non"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
            final Snack = ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF02204B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  duration: Duration(seconds: 2),
                  content: Text("Veuillez renseigné votre numero de telephone et votre adresse", style:  GoogleFonts.poppins(fontSize: 15, color: Colors.white),)
              ),
            );
            Snack.closed.then((_){
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfile()));
            });
            return; // Stoppe le paiement
          }
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('favoris')
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
