// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/auth/connectionpage.dart';
import 'package:lindashopp/features/pages/supportclient.dart';
import 'package:lindashopp/theme/themecontroller.dart';

class Parametre extends StatefulWidget {
  const Parametre({super.key});

  @override
  State<Parametre> createState() => _ParametreState();
}

class _ParametreState extends State<Parametre> {
  String selectedTheme = "";
  Map<String, dynamic>? user;

  TextEditingController regionCtrl = TextEditingController();
  TextEditingController villeCtrl = TextEditingController();
  TextEditingController quartierCtrl = TextEditingController();
  TextEditingController precisionCtrl = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final firestore = FirebaseFirestore.instance;

  Future<int> getUsersMessageSizedNotRead(String userId) async {
    final messages = await firestore
        .collection('users')
        .doc(userId)
        .collection('messages')
        .where('sender', isEqualTo: 'ADMIN')
        .where('isRead', isEqualTo: false)
        .get();
    return messages.docs.isNotEmpty ? messages.docs.length : 0;
  }

  Future<int> getUsersMessageSizedRead(String userId) async {
    final messages = await firestore
        .collection('users')
        .doc(userId)
        .collection('messages')
        .where('sender', isEqualTo: 'ADMIN')
        .where('isRead', isEqualTo: true)
        .get();
    return messages.docs.isNotEmpty ? messages.docs.length : 0;
  }

  Future<void> markAllMessagesAsRead(String userId) async {
    // Récupère tous les messages de l'utilisateur
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('sender', isEqualTo: 'ADMIN')
        .get();
    if (snapshot.docs.isEmpty) return;
    // Met à jour chaque message pour le marquer comme lu
    for (var doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    setState(() {
      user = doc.data();
    });
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void _showAdressDialog() {
    if (user == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Adresse de livraison"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                if (user!['adresse'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text("Adresse actuelle : ${user!['adresse']}"),
                  ),
                TextField(
                  controller: regionCtrl,
                  decoration: const InputDecoration(labelText: 'Région'),
                ),
                TextField(
                  controller: villeCtrl,
                  decoration: const InputDecoration(labelText: 'Ville'),
                ),
                TextField(
                  controller: quartierCtrl,
                  decoration: const InputDecoration(labelText: 'Quartier'),
                ),
                TextField(
                  controller: precisionCtrl,
                  decoration: const InputDecoration(labelText: 'Précision'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final newAdresse =
                        "${regionCtrl.text}, ${villeCtrl.text}, ${quartierCtrl.text}, ${precisionCtrl.text}";
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({'adresse': newAdresse});

                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Adresse mise à jour !')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erreur de mise à jour de l\'adresse : $e',
                          ),
                        ),
                      );
                    }
                    // Recharge les données
                    await loadUserData();
                  },
                  child: const Text("Modifier"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Paramètres",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text("Adresse de livraison"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showAdressDialog,
                ),

                // Langue
                ListTile(
                  leading: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: Text("Thème"),
                  subtitle: Text(
                    "choisir le thème",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showThemeDialog,
                ),

                // À propos
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text("À propos de l'application"),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "Linda-Shop",
                      applicationIcon: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          "assets/articlesImages/LindaLogo2.png",
                          width: 100,
                          height: 100,
                        ),
                      ),
                      applicationLegalese: "© 2025 Linda-Shop Inc.",
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          "Linda-Shop est une application de e-commerce moderne conçue pour offrir une expérience d’achat simple, rapide et sécurisée.\n\n"
                          "Fonctionnalités principales :\n"
                          "• Achat rapide et intuitif\n"
                          "• Suivi des commandes en temps réel\n"
                          "• Livraison gratuite ou payante selon les produits\n"
                          "• Nous vous livrons jusqu'à votre porte\n"
                          "• Paiements sécurisés\n"
                          "• Produits vérifiés et de qualité\n"
                          "• Promotions et recommandations personnalisées\n\n"
                          "Assistance :Nous avons un chat app directement sur l'application (support client), vous pouvez aussi nous contacter par appel directe ou whatsapp en allant sur Mon Compte \n"
                          "© 2025 Linda-Shop Inc.",
                        ),
                      ],
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.question_mark_sharp),
                  title: const Text("Support client Linda shop"),
                  onTap: () async {
                    await markAllMessagesAsRead(uid);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SupportClient()),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<int>(
                        future: getUsersMessageSizedNotRead(uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              "...",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              "Erreur",
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            );
                          }
                          return Text(
                            "${(snapshot.data ?? 0).toString()} non lus / ",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      FutureBuilder<int>(
                        future: getUsersMessageSizedRead(uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text(
                              "...",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              "Erreur",
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            );
                          }
                          return Text(
                            "${(snapshot.data ?? 0).toString()} lus",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),

                // Déconnexion
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Déconnexion",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirmation"),
                        content: const Text(
                          "Voulez-vous vraiment vous déconnecter ?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
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
                      FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Connection()),
                      );
                    }
                  },
                ),
              ],
            ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choisir le thème"),
          content: ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.themeModeNotifier,
            builder: (_, currentMode, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text("☀️ Mode clair"),
                    value: ThemeMode.light,
                    groupValue: currentMode,
                    onChanged: (value) {
                      ThemeController.saveTheme(value!);
                      setState(() {
                        selectedTheme = "Mode clair";
                      });
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text("🌙 Mode sombre"),
                    value: ThemeMode.dark,
                    groupValue: currentMode,
                    onChanged: (value) {
                      ThemeController.saveTheme(value!);
                      setState(() {
                        selectedTheme = "Mode sombre";
                      });
                      setState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text("⚙️ Mode système"),
                    value: ThemeMode.system,
                    groupValue: currentMode,
                    onChanged: (value) {
                      ThemeController.saveTheme(value!);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
