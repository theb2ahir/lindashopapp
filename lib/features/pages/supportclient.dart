// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SupportClient extends StatefulWidget {
  const SupportClient({super.key});

  @override
  State<SupportClient> createState() => _SupportClientState();
}

class _SupportClientState extends State<SupportClient> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final userEmail = FirebaseAuth.instance.currentUser?.email;
  final username = FirebaseAuth.instance.currentUser?.displayName;
  final TextEditingController _messageCtrl = TextEditingController();

  // --- ENVOI DU MESSAGE ---
  Future<void> _sendMessage() async {
    if (_messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF02204B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 3),
          content: const Text(
            "Saisissez un message",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('messages')
          .add({
            "text": _messageCtrl.text.trim(),
            "sender": userEmail ?? "Utilisateur",
            "timestamp": FieldValue.serverTimestamp(),
          });

      _messageCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  // --- AFFICHAGE DU CHAT ---
  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Erreur de chargement"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          reverse: false,
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isUser = data['sender'] == userEmail;
            final timestamp = data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now();

            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF02204B) : Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isUser ? 12 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['text'] ?? '',
                        style: GoogleFonts.poppins(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat("HH:mm").format(timestamp),
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> supprimerMessagesUtilisateur() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final email = user.email;

      // Récupérer les messages de l'utilisateur
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('messages')
          .where('sender', isEqualTo: email)
          .get();

      // Supprimer chaque message trouvé
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF02204B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 2),
          content: const Text(
            "Messages supprimés !",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 2, 7, 55),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  (FirebaseAuth.instance.currentUser?.displayName != null &&
                          FirebaseAuth
                              .instance
                              .currentUser!
                              .displayName!
                              .isNotEmpty)
                      ? FirebaseAuth.instance.currentUser!.displayName![0]
                            .toUpperCase()
                      : (FirebaseAuth.instance.currentUser?.email != null &&
                            FirebaseAuth
                                .instance
                                .currentUser!
                                .email!
                                .isNotEmpty)
                      ? FirebaseAuth.instance.currentUser!.email![0]
                            .toUpperCase()
                      : "U", // valeur par défaut si pas de nom ni email
                  style: GoogleFonts.poppins(
                    fontSize: 25,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userEmail ?? "Utilisateur",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
                ),
                Text(
                  "Support client",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'supprimer':
                  final confirmer = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirmation"),
                      content: const Text(
                        "Voulez-vous vraiment supprimer vos messages ?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Oui, supprimer"),
                        ),
                      ],
                    ),
                  );

                  if (confirmer == true) {
                    await supprimerMessagesUtilisateur();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Messages supprimés avec succès"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  break;

                case 'rafraichir':
                  setState(() {}); // Recharge le StreamBuilder
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'supprimer',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer mes messages'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rafraichir',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Rafraîchir la conversation'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[200],
              ),
              child: _buildMessageList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 10, right: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: InputDecoration(
                      hintText: "Message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    Icons.send,
                    size: 30,
                    color: Color(0xFF02204B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
