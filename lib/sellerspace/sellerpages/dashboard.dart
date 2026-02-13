import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lindashopp/features/pages/acceuilpage.dart';
import 'package:lindashopp/features/pages/notifications.dart';
import 'package:lindashopp/sellerspace/selleracceuil.dart';
import 'package:lindashopp/sellerspace/sellerpages/sellercommandes.dart';
import 'package:lindashopp/sellerspace/sellerpages/sellerproductchecking.dart';
import 'package:lindashopp/sellerspace/sellerpages/sellerprouct.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  String role = "";
  String username = "";
  int maxToAdd = 15;
  int totalCommandes = 0;
  int totalProduitConstruction = 0;
  int totalProduitElectronique = 0;
  int totalProduitFring = 0;
  int totalProduitModeEnfant = 0;
  int totalProduitSportBienEtre = 0;
  int totalProduitElectroMenage = 0;
  int totalProduitLivrer = 0;
  int totalproduit = 0;
  int totalproductreview = 0;
  int totalPromotions = 0;
  int nonlivrees = 0;
  int utilisateurs = 0;
  int inquietudes = 0;
  double totalBenefices = 0.0;
  double objectifBenefices = 1000000;
  double pourcentageatteint = 0.0;
  bool loading = false;
  String subscription = "";
  DateTime? endedat;
  DateTime? startedat;
  int nbrajouts = 0;
  int remainingStandard = 0;

  Future<void> getUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    setState(() {
      role = doc.data()!['role'];
      username = doc.data()!['name'];
      subscription = doc.data()!['subscription'];
      startedat = (doc.data()!['startedAt'] as Timestamp).toDate();
      endedat = (doc.data()!['endedAt'] as Timestamp).toDate();
      nbrajouts = doc.data()!['nbrajouts'];
    });
  }

  Future<void> _chargerStats() async {
    setState(() {
      loading = true;
    });
    final firestore = FirebaseFirestore.instance;

    final commandeSnapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection("sellercommandes")
        .get();

    final reviewproductSnapshot = await firestore
        .collection('reviewproduct')
        .where("sellerid", isEqualTo: uid)
        .get();

    final produitlivrereSnapshot = await firestore
        .collection("users")
        .doc(uid)
        .collection("sellercommandes")
        .where("livree", isEqualTo: true)
        .get();
    final productConstructionSnapshot = await firestore
        .collection("construction")
        .where("sellerid", isEqualTo: uid)
        .get();
    final productElectroniqueSnapshot = await firestore
        .collection("electronique")
        .where("sellerid", isEqualTo: uid)
        .get();
    final productFringSnapshot = await firestore
        .collection("fring")
        .where("sellerid", isEqualTo: uid)
        .get();
    final productModeEnfantSnapshot = await firestore
        .collection("produit-mode-et-enfant")
        .where("sellerid", isEqualTo: uid)
        .get();
    final productSportBienEtreSnapshot = await firestore
        .collection("produit-sport-et-bien-etre")
        .where("sellerid", isEqualTo: uid)
        .get();
    final productElectroMenageSnapshot = await firestore
        .collection("produit-électro-ménagé")
        .where("sellerid", isEqualTo: uid)
        .get();
    final promotionsSnapshot = await firestore
        .collection("promotions")
        .where("sellerid", isEqualTo: uid)
        .get();

    double somme = 0.0;
    for (var doc in commandeSnapshot.docs) {
      final prixTotal = doc.data()['prixTotal'] ?? 0;
      somme += (prixTotal is int) ? prixTotal.toDouble() : prixTotal;
    }

    int remaining = maxToAdd - nbrajouts;

    setState(() {
      totalCommandes = commandeSnapshot.size;
      totalProduitConstruction = productConstructionSnapshot.size;
      totalProduitElectronique = productElectroniqueSnapshot.size;
      totalProduitFring = productFringSnapshot.size;
      totalProduitModeEnfant = productModeEnfantSnapshot.size;
      totalProduitSportBienEtre = productSportBienEtreSnapshot.size;
      totalProduitElectroMenage = productElectroMenageSnapshot.size;
      totalProduitLivrer = produitlivrereSnapshot.size;
      totalPromotions = promotionsSnapshot.size;
      totalproductreview = reviewproductSnapshot.size;
      remainingStandard = remaining;
      totalproduit =
          totalProduitConstruction +
          totalProduitElectronique +
          totalProduitFring +
          totalProduitModeEnfant +
          totalProduitSportBienEtre +
          totalProduitElectroMenage +
          totalPromotions;
      totalBenefices = somme;
      pourcentageatteint = somme / objectifBenefices * 100;
      loading = false;
    });
  }

  void _showExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // impossible de fermer sans action
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("Abonnement expiré"),
            ],
          ),
          content: const Text(
            "Votre forfait est arrivé à échéance.\nVeuillez renouveler pour continuer à utiliser toutes les fonctionnalités.",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();

                // 🔁 Redirection vers la HomePage
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AcceuilPage()),
                  (route) => false,
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void checkSubscriptionExpiration(BuildContext context) {
    if (endedat == null) return;

    final now = DateTime.now();

    if (now.isAfter(endedat!)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showExpiredDialog(context);
      });
    }
  }

  String getRemainingTime() {
    if (endedat == null) return "—";

    final now = DateTime.now();
    final diff = endedat!.difference(now);

    if (diff.isNegative) {
      return "Expiré ❌";
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    return "$days j $hours h $minutes min";
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    _chargerStats();
    checkSubscriptionExpiration(context);
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AcceuilPage()),
              );
            },
          ),
          centerTitle: true,
          title: Text(
            !loading ? username : "Loading...",
            style: GoogleFonts.poppins(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _chargerStats();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsPage()),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1,

                  children: [
                    buildStatCard(
                      context: context,
                      title: "Souscription Linda Shop",
                      value: !loading ? subscription : "...",
                      icon: Icons.workspace_premium,
                      color: const Color.fromARGB(255, 107, 176, 198),
                      message: "Il vous reste:  ${getRemainingTime()}",
                      page: const SellerAcceuil(),
                    ),
                    if (subscription == "STANDARD")
                      buildStatCard(
                        context: context,
                        title: "Ajout journalier",
                        value: !loading ? nbrajouts.toString() : "...",
                        icon: Icons.add_circle_outline,
                        color: Colors.indigoAccent,
                        message:
                            "Vous pouvez encore ajouter ${remainingStandard.toString()} produits aujourd'hui",
                        page: const SellerAcceuil(),
                      ),
                    buildStatCard(
                      context: context,
                      title: "Commandes",
                      value: !loading ? totalCommandes.toString() : "...",
                      icon: Icons.shopping_cart_checkout_rounded,
                      color: Colors.green,
                      message:
                          "Vous avez au total ${totalCommandes.toString()} commande",
                      page: const SellerCommandes(),
                    ),
                    buildStatCard(
                      context: context,
                      title: "Produits",
                      value: !loading ? totalproduit.toString() : "...",
                      icon: Icons.inventory_2_rounded,
                      color: Colors.blue,
                      message:
                          "Vous avez au total ${totalproduit.toString()} produits",
                      page: const SellerProduct(),
                    ),
                    buildStatCard(
                      context: context,
                      title: "En verification",
                      value: !loading ? totalproductreview.toString() : "...",
                      icon: Icons.verified,
                      color: Colors.blueGrey,
                      message:
                          "Vous avez au total ${totalproductreview.toString()} produits",
                      page: const CheckProductPage(),
                    ),

                    buildStatCard(
                      context: context,
                      title: "Livrés",
                      value: !loading ? totalProduitLivrer.toString() : "...",
                      icon: Icons.local_shipping_rounded,
                      color: Colors.teal,
                      message:
                          "${totalProduitLivrer.toString()} de vos produits commandés ont été livrés",
                    ),
                    buildStatCard(
                      context: context,
                      title: "Construction",
                      value: !loading
                          ? totalProduitConstruction.toString()
                          : "...",
                      icon: Icons.construction_rounded,
                      color: Colors.brown,
                      message:
                          "Dans la catégorie construction vous avez au total ${totalProduitConstruction.toString()} produits",
                    ),
                    buildStatCard(
                      context: context,
                      title: "Électronique",
                      value: !loading
                          ? totalProduitElectronique.toString()
                          : "...",
                      icon: Icons.devices_rounded,
                      color: Colors.indigo,
                      message:
                          "Dans la catégorie électronique vous avez au total ${totalProduitElectronique.toString()} produits",
                    ),
                    buildStatCard(
                      context: context,
                      title: "Habillement",
                      value: !loading ? totalProduitFring.toString() : "...",
                      icon: Icons.checkroom_rounded,
                      color: Colors.pink,
                      message:
                          "Dans la catégorie mode vous avez au total ${totalProduitFring.toString()} produits",
                    ),
                    buildStatCard(
                      context: context,
                      title: "Mode enfant",
                      value: !loading
                          ? totalProduitModeEnfant.toString()
                          : "...",
                      icon: Icons.child_care_rounded,
                      color: Colors.orange,
                      message:
                          "Dans la catégorie mode enfant vous avez au total ${totalProduitModeEnfant.toString()} produits",
                    ),
                    buildStatCard(
                      context: context,
                      title: "Sport & Bien-être",
                      value: !loading
                          ? totalProduitSportBienEtre.toString()
                          : "...",
                      icon: Icons.fitness_center_rounded,
                      color: Colors.green,
                      message:
                          "Dans la catégorie sport & bien-être vous avez au total ${totalProduitSportBienEtre.toString()} produits",
                    ),
                    buildStatCard(
                      context: context,
                      title: "Électroménager",
                      value: !loading
                          ? totalProduitElectroMenage.toString()
                          : "...",
                      icon: Icons.kitchen_rounded,
                      color: Colors.red,
                      message:
                          "Dans la catégorie électroménager vous avez au total ${totalProduitElectroMenage.toString()} produits",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildStatCard({
  required BuildContext context,
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required String message,
  Widget? page,
}) {
  return GestureDetector(
    onTap: () {
      if (page != null) {
        showStatDialog(
          context: context,
          title: title,
          message: message,
          icon: icon,
          color: color,
          page: page,
        );
      }
    },
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.6)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26, color: Colors.white),
            ),

            const Spacer(),

            // Valeur
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 4),

            // Titre
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showStatDialog({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  required Color color,
  required Widget page,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: 230,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => page),
                        );
                      },
                      child: Text("Voir plus"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Fermer"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
