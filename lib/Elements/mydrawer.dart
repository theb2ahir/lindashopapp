// ignore_for_file: avoid_unnecessary_containers

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lindashopp/favoris.dart';
import 'package:lindashopp/inquietude.dart';
import 'package:lindashopp/nonlivre.dart';
import 'package:url_launcher/url_launcher.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      backgroundColor: Colors.transparent, // fond blanc
      child: SafeArea(
        top: true,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10) 
            )
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/articlesImages/LindaLogo2.png',
                            height: 150,
                            width: 150,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "linda@example.com",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.favorite,
                        color: Color.fromARGB(255, 245, 5, 5),
                      ),
                      title: const Text(
                        'Favoris',
                        style: TextStyle(color: Colors.black),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Favoris(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.cancel_schedule_send,
                        color: Color.fromARGB(255, 41, 8, 8),
                      ),
                      title: const Text('Non livré ?'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NonLivre(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.handshake, color: Colors.black),
                      title: const Text('Partenariat'),
                      onTap: () async {
                        const whatsappNumber =
                            '+22892349698'; // Remplace par ton numéro
                        final message = Uri.encodeComponent(
                          "Bonjour, je souhaite discuter d’un partenariat.",
                        );
                        final whatsappUrl =
                            'https://wa.me/$whatsappNumber?text=$message';

                        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                          await launchUrl(
                            Uri.parse(whatsappUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          // Gère l'erreur si WhatsApp n’est pas disponible
                          // ignore: use_build_context_synchronously
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
                      onTap: () async {
                        const phoneNumber = 'tel:+22892349698';
                        if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                          await launchUrl(Uri.parse(phoneNumber));
                        } else {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Impossible de passer l’appel'),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.question_answer,
                        color: Color.fromARGB(255, 8, 192, 63),
                      ),
                      title: const Text('Des inquiétudes ?'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Inquietude(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              const whatsappNumber =
                                  '+22892349698'; // Remplace par ton numéro
                              final message = Uri.encodeComponent(
                                "Bonjour, je souhaite discuter d’un partenariat.",
                              );
                              final whatsappUrl =
                                  'https://wa.me/$whatsappNumber?text=$message';

                              if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                                await launchUrl(
                                  Uri.parse(whatsappUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                // Gère l'erreur si WhatsApp n’est pas disponible
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Impossible d’ouvrir WhatsApp',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const FaIcon(
                              FontAwesomeIcons.whatsapp,
                              color: Colors.green,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              const facebookUrl =
                                  'https://www.facebook.com/share/18fFSp6qf6/?mibextid=wwXIfr';
                              if (await canLaunchUrl(Uri.parse(facebookUrl))) {
                                await launchUrl(
                                  Uri.parse(facebookUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                // Gère l'erreur si WhatsApp n’est pas disponible
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Impossible d’ouvrir Facebook',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const FaIcon(
                              FontAwesomeIcons.facebook,
                              color: Colors.blue,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              const tkurl =
                                  'https://www.tiktok.com/@_baahir_?is_from_webapp=1&sender_device=pc';

                              if (await canLaunchUrl(Uri.parse(tkurl))) {
                                await launchUrl(
                                  Uri.parse(tkurl),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                // Gère l'erreur si WhatsApp n’est pas disponible
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Impossible d’ouvrir TikTok'),
                                  ),
                                );
                              }
                            },
                            icon: const FaIcon(
                              FontAwesomeIcons.tiktok,
                              color: Color.fromARGB(255, 1, 17, 46),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              const ingUrl =
                                  'https://www.instagram.com/b2ahir_91?igsh=YXltNGpwZGs3N2ph&utm_source=qr';

                              if (await canLaunchUrl(Uri.parse(ingUrl))) {
                                await launchUrl(
                                  Uri.parse(ingUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                // Gère l'erreur si WhatsApp n’est pas disponible
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Impossible d’ouvrir Instagram',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const FaIcon(
                              FontAwesomeIcons.instagram,
                              color: Color.fromARGB(255, 214, 50, 39),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              const siteUrl =
                                  'https://linda-shop-2835e.web.app/';

                              if (await canLaunchUrl(Uri.parse(siteUrl))) {
                                await launchUrl(
                                  Uri.parse(siteUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                // Gère l'erreur si WhatsApp n’est pas disponible
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Impossible d’ouvrir le lien du site internet',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const FaIcon(
                              FontAwesomeIcons.globe,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
