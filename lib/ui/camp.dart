// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:golf/entities/camp.dart';
import 'package:golf/entities/cell.dart';
import 'package:golf/entities/clubs.dart';
import 'package:golf/entities/terrain.dart';

class CampScreen extends StatefulWidget {
  const CampScreen({super.key});

  @override
  State<CampScreen> createState() => _CampScreenState();
}

class _CampScreenState extends State<CampScreen> {
  double cellSize = 0;
  int seed = Random().nextInt(9999);
  late Camp camp = Camp(
    difficulty: 0,
    fixedSeed: seed,
  );
  Offset ballPosition = const Offset(0, 0);
  Cell? selectedCell;
  Cell get ballCell => camp.getCell(
        ballPosition.dx.floor(),
        ballPosition.dy.floor(),
      )!;
  Clubs selectedClub = Clubs.wood;
  bool isAnimating = false;
  int swings = 0;
  Cell? calculatingCell;
  List<Cell> path = [];
  int difficulty = 0;
  int get par => 1 + (camp.campHeight / 7).ceil();

  @override
  void initState() {
    super.initState();
    ballPosition = camp.start;
  }

  swing() async {
    if (selectedCell == null || isAnimating) return;
    setState(() {
      isAnimating = true;
      swings++;
    });
    final oldPosition = ballPosition;
    final distance = selectedClub.min +
        Random().nextInt(selectedClub.max - selectedClub.min) +
        ballCell.terrain.difficulty;

    final divergency = (((100 - selectedClub.accuracy)) / 100) / 2;
    final selectedDivergency =
        Random().nextDouble() * (Random().nextBool() ? 1 : -1) * (divergency);
    final angle = atan2(
      selectedCell!.position.dy - ballPosition.dy,
      selectedCell!.position.dx - ballPosition.dx,
    );
    final divergencyAngle = angle + selectedDivergency;
    Offset newPosition = Offset(
      (ballPosition.dx + distance * cos(divergencyAngle))
          .clamp(0, camp.campWidth - 1)
          .roundToDouble(),
      (ballPosition.dy + distance * sin(divergencyAngle))
          .clamp(0, camp.campHeight - 1)
          .roundToDouble(),
    );

    int tries = 30;
    calculatingCell = camp.getCell(
      ballPosition.dx.round(),
      ballPosition.dy.round(),
    );
    final futureCell = camp.getCell(
      newPosition.dx.round(),
      newPosition.dy.round(),
    );

    while (
        calculatingCell != null && futureCell != calculatingCell && tries > 0) {
      tries--;
      final oldPosition = calculatingCell!.position;
      final theta = atan2(
        futureCell!.y - calculatingCell!.y,
        futureCell.x - calculatingCell!.x,
      );
      final newX = calculatingCell!.x + 1 * cos(theta);
      final newY = calculatingCell!.y + 1 * sin(theta);
      setState(() {
        calculatingCell = camp.getCell(
          newX.round(),
          newY.round(),
        );
        if (calculatingCell != null) path.add(calculatingCell!);
      });
      if (calculatingCell?.terrain == Terrain.tree &&
          selectedClub != Clubs.wedge) {
        setState(() {
          newPosition = oldPosition;
        });
        break;
      }
      if (selectedClub == Clubs.putter &&
          calculatingCell?.position == camp.hole) {
        newPosition = calculatingCell!.position;
        break;
      }
    }
    setState(() {
      calculatingCell = null;
    });

    if (newPosition == camp.hole) {
      won();
      return;
    }
    if (futureCell?.terrain == Terrain.water ||
        futureCell?.terrain == Terrain.tree) {
      setState(() {
        ballPosition = newPosition;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        ballPosition = oldPosition;
      });
    } else {
      setState(() {
        if (ballPosition == newPosition) {
          isAnimating = false;
        }
        ballPosition = newPosition;
      });
    }
  }

  reset({bool isNew = false}) {
    if (isNew) {
      difficulty = (difficulty + 1).clamp(0, 20);
      seed = Random().nextInt(9999);
    }
    setState(() {
      cellSize = 0;
      camp = Camp(
        difficulty: difficulty,
        fixedSeed: seed,
      );
      swings = 0;
      selectedCell = null;
      selectedClub = Clubs.wood;
      isAnimating = false;
      ballPosition = camp.start;
      calculatingCell = null;
      path = [];
    });
  }

