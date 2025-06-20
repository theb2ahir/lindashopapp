import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/favoriteProdvider.dart';
import 'package:lindashopp/PaiementPageFlooz.dart';
import 'package:lindashopp/PaiementPageYas.dart';
import 'package:provider/provider.dart';

class Favoris extends StatefulWidget {
  const Favoris({super.key});

  @override
  State<Favoris> createState() => _FavorisState();
}

class _FavorisState extends State<Favoris> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();
    final favorites = favoriteProvider.favs;


    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // couleur de l’icône retour
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF02204B),
        title: const Text("Favoris", style: TextStyle(color: Colors.white)),
      ),
      body: favorites.isEmpty
          ? const Center(child: Text('Aucun favoris'))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: favorites.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final item = favorites[index];
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
                                    favoriteProvider.removeFav(item);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.grey[900],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              16),
                                        ),
                                        duration: Duration(seconds: 5),
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.lightGreenAccent,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Favori supprimé',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
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
