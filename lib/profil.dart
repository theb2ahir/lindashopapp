// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lindashopp/achatrecent.dart';
import 'package:lindashopp/connectionpage.dart';
import 'package:lindashopp/favoris.dart';
import 'package:lindashopp/panier.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 1, 15, 41),
        title: Text(
          "Linda Shop",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Connection()),
              );
            },
          ),
        ],
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
                        ClipRRect(
                          child: Image.asset(
                            "assets/articlesImages/LindaLogo2.png",
                            height: 250,
                          ),
                        ),
                        Text(
                          user['name'] ?? 'Non renseigné',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${user['email']}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
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
                  leading: const Icon(Icons.list_alt, color: Colors.blueAccent),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AchatRecent(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_right),
                  ),
                  title: const Text('Mes recentes achats'),
                ),

                ListTile(
                  leading: const Icon(Icons.shopping_cart, color: Color.fromARGB(255, 2, 16, 42)),
                  title: const Text('Mon panier'),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PanierPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_right),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.shape_line, color: Colors.black),
                  title: const Text("Articles qui pourraient m'intéresser"),
                  trailing: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PanierPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_right),
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
                          builder: (context) => const PanierPage(),
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