  won() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Parabéns!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                reset(isNew: true);
              },
              child: const Text('Ok'),
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tacadas: $swings'),
              Text('Par: $par'),
              const SizedBox(
                height: 10,
              ),
              Text(
                switch (swings - par) {
                  <= -3 => 'Albatros!!!',
                  -2 => 'Eagle!!',
                  -1 => 'Birdie!',
                  0 => 'Par!',
                  1 => 'Bogey',
                  2 => 'Double Bogey..',
                  3 => 'Triple Bogey...',
                  _ => 'so sorry...'
                },
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (constraints.maxWidth > 600)
                        SettingBar(
                          campName: camp.name,
                          seed: seed,
                          difficulty: difficulty,
                          minusDifficulty: () {
                            if (difficulty > 0) {
                              difficulty--;
                              reset();
                            }
                          },
                          plusDifficulty: () {
                            if (difficulty < 20) {
                              difficulty++;
                              reset();
                            }
                          },
                          cellSize: cellSize,
                          ballCell: ballCell,
                          selectClub: (club) {
                            setState(() {
                              selectedClub = club;
                            });
                          },
                          selectedClub: selectedClub,
                          changeSeed: (newSeed) {
                            setState(() {
                              seed = newSeed;
                            });
                          },
                          reset: reset,
                          par: par,
                          swings: swings,
                        ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final newCellSize = min(
                                constraints.biggest.height / camp.campHeight,
                                constraints.maxWidth / camp.campWidth);
                            if (newCellSize != cellSize) {
                              Future(() {
                                if (mounted) {
                                  setState(() {
                                    cellSize = newCellSize;
                                  });
                                }
                              });
                            }
                            return cellSize == 0
                                ? const Center(
                                    child: CircularProgressIndicator.adaptive(),
                                  )
                                : Center(
                                    child: SizedBox(
                                      width: cellSize * camp.campWidth,
                                      height: cellSize * camp.campHeight,
                                      child: MouseRegion(
                                        onHover: (event) {
                                          final x = event.localPosition.dx ~/
                                              cellSize;
                                          final y = event.localPosition.dy ~/
                                              cellSize;
                                          setState(() {
                                            selectedCell = camp.getCell(x, y);
                                          });
                                        },
                                        onExit: (event) {
                                          setState(() {
                                            selectedCell = null;
                                          });
                                        },
                                        child: GestureDetector(
                                          onTap: () {
                                            swing();
                                          },
                                          onPanEnd: (details) {
                                            swing();
                                            setState(() {
                                              selectedCell = null;
                                            });
                                          },
                                          onPanUpdate: (details) {
                                            final x =
                                                details.localPosition.dx ~/
                                                    cellSize;
                                            final y =
                                                details.localPosition.dy ~/
                                                    cellSize;
                                            setState(() {
                                              selectedCell = camp.getCell(x, y);
                                            });
                                          },
                                          child: Stack(
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: List.generate(
                                                  camp.campHeight,
                                                  (r) => Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: List.generate(
                                                      camp.campWidth,
                                                      (c) {
                                                        final cell =
                                                            camp.getCell(c, r);
                                                        final hasBall = camp
                                                                    .start.dx ==
                                                                c &&
                                                            camp.start.dy == r;
                                                        final isHole =
                                                            camp.hole.dx == c &&
                                                                camp.hole.dy ==
                                                                    r;
                                                        return Container(
                                                          alignment:
                                                              Alignment.center,
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(3),
                                                          width: cellSize,
                                                          height: cellSize,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: cell
                                                                ?.terrain.color
                                                                .withOpacity(
                                                                    0.5),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.2),
                                                              width: 0.5,
                                                            ),
                                                          ),
                                                          child: Stack(
                                                            children: [
                                                              if (cell != null)
                                                                Icon(
                                                                  cell.terrain
                                                                      .icon,
                                                                  size:
                                                                      cellSize /
                                                                          1.5,
                                                                ),
                                                              if (hasBall)
                                                                Icon(
                                                                  Icons
                                                                      .sports_golf,
                                                                  color: Colors
                                                                      .red,
                                                                  size:
                                                                      cellSize /
                                                                          1.5,
                                                                ),
                                                              if (isHole)
                                                                Icon(
                                                                  Icons.flag,
                                                                  color: Colors
                                                                      .red,
                                                                  size:
                                                                      cellSize /
                                                                          1.5,
                                                                ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (!isAnimating &&
                                                  selectedCell != null)
                                                CustomPaint(
                                                  size: Size(
                                                    cellSize * camp.campWidth,
                                                    cellSize * camp.campHeight,
                                                  ),
                                                  painter: ClubPreviewPainter(
                                                    startPoint: ballPosition,
                                                    cellSize: cellSize,
                                                    endPoint:
                                                        selectedCell!.position,
                                                    width: (100 -
                                                            selectedClub
                                                                .accuracy)
                                                        .toDouble(),
                                                    height: selectedClub.max
                                                            .toDouble() +
                                                        ballCell
                                                            .terrain.difficulty,
                                                    min: selectedClub.min
                                                        .toDouble(),
                                                  ),
                                                  child: SizedBox(
                                                    width: cellSize *
                                                        camp.campWidth,
                                                    height: cellSize *
                                                        camp.campHeight,
                                                  ),
                                                ),
                                              ...path.map(
                                                (e) => Positioned(
                                                  left: e.x * cellSize,
                                                  top: e.y * cellSize,
                                                  child: Container(
                                                    margin:
                                                        const EdgeInsets.all(5),
                                                    width: cellSize - 10,
                                                    height: cellSize - 10,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.35),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.black
                                                            .withOpacity(0.3),
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              AnimatedPositioned(
                                                curve: Curves
                                                    .fastLinearToSlowEaseIn,
                                                duration: const Duration(
                                                  milliseconds: 2000,
                                                ),
                                                onEnd: () {
                                                  setState(() {
                                                    isAnimating = false;
                                                  });
                                                },
                                                left:
                                                    ballPosition.dx * cellSize,
                                                top: ballPosition.dy * cellSize,
                                                child: Container(
                                                  margin:
                                                      const EdgeInsets.all(1),
                                                  width: cellSize - 2,
                                                  height: cellSize - 2,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (constraints.maxWidth <= 600)
                  SizedBox(
                    height: 45,
                    width: double.maxFinite,
                    child: IconButton(
                      onPressed: () {
                        showBottomSheet(
                          context: context,
                          builder: (context) => SettingBar(
                            campName: camp.name,
                            seed: seed,
                            difficulty: difficulty,
                            minusDifficulty: () {
                              if (difficulty > 0) {
                                difficulty--;
                                reset();
                                Navigator.pop(context);
                              }
                            },
                            plusDifficulty: () {
                              if (difficulty < 20) {
                                difficulty++;
                                reset();
                                Navigator.pop(context);
                              }
                            },
                            cellSize: cellSize,
                            ballCell: ballCell,
                            selectClub: (club) {
                              setState(() {
                                selectedClub = club;
                              });
                              Navigator.pop(context);
                            },
                            selectedClub: selectedClub,
                            changeSeed: (newSeed) {
                              setState(() {
                                seed = newSeed;
                              });
                              Navigator.pop(context);
                            },
                            reset: () {
                              reset();
                              Navigator.pop(context);
                            },
                            selectedCell: selectedCell,
                            par: par,
                            swings: swings,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.settings,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ClubPreviewPainter extends CustomPainter {
  ClubPreviewPainter({
    required this.startPoint,
    required this.endPoint,
    required this.width,
    required this.height,
    required this.min,
    required this.cellSize,
  });
  Offset startPoint;
  Offset endPoint;
  double width;
  double height;
  double min;
  double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final maxDis = height * cellSize + cellSize / 2;
    final minDis = min * cellSize - cellSize / 2;
    final ballPoint = Offset(
      startPoint.dx * cellSize + cellSize / 2,
      startPoint.dy * cellSize + cellSize / 2,
    );
    final angle = atan2(
      endPoint.dy * cellSize - ballPoint.dy + cellSize / 2,
      endPoint.dx * cellSize - ballPoint.dx + cellSize / 2,
    );
    final divergency = (-(width) / 100);
    final startAnglePoint = Offset(
      maxDis * cos(angle + divergency) + ballPoint.dx,
      maxDis * sin(angle + divergency) + ballPoint.dy,
    );
    final startAnglePointMin = Offset(
      minDis * cos(angle + divergency) + ballPoint.dx,
      minDis * sin(angle + divergency) + ballPoint.dy,
    );
    final endAnglePoint = Offset(
      maxDis * cos(angle - divergency) + ballPoint.dx,
      maxDis * sin(angle - divergency) + ballPoint.dy,
    );
    final endAnglePointMin = Offset(
      minDis * cos(angle - divergency) + ballPoint.dx,
      minDis * sin(angle - divergency) + ballPoint.dy,
    );

    final path = Path();
    path.moveTo(ballPoint.dx, ballPoint.dy);
    path.moveTo(startAnglePointMin.dx, startAnglePointMin.dy);
    path.lineTo(startAnglePoint.dx, startAnglePoint.dy);
    path.arcToPoint(
      endAnglePoint,
      radius: Radius.circular(maxDis),
      clockwise: true,
    );
    path.lineTo(endAnglePointMin.dx, endAnglePointMin.dy);
    path.arcToPoint(
      startAnglePointMin,
      radius: Radius.circular(minDis),
      clockwise: false,
    );
    canvas.drawPath(
      path,
      Paint()..color = Colors.red.withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(ClubPreviewPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(ClubPreviewPainter oldDelegate) => false;
}

class SettingBar extends StatelessWidget {
  final String campName;
  final int seed;
  final int difficulty;
  final void Function() minusDifficulty;
  final void Function() plusDifficulty;
  final double cellSize;
  final Cell ballCell;
  final void Function(Clubs club) selectClub;
  final Clubs selectedClub;
  final Cell? selectedCell;
  final void Function(int newSeed) changeSeed;
  final void Function() reset;
  final int par;
  final int swings;

  const SettingBar({
    super.key,
    required this.campName,
    required this.seed,
    required this.difficulty,
    required this.minusDifficulty,
    required this.plusDifficulty,
    required this.cellSize,
    required this.ballCell,
    required this.selectClub,
    required this.selectedClub,
    this.selectedCell,
    required this.changeSeed,
    required this.reset,
    required this.par,
    required this.swings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          const Text(
            'Campo:',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: FittedBox(
                    child: Text(
                      campName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: seed.toString(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Dificuldade: ${difficulty.toString()}',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: minusDifficulty,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: plusDifficulty,
              ),
            ],
          ),
          const Spacer(),
          Text('Bola ${ballCell.x}:${ballCell.y}'),
          Container(
            height: cellSize * 3,
            width: cellSize * 3,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(0.2),
                width: 0.5,
              ),
              color: ballCell.terrain.color.withOpacity(0.5),
            ),
            child: ballCell.terrain.icon == null
                ? null
                : Icon(
                    ballCell.terrain.icon,
                    size: 50,
                  ),
          ),
          Text(ballCell.terrain.label),
          Text(
            switch (ballCell.terrain) {
              Terrain.bunker ||
              Terrain.fairway ||
              Terrain.rough =>
                'Fator: ${ballCell.terrain.difficulty}',
              Terrain.water => 'Reseta a jogada',
              Terrain.tree => 'Para a bola',
              Terrain.green => 'Pode usar o put',
            },
          ),
          const Spacer(),
          const Text('Taco:'),
          const SizedBox(
            height: 10,
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            children: Clubs.values
                .map(
                  (e) =>
                      (ballCell.terrain != Terrain.green && e == Clubs.putter)
                          ? const SizedBox.shrink()
                          : InkWell(
                              onTap: () {
                                selectClub(e);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedClub == e
                                      ? Colors.blue
                                      : Colors.white,
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(e.label),
                              ),
                            ),
                )
                .toList(),
          ),
          const SizedBox(
            height: 10,
          ),
          Text('Distância: ${selectedClub.min} - ${selectedClub.max}'),
          Text('Precisão: ${selectedClub.accuracy}%'),
          if (selectedClub == Clubs.wedge) const Text('Cruza árvores'),
          const Spacer(),
          if (selectedCell != null) ...[
            Container(
              height: cellSize * 2,
              width: cellSize * 2,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withOpacity(0.2),
                  width: 0.5,
                ),
                color: selectedCell?.terrain.color.withOpacity(0.5),
              ),
              child: selectedCell?.terrain.icon == null
                  ? null
                  : Icon(
                      selectedCell!.terrain.icon,
                    ),
            ),
            Text(selectedCell!.terrain.label),
            Text(
              switch (selectedCell!.terrain) {
                Terrain.bunker ||
                Terrain.fairway ||
                Terrain.rough =>
                  'Fator: ${selectedCell!.terrain.difficulty}',
                Terrain.water => 'Reseta a jogada',
                Terrain.tree => 'Para a bola',
                Terrain.green => 'Pode usar o put',
              },
            ),
          ],
          const SizedBox(height: 20),
          const Spacer(),
          const SizedBox(height: 20),
          Text('Par $par'),
          Text('Tacadas $swings'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: reset,
            child: const Text('Reset'),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: TextField(
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  changeSeed(
                    int.tryParse(value) ?? Random().nextInt(9999),
                  );
                },
                decoration: InputDecoration(
                  labelText: 'Seed',
                  suffix: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      reset();
                    },
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
