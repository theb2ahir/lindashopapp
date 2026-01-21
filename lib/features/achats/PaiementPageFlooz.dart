// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/pages/acceuilpage.dart';
import 'package:lindashopp/features/pages/utils/notifucation_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore_for_file: file_names, unrelated_type_equality_checks, use_build_context_synchronously
import 'package:permission_handler/permission_handler.dart';

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
  final TextEditingController smsController = TextEditingController();
  bool isLoading = false;
  bool ussdAlreadylaunched = false;
  String sms = "";
  bool canProceedToSendCommande = false;
  bool firstetapegood = false;
  int suffixe = 0;

  @override
  void initState() {
    super.initState();
    transactionId = generateTransactionId();
    final int dasuffixe = suffixeAdeuxChiffresAleatoire();
    setState(() {
      suffixe = dasuffixe;
    });
  }

  @override
  void dispose() {
    smsController.dispose();
    super.dispose();
  }

  String reference = "";

  String? extraireReference(String sms) {
    // Cherche "Ref", "REF", "ref" suivi éventuellement de ":" ou "-" puis des chiffres
    final refRegex = RegExp(r"Ref\s*[:\-]?\s*(\d+)", caseSensitive: false);
    final match = refRegex.firstMatch(sms);

    if (match != null) {
      return match.group(1).toString(); // retourne uniquement la référence
    }

    return null; // si aucune référence trouvée
  }

  int? extraireMontant(String sms) {
    // Cherche "Envoi de" suivi éventuellement d'espaces, puis des chiffres
    final montantRegex = RegExp(
      r"Envoi de\s*([\d\s]+)\s*FCFA",
      caseSensitive: false,
    );
    final match = montantRegex.firstMatch(sms);

    if (match != null) {
      // Supprimer les espaces dans le nombre (ex: "1 000" -> "1000")
      String montantStr = match.group(1)!.replaceAll(' ', '');
      return int.tryParse(montantStr);
    }

    return null; // si aucun montant trouvé
  }

  Future<void> _checkPayment() async {
    final montantSms = extraireMontant(sms);
    // recuperer les deux derniers chiffres du montant
    final montantSuffixe = montantSms! % 100;

    if (suffixe != montantSuffixe) {
      setState(() {
        canProceedToSendCommande = false;
        firstetapegood = false;
      });
    }

    if (suffixe == montantSuffixe) {
      setState(() {
        canProceedToSendCommande = true;
        firstetapegood = true;
      });
    }
  }

  suffixeAdeuxChiffresAleatoire() {
    final random = Random();
    final int suffixe = 10 + random.nextInt(90); // 10 → 99
    return suffixe;
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
    final size = MediaQuery.of(context).size;
    final item = widget.data;
    final livraison = item['livraison'];
    final int prixUnitaire = int.tryParse(item['productprice'].toString()) ?? 0;
    final int quantite = int.tryParse(item['quantity'].toString()) ?? 0;
    final apayer = prixUnitaire * quantite;
    final int total = apayer + (livraison != 'true' ? 2000 : 0) + suffixe;
    final int totalAfficher = apayer + (livraison != 'true' ? 2000 : 0);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Paiement via Flooz',
          style: GoogleFonts.poppins(
            fontSize: size.width > 400 ? 25 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Stepper(
          currentStep: currentStep,
          onStepContinue: () async {
            if (currentStep == 2) {
              if (reference == "") {
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
              if (canProceedToSendCommande == false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Veuillez vérifier le SMS collé et réessayer.",
                    ),
                  ),
                );
                return;
              }

              setState(() => isLoading = true);

              DocumentReference sellerRef = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(item['sellerid'])
                  .collection('sellercommandes')
                  .add({
                    'produits': [
                      {
                        'productname': item['productname'],
                        'quantity': item['quantity'],
                        'imageurl': item['productImageUrl'],
                        'productprice': item['productprice'],
                      },
                    ],
                    'status': 'en verification',
                    'livree': false,
                    'date': DateTime.now(),
                  });

              String sellerDocId = sellerRef.id;

              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();

                final userData = userDoc.data();

                // Ajouter à 'acr' et récupérer l'ID du document
                DocumentReference acrRef = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('acr')
                    .add({
                      'imageUrl': item['productImageUrl'],
                      'productname': item['productname'],
                      'quantity': item['quantity'],
                      'productprice': item['productprice'],
                      'transactionId': transactionId,
                      'reseau': "flooz",
                      'reference': reference,
                      'Qrjson': "",
                      'status': 'en verification',
                      'date': DateTime.now(),
                    });
                final userid = uid; // ✅ Ici tu récupères l'ID
                String acrId = acrRef.id; // ✅ Ici tu récupères l'ID

                // Ensuite, ajouter dans 'infouser' avec l'acrid obtenu
                DocumentReference infouserRef = await FirebaseFirestore.instance
                    .collection('infouser')
                    .add({
                      'userid': userid,
                      'acrid': acrId, // ✅ On envoie l'ID ici
                      'transactionId': transactionId,
                      'longi': item['longitude'],
                      'lati': item['latitude'],
                      'prixTotal': total,
                      'userId': uid,
                      "sellerid": item['sellerid'],
                      "sellerCommandedocId": sellerDocId,
                      'sms': sms,
                      'firstCheck': firstetapegood,
                      'UsereReseau': 'flooz',
                      'nomberitem': item['quantity'],
                      'productname': item['productname'],
                      'productprice': item['productprice'],
                      'livraison': item['livraison'],
                      'timestamp': DateTime.now(),
                      'usernamemiff': userData?['name'],
                      'userephone': userData?['phone'],
                      'useremail': userData?['email'],
                      'UserAdresse': userData?['adresse'],
                      'ref': reference,
                    });

                String commandeId = infouserRef.id;

                final Map<String, dynamic> qrData = {
                  "transactionId": transactionId,
                  "reference": reference,
                  "total": total,
                  "userid": uid,
                  "sms": sms,
                  "reseau": "flooz",
                  "commandeId": commandeId,
                  "productname": item['productname'],
                  "quantity": item['quantity'],
                };

                final String qrJson = jsonEncode(qrData);

                acrRef.update({"Qrjson": qrJson});

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
                  title: "Payement",
                  body:
                      "Payement enregistrer nous allons verifier votre paiement et modifier le statut en consequence , rendez-vous sur la page commande",
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
                                fontSize: size.width > 400 ? 20 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: size.height > 800 ? 12 : 6),
                            Text(
                              "Ce Qr code contient toutes les informations de votre commande, il est automatiquement sauvegardé ,inutile de faire une capture d'ecran , il a pour but de faciliter la livraison et de retrouver votre commande en cas de problème",
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: size.height > 800 ? 16 : 14),

                            /// ⭐ IMAGE DU PRODUIT
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

                            const SizedBox(height: 20),

                            /// ⭐ QR CODE CONTENANT LES DONNÉES
                            QrImageView(
                              data: jsonEncode({
                                "productname": item['productname'],
                                "quantity": item['quantity'],
                                "total": total,
                                "transactionId": transactionId,
                                "reference": reference,
                              }),
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                            ),

                            const SizedBox(height: 20),

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
              title: Text(
                'Informations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: size.width > 400 ? 17 : 14,
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Nom du produit :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width > 400 ? 16 : 14,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(' ${item['productname']}'),
                    ],
                  ),
                  SizedBox(height: size.height > 800 ? 12 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Prix unitaire :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width > 400 ? 16 : 14,
                        ),
                      ),
                      SizedBox(width: 9),
                      Text(' $prixUnitaire FCFA'),
                    ],
                  ),
                  SizedBox(height: size.height > 800 ? 12 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Quantité :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width > 400 ? 16 : 14,
                        ),
                      ),
                      SizedBox(width: 9),
                      Text(' ${item['quantity']}'),
                    ],
                  ),
                  SizedBox(height: size.height > 800 ? 12 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Frais de livraison :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width > 400 ? 16 : 14,
                        ),
                      ),
                      SizedBox(width: 9),
                      Text(' ${livraison != "true" ? 2000 : 0}  FCFA'),
                    ],
                  ),

                  SizedBox(height: size.height > 800 ? 12 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Total :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width > 400 ? 16 : 14,
                        ),
                      ),
                      SizedBox(width: 9),
                      Text(' $totalAfficher FCFA'),
                    ],
                  ),
                  SizedBox(height: size.height > 800 ? 12 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "adresse :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width > 400 ? 16 : 14,
                        ),
                      ),
                      SizedBox(width: 9),
                      Text(
                        item['addressLivraison'] != null &&
                                item['addressLivraison'].length >= 20
                            ? item['addressLivraison'].substring(0, 15) + " ..."
                            : item['addressLivraison'] ?? '',
                      ),
                    ],
                  ),
                  SizedBox(height: size.height > 800 ? 12 : 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Transaction ID :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width > 400 ? 16 : 14,
                        ),
                      ),
                      SizedBox(width: 9),
                      Text(' $transactionId'),
                    ],
                  ),
                ],
              ),
              isActive: currentStep >= 0,
            ),
            Step(
              title: Text(
                'Paiement',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: size.width > 400 ? 17 : 14,
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Effectuez le paiement en cliquant sur le bouton ci-dessous :',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final codeUSSD = "*155*1*1*96368151*96368151*$total*2#";
                      final encoded = Uri.encodeComponent(codeUSSD);
                      final Uri ussdUri = Uri.parse('tel:$encoded');

                      if (ussdAlreadylaunched == true) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Entrer le SMS reçu de votre opérateur",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: smsController,
                                      maxLines: 5,
                                      decoration: InputDecoration(
                                        labelText: 'sms reçue par SMS',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black
                                            : Colors.grey[100],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        onPressed: () {
                                          final smsText = smsController.text
                                              .trim();

                                          if (smsText.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Veuillez copier et coller le SMS reçu de votre opérateur.",
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            return;
                                          }

                                          final resultat = extraireReference(
                                            smsText,
                                          );

                                          if (resultat != null) {
                                            setState(() {
                                              reference = resultat;
                                              sms = smsText;
                                            });
                                            _checkPayment();
                                            Navigator.pop(
                                              context,
                                            ); // Ferme le premier popup
                                            // Deuxième popup : confirmation
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    20.0,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        "Sms enregistrée ✅",
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        "Votre SMS a été enregistrée. Vous pouvez maintenant confirmer la commande.",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.teal,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 14,
                                                                ),
                                                          ),
                                                          onPressed: () {
                                                            // 1️⃣ Fermer le dialog "SMS enregistré"
                                                            Navigator.pop(
                                                              context,
                                                            );

                                                            // 2️⃣ Attendre un micro instant (important pour Flutter)

                                                            if (canProceedToSendCommande ==
                                                                true) {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder: (context) => AlertDialog(
                                                                  title: const Icon(
                                                                    Icons.check,
                                                                    color: Colors
                                                                        .lightGreenAccent,
                                                                    size: 40,
                                                                  ),
                                                                  content:
                                                                      const Text(
                                                                        "Votre paiement est valide, merci de confirmer votre commande",
                                                                      ),
                                                                ),
                                                              );
                                                            } else {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder: (context) => AlertDialog(
                                                                  title: const Icon(
                                                                    Icons.close,
                                                                    color: Colors
                                                                        .red,
                                                                    size: 40,
                                                                  ),
                                                                  content:
                                                                      const Text(
                                                                        "Votre paiement n'est pas valide. Veuillez vérifier le SMS collé et réessayer, si vous voulez coller un nouveau SMS, cliquez sur le bouton | Lancer le code USSD |",
                                                                      ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        Navigator.pop(
                                                                          context,
                                                                        );
                                                                        Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                                const AcceuilPage(),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: const Text(
                                                                        "Fermer",
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }
                                                          },

                                                          child: Text(
                                                            "OK",
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Veuillez entrer la référence.",
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text(
                                          "Envoyer",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                      if (ussdAlreadylaunched == false) {
                        setState(() {
                          ussdAlreadylaunched = true;
                        });
                        await lancerUSSD(codeUSSD);
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Entrer le SMS reçu de votre opérateur",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: smsController,
                                      maxLines: 5,
                                      decoration: InputDecoration(
                                        labelText: 'Référence reçue par SMS',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black
                                            : Colors.grey[100],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        onPressed: () {
                                          final smsText = smsController.text
                                              .trim();

                                          if (smsText.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Veuillez copier et coller le SMS reçu de votre opérateur.",
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            return;
                                          }

                                          final resultat = extraireReference(
                                            smsText,
                                          );

                                          if (resultat != null) {
                                            setState(() {
                                              reference = resultat;
                                              sms = smsText;
                                            });
                                            _checkPayment();
                                            Navigator.pop(
                                              context,
                                            ); // Ferme le premier popup
                                            // Deuxième popup : confirmation
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    20.0,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        "Sms enregistrée ✅",
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        "Votre SMS a été enregistrée. Vous pouvez maintenant confirmer la commande.",
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 24,
                                                      ),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.teal,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 14,
                                                                ),
                                                          ),
                                                          onPressed: () {
                                                            // 1️⃣ Fermer le dialog "SMS enregistré"
                                                            Navigator.pop(
                                                              context,
                                                            );

                                                            // 2️⃣ Attendre un micro instant (important pour Flutter)

                                                            if (canProceedToSendCommande ==
                                                                true) {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder: (context) => AlertDialog(
                                                                  title: const Icon(
                                                                    Icons.check,
                                                                    color: Colors
                                                                        .lightGreenAccent,
                                                                    size: 40,
                                                                  ),
                                                                  content:
                                                                      const Text(
                                                                        "Votre paiement est valide, merci de confirmer votre commande",
                                                                      ),
                                                                ),
                                                              );
                                                            } else {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder: (context) => AlertDialog(
                                                                  title: const Icon(
                                                                    Icons.close,
                                                                    color: Colors
                                                                        .red,
                                                                    size: 40,
                                                                  ),
                                                                  content:
                                                                      const Text(
                                                                        "Votre paiement n'est pas valide. Veuillez vérifier le SMS collé et réessayer, si vous voulez coller un nouveau SMS, cliquez sur le bouton | Lancer le code USSD |",
                                                                      ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        Navigator.pop(
                                                                          context,
                                                                        );
                                                                        Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                                const AcceuilPage(),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: const Text(
                                                                        "Fermer",
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }
                                                          },

                                                          child: Text(
                                                            "OK",
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Veuillez entrer la référence.",
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text(
                                          "Envoyer",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                    child: Text(
                      "Lancer le code USSD",
                      style: GoogleFonts.poppins(
                        fontSize: size.width > 400 ? 16 : 14,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height > 800 ? 18 : 12),
                  Text(
                    "Reference de paiement : $reference",
                    style: GoogleFonts.poppins(
                      fontSize: size.width > 400 ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: size.height > 800 ? 10 : 6),
                  Text(
                    sms,
                    style: GoogleFonts.poppins(
                      fontSize: size.width > 400 ? 17 : 14,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                                fontSize: size.width > 400 ? 16 : 14,
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
                                fontSize: size.width > 400 ? 16 : 14,
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
                                fontSize: size.width > 400 ? 16 : 14,
                              ),
                            ),
                            Text(reference),
                          ],
                        ),
                        SizedBox(height: size.height > 800 ? 12 : 6),
                        Text(
                          'Appuyez sur "Continuer" pour finaliser.',
                          style: GoogleFonts.poppins(
                            fontSize: size.width > 400 ? 16 : 14,
                          ),
                        ),
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
