// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/customtextfields.dart';

class Inquietude extends StatefulWidget {
  const Inquietude({super.key});
  @override
  State<Inquietude> createState() => _InquietudeState();
}

class _InquietudeState extends State<Inquietude> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController refController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // couleur de l’icône retour
        ),
        title: const Text("Formulaire - Inquiétudes", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF02204B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            key: _formKey,
            child: Column(
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
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade400,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    "Envoyer",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
