import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:golf/entities/cell.dart';
import 'package:golf/entities/terrain.dart';

class Camp {
  late String name;
  late int campWidth;
  late int campHeight;
  late int seed;
  late int difficulty;
  late Offset start;
  late Offset hole;
  List<Cell> cells = [];

  Cell? getCell(int x, int y) {
    return cells.firstWhereOrNull((cell) => cell.x == x && cell.y == y);
  }

  Camp({int? fixedSeed, this.difficulty = 3}) {
    seed = fixedSeed ?? DateTime.now().millisecondsSinceEpoch;
    final random = Random(seed);
    campHeight = random.nextInt(2 * (difficulty + 1)) + 30;
    campWidth = (random.nextInt(2 * (difficulty + 1)) + 15)
        .clamp(1, (campHeight / 2).floor());

    name = '$seed';

    start = Offset(
      3 + random.nextInt(campWidth - 6) / 1,
      campHeight - 2 - random.nextInt(3) / 1,
    );

    hole = Offset(
      3 + random.nextInt(campWidth - 6) / 1,
      2 + random.nextInt(3) / 1,
    );

    bool cellAvaible(int x, int y) {
      final insideBounds = x >= 0 && x < campWidth && y >= 0 && y < campHeight;
      final alreadyOccpied = getCell(x, y) != null;
      return insideBounds && !alreadyOccpied;
    }

    fillCells({
      required Offset start,
      required Terrain terrain,
      required int max,
      required int min,
    }) {
      final startCell = Cell(
        start.dx.toInt(),
        start.dy.toInt(),
        terrain: terrain,
      );
      List<Cell> startCells = [startCell];
      cells.add(startCell);

      Offset getOffset(Offset lastPosition) {
        final direction = random.nextInt(8);
        final dx = lastPosition.dx + (direction % 3) - 1;
        final dy = lastPosition.dy + (direction ~/ 3) - 1;
        return Offset(dx, dy);
      }

      Offset position = start;
      int tries = 0;
      for (int n = 0; n < random.nextInt(max - min) + min; n++) {
        final newPosition = getOffset(position);
        if (cellAvaible(newPosition.dx.toInt(), newPosition.dy.toInt())) {
          final cell = Cell(
            newPosition.dx.toInt(),
            newPosition.dy.toInt(),
            terrain: terrain,
          );
          startCells.add(cell);
          cells.add(cell);
        } else {
          tries++;
          if (tries > 8) {
            position = startCells.last.position;
            tries = 0;
          }
        }
      }
    }

    //Calcula o fairway inicial
    final fairwayBase = (campHeight).floor();
    fillCells(
      start: start,
      terrain: Terrain.fairway,
      max: (fairwayBase * 2 * (fairwayBase - difficulty + 1)),
      min: fairwayBase,
    );

    //Calcula o green
    fillCells(
      start: hole,
      terrain: Terrain.green,
      max: fairwayBase * 2 * (fairwayBase - difficulty + 1),
      min: fairwayBase,
    );

    Offset freePosition() {
      Offset position = Offset(
        random.nextInt(campWidth).toDouble(),
        random.nextInt(campHeight).toDouble(),
      );
      while (!cellAvaible(position.dx.toInt(), position.dy.toInt())) {
        position = Offset(
          random.nextInt(campWidth).toDouble(),
          random.nextInt(campHeight).toDouble(),
        );
      }
      return position;
    }

    //Calcula outros Fairways
    final fairways = random.nextInt((30 - difficulty) ~/ 3);
    for (int n = 0; n < fairways; n++) {
      fillCells(
        start: freePosition(),
        terrain: Terrain.fairway,
        max: (fairwayBase * 2 * (fairwayBase - difficulty + 1)),
        min: fairwayBase,
      );
    }

    //Calcula trees
    final trees = random.nextInt((difficulty + 1) * 3);
    for (int n = 0; n < trees; n++) {
      fillCells(
        start: freePosition(),
        terrain: Terrain.tree,
        max: (fairwayBase / 2 * (fairwayBase / 2 - difficulty + 1)).floor(),
        min: (fairwayBase / 2).floor(),
      );
    }

    if (difficulty > 0) {
      //Calcula waters
      final waters = random.nextInt((difficulty) * 2);
      for (int n = 0; n < waters; n++) {
        fillCells(
          start: freePosition(),
          terrain: Terrain.water,
          max: (fairwayBase * (fairwayBase - difficulty + 1)).floor(),
          min: (fairwayBase).floor(),
        );
      }
      //Calcula bunkers
      final bunkers = random.nextInt((difficulty) * 1);
      for (int n = 0; n < bunkers; n++) {
        fillCells(
          start: freePosition(),
          terrain: Terrain.bunker,
          max: (fairwayBase / 2 * (fairwayBase / 2 - difficulty + 1)).floor(),
          min: (fairwayBase / 2).floor(),
        );
      }
    }

    //Calcula roughs
    while (cells.length < campWidth * campHeight) {
      fillCells(
        start: freePosition(),
        terrain: Terrain.rough,
        max: (fairwayBase * (fairwayBase - difficulty + 1)).floor(),
        min: (fairwayBase).floor(),
      );
    }
  }
}
