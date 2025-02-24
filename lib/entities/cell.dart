// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:golf/entities/terrain.dart';

class Cell {
  final int x;
  final int y;
  final Terrain terrain;

  Offset get position => Offset(x.toDouble(), y.toDouble());

  Cell(
    this.x,
    this.y, {
    required this.terrain,
  });

  @override
  bool operator ==(covariant Cell other) {
    if (identical(this, other)) return true;

    return other.x == x && other.y == y && other.terrain == terrain;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ terrain.hashCode;
}
