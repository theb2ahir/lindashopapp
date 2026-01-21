// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/pages/utils/notifucation_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

import '../pages/profil/editprofile.dart';

class BuyAllPage extends StatefulWidget {
  final List<Map<String, dynamic>> commandes;

  const BuyAllPage({super.key, required this.commandes});

  @override
  State<BuyAllPage> createState() => _BuyAllPageState();
}

class _BuyAllPageState extends State<BuyAllPage> {
  late String transactionId;
  int total = 0;
  int totalGeneral = 0;
  bool isLoading = false;
  bool ussdAlreadylaunched = false;
  int suffixeActuel = 0;
  String sms = "";
  bool canProceedToSendCommande = false;
  bool firstetapegood = false;

  @override
  void initState() {
    super.initState();
    transactionId = generateTransactionId();
    final total = getTotalPrice();
    bool aLivraisonPayante = widget.commandes.any(
      (item) => item['livraison'] != 'true',
    );

    double fraisLivraison = aLivraisonPayante ? 2000 : 0;
    final suffixe = suffixeAdeuxChiffresAleatoire();
    double totalGenerale = total + fraisLivraison + suffixe;

    final totalGeneralString = totalGenerale.toInt().toString();

    setState(() {
      totalGeneral = totalGenerale.toInt();
      suffixeActuel = suffixe;
    });

    ussdCodes.addAll({
      'Moov': "*155*1*1*96368151*96368151*$totalGeneralString*2#",
      'Yas': "*145*1*$totalGeneralString*92349698*2#",
    });
  }

  bool _permissionChecked = false;
  String reference = "";

  suffixeAdeuxChiffresAleatoire() {
    final random = Random();
    final int suffixe = 10 + random.nextInt(90); // 10 → 99
    return suffixe;
  }

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

    if (suffixeActuel != montantSuffixe) {
      setState(() {
        canProceedToSendCommande = false;
        firstetapegood = false;
      });
    }

