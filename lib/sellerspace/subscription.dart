// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/pages/profil/profil.dart';
import 'package:lindashopp/sellerspace/selleracceuil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Abonnements",
          style: GoogleFonts.poppins(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Choisissez le forfait adapté à votre activité",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                children: const [
                  SubscriptionCard(
                    title: "STANDARD",
                    price: 1500,
                    description:
                        "Idéal pour débuter sur Linda Shop / payement mensuel",
                    features: [
                      "15 produits par jour",
                      "Gestion des commandes",
                      "Tableau de bord vendeur",
                      "Support standard (48h)",
                    ],
                    color: Colors.indigo,
                    isPopular: false,
                  ),
                  SizedBox(height: 16),
                  SubscriptionCard(
                    title: "PREMIUM",
                    price: 4000,
                    description:
                        "Pour les vendeurs professionnels / payement mensuel",
                    features: [
                      "Produits illimités",
                      "Produits mis en avant",
                      "Statistiques avancées",
                      "Priorité dans la recherche",
                      "Support prioritaire (24h)",
                    ],
                    color: Colors.amber,
                    isPopular: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionCard extends StatefulWidget {
  const SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.features,
    required this.color,
    required this.isPopular,
  });

  final String title;
  final int price;
  final String description;
  final List<String> features;
  final Color color;
  final bool isPopular;

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  TextEditingController smsController = TextEditingController();
  final endedAt = DateTime.now().add(const Duration(days: 30));
  final dateaujourdhui = DateTime.now();

  int suffixeActuel = 0;
  String sms = "";
  String souscription = "";
  bool _permissionChecked = false;
  bool canProceed = false;
  bool good = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final suffixe = suffixeAdeuxChiffresAleatoire();
    setState(() {
      suffixeActuel = suffixe;
    });
  }

  // fonction pour update les champs firestore du user
  Future<void> updateUserDataForGood(
    String subscription,
    int montantpayer,
  ) async {
    // fini dans 1 mois
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'subscribed': true,
      'subscription': subscription,
      'startedAt': dateaujourdhui,
      'endedAt': endedAt,
      'amountPaid': montantpayer,
      'sellerid': uid,
      'role': "seller",
      'datePaid': DateTime.now(),
    });
  }

  Future<void> updateUserDataForBad() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'subscribed': false,
    });
  }

  suffixeAdeuxChiffresAleatoire() {
    final random = Random();
    final int suffixe = 10 + random.nextInt(90); // 10 → 99
    return suffixe;
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

  _checkPayment() {
    setState(() => loading = true);
    final montantSms = extraireMontant(sms);
    // recuperer les deux derniers chiffres du montant
    final montantSuffixe = montantSms! % 100;

    if (suffixeActuel != montantSuffixe) {
      setState(() {
        good = false;
      });
    }

    if (suffixeActuel == montantSuffixe) {
      setState(() {
        good = true;
      });
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.description),
              const SizedBox(height: 12),

              Text(
                widget.price.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              ...widget.features.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: widget.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          title: Text(
                            "Choisissez un opérateur",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  final somme = widget.price + suffixeActuel;
                                  lancerUSSD(
                                    "*155*1*1*96368151*96368151*$somme*2#",
                                  );
                                  Navigator.of(context).pop();

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                20.0,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Copier et coller le SMS reçu de votre opérateur",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                              duration:
                                                                  Duration(
                                                                    seconds: 2,
                                                                  ),
                                                            ),
                                                          );
                                                          return;
                                                        }

                                                        setState(() {
                                                          sms = smsText;
                                                        });
                                                        Navigator.of(
                                                          context,
                                                        ).pop();

                                                        _checkPayment();

                                                        if (good == true) {
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
                                                                      "Paiement validé ✅",
                                                                      style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          16,
                                                                    ),

                                                                    TextButton(
                                                                      onPressed: () async {
                                                                        await updateUserDataForGood(
                                                                          widget
                                                                              .title,
                                                                          somme,
                                                                        );
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop(); // ferme le premier dialog
                                                                        Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                                SellerAcceuil(),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                        "Fermer",
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );

                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        }

                                                        if (good == false) {
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
                                                                      "Paiement refusé ❌",
                                                                      style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          16,
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () async {
                                                                        await updateUserDataForBad();
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop(); // ferme le premier dialog
                                                                        Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                                Profile(),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                        "Fermer",
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
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
                                },
                                child: Text("Moov"),
                              ),
                              TextButton(
                                onPressed: () {
                                  final somme = widget.price + suffixeActuel;
                                  lancerUSSD("*145*1*$somme*92349698*2#");
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                20.0,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Copier et coller le SMS reçu de votre opérateur",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                              duration:
                                                                  Duration(
                                                                    seconds: 2,
                                                                  ),
                                                            ),
                                                          );
                                                          return;
                                                        }

                                                        setState(() {
                                                          sms = smsText;
                                                        });
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                        // Ferme le premier dialog
                                                        // enlencher la verification du paiement

                                                        _checkPayment();
                                                        // Deuxième popup : confirmation
                                                        if (good == true) {
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
                                                                      "Paiement validé ✅",
                                                                      style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          16,
                                                                    ),

                                                                    TextButton(
                                                                      onPressed: () async {
                                                                        await updateUserDataForGood(
                                                                          widget
                                                                              .title,
                                                                          somme,
                                                                        );
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop(); // ferme le premier dialog
                                                                        Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                                SellerAcceuil(),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                        "Fermer",
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        if (good == false) {
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
                                                                      "Paiement non validé ❌",
                                                                      style: GoogleFonts.poppins(
                                                                        fontSize:
                                                                            18,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          16,
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () async {
                                                                        await updateUserDataForBad();
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop(); // ferme le premier dialog
                                                                        Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                                Profile(),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: Text(
                                                                        "Fermer",
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
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
                                },
                                child: Text("Yas"),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                    // fermer le premier dialog
                  },
                  child: const Text("Choisir ce forfait"),
                ),
              ),
            ],
          ),
        ),

        if (widget.isPopular)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: const Text(
                "POPULAIRE",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
