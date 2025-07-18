// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    transactionId = generateTransactionId();
    total = getTotalPrice(); // ← Initialisation ici
    ussdCodes.addAll({
      'Moov': "*155*1*1*96368151*96368151*$total*1#",
      'Yas': "*145*1*$total*92349698*1#",
    });
  }

  void lancerUSSD(String codeUSSD) async {
    final String encoded = codeUSSD
        .replaceAll('*', Uri.encodeComponent('*'))
        .replaceAll('#', Uri.encodeComponent('#'));
    final Uri ussdUri = Uri.parse("tel:$encoded");

    if (await canLaunchUrl(ussdUri)) {
      await launchUrl(ussdUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Impossible de lancer le code USSD. Vérifiez les permissions ou testez sur un vrai téléphone.",
          ),
        ),
      );
    }
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
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Utilisateur non connecté")));
      return;
    }

    if (reseauChoisi == null || referenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez choisir un réseau et entrer la référence."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final infouserRef = FirebaseFirestore.instance.collection('infouser');

    try {
      for (var item in widget.commandes) {
        final userAdresse = item['addressLivraison'];
        final productprice = item['productprice'];
        final nomberitem = item['quantity'];
        final livraison = item['livraison'];
        final productname = item['productname'];
        final useremail = item['email'];
        final userephone = item['phone'];
        final usernamemiff = item['username'];
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
              'reference': referenceController.text.trim(),
              'status': 'en verification',
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
          "lati": lati, 
          "longi": longi,
          'transactionId': transactionId,
          'ref': referenceController.text.trim(),
          "UserReseau": reseauChoisi,
          "prixTotal": total,
          "acrid": acrId,
          "userid": userid,
          'timestamp': DateTime.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Commande enregistrée avec succès !"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = getTotalPrice();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Valider mon panier", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
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
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['productImageUrl'] ?? '',
                                height:80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(item['productname'] ?? 'Produit', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                            subtitle: Text(
                              '${item['quantity']} * ${item['productprice']} FCFA',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Choisissez votre réseau et lancez le code USSD :",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text("Moov"),
                      value: reseauChoisi == "Moov",
                      onChanged: (value) {
                        setState(() {
                          reseauChoisi = value! ? "Moov" : null;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text("Yas"),
                      value: reseauChoisi == "Yas",
                      onChanged: (value) {
                        setState(() {
                          reseauChoisi = value! ? "Yas" : null;
                        });
                      },
                    ),

                    // Affichage du code USSD
                    if (reseauChoisi != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextButton(
                          onPressed: () {
                            lancerUSSD(ussdCodes[reseauChoisi]!);
                          },
                          child: Text(
                            "Lancer le code USSD",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Référence de paiement
                Row(
                  children: [
                    const Text("Référence fournie par l'opérateur : "),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: referenceController,
                        decoration: InputDecoration(
                          labelText: 'reference ......',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  '💰$total FCFA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () => envoyerInfosAuServeur(context),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    "Valider le panier",
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
        ),
      ),
    );
  }
}
