import 'package:flutter/material.dart';
import 'package:lindashopp/notifucation_service.dart';
import 'package:permission_handler/permission_handler.dart';

class TestNotifPage extends StatefulWidget {
  const TestNotifPage({super.key});

  @override
  State<TestNotifPage> createState() => _TestNotifPageState();
}

class _TestNotifPageState extends State<TestNotifPage> {
  @override
  void initState() {
    super.initState();
    _askNotificationPermission();
  }

  Future<void> _askNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test notif")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                NotificationService.showNotification(
                  title: "Test notif",
                  message: "Ceci est un test de notification",
                );
              },
              child: const Text("notif simple"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                NotificationService.showNotification(
                  title: "Breaking News 📰",
                  message: "Regarde cette image téléchargée",
                  imageUrl: "https://picsum.photos/600/300",
                );
              },
              child: const Text("notif avec image"),
            ),
          ],
        ),
      ),
    );
  }
}
