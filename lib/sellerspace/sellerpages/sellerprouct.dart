// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SellerProduct extends StatefulWidget {
  const SellerProduct({super.key});

  @override
  State<SellerProduct> createState() => _SellerProductState();
}

class _SellerProductState extends State<SellerProduct> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  List<QueryDocumentSnapshot> allProducts = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllCollections();
  }

  Future<void> _fetchAllCollections() async {
    setState(() => loading = true);

    final collections = [
      'construction',
      'electronique',
      'fring',
      'produit-mode-et-enfant',
      'produit-sport-et-bien-etre',
      'produit-électro-ménagé',
    ];

    try {
      final futures = collections.map(
        (collectionName) => FirebaseFirestore.instance
            .collection(collectionName)
            .where('sellerid', isEqualTo: uid)
            .get(),
      );

      final snapshots = await Future.wait(futures);
      final allDocs = snapshots.expand((s) => s.docs).toList();

      if (!mounted) return;

      setState(() {
        allProducts = allDocs;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Produits",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : allProducts.isEmpty
          ? Center(
              child: Text(
                "Aucun produit à afficher",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: allProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                final data = allProducts[index].data();

                if (data is! Map<String, dynamic>) {
                  return const SizedBox();
                }

                final produit = data;
                final String nom = produit['name'] ?? 'Sans nom';
                final String prix = produit['prix']?.toString() ?? '0';
                final String imageUrl = produit['imageURL'] ?? '';

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: Colors.grey.shade100,
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            nom,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$prix fcfa",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          "Supprimer le produit",
                                        ),
                                        content: const Text(
                                          "Voulez-vous vraiment supprimer ce produit ?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Annuler"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text("Supprimer"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await allProducts[index].reference
                                            .delete();
                                        setState(() {
                                          allProducts.removeAt(index);
                                        });

                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Produit supprimé avec succès ✅",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Erreur lors de la suppression : $e",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
