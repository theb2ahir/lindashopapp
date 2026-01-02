// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() => _imageFile = File(pickedFile.path));

    try {
      final imageUrl = await _uploadImageToCloudinary(_imageFile!);
      await _sendPhotoMessage(imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'envoi de l'image")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _uploadImageToCloudinary(File file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dccsqxaxu/upload');
    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['upload_preset'] = 'baahir';

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Échec de l\'upload de l\'image');
    }

    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);
    return data['secure_url'];
  }

  Future<void> _sendPhotoMessage(String imageurl) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('messages')
          .add({
            'type': 'image',
            "text": imageurl,
            "sender": userEmail ?? "Utilisateur",
            'isRead': false,
            "timestamp": FieldValue.serverTimestamp(),
          });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'envoie du message : $e")),
      );
    }
  }

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
            'type': 'text',
            "text": _messageCtrl.text.trim(),
            "sender": userEmail ?? "Utilisateur",
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
          });

      _messageCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  void _showEditMessageDialog(
    BuildContext context, {
    required String messageId,
    required String oldText,
  }) {
    final controller = TextEditingController(text: oldText);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Modifier le message"),
          content: TextField(
            controller: controller,
            maxLines: null,
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Enregistrer"),
              onPressed: () async {
                final newText = controller.text.trim();
                if (newText.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('messages')
                    .doc(messageId)
                    .update({"text": newText, "edited": true});

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showTextOptions(
    BuildContext context, {
    required String messageId,
    required String text,
    required bool isUser,
    required DateTime timestamp,
  }) {
    final canEdit = DateTime.now().difference(timestamp).inMinutes < 3;
    final candelete = DateTime.now().difference(timestamp).inMinutes < 5;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 📋 Copier
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Copier"),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Message copié")),
                  );
                },
              ),

              if (!candelete)
                ListTile(
                  title: const Text("Impossible de supprimer passer 5 minutes"),
                ),

              if (!canEdit)
                ListTile(
                  title: const Text("Impossible de modifier passer 3 minutes"),
                ),
              // ✏️ Modifier (seulement si c’est ton message)
              if (isUser && canEdit)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Modifier"),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditMessageDialog(
                      context,
                      messageId: messageId,
                      oldText: text,
                    );
                  },
                ),

              // 🗑️ Supprimer (seulement si c’est ton message)
              if (isUser && candelete)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Supprimer",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Confirmation"),
                          content: const Text(
                            "Voulez-vous vraiment supprimer ce message ?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Annuler"),
                            ),
                            TextButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .collection('messages')
                                    .doc(messageId)
                                    .delete();

                                Navigator.pop(context);
                              },
                              child: const Text("Oui, supprimer"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showImageOptions(
    BuildContext context, {
    required String imageUrl,
    required String messageId,
    required bool isUser,
    required DateTime timestamp,
  }) {
    final canDelete = DateTime.now().difference(timestamp).inMinutes < 5;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 📋 Copier le lien
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Copier l'image"),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: imageUrl));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Image copiée")));
                },
              ),

              if (!canDelete)
                ListTile(
                  title: const Text("Impossible de supprimer passer 5 minutes"),
                ),

              // 🗑️ Supprimer (seulement si c’est ton message)
              if (isUser && canDelete)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Supprimer",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Confirmation"),
                          content: const Text(
                            "Voulez-vous vraiment supprimer ce message ?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Annuler"),
                            ),
                            TextButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .collection('messages')
                                    .doc(messageId)
                                    .delete();

                                Navigator.pop(context);
                              },
                              child: const Text("Oui, supprimer"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
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
            final type = data['type'];
            final edited = data['edited'] ?? false;
            final isRead = data['isRead'] ?? false;

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
                      if (type == 'text')
                        GestureDetector(
                          onLongPress: () {
                            _showTextOptions(
                              context,
                              messageId: docs[index].id,
                              text: data['text'] ?? '',
                              isUser: isUser,
                              timestamp: timestamp,
                            );
                          },
                          child: Text(
                            "${data['text'] ?? ''}",
                            style: GoogleFonts.poppins(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                            // afficher un arrow down ios pour lui demander sil veut modifier son message , le supprimer ou le copier
                          ),
                        ),
                      if (type == 'image')
                        GestureDetector(
                          onLongPress: () {
                            _showImageOptions(
                              context,
                              imageUrl: data['text'],
                              messageId: docs[index].id,
                              isUser: isUser,
                              timestamp: timestamp,
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              data['text'],
                              width: 200,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, size: 40);
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (edited == true)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                "modifié",
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: isUser
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                          Text(
                            DateFormat("HH:mm").format(timestamp),
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (isRead == true)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_sharp,
                                  color: Colors.green,
                                  size: 12,
                                ),
                                Icon(
                                  Icons.check_sharp,
                                  color: Colors.green,
                                  size: 12,
                                ),
                              ],
                            ),

                          if (isRead == false)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_sharp,
                                  color: Colors.grey,
                                  size: 10,
                                ),
                                Icon(
                                  Icons.check_sharp,
                                  color: Colors.grey,
                                  size: 10,
                                ),
                              ],
                            ),
                        ],
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
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                Text(
                  "Support client",
                  style: GoogleFonts.poppins(fontSize: 13),
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
                    Text('Vider la conversation'),
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
                  icon: Icon(
                    Icons.send,
                    size: 30,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Color(0xFF02204B),
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.photo),
                        onPressed: _pickImage,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
