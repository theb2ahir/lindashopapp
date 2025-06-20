// ignore: file_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/achatrec.dart';

class AcrProvider with ChangeNotifier {
  final List<ACR> _acrs = [];

  List<ACR> get acrs => _acrs;

  void ajouterACR(ACR acrs) {
    _acrs.add(acrs);
    notifyListeners();
  }

  void removeACR(ACR acrs) {
    _acrs.remove(acrs);
    notifyListeners();
  }

  void supprimerACR(int index) {
    _acrs.removeAt(index);
    notifyListeners();
  }

  void viderACR() {
    _acrs.clear();
    notifyListeners();
  }
}
