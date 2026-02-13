import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> sendNotification(String token, String title, String text) async {
  final url = Uri.parse("https://lindanotifsender-1.onrender.com/sendNotif");

  await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'token': token, 'title': title, 'body': text}),
  );
}