    if (suffixeActuel == montantSuffixe) {
      setState(() {
        canProceedToSendCommande = true;
        firstetapegood = true;
      });
    }
  }

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
      await launchUrl(
        ussdUri,
        mode: LaunchMode.platformDefault,
      ); // lancer le USSD
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible de lancer le code USSD : $e")),
      );
    }
  }

  void showCommandeDialog() {
    // Préparation des données de la commande en JSON
    final Map<String, dynamic> qrData = {
      "transactionId": transactionId,
      "reference": reference,
      "total": totalGeneral,
      "commandes": widget.commandes.map((item) {
        return {
          "productname": item['productname'],
          "quantity": item['quantity'],
          "price": item['productprice'],
        };
      }).toList(),
    };

    final String qrJson = jsonEncode(qrData);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Text(
                  "Ce Qr code contient toutes les informations de votre commande , il est automatiquement sauvegardé inutile de faire une capture d'ecran , il a pour but de faciliter la livraison et de retrouver votre commande en cas de problème",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                /// 🔥 QR CODE ICI
                QrImageView(
                  data: qrJson,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),

                const SizedBox(height: 10),

                Text(
                  "Total : $totalGeneral FCFA",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Fermer"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = 1000 + (DateTime.now().microsecond % 9000);
    return 'TXN-$timestamp-$random';
  }

  int getTotalPrice() {
    int total = 0;
    for (var item in widget.commandes) {
      final price = int.tryParse(item['productprice'].toString()) ?? 0;
      final qty = int.tryParse(item['quantity'].toString()) ?? 1;
      total += price * qty;
    }
    return total;
  }

  String? reseauChoisi;
  final Map<String, String> ussdCodes = {};

  Future<void> envoyerInfosAuServeur(BuildContext context) async {
    if (isLoading) return; // évite double clic

    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Utilisateur non connecté")));
      return;
    }

    if (reseauChoisi == null || reference == "") {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez choisir un réseau et entrer la référence."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final userData = userDoc.data();

    if (userData == null ||
        userData['phone'] == null ||
        userData['phone'].toString().isEmpty ||
        userData['adresse'] == null ||
        userData['adresse'].toString().isEmpty) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF02204B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfile()),
                  );
                },
                icon: const Icon(Icons.edit, color: Colors.white),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfile()),
                  );
                },
                child: Text(
                  "Veuillez compléter votre profil",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(width: 9),
            ],
          ),
        ),
      );
      return; // Stoppe le paiement
    }

    final infouserRef = FirebaseFirestore.instance.collection('infouser');

    // 1️⃣ Grouper les produits par vendeur
    Map<String, List<Map<String, dynamic>>> commandesParVendeur = {};
    for (var item in widget.commandes) {
      final sellerId = item['sellerid'];
      if (sellerId != null && sellerId.isNotEmpty) {
        commandesParVendeur.putIfAbsent(sellerId, () => []);
        commandesParVendeur[sellerId]!.add({
          'productname': item['productname'],
          'quantity': item['quantity'],
          'imageurl': item['productImageUrl'],
          'productprice': item['productprice'],
        });
      }
    }

    // 2️⃣ Créer les documents vendeur
    Map<String, String> sellerCommandIds = {}; // sellerId -> docId
    for (final entry in commandesParVendeur.entries) {
      final sellerId = entry.key;
      final produits = entry.value;

      DocumentReference sellerRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .collection('sellercommandes')
          .add({
            'produits': produits,
            'status': 'en verification',
            'livree': false,
            'date': DateTime.now(),
          });

      sellerCommandIds[sellerId] = sellerRef.id;
    }

    try {
      for (var item in widget.commandes) {
        final userAdresse = userData['adresse'];
        final userephone = userData['phone'];
        final useremail = userData['email'];
        final usernamemiff = userData['name'];
        final productprice = item['productprice'];
        final nomberitem = item['quantity'];
        final livraison = item['livraison'];
        final productname = item['productname'];
        final lati = item['latitude'];
        final longi = item['longitude'];
        final String sellerid = item['sellerid'] ?? '';
        final String? sellerDocId = sellerid.isNotEmpty
            ? sellerCommandIds[sellerid]
            : null;
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
              'reference': reference,
              'reseau': reseauChoisi,
              "Qrjson": "",
              'status': 'en verification',
              'date': DateTime.now(),
            });

        final userid = uid;
        String acrId = acrRef.id;
        await infouserRef.add({
          "UserAdresse": userAdresse,
          "productprice": productprice,
          "nomberitem": nomberitem,
          "livraison": livraison,
          "productname": productname,
          "useremail": useremail,
          "userephone": userephone,
          "usernamemiff": usernamemiff,
          'userId': uid,
          "firstCheck": firstetapegood,
          "sms": sms,
          "lati": lati,
          "longi": longi,
          'transactionId': transactionId,
          'ref': reference,
          "UsereReseau": reseauChoisi,
          "prixTotal": totalGeneral,
          "acrid": acrId,
          "userid": userid,
          "sellerid": sellerid.isNotEmpty ? sellerid : null,
          "sellerCommandedocId": sellerDocId,
          'timestamp': DateTime.now(),
        });

        String commandeId = infouserRef.id;

        final Map<String, dynamic> qrData = {
          "transactionId": transactionId,
          "reference": reference,
          "total": totalGeneral,
          "commandeId": commandeId,
          "sms": sms,
          "reseau": reseauChoisi,
          "userid": uid,
          "commandes": widget.commandes.map((item) {
            return {
              "productname": item['productname'],
              "quantity": item['quantity'],
              "price": item['productprice'],
            };
          }).toList(),
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

        showCommandeDialog();
      }

      NotificationService.showNotification(
        title: "Paiement effectué",
        body:
            "Vos commandes ont été enregistrées avec succès, nous allons verifier votre paiement et modifier le statut en consequence , rendez-vous sur la page commande",
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final total = getTotalPrice();

    bool aLivraisonPayante = widget.commandes.any(
      (item) => item['livraison'] != 'true',
    );

    double fraisLivraison = aLivraisonPayante ? 2000 : 0;
    double totalGeneral = total + fraisLivraison;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Valider mon panier",
          style: GoogleFonts.poppins(
            fontSize: size.width > 400 ? 25 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SafeArea(
            bottom: true,
            top: true,
            child: Column(
              children: [
                SizedBox(
                  height: size.height > 800
                      ? MediaQuery.of(context).size.height * 0.4
                      : MediaQuery.of(context).size.height * 0.3,
                  child: ListView.builder(
                    itemCount: widget.commandes.length,
                    itemBuilder: (context, index) {
                      final item = widget.commandes[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.transparent
                                    : Colors.transparent,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.transparent
                                      : Colors.transparent,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item['productImageUrl'] ?? '',
                                    height: size.width > 400 ? 60 : 50,
                                    width: size.width > 400 ? 60 : 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: size.width > 400 ? 12 : 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['productname'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: size.width > 400 ? 16 : 14,
                                        ),
                                      ),
                                      SizedBox(
                                        height: size.height > 800 ? 4 : 2,
                                      ),
                                      Text(
                                        '${item['quantity']} x ${item['productprice']} FCFA',
                                        style: GoogleFonts.poppins(
                                          fontSize: size.width > 400 ? 14 : 12,
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      (item['livraison'] == 'true')
                                          ? 'Livraison gratuite'
                                          : 'Livraison payante',
                                      style: TextStyle(
                                        fontSize: size.width > 400 ? 13 : 11,
                                        fontWeight: FontWeight.bold,
                                        color: (item['livraison'] == 'true')
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      '${(int.tryParse(item['productprice'].toString()) ?? 0) * (int.tryParse(item['quantity'].toString()) ?? 0)} FCFA',
                                      style: GoogleFonts.poppins(
                                        fontSize: size.width > 400 ? 16 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: size.height > 800 ? 16 : 12),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🧾 Facture style "carte"
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.transparent
                                  : Colors.transparent,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Facture",
                              style: GoogleFonts.poppins(
                                fontSize: size.width > 400 ? 19 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: size.height > 800 ? 10 : 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total panier",
                                  style: GoogleFonts.poppins(
                                    fontSize: size.width > 400 ? 16 : 14,
                                  ),
                                ),
                                Text(
                                  "$total FCFA",
                                  style: GoogleFonts.poppins(
                                    fontSize: size.width > 400 ? 14 : 12,
                                  ), // ← total panier
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Frais de livraison",
                                  style: GoogleFonts.poppins(
                                    fontSize: size.width > 400 ? 16 : 14,
                                  ),
                                ),
                                Text(
                                  "${fraisLivraison.toStringAsFixed(0)} FCFA",
                                  style: GoogleFonts.poppins(
                                    fontSize: size.width > 400 ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: size.height > 800 ? 19 : 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Reference de paiement",
                                  style: GoogleFonts.poppins(
                                    fontSize: size.width > 400 ? 16 : 14,
                                  ),
                                ),
                                Text(
                                  reference,
                                  style: GoogleFonts.poppins(
                                    fontSize: size.width > 400 ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Sms coller",
                                      style: GoogleFonts.poppins(
                                        fontSize: size.width > 400 ? 17 : 14,
                                      ),
                                    ),
                                  ],
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    sms,
                                    style: GoogleFonts.poppins(
                                      fontSize: size.width > 400 ? 14 : 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: size.height > 800 ? 20 : 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total",
                                  style: GoogleFonts.poppins(
                                    fontSize: size.width > 400 ? 19 : 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${totalGeneral.toStringAsFixed(0)} FCFA",
                                  style: GoogleFonts.poppins(
                                    fontSize: size.width > 400 ? 16 : 14,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: size.height > 800 ? 30 : 20),

                      // 🟢 Réseaux (checkboxes)
                      SizedBox(
                        // Largeur fixe du Row
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          // Écart entre les boutons
                          children: [
                            // Bouton Moov
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: reseauChoisi == "Moov"
                                      ? Colors.teal
                                      : Colors.grey[300],
                                  foregroundColor: reseauChoisi == "Moov"
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                onPressed: () {
                                  setState(() {
                                    reseauChoisi = "Moov";
                                  });
                                },
                                child: const Text("Moov"),
                              ),
                            ),
                            SizedBox(width: size.width > 400 ? 16 : 14),
                            // Espace entre les boutons
                            // Bouton Yas
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: reseauChoisi == "Yas"
                                      ? Colors.teal
                                      : Colors.grey[300],
                                  foregroundColor: reseauChoisi == "Yas"
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                onPressed: () {
                                  setState(() {
                                    reseauChoisi = "Yas";
                                  });
                                },
                                child: const Text("Yas"),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height > 800 ? 16 : 12),
                      if (reseauChoisi != null)
                        TextButton(
                          onPressed: () {
                            TextEditingController smsController =
                                TextEditingController();

                            if (ussdAlreadylaunched == true) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setDialogState) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Copier et coller le SMS reçu de votre opérateur",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              TextField(
                                                maxLines: 5,
                                                controller: smsController,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'SMS reçu de votre opérateur',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
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
                                                    final smsText =
                                                        smsController.text
                                                            .trim();
                                                    if (smsText.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Veuillez copier et coller le SMS reçu de votre opérateur.",
                                                          ),
                                                          duration: Duration(
                                                            seconds: 2,
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    final resultat =
                                                        extraireReference(
                                                          smsText,
                                                        );

                                                    if (resultat != null) {
                                                      setState(() {
                                                        reference = resultat;
                                                        sms = smsText;
                                                      });
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                      // Ferme le premier dialog
                                                      // enlencher la verification du paiement
                                                      _checkPayment();
                                                      // Deuxième popup : confirmation
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => Dialog(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  20.0,
                                                                ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  "Référence enregistrée ✅",
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 16,
                                                                ),
                                                                Text(
                                                                  "Votre Sms a bien été enregistrée il ne vous reste plus qu'à confirmer votre commande.",
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style:
                                                                      GoogleFonts.poppins(
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 24,
                                                                ),
                                                                SizedBox(
                                                                  width: double
                                                                      .infinity,
                                                                  child: ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .teal,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                      ),
                                                                      padding: const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            14,
                                                                      ),
                                                                    ),
                                                                    onPressed: () {
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop();
                                                                      if (canProceedToSendCommande ==
                                                                          true) {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (
                                                                                context,
                                                                              ) {
                                                                                return AlertDialog(
                                                                                  title: Icon(
                                                                                    Icons.check,
                                                                                    color: Colors.lightGreenAccent,
                                                                                    size: 40,
                                                                                  ),
                                                                                  content: const Text(
                                                                                    "Votre paiement est valide, merci de confirmer votre commande",
                                                                                  ),
                                                                                );
                                                                              },
                                                                        );
                                                                      } else if (canProceedToSendCommande ==
                                                                          false) {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (
                                                                                context,
                                                                              ) {
                                                                                return AlertDialog(
                                                                                  title: Icon(
                                                                                    Icons.close,
                                                                                    color: Colors.red,
                                                                                    size: 40,
                                                                                  ),
                                                                                  content: const Text(
                                                                                    "Votre paiement n'est pas valide , merci de vérifier votre Sms que vous avez coller ,  pour en envoyer un nouveau clicker sur | Cliquez ici pour initier le payement |",
                                                                                  ),
                                                                                );
                                                                              },
                                                                        );
                                                                      }
                                                                    },
                                                                    child: Text(
                                                                      "OK",
                                                                      style: GoogleFonts.poppins(
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
                                                      // Extraction échouée
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Erreur : impossible d'extraire la référence ou le montant.",
                                                          ),
                                                          duration: Duration(
                                                            seconds: 2,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: const Text(
                                                    "Envoyer",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                },
                              );
                            }

                            if (ussdAlreadylaunched == false) {
                              setState(() {
                                ussdAlreadylaunched = true;
                              });
                              lancerUSSD(ussdCodes[reseauChoisi]!);
                              // Assure-toi d'avoir ceci dans ton State
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setDialogState) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Copier et coller le SMS reçu de votre opérateur",
                                                style: GoogleFonts.poppins(
                                                  fontSize: size.width > 400
                                                      ? 18
                                                      : 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(
                                                height: size.height > 800
                                                    ? 16
                                                    : 14,
                                              ),
                                              TextField(
                                                maxLines: 5,
                                                controller: smsController,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'SMS reçu de votre opérateur',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
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
                                                    final smsText =
                                                        smsController.text
                                                            .trim();
                                                    if (smsText.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Veuillez copier et coller le SMS reçu de votre opérateur.",
                                                          ),
                                                          duration: Duration(
                                                            seconds: 2,
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    final resultat =
                                                        extraireReference(
                                                          smsText,
                                                        );

                                                    if (resultat != null) {
                                                      setState(() {
                                                        reference = resultat;
                                                        sms = smsText;
                                                      });
                                                      // Ferme le premier dialog
                                                      Navigator.of(
                                                        context,
                                                      ).pop();

                                                      // enlencher la verification du paiement
                                                      _checkPayment();

                                                      // Deuxième popup : confirmation
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => Dialog(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  20.0,
                                                                ),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  "Référence enregistrée ✅",
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 16,
                                                                ),
                                                                Text(
                                                                  "Votre Sms a bien été enregistrée il ne vous reste plus qu'à confirmer votre commande.",
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style:
                                                                      GoogleFonts.poppins(
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 24,
                                                                ),
                                                                SizedBox(
                                                                  width: double
                                                                      .infinity,
                                                                  child: ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .teal,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                      ),
                                                                      padding: const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            14,
                                                                      ),
                                                                    ),
                                                                    onPressed: () {
                                                                      if (canProceedToSendCommande ==
                                                                          true) {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (
                                                                                context,
                                                                              ) {
                                                                                return AlertDialog(
                                                                                  title: Icon(
                                                                                    Icons.check,
                                                                                    color: Colors.lightGreenAccent,
                                                                                    size: 40,
                                                                                  ),
                                                                                  content: const Text(
                                                                                    "Votre paiement est valide, merci de confirmer votre commande",
                                                                                  ),
                                                                                );
                                                                              },
                                                                        );
                                                                      } else if (canProceedToSendCommande ==
                                                                          false) {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (
                                                                                context,
                                                                              ) {
                                                                                return AlertDialog(
                                                                                  title: Icon(
                                                                                    Icons.close,
                                                                                    color: Colors.red,
                                                                                    size: 40,
                                                                                  ),
                                                                                  content: const Text(
                                                                                    "Votre paiement n'est pas valide , merci de vérifier votre Sms que vous avez coller, pour en envoyer un nouveau clicker sur | Cliquez ici pour initier le payement |",
                                                                                  ),
                                                                                );
                                                                              },
                                                                        );
                                                                      }
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop();
                                                                      setState(() {
                                                                        ussdAlreadylaunched =
                                                                            true;
                                                                      });
                                                                    },
                                                                    child: Text(
                                                                      "OK",
                                                                      style: GoogleFonts.poppins(
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
                                                      // Extraction échouée
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Erreur : impossible d'extraire la référence ou le montant.",
                                                          ),
                                                          duration: Duration(
                                                            seconds: 2,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: const Text(
                                                    "Envoyer",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                },
                              );
                            }
                          },
                          child: Text(
                            "💸 Cliquez ici pour initier le payement 📲",
                            style: GoogleFonts.poppins(
                              color: Colors.teal,
                              fontSize: size.width > 400 ? 18 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      SizedBox(height: size.height > 800 ? 25 : 20),
                      if (canProceedToSendCommande == true)
                        // 🔘 Bouton de validation
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: Size(
                              double.infinity,
                              size.height > 800 ? 50 : 40,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () => envoyerInfosAuServeur(context),
                          icon: isLoading
                              ? SizedBox(
                                  width: size.width > 400 ? 24 : 18,
                                  height: size.height > 800 ? 24 : 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: size.width > 400 ? 2 : 1,
                                  ),
                                )
                              : const Icon(Icons.check, color: Colors.white),
                          label: isLoading
                              ? Text(
                                  "Patientez...",
                                  style: TextStyle(
                                    fontSize: size.width > 400 ? 18 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  "Confirmer la commande",
                                  style: TextStyle(
                                    fontSize: size.width > 400 ? 18 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),

                      if (canProceedToSendCommande == false)
                        // 🔘 Bouton de validation
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: Size(
                              double.infinity,
                              size.height > 800 ? 50 : 40,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: null,
                          icon: const Icon(Icons.close),
                          label: Text(
                            "Impossible de valider la commande",
                            style: TextStyle(
                              fontSize: size.width > 400 ? 18 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
