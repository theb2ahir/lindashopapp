// ignore_for_file: file_names, unrelated_type_equality_checks, use_build_context_synchronously, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/notifucation_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PaiementPage extends StatefulWidget {
  final dynamic data;
  const PaiementPage({super.key, required this.data});

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
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

  bool _permissionChecked = false;
  Future<void> _checkAndRequestPermission() async {
    // Vérifie si la permission est déjà accordée
    if (await Permission.phone.isGranted) {
      _permissionChecked = true;
      return;
    }

    // Vérifie si la permission est refusée définitivement
    if (await Permission.phone.isPermanentlyDenied) {
      // Redirige vers les paramètres
      await openAppSettings();
      return;
    }

    // Demande la permission une seule fois
    final status = await Permission.phone.request();
    if (status.isGranted) {
      _permissionChecked = true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission d'appel refusée")),
      );
    }
  }

  Future<void> lancerUSSD(String codeUSSD) async {
    // Vérifie et demande la permission une seule fois
    if (!_permissionChecked) {
      await _checkAndRequestPermission();
      if (!_permissionChecked) return; // permission refusée
    }

    final encoded = Uri.encodeComponent(codeUSSD);
    final Uri ussdUri = Uri.parse('tel:$encoded');

    try {
      await launchUrl(ussdUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible de lancer le code USSD : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.data;
    final int prixUnitaire = int.tryParse(item['productprice'].toString()) ?? 0;
    final int quantite = int.tryParse(item['quantity'].toString()) ?? 0;
    final int total = prixUnitaire * quantite;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Paiement via Yas togo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
                      'date': DateTime.now(),
                      'productprice': item['productprice'],
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
                  'UsereReseau': 'Yas',
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

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('notifications')
                    .add({
                      'imageUrl':
                          "https://res.cloudinary.com/dccsqxaxu/image/upload/v1753640623/LindaLogo2_jadede.png",
                      'notifText':
                          "Votre commande de ${item['quantity']} x ${item['productname']} a été enregistrée avec succès. Merci pour votre achat !",
                      'type': 'commande', // utile pour filtrer
                      'date': DateTime.now(),
                    });

                setState(() => isLoading = false);

                NotificationService.showNotification(
                  title: "Achat réussi 🎉",
                  message:
                      "Merci pour votre achat de ${item['quantity']} x ${item['productname']}",
                  imageUrl: "${item['productImageUrl']}",
                );

                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Confirmation",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Sauvegarder en faisant une capture d'écran ces informations.",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.network(
                                  item['productImageUrl'] ?? '',
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.image, size: 40),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.grey[100],
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Nom du produit : ${item['productname']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Quantité : ${item['quantity']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "ID de la Transaction : $transactionId",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Prix total : $total FCFA",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Référence : $reference",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(double.infinity, 45),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Fermer"),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                  Text('Nom du produit : ${item['productname']}'),
                  const SizedBox(height: 8),
                  Text('Prix unitaire : $prixUnitaire FCFA'),
                  const SizedBox(height: 8),
                  Text('Quantité : ${item['quantity']}'),
                  const SizedBox(height: 8),
                  Text('Total : $total FCFA'),
                  const SizedBox(height: 8),
                  Text('Livraison : ${item['addressLivraison']}'),
                  const SizedBox(height: 8),
                  Text('Transaction ID : $transactionId'),
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
                    onPressed: () async {
                      final codeUSSD = "*155*1*1*96368151*96368151*$total*1#";
                      final encoded = Uri.encodeComponent(codeUSSD);
                      final Uri ussdUri = Uri.parse('tel:$encoded');

                      try {
                        await lancerUSSD(codeUSSD);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Impossible de lancer le code USSD : $e",
                            ),
                          ),
                        );
                      }
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
      ),
    );
  }
}
