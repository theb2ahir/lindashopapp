import 'package:flutter/material.dart';

class AppColors {
  /// Fond principal
  static Color background(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Cartes, containers, dialogs
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Texte principal
  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Texte sur surface
  static Color onSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Couleur principale
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Bordures
  static Color border(BuildContext context) => Theme.of(context).dividerColor;
}
