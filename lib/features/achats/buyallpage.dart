// ignore_for_file: use_build_context_synchronously, deprecated_member_use

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
  final TextEditingController referenceController = TextEditingController();
  int total = 0;
  int totalGeneral = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    transactionId = generateTransactionId();
    final total = getTotalPrice();

    bool aLivraisonPayante = widget.commandes.any(
      (item) => item['livraison'] != 'true',
    );

    double fraisLivraison = aLivraisonPayante ? 2000 : 0;

    double totalGenerale = total + fraisLivraison;

    final totalGeneralString = totalGenerale.toInt().toString();

    setState(() {
      totalGeneral = totalGenerale.toInt();
    });

    ussdCodes.addAll({
      'Moov': "*155*1*1*96368151*96368151*$totalGeneralString*1#",
      'Yas': "*145*1*$totalGeneralString*92349698*1#",
    });
  }

  bool _permissionChecked = false;
  String reference = "";

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
                const Text(
                  "Faites une capture d'écran de ce Qr code , le livreur en aura besoin pour valider votre commande",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                /// 🔥 QR CODE ICI
                QrImageView(
                  data: qrJson,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),

                const SizedBox(height: 20),

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
                  onPressed: () => Navigator.pop(context),
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
        DocumentReference acrRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('acr')
            .add({
              'imageUrl': item['productImageUrl'],
              'productname': item['productname'],
              'quantity': item['quantity'],
              'productprice': item['productprice'],
              'reference': reference,
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
          "lati": lati,
          "longi": longi,
          'transactionId': transactionId,
          'ref': reference,
          "UsereReseau": reseauChoisi,
          "prixTotal": totalGeneral,
          "acrid": acrId,
          "userid": userid,
          'timestamp': DateTime.now(),
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

        NotificationService.showNotification(
          title: "Paiement effectué",
          body:
              "Vos commandes ont été enregistrées avec succès, nous allons verifier votre paiement et modifier le statut en consequence , rendez-vous sur la page commande",
        );
        showCommandeDialog();
      }

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
            fontSize: 25,
            color: Colors.black,
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
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ListView.builder(
                    itemCount: widget.commandes.length,
                    itemBuilder: (context, index) {
                      final item = widget.commandes[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey,
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
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['productname'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['quantity']} x ${item['productprice']} FCFA',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: (item['livraison'] == 'true')
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      '${(int.tryParse(item['productprice'].toString()) ?? 0) * (int.tryParse(item['quantity'].toString()) ?? 0)} FCFA',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black,
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

                const SizedBox(height: 16),
                const SizedBox(height: 16),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
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
                                fontSize: 19,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total panier",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "$total FCFA",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black,
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
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "${fraisLivraison.toStringAsFixed(0)} FCFA",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Reference de paiement",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  reference,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total",
                                  style: GoogleFonts.poppins(
                                    fontSize: 19,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${totalGeneral.toStringAsFixed(0)} FCFA",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

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
                            const SizedBox(width: 16),
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
                      const SizedBox(height: 16),
                      if (reseauChoisi != null)
                        TextButton(
                          onPressed: () {
                            lancerUSSD(ussdCodes[reseauChoisi]!);
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              // L'utilisateur doit envoyer la référence
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
                                          "Entrer la référence",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: referenceController,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Référence fournie par l’opérateur',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                            ),
                                            onPressed: () {
                                              if (referenceController
                                                  .text
                                                  .isNotEmpty) {
                                                Navigator.of(context).pop();
                                                setState(() {
                                                  reference =
                                                      referenceController.text
                                                          .trim();
                                                }); // Ferme le premier popup

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
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            "Référence enregistrée ✅",
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
                                                            "Votre référence a été enregistrée ,rendez-vous sur la page commande pour suivre votre commande.",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 24,
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                double.infinity,
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
                                                                      vertical:
                                                                          14,
                                                                    ),
                                                              ),
                                                              onPressed: () {
                                                                Navigator.of(
                                                                  context,
                                                                ).pop();
                                                                // Ferme le dialogue
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
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Veuillez entrer la référence.",
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
                          },
                          child: Text(
                            "💸 Cliquez ici pour initier le payement 📲",
                            style: GoogleFonts.poppins(
                              color: Colors.teal,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 25),

                      // 🔘 Bouton de validation
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () => envoyerInfosAuServeur(context),
                        icon: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check, color: Colors.white),
                        label: isLoading
                            ? const Text(
                                "Patientez...",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Confirmer la commande",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
