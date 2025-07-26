// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lindashopp/favoris.dart';
import 'package:lindashopp/inquietude.dart';
import 'package:lindashopp/nonlivre.dart';
import 'package:lindashopp/parametre.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    Future<Map<String, dynamic>> getUserData() async {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.data()!;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Linda Shop",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            FutureBuilder<Map<String, dynamic>>(
              future: getUserData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                final user = snapshot.data!;
                return Column(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        ClipRRect(
                          child: Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              color: Color(0xFF02204B),
                              borderRadius: BorderRadius.circular(200),
                            ),
                            child: Center(
                              child: Text(
                                user['name'].substring(0, 2).toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 90,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person),
                            Text(
                              "  ${user['name'] ?? 'Non renseigné'}",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email),
                            Text(
                              "  ${user['email'] ?? 'Non renseigné'}",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone),
                            Text(
                              "  ${user['phone'] ?? 'Non renseigné'}",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 90),
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: const Text('Mes favoris'),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Favoris()),
                      );
                    },
                    icon: const Icon(Icons.arrow_right),
                  ),
                ),

                ListTile(
                  leading: const Icon(
                    Icons.cancel_schedule_send,
                    color: Color.fromARGB(255, 41, 8, 8),
                  ),
                  title: const Text('Non livré ?'),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NonLivre(),
                        ),
                      );
                    },
                    icon: Icon(Icons.arrow_right),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.handshake, color: Colors.black),
                  title: const Text('Partenariat'),
                  trailing: IconButton(
                    onPressed: () async {
                      const whatsappNumber =
                          '+22892349698'; // Remplace par ton numéro
                      final message = Uri.encodeComponent(
                        "Bonjour, je souhaite discuter d’un partenariat.",
                      );
                      final whatsappUrl =
                          'https://wa.me/$whatsappNumber?text=$message';

                      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                        await launchUrl(
                          Uri.parse(whatsappUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossible d’ouvrir WhatsApp'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_right),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.black),
                  title: const Text('Appeler'),
                  trailing: IconButton(
                    onPressed: () async {
                      const phoneNumber = 'tel:+22892349698';
                      if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                        await launchUrl(Uri.parse(phoneNumber));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossible de passer l’appel'),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.arrow_right),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.question_answer,
                    color: Color.fromARGB(255, 8, 192, 63),
                  ),
                  title: const Text('Des inquiétudes ?'),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Inquietude(),
                        ),
                      );
                    },
                    icon: Icon(Icons.arrow_right),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.black),
                  title: const Text('Paramètres'),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Parametre(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_right),
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
