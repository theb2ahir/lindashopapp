
// ignore_for_file: file_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/favs.dart';

class FavoriteProvider with ChangeNotifier {
  final List<Fav> _favs = [];

  List<Fav> get favs => _favs;

  void ajouterFav(Fav favs) {
    _favs.add(favs);
    notifyListeners();
  }

  void removeFav(Fav favs) {
    _favs.remove(favs);
    notifyListeners();
  }

  void supprimerFav(int index) {
    _favs.removeAt(index);
    notifyListeners();
  }

  void viderfavs() {
    _favs.clear();
    notifyListeners();
  }
}
