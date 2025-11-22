import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating; // Note sur 5
  final double size;
  final Color color;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 20,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: size, color: color); // étoile pleine
        } else if (index < rating && rating % 1 != 0) {
          return Icon(Icons.star_half, size: size, color: color); // demi-étoile
        } else {
          return Icon(Icons.star_border, size: size, color: color); // étoile vide
        }
      }),
    );
  }
}
