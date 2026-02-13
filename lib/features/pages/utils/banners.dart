import 'dart:ui';

class PromoBanner {
  final String tag;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  PromoBanner({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
