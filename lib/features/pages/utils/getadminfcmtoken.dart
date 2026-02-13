import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> getAdminToken() async {
  final adminQuery = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'admin') // corrige typo ici
      .limit(1)
      .get();

  if (adminQuery.docs.isNotEmpty) {
    final adminData = adminQuery.docs.first.data();
    final adminToken = adminData['fcmToken'] as String?;
    return adminToken;
  }

  return null; // Aucun admin trouvé
}
