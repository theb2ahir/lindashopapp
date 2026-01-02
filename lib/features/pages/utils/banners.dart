import 'dart:ui';

class PromoBanner {
  final String image;
  final String title;
  final VoidCallback onTap;

  PromoBanner({required this.image, required this.title, required this.onTap});
}
