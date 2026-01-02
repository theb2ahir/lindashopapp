import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CheckProductPage extends StatefulWidget {
  const CheckProductPage({super.key});

  @override
  State<CheckProductPage> createState() => _CheckProductPageState();
}

class _CheckProductPageState extends State<CheckProductPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Vérification",
          style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reviewproduct")
            .where("sellerid", isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement',
                style: GoogleFonts.poppins(fontSize: 15, color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Aucun produit à vérifier",
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            );
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;
              final reviewid = reviews[index].id;
              final imageurl = data['imageURL'] ?? '';
              final name = data['name'] ?? '';
              final statut = data['statut'] ?? '';
              final timestamp = data['timestamp'] as Timestamp?;
              final parsedDate = timestamp?.toDate();
              final displayDate = parsedDate != null
                  ? DateFormat('dd MMM yyyy – HH:mm').format(parsedDate)
                  : 'Date inconnue';

              return ListTile(
                leading: imageurl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageurl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          color: Colors.grey,
                          child: const Icon(Icons.notifications),
                        ),
                      ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _statusBadge(statut, context),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: const Text("Suppression"),
                              content: const Text(
                                "Confirmez-vous cette suppression ?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Annuler"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    try {
                                      FirebaseFirestore.instance
                                          .collection("reviewproduct")
                                          .doc(reviewid)
                                          .delete();

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Produit supprimé avec succès ✅",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Erreur lors de la suppression : $e",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text("Supprimer"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
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
    case 'valide':
      color = Colors.green;
      break;
    case 'en attente':
      color = Colors.orange;
      break;
    case 'rejeter':
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
