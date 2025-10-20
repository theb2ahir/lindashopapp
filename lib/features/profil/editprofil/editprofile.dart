// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  Map<String, dynamic>? user;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController newemaailController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email ?? '',
    );
    bool isSending = false;

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
                  Icon(Icons.help_outline, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    "Réinitialiser le mot de passe",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Entrez votre email. Un lien de réinitialisation sera envoyé.",
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  if (isSending) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Veuillez entrer un email."),

                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          setState(() => isSending = true);
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: email,
                            );
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Lien de réinitialisation envoyé à $email.",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            String message = "Une erreur est survenue.";
                            if (e.code == 'user-not-found') {
                              message = "Aucun utilisateur avec cet email.";
                            } else if (e.code == 'invalid-email') {
                              message = "Email invalide.";
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Erreur : $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => isSending = false);
                          }
                        },
                  child: const Text("Envoyer"),
                ),
              ],
            );
          },
        );
      },
    );
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
                  Text(
                    "Changer le mot de passe",
                    style: TextStyle(fontSize: 16),
                  ),
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

                    TextButton(
                      onPressed: () {
                        _showForgotPasswordDialog();
                      },
                      child: const Text("mot de passe oublier ?"),
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

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    user = doc.data();

    if (user != null) {
      _nameController.text = user!['name'] ?? '';
      _emailController.text = user!['email'] ?? '';
      _phoneNumberController.text = user!['phone'] ?? '';
      _addressController.text = user!['adresse'] ?? '';
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': _nameController.text,
      'phone': _phoneNumberController.text,
      'adresse': _addressController.text,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Modifications enregistrées")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Éditer mon profil" , style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (user != null)
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
                            user!['name'].substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/profil.jpg'),
                    ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.email),
                    title: TextFormField(
                      readOnly: true,
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.lock),
                    title: Text("******..."),
                    onTap: () {
                      _showChangePasswordDialog();
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Adresse(region,ville , quartier , precision)'),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: saveChanges,
                    child: const Text("Sauvegarder"),
                  ),
                ],
              ),
            ),
    );
  }
}
