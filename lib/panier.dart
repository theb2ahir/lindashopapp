// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/panierprovider.dart';
import 'package:lindashopp/PaiementPageFlooz.dart';
import 'package:lindashopp/PaiementPageYas.dart';
import 'package:provider/provider.dart';

class PanierPage extends StatefulWidget {
  const PanierPage({super.key});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final panierProvider = context.watch<PanierProvider>();
    final panier = panierProvider.items;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF02204B),
        iconTheme: const IconThemeData(
          color: Colors.white, // couleur de l’icône retour
        ),
        title: const Text('Mon Panier', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          Text(
            "${panier.length} article(s)",
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 13),
        ],
      ),
      body: panier.isEmpty
          ? const Center(child: Text('Aucun article dans le panier'))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: panier.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final item = panier[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/${item.productImageUrl.replaceAll(r'\', '/')}',
                              width: double.infinity,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.productPrice} FCFA'),
                              Text('Qté: ${item.quantity}'),
                            ],
                          ),
                          Text(
                            "Total à payer : ${int.parse(item.productPrice) * item.quantity} FCFA",
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Ajouté le : ${item.dateAjout.toLocal().toString().substring(0, 16)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  try {
                                    panierProvider.removeItem(item);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(
                                          top: 20,
                                          left: 20,
                                          right: 20,
                                        ),
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        content: Text('Erreur : $e'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.payment,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                onPressed: () {
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
                                          Icon(
                                            Icons.phone,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Choisissez un operateur',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          PaiementPage2(
                                                            item: item,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  "Flooz",
                                                  style: TextStyle(
                                                    color:
                                                        Colors.lightGreenAccent,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          PaiementPage(
                                                            item: item,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  "Yas",
                                                  style: TextStyle(
                                                    color: Colors.yellowAccent,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Offstage(
                            offstage: true,
                            child: Column(
                              children: [
                                Text('Username: ${item.username}'),
                                Text('Prenom: ${item.prenom}'),
                                Text('Phone: ${item.phone}'),
                                Text('Email: ${item.email}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
