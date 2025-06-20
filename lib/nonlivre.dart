// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/customtextfields.dart';

class NonLivre extends StatefulWidget {
  const NonLivre({super.key});
  @override
  State<NonLivre> createState() => _NonLivreState();
}

class _NonLivreState extends State<NonLivre> {
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
      await FirebaseFirestore.instance.collection('NonLivree').add({
        'NlivreName': nameController.text,
        'NlivrePrenom': prenomController.text,
        'NlivreEmail': emailController.text,
        'NlivrePhone': phoneController.text,
        'NlivreRef': refController.text,
        'NlivreTransactionId': transactionIdController.text,
        'NlivreMessage': messageController.text,
        'NlivreStamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor:  Color(0xFF02204B),
          content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.lightGreenAccent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'requête de commande non livré envoyées avec succès !',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
        ),
      );
      nameController.clear();
      prenomController.clear();
      phoneController.clear();
      refController.clear();
      transactionIdController.clear();
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
                  'Erreur : $e',
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
        iconTheme: const IconThemeData(
          color: Colors.white, // couleur de l’icône retour
        ),
        title: const Text(
          "Formulaire - non livré",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF02204B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              const Text(
                "Les informations que vous avez a fournir sont presentes sur votre reçu de paiement , veuillez ne pas faire de fautes dans la saisie pour nous faciliter la tache , merci Linda Shop",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(controller: nameController, label: "Nom"),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: prenomController,
                      label: "Prénom",
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: phoneController,
                      label: "Téléphone",
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: refController,
                      label: "Référence",
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: transactionIdController,
                      label: "Transaction ID",
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: emailController,
                      label: "Email",
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: messageController,
                      label:
                          "Décriver votre commande (ex: support pc , 1piece)",
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
                        backgroundColor: Colors.greenAccent.shade400,
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
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
