import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/achatrecentprovider.dart';
import 'package:lindashopp/homepage.dart';
import 'package:provider/provider.dart';

class AchatRecent extends StatefulWidget {
  const AchatRecent({super.key});

  @override
  State<AchatRecent> createState() => _AchatRecentState();
}

class _AchatRecentState extends State<AchatRecent> {
  @override
  Widget build(BuildContext context) {
    final acrsProfider = context.watch<AcrProvider>();
    final acr = acrsProfider.acrs;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 1, 15, 41),
        centerTitle: true,
        title: Text(
          "Achats récents",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyHomePage()),
              );
            },
          ),
        ],
      ),
      body: acr.isEmpty
          ? const Center(child: Text('Aucun achats pour le moment '))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: acr.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final item = acr[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF011529),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/${item.productImageUrl.replaceAll(r'\', '/')}',
                              width: double.infinity,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Prix: ${item.productPrice} FCFA',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Quantité: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Transaction ID : ${item.transactionId}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Référence : ${item.reference}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(), // pousse les éléments restants en bas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.dateAjout.toLocal().toString().substring(
                                  0,
                                  16,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  try {
                                    acrsProfider.supprimerACR(index);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.grey[900],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        duration: const Duration(seconds: 3),
                                        content: Row(
                                          children: const [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.lightGreenAccent,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Achat récent supprimé',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
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
