// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  // 🔥 Fonction pour supprimer toutes les notifications si leur nombre >= 30
  Future<void> deleteAllNotificationsIf30Reached(
    List<QueryDocumentSnapshot> docs,
  ) async {
    if (docs.length >= 30) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications');

      for (final doc in docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "30 notifications détectées. Toutes ont été supprimées automatiquement.",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: uid == null
          ? const Center(child: Text("Utilisateur non connecté"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('notifications')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Erreur de chargement"));
                }

                final notifications = snapshot.data?.docs ?? [];

                // 🧠 Appel automatique de la suppression si le seuil est atteint
                if (notifications.length >= 30) {
                  deleteAllNotificationsIf30Reached(notifications);
                }

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text("Aucune notification pour le moment."),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final data =
                        notifications[index].data() as Map<String, dynamic>;
                    final imageUrl = data['imageUrl'] ?? '';
                    final notifText = data['notifText'] ?? '';
                    final timestamp = data['date'] as Timestamp?;
                    final parsedDate = timestamp?.toDate();
                    final displayDate = parsedDate != null
                        ? DateFormat('dd MMM yyyy – HH:mm').format(parsedDate)
                        : 'Date inconnue';

                    return ListTile(
                      leading: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl,
                                width:70,
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
                      title: Text(
                        notifText,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(displayDate),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirmation"),
              content: const Text(
                "Voulez-vous vraiment supprimer toutes les notifications ?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Non"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Oui"),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              final notifsRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('notifications');

              final snapshot = await notifsRef.get();
              for (final doc in snapshot.docs) {
                await doc.reference.delete();
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Toutes les notifications ont été supprimées."),
                ),
              );
            }
          }
        },
        child: const Icon(Icons.delete),
      ),
    );
  }
}
