// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gal/gal.dart';
import 'package:lindashopp/features/pages/acceuilpage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String transactionId;
  final String reference;
  final double totalGeneral;
  final String reseau;
  final List<Map<String, dynamic>> commandes;

  const PaymentSuccessPage({
    super.key,
    required this.reseau,
    required this.transactionId,
    required this.reference,
    required this.totalGeneral,
    required this.commandes,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> qrData = {
      "transactionId": widget.transactionId,
      "reference": widget.reference,
      "total": widget.totalGeneral,
      "commandes": widget.commandes.map((item) {
        return {
          "productname": item['productname'],
          "quantity": item['quantity'],
          "price": item['productprice'],
          "imageurl": item['productImageUrl'],
          "livraison": item['livraison'],
        };
      }).toList(),
    };

    final String qrJson = jsonEncode(qrData);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF00BFA5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),

              /// ✅ Success Icon
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 90,
              ),

              const SizedBox(height: 10),

              Text(
                "Paiement Réussi 🎉",
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              /// ✅ Glass Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow("Transaction ID", widget.transactionId),
                      _buildInfoRow("Référence", widget.reference),
                      _buildInfoRow("Opérateur", widget.reseau),
                      _buildInfoRow("Total", "${widget.totalGeneral} FCFA"),

                      const SizedBox(height: 20),

                      const Divider(color: Colors.white),

                      const SizedBox(height: 20),

                      /// ✅ QR Screenshot Area
                      Screenshot(
                        controller: screenshotController,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: qrJson,
                                version: QrVersions.auto,
                                size: 220,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      /// ✅ Capture Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          await Permission.photos.request();

                          final image = await screenshotController.capture();

                          if (image != null) {
                            await Gal.putImageBytes(image);

                            final snack = ScaffoldMessenger.of(context)
                                .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "QR Code sauvegardé dans la galerie ✅",
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                            snack.closed.then((_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AcceuilPage(),
                                ),
                              );
                            });
                          }
                        },
                        child: Text(
                          "Sauvegarder l'image",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16)),
          Flexible(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
              },
              child: Text(
                value.length > 15 ? "${value.substring(0, 15)} ..." : value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
