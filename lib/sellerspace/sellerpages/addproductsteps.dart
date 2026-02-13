// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lindashopp/features/pages/acceuilpage.dart';
import 'package:lindashopp/features/pages/utils/getadminfcmtoken.dart';
import 'package:lindashopp/features/pages/utils/sendnotif.dart';

class AddProductSteps extends StatefulWidget {
  const AddProductSteps({super.key});

  @override
  State<AddProductSteps> createState() => _AddProductStepsState();
}

class _AddProductStepsState extends State<AddProductSteps> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pccsController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _pourcentageController = TextEditingController();

  bool _ndpSaved = false;
  bool _pccsSaved = false;

  File? _imageFile;
  String productname = "";
  String description = "";
  String pccs = "";
  double price = 0;
  double pourcentage = 0;
  List<String> avantages = [];
  List<String> caracteristiques = [];
  List<String> contenuPaquet = [];
  bool _livraison = true;
  String _collectionName = 'construction';

  String sellerId = '';
  String role = "";
  String username = "";
  bool audone = false;
  bool ctdone = false;
  bool cpdone = false;
  bool loading = false;
  // 🔹 Variables
  int nbrajouts = 0;
  String subscription = "";

  String _adminToken = "";
  @override
  void initState() {
    super.initState();
    getUserData();
    getToken();
  }

  // 🔹 Fonction pour savoir si deux dates sont le même jour
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 🔹 Récupérer les infos utilisateur et reset journalier
  Future<void> getUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final Timestamp? lastAddTs = doc.data()!['lastAddDate'];
    final DateTime now = DateTime.now();

    int newCount = doc.data()!['nbrajouts'] ?? 0;

    // Reset journalier si la dernière ajout date d'un autre jour
    if (lastAddTs != null) {
      final lastDate = lastAddTs.toDate();
      if (!isSameDay(lastDate, now)) {
        newCount = 0;
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'nbrajouts': 0, // reset côté Firestore
        });
      }
    }

    setState(() {
      role = doc.data()!['role'];
      username = doc.data()!['name'];
      sellerId = uid;
      nbrajouts = newCount;
      subscription = doc.data()!['subscription'];
    });
  }

  Future<void> getToken() async {
    final token = await getAdminToken();
    if (token != null) {
      setState(() {
        _adminToken = token;
      });
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _saveNDPinfo() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _prixController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner tous les champs')),
      );
      return;
    }

    setState(() {
      productname = _nameController.text.trim();
      description = _descriptionController.text.trim();
      price = double.tryParse(_prixController.text) ?? 0;
      _ndpSaved = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('info enregistrée')));
  }

  Future<void> _savePCCSPinfo() async {
    if (_pccsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner tous les champs')),
      );
      return;
    }

    setState(() {
      pccs = _pccsController.text.trim();
      pourcentage = double.tryParse(_pourcentageController.text) ?? 0;
      _pccsSaved = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('info enregistrée')));
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImageToCloudinary(File file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dccsqxaxu/upload');
    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['upload_preset'] = 'baahir';

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Échec de l\'upload de l\'image');
    }

    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);
    return data['secure_url'];
  }

  Future<void> _addProduct() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une image')),
      );
      return;
    }
    if (productname == "" ||
        description == "" ||
        price == 0 ||
        pccs == "" ||
        avantages.isEmpty ||
        caracteristiques.isEmpty ||
        contenuPaquet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => loading = true);
    int newCount = nbrajouts + 1;
    String imageURL;
    try {
      imageURL = await _uploadImageToCloudinary(_imageFile!);

      final product = {
        'name': productname,
        'description': description,
        'imageURL': imageURL,
        'pccs': pccs,
        'prix': price,
        'pourcentage': pourcentage,
        'au': avantages,
        'cp': contenuPaquet,
        'ct': caracteristiques,
        'avis': [],
        'livraison': _livraison,
        'collectionName': _collectionName,
        'statut': "en attente",
        'timestamp': FieldValue.serverTimestamp(),
        'sellerid': sellerId,
      };

      await FirebaseFirestore.instance.collection('reviewproduct').add(product);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit envoyer avec succès !')),
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'nbrajouts': newCount,
        'lastAddDate': FieldValue.serverTimestamp(),
      });

      await sendNotification(
        _adminToken,
        "Produit",
        "$username a envoyé un produit pour la validation",
      );

      setState(() {
        nbrajouts = newCount;
        _imageFile = null;
        _nameController.clear();
        productname = "";
        _descriptionController.clear();
        description = "";
        _pccsController.clear();
        pccs = "";
        _prixController.clear();
        price = 0;
        _pourcentageController.clear();
        pourcentage = 0;
        _livraison = true;
        avantages = [];
        caracteristiques = [];
        contenuPaquet = [];
        cpdone = false;
        ctdone = false;
        audone = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de l ajout : $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required int maxlines,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return TextFormField(
      maxLines: maxlines,
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
      ),
      validator: (v) => isRequired && v!.isEmpty ? 'Champ requis' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AcceuilPage()),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IntroductionScreen(
              pages: [
                // texte et design accrocheur pour demarrer l'ajout du produit
                PageViewModel(
                  titleWidget: SafeArea(
                    child: Column(
                      children: [
                        Text(
                          "Ajouter un produit",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  bodyWidget: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          "Ajouter un produit a votre boutique en toute simpliciter en suivant les étapes ci apres ✅ (6 étapes)",
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),

                        const SizedBox(height: 30),

                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: const [
                              StepInstructionTile(
                                step: 1,
                                title: "Choisir une image",
                                description:
                                    "Ajoutez une image claire et attrayante du produit.",
                              ),
                              SizedBox(height: 20),
                              StepInstructionTile(
                                step: 2,
                                title: "Informations du produit",
                                description:
                                    "Renseignez le nom, la description et le prix du produit.",
                              ),
                              SizedBox(height: 20),
                              StepInstructionTile(
                                step: 3,
                                title: "Mise en avant & promotion",
                                description:
                                    "Expliquez pourquoi choisir ce produit et indiquez le pourcentage de promotion si applicable.",
                              ),
                              SizedBox(height: 20),
                              StepInstructionTile(
                                step: 4,
                                title: "Détails du produit",
                                description:
                                    "Ajoutez les avantages utilisations, caractéristiques techniques et le contenu du paquet. ces informations ont un impact significatif lors de la recherche des produits par les clients.",
                              ),
                              SizedBox(height: 20),
                              StepInstructionTile(
                                step: 5,
                                title: "Catégorie & livraison",
                                description:
                                    "Choisissez la catégorie du produit et activez le bouton pour une livraison gratuite et désactivez le pour une livraison payante.",
                              ),
                              SizedBox(height: 20),
                              StepInstructionTile(
                                step: 6,
                                title: "Aperçu & validation",
                                description:
                                    "Vérifiez toutes les informations avant de valider et publier le produit.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // choisir une image
                PageViewModel(
                  titleWidget: SafeArea(
                    child: Column(
                      children: [
                        Text(
                          "Choisir une image",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  bodyWidget: Column(
                    children: [
                      Text(
                        "Choisissez une image claire et attrayante du produit.",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 30),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color.fromARGB(54, 245, 245, 245)
                                  : Colors.grey.shade300,
                            ),
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : Center(
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color.fromARGB(
                                                  54,
                                                  245,
                                                  245,
                                                  245,
                                                )
                                              : Colors.grey.shade300,
                                          border: Border.all(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add_a_photo),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Ajouter une image",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (_imageFile != null)
                        NextStepHint(
                          nextStepText:
                              "Prochaine étape : nom du produit, description et prix",
                        ),
                    ],
                  ),
                ),

                // ajouter nom , description et prix
                PageViewModel(
                  titleWidget: SafeArea(
                    child: Column(
                      children: [
                        Text(
                          "Ajouter les informations primaires du produit",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  bodyWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Renseignez le nom, la description et le prix du produit.",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildTextField(
                                  hintText: 'Le nom du produit',
                                  maxlines: 1,
                                  controller: _nameController,
                                  label: 'Nom du produit',
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  hintText: 'Une description de votre produit',
                                  maxlines: 3,
                                  controller: _descriptionController,
                                  label: 'Description',
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  hintText: 'Le prix du produit',
                                  maxlines: 1,
                                  controller: _prixController,
                                  label: 'Prix',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      if (_ndpSaved == false)
                        ElevatedButton(
                          onPressed: _saveNDPinfo,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            elevation: 2,
                          ),
                          child: const Text(
                            ' Enregistrer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (productname.isNotEmpty &&
                          description.isNotEmpty &&
                          price != 0)
                        NextStepHint(
                          nextStepText:
                              "Prochaine étape : pourquoi choisir ce produit et le pourcentage si sujette a une promotion",
                        ),
                    ],
                  ),
                ),

                // pourquoi choisir ce produit et le pourcentage si sujette a une promotion
                PageViewModel(
                  titleWidget: SafeArea(
                    child: Column(
                      children: [
                        Text(
                          "Dites à vos clients pourquoi ils doivent choisir ce produit",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  bodyWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "en suite Renseignez le pourcentage ce produit est sujette a une promotion.",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const SizedBox(height: 23),
                                _buildTextField(
                                  hintText:
                                      'Dites leurs pourquoi choisir ce produit',
                                  maxlines: 2,
                                  controller: _pccsController,
                                  label: 'PCCS',
                                ),
                                const SizedBox(height: 33),
                                _buildTextField(
                                  hintText: "Le pourcentage de la remise",
                                  maxlines: 1,
                                  controller: _pourcentageController,
                                  label: 'Pourcentage',
                                  keyboardType: TextInputType.number,
                                  isRequired: false,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "*Remplire se champ uniquement si le produit ci apres est sujette a une promotion",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),

                                const SizedBox(height: 35),
                                if (_pccsSaved == false)
                                  ElevatedButton(
                                    onPressed: _savePCCSPinfo,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 32,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      backgroundColor:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                      foregroundColor:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.black
                                          : Colors.white,
                                      elevation: 2,
                                    ),
                                    child: const Text(
                                      ' Enregistrer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 34),

                                if (pccs.isNotEmpty)
                                  NextStepHint(
                                    nextStepText:
                                        "Prochaine étape : ajouter les avantages et utilisations, caractéristiques techniques et le contenu du paquet",
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ajouter avantages_utilisations  , caracteristiques_techniques et contenu_du_paquet
                PageViewModel(
                  titleWidget: SafeArea(
                    child: Column(
                      children: [
                        Text(
                          "Renseignez les avantages utilisations , caractéristiques techniques et contenu du paquet du produit",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  bodyWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Ajouter au moins 3 infromations chacune afin d'avoir un bon aperçu du produit et capter le plus de clients possible.",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 30),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                // Bouton pour ajouter des avantages
                                ElevatedButton(
                                  onPressed: () async {
                                    final result = await showModalBottomSheet<String>(
                                      context: context,
                                      isScrollControlled:
                                          true, // permet d'avoir le clavier visible
                                      builder: (context) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(
                                            context,
                                          ).viewInsets.bottom,
                                        ),
                                        child: SimpleListAdder(
                                          title:
                                              "Ajouter des avantages et utilisations",
                                          list: [],
                                          onValidate: (val) {
                                            setState(() {
                                              audone = true;
                                            });
                                            Navigator.pop(context, val);
                                          },
                                        ),
                                      ),
                                    );

                                    if (result != null && result.isNotEmpty) {
                                      setState(() {
                                        avantages.addAll(result.split(', '));
                                      });
                                    }
                                  },

                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all(
                                      const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 32,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "${audone ? "✅" : "❌"}  Ajouter les avantages et utilisations",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Bouton pour caractéristiques techniques
                                ElevatedButton(
                                  onPressed: () async {
                                    final result =
                                        await showModalBottomSheet<String>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) => Padding(
                                            padding: EdgeInsets.only(
                                              bottom: MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom,
                                            ),
                                            child: SimpleListAdder(
                                              title:
                                                  "Ajouter des caractéristiques techniques",
                                              list: [],
                                              onValidate: (val) {
                                                setState(() {
                                                  ctdone = true;
                                                });
                                                Navigator.pop(context, val);
                                              },
                                            ),
                                          ),
                                        );

                                    if (result != null && result.isNotEmpty) {
                                      setState(() {
                                        caracteristiques.addAll(
                                          result.split(', '),
                                        );
                                      });
                                    }
                                  },
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all(
                                      const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 32,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "${ctdone ? "✅" : "❌"} Ajouter les caractéristiques techniques",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Bouton pour contenu du paquet
                                ElevatedButton(
                                  onPressed: () async {
                                    final result =
                                        await showModalBottomSheet<String>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) => Padding(
                                            padding: EdgeInsets.only(
                                              bottom: MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom,
                                            ),
                                            child: SimpleListAdder(
                                              title:
                                                  "Ajouter contenu du paquet",
                                              list: [],
                                              onValidate: (val) {
                                                setState(() {
                                                  cpdone = true;
                                                });
                                                Navigator.pop(context, val);
                                              },
                                            ),
                                          ),
                                        );

                                    if (result != null && result.isNotEmpty) {
                                      setState(() {
                                        contenuPaquet.addAll(
                                          result.split(', '),
                                        );
                                      });
                                    }
                                  },
                                  style: ButtonStyle(
                                    padding: WidgetStateProperty.all(
                                      const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 32,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "${cpdone ? "✅" : "❌"} Ajouter les données du contenu du paquet",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      if (audone == true && ctdone == true && cpdone == true)
                        NextStepHint(
                          nextStepText:
                              "Prochaine étape : choisir la catégorie du produit et activez le bouton pour une livraison gratuite et désactivez le pour une livraison payante",
                        ),
                    ],
                  ),
                ),

                // choisir la catégorie du produit et toggle la livraison
                PageViewModel(
                  titleWidget: SafeArea(
                    child: Column(
                      children: [
                        Text(
                          "Choisissez la catégorie de votre produit",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  bodyWidget: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Activer le bouton pour une livraison gratuite et désactivez le pour une livraison payante",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 30),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const SizedBox(height: 26),
                            Text(
                              'Livraison ?( ${_livraison ? "Gratuite" : "Payante"} )',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            SwitchListTile(
                              title: const Text('Livraison'),
                              value: _livraison,
                              onChanged: (v) => setState(() => _livraison = v),
                            ),
                            const SizedBox(height: 33),
                            Text(
                              'Choisissez la catégorie de votre produit',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _collectionName,
                              decoration: const InputDecoration(
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(25),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'construction',
                                  child: Text('Construction'),
                                ),
                                DropdownMenuItem(
                                  value: 'electronique',
                                  child: Text('Electronique'),
                                ),
                                DropdownMenuItem(
                                  value: 'fring',
                                  child: Text('Habillement'),
                                ),
                                DropdownMenuItem(
                                  value: 'promotions',
                                  child: Text('Promotions'),
                                ),
                                DropdownMenuItem(
                                  value: 'produit-mode-et-enfant',
                                  child: Text('Mode & Enfant'),
                                ),
                                DropdownMenuItem(
                                  value: 'produit-sport-et-bien-etre',
                                  child: Text('Sport & Bien-être'),
                                ),
                                DropdownMenuItem(
                                  value: 'produit-électro-ménagé',
                                  child: Text('Électro-ménagé'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _collectionName = v!),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 34),
                      if (_livraison && _collectionName != '')
                        NextStepHint(
                          nextStepText:
                              "Prochaine étape : verifiez toutes les informations et soumettre a la validation par l'equipe de Linda Shop",
                        ),
                    ],
                  ),
                ),

                // preview du produit et valider
                PageViewModel(
                  titleWidget: SafeArea(
                    child: Column(
                      children: [
                        Text(
                          "Aperçu du produit",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  bodyWidget: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          "Vérifiez les informations avant publication",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// 🖼️ IMAGE PRODUIT
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            height: 240,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color.fromARGB(54, 245, 245, 245)
                                : Colors.grey.shade300,
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : const Icon(Icons.image, size: 80),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// 🏷️ NOM + PRIX
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                productname.isEmpty
                                    ? "Nom du produit"
                                    : productname,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              "${price.toStringAsFixed(0)} FCFA",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.indigo[900],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        /// 📦 COLLECTION
                        Text(
                          "Catégorie : $_collectionName",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// 🧾 DESCRIPTION
                        _PreviewSection(
                          title: "Description",
                          child: Text(
                            description.isEmpty
                                ? "Aucune description"
                                : description,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),

                        /// ⭐ AVANTAGES
                        if (avantages.isNotEmpty)
                          _PreviewSection(
                            title: "Avantages",
                            child: Column(
                              children: avantages
                                  .map((e) => _BulletText(text: e))
                                  .toList(),
                            ),
                          ),

                        /// ⚙️ CARACTÉRISTIQUES
                        if (caracteristiques.isNotEmpty)
                          _PreviewSection(
                            title: "Caractéristiques",
                            child: Column(
                              children: caracteristiques
                                  .map((e) => _BulletText(text: e))
                                  .toList(),
                            ),
                          ),

                        /// 📦 CONTENU DU PAQUET
                        if (contenuPaquet.isNotEmpty)
                          _PreviewSection(
                            title: "Contenu du paquet",
                            child: Column(
                              children: contenuPaquet
                                  .map((e) => _BulletText(text: e))
                                  .toList(),
                            ),
                          ),

                        /// 🚚 LIVRAISON
                        _PreviewSection(
                          title: "Livraison",
                          child: Row(
                            children: [
                              Icon(
                                _livraison ? Icons.check_circle : Icons.cancel,
                                color: _livraison ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _livraison
                                    ? "Livraison payante"
                                    : "Livraison gratuite",
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// 👉 PROCHAINE ÉTAPE
                        NextStepHint(
                          nextStepText:
                              "Si tout est correct, cliquez sur Terminer",
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // ------------- BOUTONS -------------
              skip: Text(
                "Passer",
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              back: Icon(
                Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.indigo[900],
              ),
              next: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.indigo[900],
              ),
              done: Text(
                "Terminer",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.indigo[900],
                ),
              ),

              onDone: () async {
                if (subscription == "PREMIUM") {
                  await _addProduct();
                } else if (subscription == "STANDARD") {
                  if (nbrajouts < 15) {
                    await _addProduct();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Vous avez atteint le nombre maximum de 15 produits par jour",
                        ),
                      ),
                    );
                  }
                }
              },
              dotsDecorator: DotsDecorator(
                activeColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.indigo[900],
                color: Colors.indigo[900]!.withValues(alpha: 0.3),
                size: const Size(3, 3),
                activeSize: const Size(6, 6),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),

            if (loading)
              const FullScreenLoader(message: "Envoie du produit en cours..."),
          ],
        ),
      ),
    );
  }
}

class StepInstructionTile extends StatelessWidget {
  final int step;
  final String title;
  final String description;

  const StepInstructionTile({
    super.key,
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numéro
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Texte
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(description, style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class NextStepHint extends StatelessWidget {
  final String nextStepText; // texte à afficher

  const NextStepHint({super.key, required this.nextStepText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_forward, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nextStepText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleListAdder extends StatefulWidget {
  final String title;
  final List<String> list;
  final Function(String)? onValidate;

  const SimpleListAdder({
    super.key,
    required this.title,
    required this.list,
    this.onValidate,
  });

  @override
  State<SimpleListAdder> createState() => _SimpleListAdderState();
}

class _SimpleListAdderState extends State<SimpleListAdder> {
  final TextEditingController _controller = TextEditingController();

  void _addItem() {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    // Supprimer les virgules
    text = text.replaceAll(',', '');

    setState(() {
      widget.list.add(text);
      _controller.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      widget.list.removeAt(index);
    });
  }

  void _validate() {
    final result = widget.list.join(', ');

    if (widget.onValidate != null) {
      widget.onValidate!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ecrire ici",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(19)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.green,
                    size: 30,
                  ),
                  onPressed: _addItem,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (widget.list.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: widget.list.length,
                itemBuilder: (_, index) {
                  return ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(widget.list[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeItem(index),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          Text(
            "${widget.list.length} élément(s) ajouté(s)",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _validate, child: const Text("Valider")),
        ],
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _PreviewSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromARGB(54, 245, 245, 245)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• "),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14))),
        ],
      ),
    );
  }
}

class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
