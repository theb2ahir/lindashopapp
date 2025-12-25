// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lindashopp/core/widgets/customtextfields.dart';

class NonLivre extends StatefulWidget {
  const NonLivre({super.key});

  @override
  State<NonLivre> createState() => _NonLivreState();
}

class _NonLivreState extends State<NonLivre> {
  final _formKey = GlobalKey<FormState>();
  //  creer un list de commande non livrer

  List<String> nonLivrerList = [];
  bool cocher = false;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController refController = TextEditingController();
  final TextEditingController transactionIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
  }

  /// 🔹 Préremplit les champs avec les infos de l'utilisateur connecté
  Future<void> _prefillUserInfo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          nameController.text = data['name'] ?? '';
          phoneController.text = data['phone'] ?? '';
          emailController.text = data['email'] ?? user.email ?? '';
        });
      } else {
        // Si pas de document, on met au moins l'email du compte Firebase
        emailController.text = user.email ?? '';
      }
    } catch (e) {
      debugPrint('Erreur lors du préremplissage : $e');
    }
  }

  /// 🔹 Envoie la requête à Firestore
  Future<void> submitToFirestore() async {
    try {
      setState(() => isLoading = true);

      await _firestore.collection('NonLivree').add({
        'NlivreName': nameController.text.trim(),
        'NlivrePrenom': nameController.text.trim(),
        'NlivreEmail': emailController.text.trim(),
        'NlivrePhone': phoneController.text.trim(),
        'userId': _auth.currentUser?.uid,
        'NlivreQrJson': nonLivrerList,
        'NlivreStamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF02204B),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.lightGreenAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Requête envoyée avec succès !',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );

      // Réinitialisation du formulaire
      _formKey.currentState?.reset();
      nameController.clear();
      phoneController.clear();
      refController.clear();
      transactionIdController.clear();
      emailController.clear();
      messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent.shade400,
          content: Text(
            'Erreur : $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Commande non livrée",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFFE8F0FE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "📝 Formulaire de commande non livrer , vérifier vos informations ( nom , tel et email ) et cocher les commandes qui ne vous ont pas encore été livrées",
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Form(
              key: _formKey,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color.fromARGB(59, 200, 199, 199)
                      : Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                child: Column(
                  children: [
                    CustomTextField(controller: nameController, label: "Nom"),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: phoneController,
                      label: "Téléphone",
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: emailController,
                      label: "Email",
                    ),

                    const SizedBox(height: 40),

                    //liste des commandes, pour pouvoir les cocher en cas de non livraison
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('acr')
                          .orderBy('date', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Erreur de chargement'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Aucune commande trouvée',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 260,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              itemCount: docs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                final imageUrl = data['imageUrl'] ?? '';
                                final qr = data['Qrjson'] ?? '';
                                final name = data['productname'] ?? '';
                                final quantity = data['quantity'] ?? '';
                                final price = data['productprice'] ?? '';
                                final timestamp = data['date'] as Timestamp?;
                                final date = timestamp?.toDate();

                                final isChecked = nonLivrerList.contains(qr);

                                return Container(
                                  width: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black.withValues(
                                                alpha: 0.05,
                                              )
                                            : Colors.white,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // IMAGE
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                height: 120,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                height: 120,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 40,
                                                ),
                                              ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // NOM + CHECK
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: Icon(
                                                    isChecked
                                                        ? Icons.check_box
                                                        : Icons
                                                              .check_box_outline_blank,
                                                    color: isChecked
                                                        ? Colors.green
                                                        : Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (isChecked) {
                                                        nonLivrerList.remove(
                                                          qr,
                                                        );
                                                      } else {
                                                        nonLivrerList.add(qr);
                                                      }
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 6),

                                            Text(
                                              '$quantity × $price FCFA',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            Text(
                                              date != null
                                                  ? DateFormat(
                                                      'dd/MM/yy HH:mm',
                                                    ).format(date)
                                                  : 'Date inconnue',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  submitToFirestore();
                                }
                              },
                        icon: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          isLoading ? "Envoi en cours..." : "Envoyer",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF02204B),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
