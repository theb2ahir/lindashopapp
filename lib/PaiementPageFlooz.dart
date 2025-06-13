import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';  


// ignore_for_file: file_names, unrelated_type_equality_checks, use_build_context_synchronously


class PaiementPage2 extends StatefulWidget {
  final dynamic item;
  const PaiementPage2({super.key, required this.item});

  @override
  State<PaiementPage2> createState() => _PaiementPage2State();
}

class _PaiementPage2State extends State<PaiementPage2> {
  int currentStep = 0;
  late String transactionId;
  final TextEditingController referenceController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    transactionId = generateTransactionId();
  }

  @override
  void dispose() {
    referenceController.dispose();
    super.dispose();
  }

  Future<void> generateRecuPDF({
    required String productName,
    required int montant,
    required String reference,
    required String transactionId,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("REÇU DE PAIEMENT",
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Produit : $productName"),
            pw.Text("Montant : $montant FCFA"),
            pw.Text("Référence : $reference"),
            pw.Text("Transaction ID : $transactionId"),
            pw.Text("Date : ${DateTime.now()}"),
          ],
        ),
      ),
    );

    final output = await getExternalStorageDirectory();
    final file = File('${output!.path}/recu_$transactionId.pdf');

    await file.writeAsBytes(await pdf.save());

    // Optionnel : message console
  }

  String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = 1000 + (DateTime.now().microsecond % 9000);
    return 'TXN-$timestamp-$random';
  }

  Future<bool> hasInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void lancerUSSD(String codeUSSD) async {
    final String encoded = Uri.encodeComponent(codeUSSD);
    final Uri ussdUri = Uri(scheme: 'tel', path: encoded);

    if (await canLaunchUrl(ussdUri)) {
      await launchUrl(ussdUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d’ouvrir le code USSD.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final int prixUnitaire = int.tryParse(item.productPrice.toString()) ?? 0;
    final total = prixUnitaire * item.quantity;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF02204B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Paiement via Flooz', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stepper(
        currentStep: currentStep,
        onStepContinue: () async {
          if (currentStep == 2) {
            final reference = referenceController.text.trim();
            if (reference.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      "Veuillez renseigner la référence de paiement."),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
              return;
            }

            if (!await hasInternetConnection()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pas de connexion Internet.")),
              );
              return;
            }

            setState(() => isLoading = true);

            try {
              await FirebaseFirestore.instance.collection('infouser').add({
                'transactionId': transactionId,
                'longi': item.longitude,
                'lati': item.latitude,
                'prixTotal': total,
                'UserReseau': 'Flooz',
                'nomberitem': item.quantity,
                'productname': item.productName,
                'productprice': item.productPrice,
                'livraison': item.livraison,
                'timestamp': DateTime.now(),
                'usernamemiff': item.username,
                'username': item.prenom,
                'userephone': item.phone,
                'useremail': item.email,
                'ref': reference,
              });

              setState(() => isLoading = false);

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Confirmation"),
                  content: const Text("Commande enregistrée avec succès !"),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // Fermer la boîte de dialogue

                        await generateRecuPDF(
                          productName: item.productName,
                          montant: total.toInt(),
                          reference: reference,
                          transactionId: transactionId,
                        );

                        Navigator.pop(context); // Revenir à la page précédente

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Reçu PDF téléchargé.")),
                        );
                      },
                      child: const Text("OK"),
                    )
                  ],
                ),
              );

            } catch (e) {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur : $e')),
              );
            }
          } else {
            setState(() => currentStep += 1);
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() => currentStep -= 1);
          }
        },
        steps: [
          Step(
            title: const Text('Informations'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom du produit : ${item.productName}'),
                Text('Prix unitaire : $prixUnitaire FCFA'),
                Text('Quantité : ${item.quantity}'),
                Text('Total : $total FCFA'),
                const SizedBox(height: 8),
                Text('Transaction ID : $transactionId'),
              ],
            ),
            isActive: currentStep >= 0,
          ),
          Step(
            title: const Text('Paiement'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Effectuez le paiement en cliquant sur le bouton ci-dessous :'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    lancerUSSD(
                        "*155*1*1*96368151*96368151*$total*1#"); // USSD personnalisé
                  },
                  child: const Text("Lancer le code USSD"),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Après le paiement, collez la référence reçue par SMS dans le champ ci-dessous, puis cliquez sur Continuer.",
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: referenceController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Coller la référence ici',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            isActive: currentStep >= 1,
          ),
          Step(
            title: const Text('Reçu'),
            content: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Transaction : $transactionId'),
                      Text('Montant Total : $total FCFA'),
                      Text('Référence : ${referenceController.text.trim()}'),
                      const SizedBox(height: 16),
                      const Text('Appuyez sur "Continuer" pour finaliser.'),
                    ],
                  ),
            isActive: currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
