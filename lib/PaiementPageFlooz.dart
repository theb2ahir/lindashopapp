import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore_for_file: file_names, unrelated_type_equality_checks, use_build_context_synchronously

class PaiementPage2 extends StatefulWidget {
  final dynamic data;
  const PaiementPage2({super.key, required this.data});

  @override
  State<PaiementPage2> createState() => _PaiementPage2State();
}

class _PaiementPage2State extends State<PaiementPage2> {
  final uid = FirebaseAuth.instance.currentUser?.uid;

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
    final item = widget.data;
    final int prixUnitaire = int.tryParse(item['productprice'].toString()) ?? 0;
    final total = prixUnitaire * item['quantity'];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Paiement via Flooz',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Stepper(
          currentStep: currentStep,
          onStepContinue: () async {
            if (currentStep == 2) {
              final reference = referenceController.text.trim();
              if (reference.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "Veuillez renseigner la référence de paiement.",
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                // Ajouter à 'acr' et récupérer l'ID du document
                DocumentReference acrRef = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('acr')
                    .add({
                      'imageUrl': item['productImageUrl'],
                      'productname': item['productname'],
                      'quantity': item['quantity'],
                      'reference': reference,
                      'status': 'en verification',
                    });
                final userid = uid; // ✅ Ici tu récupères l'ID
                String acrId = acrRef.id; // ✅ Ici tu récupères l'ID

                // Ensuite, ajouter dans 'infouser' avec l'acrid obtenu
                await FirebaseFirestore.instance.collection('infouser').add({
                  'userid': userid,
                  'acrid': acrId, // ✅ On envoie l'ID ici
                  'transactionId': transactionId,
                  'longi': item['longitude'],
                  'lati': item['latitude'],
                  'prixTotal': total,
                  'UserReseau': 'togocel',
                  'nomberitem': item['quantity'],
                  'productname': item['productname'],
                  'productprice': item['productprice'],
                  'livraison': item['livraison'],
                  'timestamp': DateTime.now(),
                  'usernamemiff': item['username'],
                  'userephone': item['phone'],
                  'useremail': item['email'],
                  'UserAdresse': item['addressLivraison'],
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

                          Navigator.pop(
                            context,
                          ); // Revenir à la page précédente

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Reçu PDF téléchargé."),
                            ),
                          );
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                setState(() => isLoading = false);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
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
              title: const Text(
                'Informations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Nom du produit :",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(' ${item['productname']}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Prix unitaire :",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(' $prixUnitaire FCFA'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Quantité :",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(' ${item['quantity']}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Total :",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(' $total FCFA'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "adresse :",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        item['addressLivraison'] != null &&
                                item['addressLivraison'].length >= 20
                            ? item['addressLivraison'].substring(0, 15) + " ..."
                            : item['addressLivraison'] ?? '',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Transaction ID :",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(' $transactionId'),
                    ],
                  ),
                ],
              ),
              isActive: currentStep >= 0,
            ),
            Step(
              title: const Text(
                'Paiement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Effectuez le paiement en cliquant sur le bouton ci-dessous :',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      lancerUSSD(
                        "*155*1*1*96368151*96368151*$total*1#",
                      ); // USSD personnalisé
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
              title: const Text(
                'Reçu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              content: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Transaction : ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(transactionId),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Montant Total : ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text('$total FCFA'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Référence : ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(referenceController.text.trim()),
                          ],
                        ),
                        const Text('Appuyez sur "Continuer" pour finaliser.'),
                      ],
                    ),
              isActive: currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }
}
