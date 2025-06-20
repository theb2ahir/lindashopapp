// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/connectionpage.dart';
import 'package:lindashopp/homepage.dart';

class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  bool _obscurePassword = true;
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phonectrl = TextEditingController();

  void signup() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      if (nameCtrl.text.isEmpty ||
          emailCtrl.text.isEmpty ||
          passwordCtrl.text.isEmpty ||
          phonectrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF02204B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            duration: Duration(seconds: 5),
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Veuillez remplir tous les champs',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }

      if (!emailCtrl.text.contains('@gmail.com')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF02204B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            duration: Duration(seconds: 5),
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Veuillez utiliser un email valide',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );

        emailCtrl.text = "";
        return;
      }

      if (passwordCtrl.text.length <= 5 || passwordCtrl.text.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF02204B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            duration: Duration(seconds: 5),
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Veuillez utiliser un mot de passe contenant entre 6 et 10 caractères',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );

        passwordCtrl.text = "";
        return;
      }

      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: emailCtrl.text,
        password: passwordCtrl.text,
      );

      await firestore.collection('users').doc(result.user!.uid).set({
        'name': nameCtrl.text,
        'email': emailCtrl.text,
        'phone': phonectrl.text,
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF02204B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.lightGreenAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Inscription réussie',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(Duration(seconds: 3), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyHomePage()),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF02204B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 5),
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Erreur dans le processus d'inscription $e",
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF02204B),
        centerTitle: true,
        title: Text(
          "Inscription",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        "assets/articlesImages/LindaLogo2.png",
                        height: 300,
                      ),
                    ),
                    const SizedBox(height: 20),
        
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(labelText: 'Nom'),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: phonectrl,
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone',
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      obscureText: _obscurePassword,
                      controller: passwordCtrl,
                      decoration: InputDecoration(
                        labelText:
                            'Mot de passe contenant au moins 6 et au plus 10 caractères',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 45),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                            Colors.green,
                          ),
                        ),
                        onPressed: signup,
                        child: Text(
                          "S'inscrire",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "mot de passe oublier ?",
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Déjà inscrit ?",
                          style: const TextStyle(fontSize: 17),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Connection(),
                              ),
                            );
                          },
                          child: Text(
                            "connectez-vous",
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
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
