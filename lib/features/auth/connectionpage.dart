// ignore_for_file: avoid_print, use_build_context_synchronously
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/auth/InscriptionPage.dart';
import 'package:lindashopp/features/pages/acceuilpage.dart';

class Connection extends StatefulWidget {
  const Connection({super.key});

  @override
  State<Connection> createState() => _ConnectionState();
}

class _ConnectionState extends State<Connection> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  void login(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      if (!mounted) return; // ✅ Sécurise l'appel
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF02204B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 3),
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
      if (!mounted) return; // ✅ Sécurise l'appel
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF02204B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Veuillez utiliser un emailvalide',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );

      emailCtrl.text = "";
      passwordCtrl.text = "";
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text,
        password: passwordCtrl.text,
      );
      if (!mounted) return; // ✅ Sécurise l'appel
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF02204B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 2),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.lightGreenAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connexion réussie',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AcceuilPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF02204B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 2),
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erreur de connexion veuillez bien verifier votre adresse email et votre mot de passe et ressayer',
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
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Connexion",
          style: GoogleFonts.roboto(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          TextField(
                            style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            cursorColor: const Color.fromARGB(255, 0, 0, 0),
                            controller: emailCtrl,
                            decoration: InputDecoration(
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 2,
                                ),
                              ),
                              labelText: 'Email',
                            ),
                          ),

                          const SizedBox(height: 25),
                          TextField(
                            style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                            cursorColor: const Color.fromARGB(255, 0, 0, 0),
                            controller: passwordCtrl,
                            decoration: InputDecoration(
                              labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 2,
                                ),
                              ),

                              labelText: 'Mot de passe',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            obscureText: _obscurePassword,
                          ),
                          const SizedBox(height: 45),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                  const Color.fromARGB(255, 255, 82, 82),
                                ),
                              ),
                              onPressed: () => login(context),
                              child: Text(
                                "Se connecter",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  final email = emailCtrl.text.trim();
                                  if (email.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Veuillez entrer votre adresse email.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  FirebaseAuth.instance
                                      .sendPasswordResetEmail(email: email)
                                      .then((_) {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Email envoyé'),
                                            content: const Text(
                                              'Un lien de réinitialisation a été envoyé à votre adresse email si vous ne le voyez pas , verifiez vos spams.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                        );
                                      })
                                      .catchError((e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Erreur : ${e.message ?? e.toString()}',
                                            ),
                                          ),
                                        );
                                      });
                                },
                                child: const Text(
                                  "Mot de passe oublié ?",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Nouveau sur Linda Shop ?",
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const Inscription(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Inscrivez-vous",
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
