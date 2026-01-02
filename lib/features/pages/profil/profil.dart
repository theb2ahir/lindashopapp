// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/auth/connectionpage.dart';
import 'package:lindashopp/features/pages/favoris.dart';
import 'package:lindashopp/features/pages/inquietude.dart';
import 'package:lindashopp/features/pages/nonlivre.dart';
import 'package:lindashopp/features/pages/parametre.dart';
import 'package:lindashopp/sellerspace/selleracceuil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'editprofile.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController usernameCtrl = TextEditingController();
  TextEditingController useremailCtrl = TextEditingController();
  TextEditingController phoneCtrl = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  String role = "";

  Future<Map<String, dynamic>> getUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()!;
  }

  Future<void> loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      setState(() {
        role = doc.data()!['role'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Mon Profil",
          style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.bold),
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
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
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
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(name, style: GoogleFonts.poppins(fontSize: 23)),
                      const SizedBox(height: 11),
                      Text(email, style: GoogleFonts.poppins(fontSize: 16)),
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
                          style: GoogleFonts.poppins(fontSize: 16),
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
                  if (role == "seller")
                    ListTile(
                      leading: Icon(
                        Icons.storefront_outlined,
                        color: Colors.blue,
                      ),
                      title: Text(
                        "Ma boutique",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      onTap: () async {
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
                          final snack = ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Color(0xFF02204B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              duration: Duration(seconds: 2),
                              content: Text(
                                "Veuillez renseigné votre numero de telephone et votre adresse",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                          snack.closed.then((_) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProfile()),
                            );
                          });
                          return; // Stoppe le paiement
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SellerAcceuil()),
                          );
                        }
                      },
                      trailing: const Icon(Icons.arrow_right),
                    ),
                  ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: Text(
                      'Mes favoris',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.arrow_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Favoris()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cancel_schedule_send),
                    title: Text(
                      'Non livré ?',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.arrow_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NonLivre()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.handshake),
                    title: Text(
                      'Partenariat',
                      style: GoogleFonts.poppins(fontSize: 16),
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
                    leading: const Icon(Icons.phone),
                    title: Text(
                      'Appeler',
                      style: GoogleFonts.poppins(fontSize: 16),
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
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.arrow_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Inquietude()),
                    ),
                  ),

                  GestureDetector(
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
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        "Déconnexion",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_right),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
