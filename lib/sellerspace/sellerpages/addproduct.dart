// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class SellerAddProduct extends StatefulWidget {
  const SellerAddProduct({super.key});

  @override
  State<SellerAddProduct> createState() => _SellerAddProductState();
}

class _SellerAddProductState extends State<SellerAddProduct> {
  final _formKey = GlobalKey<FormState>();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pccsController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _pourcentageController = TextEditingController();

  List<String> avantages = [];
  List<String> caracteristiques = [];
  List<String> contenuPaquet = [];

  bool _livraison = true;
  String _collectionName = 'construction';
  File? _imageFile;
  String sellerId = '';
  String role = "";
  String username = "";
  bool audone = false;
  bool ctdone = false;
  bool cpdone = false;

  Future<void> getUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    setState(() {
      role = doc.data()!['role'];
      username = doc.data()!['name'];
      sellerId = uid;
    });
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
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
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une image')),
      );
      return;
    }

    String imageURL;
    try {
      imageURL = await _uploadImageToCloudinary(_imageFile!);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur upload : $e')));
      return;
    }

    final product = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'imageURL': imageURL,
      'pccs': _pccsController.text.trim(),
      'prix': double.tryParse(_prixController.text) ?? 0,
      'pourcentage': double.tryParse(_pourcentageController.text) ?? 0,
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

    try {
      await FirebaseFirestore.instance.collection('reviewproduct').add(product);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit ajouté avec succès !')),
      );

      _formKey.currentState!.reset();
      setState(() => _imageFile = null);
      _nameController.clear();
      _descriptionController.clear();
      _pccsController.clear();
      _prixController.clear();
      _pourcentageController.clear();
      _livraison = true;
      avantages = [];
      caracteristiques = [];
      contenuPaquet = [];
      setState(() {
        cpdone = false;
        ctdone = false;
        audone = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Ajouter un produit',
          style: GoogleFonts.poppins(fontSize: 23, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Informations principales du produit',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hintText: 'Le nom du produit',
                        maxlines: 1,
                        controller: _nameController,
                        label: 'Nom du produit',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hintText: 'Une description de votre produit',
                        maxlines: 3,
                        controller: _descriptionController,
                        label: 'Description',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hintText: 'Dites leurs pourquoi choisir ce produit',
                        maxlines: 2,
                        controller: _pccsController,
                        label: 'PCCS',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hintText: 'Le prix du produit',
                        maxlines: 1,
                        controller: _prixController,
                        label: 'Prix',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 26),
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Ajoutez ses données pour une bonne visibilité du produit',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                              "${audone ? "✅" : "❌"} Ajouter les avantages et utilisations",
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
                              final result = await showModalBottomSheet<String>(
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
                                  caracteristiques.addAll(result.split(', '));
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
                              final result = await showModalBottomSheet<String>(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(
                                      context,
                                    ).viewInsets.bottom,
                                  ),
                                  child: SimpleListAdder(
                                    title: "Ajouter contenu du paquet",
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
                                  contenuPaquet.addAll(result.split(', '));
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
              ),

              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Livraison ?( ${_livraison ? "Payante" : "Gratuite"} )',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Livraison'),
                        value: _livraison,
                        onChanged: (v) => setState(() => _livraison = v),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Choisissez la catégorie de votre produit',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _collectionName,
                        decoration: const InputDecoration(
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25)),
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
                        onChanged: (v) => setState(() => _collectionName = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Choisissez une image',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Choisir une image'),
                          ),
                          const SizedBox(width: 16),
                          _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    _imageFile!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Text('Aucune image'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  foregroundColor: Theme.of(context).primaryColor,
                  elevation: 2,
                ),
                child: const Text(
                  'Ajouter le produit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
