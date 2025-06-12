import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/items.dart';

class PanierProvider with ChangeNotifier {
  final List<Item> _items = [];

  List<Item> get items => _items;

  void ajouterItem(Item item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(Item item) {
    _items.remove(item);
    notifyListeners();
  }

  void supprimerItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void viderPanier() {
    _items.clear();
    notifyListeners();
  }
}
