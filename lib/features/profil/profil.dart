// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/auth/connection/connectionpage.dart';
import 'package:lindashopp/features/profil/editprofil/editprofile.dart';
import 'package:lindashopp/features/favoris/favoris.dart';
import 'package:lindashopp/features/inquietudes/inquietude.dart';
import 'package:lindashopp/features/nonlivre/nonlivre.dart';
import 'package:lindashopp/parametre.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController usernameCtrl = TextEditingController();
  TextEditingController useremailCtrl = TextEditingController();
  TextEditingController phoneCtrl = TextEditingController();

  Future<Map<String, dynamic>> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Mon Profil",
          style: GoogleFonts.poppins(
            fontSize: 19,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Parametre()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            const SizedBox(height: 3),
            FutureBuilder<Map<String, dynamic>>(
              future: getUserData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                final userData = snapshot.data!;
                final name = userData['name'] ?? 'Utilisateur';
                final email = userData['email'] ?? 'Utilisateur';

                return Column(
                  children: [
                    const SizedBox(height: 24),
                    ClipRRect(
                      child: Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF02204B),
                          borderRadius: BorderRadius.circular(200),
                        ),
                        child: Center(
                          child: Text(
                            name.substring(0, 2).toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 69,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 23,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Text(
                      email,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 19),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfile(),
                          ),
                        );
                      },
                      child: Text(
                        "Editer le profil",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            /// Liste des options
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: Text(
                    'Mes favoris',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Favoris()),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.cancel_schedule_send,
                    color: Colors.black,
                  ),
                  title: Text(
                    'Non livré ?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NonLivre()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.handshake, color: Colors.black),
                  title: Text(
                    'Partenariat',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () async {
                    const whatsappNumber = '+22892349698';
                    final message = Uri.encodeComponent(
                      "Bonjour, je souhaite discuter d’un partenariat.",
                    );
                    final url = 'https://wa.me/$whatsappNumber?text=$message';

                    try {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Impossible d’ouvrir WhatsApp. Vérifie qu’il est installé.',
                          ),
                        ),
                      );
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.black),
                  title: Text(
                    'Appeler',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () async {
                    const phoneNumber = '+22892349698';
                    final Uri telUri = Uri.parse('tel:$phoneNumber');

                    try {
                      await launchUrl(
                        telUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Impossible de passer l’appel. Vérifie les permissions.',
                          ),
                        ),
                      );
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.question_answer,
                    color: Colors.green,
                  ),
                  title: Text(
                    'Des inquiétudes ?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Inquietude()),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    "Déconnexion",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                  ),
                  trailing: IconButton(
                    onPressed: () async {
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
                    icon: Icon(Icons.arrow_right),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
