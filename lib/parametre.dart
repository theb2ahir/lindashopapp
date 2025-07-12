import 'package:flutter/material.dart';

class Parametre extends StatefulWidget {
  const Parametre({super.key});

  @override
  State<Parametre> createState() => _ParametreState();
}

class _ParametreState extends State<Parametre> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("parametre"),
      ),

      body: Center(
        child: Column(
          children: [
            Text("hey its the parametre area"),
            Text("hey"),
          ],
        ),
      ),
    );
  }
}