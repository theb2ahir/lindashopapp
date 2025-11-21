// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/core/widgets/customtextfields.dart';

class Inquietude extends StatefulWidget {
  const Inquietude({super.key});
  @override
  State<Inquietude> createState() => _InquietudeState();
}

class _InquietudeState extends State<Inquietude> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
  }

  /// 🔹 Préremplit les champs avec les infos de l'utilisateur connecté
  Future<void> _prefillUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc =
      await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? user.email ?? '';
        });
      } else {
        // Si pas de document, on met au moins l'email du compte Firebase
        emailController.text = user.email ?? '';
      }
    } catch (e) {
      debugPrint('Erreur lors du préremplissage : $e');
    }
  }


  Future<void> submitToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('inquietudes').add({
        'inquietudeName': nameController.text,
        'inquietudeEmail': emailController.text,
        'inquietudeMessage': messageController.text,
        'inquietudeStamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("inquiétude envoyées avec succès !")),
      );
      nameController.clear();
      emailController.clear();
      messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 5),
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.redAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'erreur : $e',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white, // couleur de l’icône retour
        ),
        centerTitle: true,
        title: const Text(
          "Formulaire - Inquiétudes",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomTextField(controller: nameController, label: "Nom"),
                const SizedBox(height: 15),
                CustomTextField(controller: emailController, label: "Email"),
                const SizedBox(height: 15),
                CustomTextField(
                  controller: messageController,
                  label: "Message",
                  maxLines: 4,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      submitToFirestore();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          duration: Duration(seconds: 5),
                          content: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.lightGreenAccent,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Message envoyé!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Envoyer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
