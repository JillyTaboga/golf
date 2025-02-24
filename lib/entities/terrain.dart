import 'package:flutter/material.dart';

enum Terrain {
  fairway(Colors.green, null, 'Liso', 2),
  rough(Colors.lightGreen, null, 'Áspero', 0),
  bunker(Colors.yellow, null, 'Areia', -2),
  water(Colors.blue, null, 'Água', 0),
  green(Colors.greenAccent, null, 'Revaldo', 1),
  tree(Colors.lightGreenAccent, Icons.nature, 'Árvore', 0);

  final Color color;
  final IconData? icon;
  final String label;
  final int difficulty;

  const Terrain(
    this.color,
    this.icon,
    this.label,
    this.difficulty,
  );
}
