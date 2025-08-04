// ignore_for_file: avoid_print, use_build_context_synchronously, file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/home/acceuil/acceuilpage.dart';
import 'package:lindashopp/features/auth/connection/connectionpage.dart';

class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  int _stepIndex = 0;
  bool _obscurePassword = true;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phonectrl = TextEditingController();
  final regionCtrl = TextEditingController();
  final villeCtrl = TextEditingController();
  final quartierCtrl = TextEditingController();
  final precisionCtrl = TextEditingController();

  void signup() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: emailCtrl.text,
        password: passwordCtrl.text,
      );

      await firestore.collection('users').doc(result.user!.uid).set({
        'name': nameCtrl.text,
        'email': emailCtrl.text,
        'phone': phonectrl.text,
        'adresse':
            '${regionCtrl.text}, ${villeCtrl.text}, ${quartierCtrl.text}, ${precisionCtrl.text}',
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF02204B),
          content: Row(
            children: const [
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
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AcceuilPage()),
        );
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF02204B),
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Erreur losrs de linscription : $e",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  bool _allFieldsFilled(List<TextEditingController> controllers) {
    return controllers.every((ctrl) => ctrl.text.isNotEmpty);
  }

  InputDecoration _customDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF02204B)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF02204B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF02204B),
        title: const Text("Inscription", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                "assets/articlesImages/LindaLogo2.png",
                height: 220,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Theme(
              data: ThemeData(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF02204B),
                  onPrimary: Colors.white,
                ),
              ),
              child: Stepper(
                type: StepperType.horizontal,
                elevation: 2,
                margin: const EdgeInsets.all(16),
                currentStep: _stepIndex,
                onStepContinue: () {
                  if (_stepIndex < 2) {
                    setState(() => _stepIndex++);
                  } else {
                    if (_allFieldsFilled([
                      nameCtrl,
                      emailCtrl,
                      passwordCtrl,
                      phonectrl,
                      regionCtrl,
                      villeCtrl,
                      quartierCtrl,
                      precisionCtrl,
                    ])) {
                      signup();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF02204B),
                          content: Row(
                            children: const [
                              Icon(Icons.error, color: Colors.red),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Veuillez remplir tous les champs',
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
                  }
                },
                onStepCancel: () {
                  if (_stepIndex > 0) {
                    setState(() => _stepIndex--);
                  }
                },
                steps: [
                  Step(
                    title: const Text("Infos"),
                    isActive: _stepIndex >= 0,
                    content: Column(
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: _customDecoration('Nom'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailCtrl,
                          decoration: _customDecoration('Email'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          obscureText: _obscurePassword,
                          controller: passwordCtrl,
                          decoration:
                              _customDecoration(
                                'Mot de passe (max 9 caractères)',
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF02204B),
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text("Contact"),
                    isActive: _stepIndex >= 1,
                    content: TextField(
                      controller: phonectrl,
                      decoration: _customDecoration('Numéro de téléphone'),
                    ),
                  ),
                  Step(
                    title: const Text("Adresse"),
                    isActive: _stepIndex >= 2,
                    content: Column(
                      children: [
                        TextField(
                          controller: regionCtrl,
                          decoration: _customDecoration('Région'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: villeCtrl,
                          decoration: _customDecoration('Ville'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: quartierCtrl,
                          decoration: _customDecoration('Quartier'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: precisionCtrl,
                          decoration: _customDecoration(
                            'Indice pour vous retrouver',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),


          Padding(
            padding: const EdgeInsets.all(19.0),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("vous avez deja un compte ?"),
                  TextButton(onPressed: () {
                    Navigator.push(context, 
                    MaterialPageRoute(builder: (_) => Connection())
                  );
                  }, child: Text("connectez-vous"))
                ],
              ),
            ),
          )
        
        ],
      ),
    );
  }
}
