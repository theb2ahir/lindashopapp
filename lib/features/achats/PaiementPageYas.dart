// ignore_for_file: file_names, unrelated_type_equality_checks, use_build_context_synchronously, unused_local_variable

import 'dart:convert';
import 'dart:math';
import 'package:lindashopp/features/achats/paymentsucces.dart';
import 'package:lindashopp/features/pages/acceuilpage.dart';
import 'package:lindashopp/features/pages/utils/getadminfcmtoken.dart';
import 'package:lindashopp/features/pages/utils/sendnotif.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final TextEditingController smsController = TextEditingController();
  bool isLoading = false;
  bool ussdAlreadylaunched = false;
  String sms = "";
  bool canProceedToSendCommande = false;
  bool firstetapegood = false;
  int suffixe = 0;
  String _adminToken = "";
  double deliveryPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _initCommande();
  }

  @override
  void dispose() {
    smsController.dispose();
    super.dispose();
  }

  Future<void> _initCommande() async {
    getToken();
    transactionId = generateTransactionId();
    deliveryPrice = await getDeliveryPrice();
    final int dasuffixe = suffixeAdeuxChiffresAleatoire();
    setState(() {
      suffixe = dasuffixe;
    });
  }

  Future<double> getDeliveryPrice() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('delivery')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        deliveryPrice = (snapshot.docs.first.data()['price'] ?? 0).toDouble();
      });
      return (snapshot.docs.first.data()['price'] ?? 0).toDouble();
    }
    return 0.0;
  }

  Future<void> getToken() async {
    final token = await getAdminToken();
    if (token != null) {
      setState(() {
        _adminToken = token;
      });
    }
  }

  int? extraireMontant(String sms) {
    final regex = RegExp(
      r"Envoi de\s*([\d\s,\.]+)\s*FCFA",
      caseSensitive: false,
    );

    final match = regex.firstMatch(sms);

    if (match != null) {
      final montantStr = match.group(1)!.replaceAll(RegExp(r"[^\d]"), '');
      return int.tryParse(montantStr);
    }

    return null;
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
    final int total =
        apayer + (livraison != true ? deliveryPrice.toInt() : 0) + suffixe;
    final int totalAfficher =
        apayer + (livraison != true ? deliveryPrice.toInt() : 0);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Paiement via Yas togo',
          style: GoogleFonts.poppins(
            fontSize: size.width > 400 ? 25 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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

              String sellerDocId = "";

              if (item['sellerid'] != null &&
                  item['sellerid'].toString().isNotEmpty) {
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
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(item['sellerid'])
                    .collection('notifications')
                    .add({
                      'imageUrl':
                          "https://res.cloudinary.com/dccsqxaxu/image/upload/v1753640623/LindaLogo2_jadede.png",
                      'notifText':
                          "Votre produit ${item['productname']} a été commandé",
                      'type': 'commande', // utile pour filtrer
                      'date': DateTime.now(),
                    });

                sellerDocId = sellerRef.id;
              }

              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();

                final userData = userDoc.data() ?? {};
                // Ajouter à 'acr' et récupérer l'ID du document
                DocumentReference acrRef = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('acr')
                    .add({
                      'transactionId': transactionId,
                      'reference': reference,
                      'reseau': "Yas",
                      'Qrjson': "",
                      'status': 'en verification',
                      'prixTotal': total,
                      'deliveryPrice': deliveryPrice,
                      'items': [
                        {
                          "sellerid": item['sellerid'] != ""
                              ? item['sellerid']
                              : null,
                          "sellerCommandedocId": item['sellerid'] != ""
                              ? sellerDocId
                              : null,
                          'productname': item['productname'] ?? "",
                          'quantity': item['quantity'] ?? 0,
                          'productprice': item['productprice'] ?? 0,
                          'livraison': item['livraison'] ?? false,
                          'imageurl': item['productImageUrl'] ?? "",
                        },
                      ],
                      'date': DateTime.now(),
                    });
                String acrId = acrRef.id; // ✅ Ici tu récupères l'ID

                // Ensuite, ajouter dans 'infouser' avec l'acrid obtenu
                DocumentReference infouserRef = await FirebaseFirestore.instance
                    .collection('infouser')
                    .add({
                      'userid': uid ?? "",
                      'usernamemiff': userData['name'] ?? "Utilisateur",
                      'useremail': userData['email'] ?? "",
                      'userephone': userData['phone'] ?? "",
                      'UserAdresse': userData['adresse'] ?? "",
                      'sms': sms,
                      'lati': item['latitude'] ?? 0.0,
                      'longi': item['longitude'] ?? 0.0,
                      'transactionId': transactionId,
                      'ref': reference,
                      'UsereReseau': 'Yas',
                      'prixTotal': total,
                      'firstCheck': firstetapegood,
                      'items': [
                        {
                          "sellerid": item['sellerid'] != ""
                              ? item['sellerid']
                              : null,
                          "sellerCommandedocId": item['sellerid'] != ""
                              ? sellerDocId
                              : null,
                          'productname': item['productname'] ?? "",
                          'quantity': item['quantity'] ?? 0,
                          'productprice': item['productprice'] ?? 0,
                          'livraison': item['livraison'] ?? false,
                          'imageurl': item['productImageUrl'] ?? "",
                        },
                      ],
                      'acrid': acrId, // ✅ On envoie l'ID ici
                      'timestamp': DateTime.now(),
                    });

                String commandeId = infouserRef.id;

                final Map<String, dynamic> qrData = {
                  "transactionId": transactionId,
                  "reference": reference,
                  "total": total,
                  "commandeId": commandeId,
                  "sms": sms,
                  "reseau": "Yas",
                  "userid": uid ?? "",
                  "items": [
                    {
                      "sellerid": item['sellerid'] != ""
                          ? item['sellerid']
                          : null,
                      "sellerCommandedocId": item['sellerid'] != ""
                          ? sellerDocId
                          : null,
                      'productname': item['productname'] ?? "",
                      'quantity': item['quantity'] ?? 0,
                      'productprice': item['productprice'] ?? 0,
                      'livraison': item['livraison'] ?? false,
                      'imageurl': item['productImageUrl'] ?? "",
                    },
                  ],
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

                await sendNotification(
                  _adminToken,
                  "Commande",
                  "${userData['name'] ?? 'Utilisateur'} a passer la commande  de ( ${item['quantity']} x ${item['productname']} ) , prix total : $total FCFA",
                );
                if (item['sellerid'] != null &&
                    item['sellerid'].toString().isNotEmpty) {
                  final sellerMainDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(item['sellerid'])
                      .get();
                  final sellerMainData = sellerMainDoc.data();
                  final String? token = sellerMainData?['fcmToken'];

                  if (token != null && token.isNotEmpty) {
                    await sendNotification(
                      token,
                      "Commande",
                      "Vous avez une nouvelle commande de : ${item['productname']}",
                    );
                  }
                }

                setState(() => isLoading = false);

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
                              "Ce Qr code contient toutes les informations de votre commande, faite une capture d'ecran , il a pour but de faciliter la livraison et de retrouver votre commande en cas de problème",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            /// ⭐ PHOTO PRODUIT
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

                            /// ⭐ QR CODE REMPLACE LA CARTE D'INFOS
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PaymentSuccessPage(
                                      transactionId: transactionId,
                                      reference: reference,
                                      totalGeneral: total.toDouble(),
                                      reseau: "yas",
                                      commandes: [
                                        {
                                          'productname': item['productname'],
                                          'quantity': item['quantity'],
                                          'productprice': item['productprice'],
                                          'livraison': item['livraison'],
                                          'imageurl': item['productImageUrl'],
                                        },
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 9),
                      Text(' ${item['productname']}'),
                    ],
                  ),
                  SizedBox(height: 12),
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
                      Text(' ${livraison != true ? deliveryPrice : 0}  FCFA'),
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
                  SizedBox(height: 12),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
                      final codeUSSD = "*145*1*$total*92349698*1#";
                      final encoded = Uri.encodeComponent(codeUSSD);
                      final Uri ussdUri = Uri.parse('tel:$encoded');
                      if (ussdAlreadylaunched == true) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            TextEditingController referenceController =
                                TextEditingController();
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
                                        labelText: 'Sms reçue par SMS',
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
                                                            Navigator.pop(
                                                              context,
                                                            ); // Ferme le deuxième popup

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
                            TextEditingController referenceController =
                                TextEditingController();
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
                                                            Navigator.pop(
                                                              context,
                                                            );

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
                                                            } // Ferme le deuxième popup
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
                    child: const Text("Lancer le code USSD"),
                  ),
                  SizedBox(height: size.height > 800 ? 18 : 12),
                  Text(
                    "Reference de paiement : $reference",
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: size.width > 400 ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
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
              title: Text(
                'Reçu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: size.width > 400 ? 17 : 14,
                ),
              ),
              content: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transaction : $transactionId'),
                        Text('Montant Total : $total FCFA'),
                        Text('Référence : $reference'),
                        SizedBox(height: size.height > 800 ? 16 : 14),
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
