// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lindashopp/favoris.dart';
import 'package:lindashopp/inquietude.dart';
import 'package:lindashopp/nonlivre.dart';
import 'package:lindashopp/parametre.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController usernameCtrl = TextEditingController();
  TextEditingController useremailCtrl = TextEditingController();
  TextEditingController phoneCtrl = TextEditingController();

  Future<Map<String, dynamic>> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()!;
  }

  void _showModifyUsernameDialog(String currentUsername) {
    usernameCtrl.text = currentUsername;
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.edit, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "Modifier le nom d'utilisateur",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nom actuel :",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  currentUsername,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameCtrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Nouveau nom d'utilisateur",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final newUsername = usernameCtrl.text.trim();

                if (newUsername.isNotEmpty && uid != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'name': newUsername});

                    Navigator.of(context).pop();
                    setState(() {}); // Recharge les données

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Nom d'utilisateur mis à jour !"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur de mise à jour : $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  focusNode.requestFocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Veuillez entrer un nom valide."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                "Enregistrer",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      focusNode.requestFocus();
    });
  }

  void _showModifyEmailDialog(String currentEmail) {
    useremailCtrl.text = currentEmail;
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.edit, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "Modifier l'email",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "email actuel :",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  currentEmail,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: useremailCtrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Nouveau email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final newuseremail = useremailCtrl.text.trim();

                if (newuseremail.isNotEmpty &&
                    uid != null &&
                    newuseremail.contains("@gmail.com")) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'email': newuseremail});

                    Navigator.of(context).pop();
                    setState(() {}); // Recharge les données

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Email mis à jour !"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur de mise à jour : $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  focusNode.requestFocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Veuillez entrer un email valide."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                "Enregistrer",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      focusNode.requestFocus();
    });
  }

  void _showModifyPhoneDialog(String currentPhone) {
    phoneCtrl.text = currentPhone;
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.edit, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "Modifier le numéro de téléphone",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Numéro de téléphone actuel :",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  currentPhone,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneCtrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Nouveau numéro de téléphone",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final newphone = phoneCtrl.text.trim();

                if (newphone.isNotEmpty && uid != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'phone': newphone});

                    Navigator.of(context).pop();
                    setState(() {}); // Recharge les données

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Numéro de téléphone mis à jour !"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur de mise à jour : $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  focusNode.requestFocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Veuillez entrer un numéro de téléphone valide.",
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                "Enregistrer",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      focusNode.requestFocus();
    });
  }

  void _showChangePasswordDialog() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    // États pour afficher ou masquer les mots de passe
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(Icons.lock, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text("Changer le mot de passe" , style: TextStyle(fontSize: 16),),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: currentPasswordCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: "Mot de passe actuel",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => obscureCurrent = !obscureCurrent);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: "Nouveau mot de passe , max 9 caractères",
                        prefixIcon: const Icon(Icons.lock_open),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => obscureNew = !obscureNew);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: "Confirmer le mot de passe",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => obscureConfirm = !obscureConfirm);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    final currentPassword = currentPasswordCtrl.text.trim();
                    final newPassword = newPasswordCtrl.text.trim();
                    final confirmPassword = confirmPasswordCtrl.text.trim();

                    if (newPassword != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Les mots de passe ne correspondent pas.",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    if (newPassword.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Le mot de passe doit contenir au moins 6 caractères.",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    try {
                      final cred = EmailAuthProvider.credential(
                        email: user!.email!,
                        password: currentPassword,
                      );

                      await user.reauthenticateWithCredential(cred);
                      await user.updatePassword(newPassword);

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Mot de passe mis à jour !"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erreur : $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Modifier"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Linda Shop",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            const SizedBox(height: 3),
            FutureBuilder<Map<String, dynamic>>(
              future: getUserData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                final userData = snapshot.data!;
                final name = userData['name'] ?? 'Utilisateur';
                final email = userData['email'] ?? 'Non renseigné';
                final phone = userData['phone'] ?? 'Non renseigné';

                return Column(
                  children: [
                    const SizedBox(height: 24),
                    ClipRRect(
                      child: Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF02204B),
                          borderRadius: BorderRadius.circular(200),
                        ),
                        child: Center(
                          child: Text(
                            name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 90,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    /// Nom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 13),
                        Text(name, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            _showModifyUsernameDialog(name);
                          },
                          icon: const Icon(Icons.edit, size: 17),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),

                    /// Email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email),
                        Text("  $email", style: const TextStyle(fontSize: 18)),
                        IconButton(
                          onPressed: () {
                            _showModifyEmailDialog(email);
                          },
                          icon: const Icon(Icons.edit, size: 17),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),

                    /// Téléphone
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone),
                        Text("  $phone", style: const TextStyle(fontSize: 18)),
                        IconButton(
                          onPressed: () {
                            _showModifyPhoneDialog(phone);
                          },
                          icon: const Icon(Icons.edit, size: 17),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("******", style: const TextStyle(fontSize: 18)),
                        IconButton(
                          onPressed: () {
                            _showChangePasswordDialog();
                          },
                          icon: const Icon(Icons.edit, size: 17),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            /// Liste des options
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite, color: Colors.red),
                  title: const Text('Mes favoris'),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Favoris()),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.cancel_schedule_send,
                    color: Colors.black,
                  ),
                  title: const Text('Non livré ?'),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NonLivre()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.handshake, color: Colors.black),
                  title: const Text('Partenariat'),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () async {
                    const whatsappNumber = '+22892349698';
                    final message = Uri.encodeComponent(
                      "Bonjour, je souhaite discuter d’un partenariat.",
                    );
                    final url = 'https://wa.me/$whatsappNumber?text=$message';

                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible d’ouvrir WhatsApp'),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.black),
                  title: const Text('Appeler'),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () async {
                    const phoneNumber = 'tel:+22892349698';
                    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                      await launchUrl(Uri.parse(phoneNumber));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible de passer l’appel'),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.question_answer,
                    color: Colors.green,
                  ),
                  title: const Text('Des inquiétudes ?'),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Inquietude()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.black),
                  title: const Text('Paramètres'),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Parametre()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
