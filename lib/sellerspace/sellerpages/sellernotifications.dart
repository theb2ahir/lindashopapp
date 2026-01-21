// afficher les notifications de l'utilisateur a travers la sous collection "notifications"  contenu dans collection users , les affciher dans des lisTtile avec leading icon logo lindashop , les notif on pour champs , contenu et date

// ignore_for_file: unrelated_type_equality_checks, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SellerNotifications extends StatefulWidget {
  const SellerNotifications({super.key});

  @override
  State<SellerNotifications> createState() => _SellerNotificationsState();
}

class _SellerNotificationsState extends State<SellerNotifications> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
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
                "Aucune notification pour le moment.",
                style: GoogleFonts.poppins(fontSize: 15),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = data['date'] as Timestamp?;
              final parsedDate = date?.toDate();
              final displayDate = parsedDate != null
                  ? DateFormat('dd MMM yyyy – HH:mm').format(parsedDate)
                  : 'Date inconnue';

              return ListTile(
                leading: Icon(Icons.notifications, color: Colors.red),
                title: Text(
                  data['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['content'],
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    Text(
                      displayDate,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  onPressed: () async {
                    final confrim = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Supprimer"),
                        content: Text(
                          "Voulez-vous vraiment supprimer cette notification ?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Annuler"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Supprimer"),
                          ),
                        ],
                      ),
                    );
                    if (confrim == true) {
                      try {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('notifications')
                            .doc(doc.id)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Notification supprimée"),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur de suppression : $e")),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.delete, color: Colors.red),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
