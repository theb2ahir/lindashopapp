// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/profil/editprofil/editprofile.dart';
import 'package:lindashopp/notifucation_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

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
    total = getTotalPrice();
    final totalString = total.toInt().toString();
    ussdCodes.addAll({
      'Moov': "*155*1*1*96368151*96368151*$totalString*1#",
      'Yas': "*145*1*$totalString*92349698*1#",
    });
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

  void showCommandeDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Text(
                  "Récapitulatif de la commande , veuillez faire une capture d'ecran de ces informations",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.commandes.length,
                    itemBuilder: (context, index) {
                      final item = widget.commandes[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['productImageUrl'] ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image),
                            ),
                          ),
                          title: Text(
                            item['productname'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quantité : ${item['quantity']}x ${item['productprice']}",
                              ),
                              const SizedBox(height: 3),
                              Text("transation id : $transactionId"),
                              Text("Réf: ${referenceController.text.trim()}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "id de transaction : $transactionId",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Total : $total FCFA",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 7),
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
              'reference': referenceController.text.trim(),
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
          "lati": lati,
          "longi": longi,
          'transactionId': transactionId,
          'ref': referenceController.text.trim(),
          "UsereReseau": reseauChoisi,
          "prixTotal": total,
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
          title: "Achat réussi 🎉",
          message:
              "Merci pour vos achats , vous serez livré dans les plus brefs délais !",
        );
        showCommandeDialog();
      }

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
    int livraisonsPayantes = widget.commandes
        .where((item) => item['livraison'] != 'true')
        .length;

    double fraisLivraison = livraisonsPayantes * 2000;
    double totalGeneral = total + fraisLivraison;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Valider mon panier",
          style: const TextStyle(
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['quantity']} x ${item['productprice']} FCFA',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
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
                            const Text(
                              "Facture",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total panier"),
                                Text(
                                  "$total FCFA", // ← total panier
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Frais de livraison"),
                                Text(
                                  "${fraisLivraison.toStringAsFixed(0)} FCFA",
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  "${totalGeneral.toStringAsFixed(0)} FCFA",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🟢 Réseaux (checkboxes)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Choisir le réseau",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
                          if (reseauChoisi != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: TextButton(
                                onPressed: () {
                                  lancerUSSD(ussdCodes[reseauChoisi]!);
                                },
                                child: Text(
                                  "Clicker sur ce text pour lancer le code USSD et ensuite entrer la référence fournie par l'opérateur",
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

                      // 🧾 Référence opérateur
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Entrer ici la référence fournie par l'opérateur :",
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: referenceController,
                            decoration: InputDecoration(
                              labelText: 'Référence...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 🔘 Bouton de validation
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => envoyerInfosAuServeur(context),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
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
