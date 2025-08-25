// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/auth/connection/connectionpage.dart';

class Parametre extends StatefulWidget {
  const Parametre({super.key});

  @override
  State<Parametre> createState() => _ParametreState();
}

class _ParametreState extends State<Parametre> {
  String selectedLanguage = "Français";
  Map<String, dynamic>? user;

  TextEditingController regionCtrl = TextEditingController();
  TextEditingController villeCtrl = TextEditingController();
  TextEditingController quartierCtrl = TextEditingController();
  TextEditingController precisionCtrl = TextEditingController();

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
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.black,
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
                  leading: const Icon(Icons.language),
                  title: const Text("Langue"),
                  subtitle: Text(selectedLanguage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showLanguageDialog,
                ),

                // À propos
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text("À propos de l'application"),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "Linda-Shop",
                      applicationLegalese: "© 2025 Linda-Shop Inc.",
                    );
                  },
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Choisir une langue"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text("Français"),
                value: "Français",
                groupValue: selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile(
                title: const Text("Anglais"),
                value: "Anglais",
                groupValue: selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
