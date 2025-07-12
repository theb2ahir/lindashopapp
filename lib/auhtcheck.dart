import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lindashopp/acceuilpage.dart';
import 'package:lindashopp/connectionpage.dart';


class Auhtcheck extends StatelessWidget {
  const Auhtcheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          return AcceuilPage();
        } else {
          return Connection();
        }
      },
    );
  }
}