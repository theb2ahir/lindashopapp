// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/core/widgets/customtextfields.dart';

class NonLivre extends StatefulWidget {
  const NonLivre({super.key});

  @override
  State<NonLivre> createState() => _NonLivreState();
}

class _NonLivreState extends State<NonLivre> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController refController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

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
          phoneController.text = data['phone'] ?? '';
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

  /// 🔹 Envoie la requête à Firestore
  Future<void> submitToFirestore() async {
    try {
      setState(() => isLoading = true);

      await _firestore.collection('NonLivree').add({
        'NlivreName': nameController.text.trim(),
        'NlivrePrenom': nameController.text.trim(),
        'NlivreEmail': emailController.text.trim(),
        'NlivrePhone': phoneController.text.trim(),
        'NlivreRef': refController.text.trim(),
        'userId': _auth.currentUser?.uid,
        'NlivreTransactionId': transactionIdController.text.trim(),
        'NlivreMessage': messageController.text.trim(),
        'NlivreStamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF02204B),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.lightGreenAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Requête envoyée avec succès !',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );

      // Réinitialisation du formulaire
      _formKey.currentState?.reset();
      nameController.clear();
      phoneController.clear();
      refController.clear();
      transactionIdController.clear();
      emailController.clear();
      messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent.shade400,
          content: Text('Erreur : $e',
              style: const TextStyle(color: Colors.white)),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Commande non livrée",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFFE8F0FE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "📝 Les informations demandées figurent sur votre reçu de paiement.\n"
                      "Veuillez remplir le formulaire avec soin pour faciliter le traitement.",
                  style: TextStyle(fontSize: 15.5, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Form(
              key: _formKey,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  children: [
                    CustomTextField(controller: nameController, label: "Nom"),
                    const SizedBox(height: 15),
                    CustomTextField(
                        controller: phoneController, label: "Téléphone"),
                    const SizedBox(height: 15),
                    CustomTextField(controller: emailController, label: "Email"),
                    const SizedBox(height: 15),
                    CustomTextField(
                        controller: refController, label: "Référence"),
                    const SizedBox(height: 15),
                    CustomTextField(
                        controller: transactionIdController,
                        label: "Transaction ID"),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: messageController,
                      label:
                      "Décrivez votre commande (ex: support PC, 1 pièce)",
                      maxLines: 4,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            submitToFirestore();
                          }
                        },
                        icon: isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.send),
                        label: Text(
                          isLoading ? "Envoi en cours..." : "Envoyer",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF02204B),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
