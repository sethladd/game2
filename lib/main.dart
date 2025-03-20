// Copyright 2025 Seth Ladd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'dart:async';
import 'gem.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool isPlaying = false;
  bool isGameOver = false;
  Timer? _timer;
  List<GemPair> gemPairs = [];
  double gameAreaHeight = 0;
  double gameAreaWidth = 0;
  static const int gridColumns = 8; // Number of columns in the grid
  late double gridCellWidth; // Width of each grid cell
  late double gridCellHeight; // Height of each grid cell
  static const double gemPairSpacing = 8; // Spacing between gems in a pair
  late double
  totalGemPairHeight; // Total height of a gem pair including spacing

  void _updateGridDimensions(double width, double height) {
    gameAreaWidth = width;
    gridCellWidth = width / gridColumns; // Remove padding
    gridCellHeight = gridCellWidth; // Make cells square

    // Set height to exactly 16 cells
    gameAreaHeight = gridCellHeight * 16;

    totalGemPairHeight = gridCellHeight * 2 + gemPairSpacing;
  }

  double _snapToGridX(double x) {
    // Convert x position to grid column
    final column = (x / gridCellWidth).round();
    // Convert back to pixel position
    return column * gridCellWidth;
  }

  double _snapToGridY(double y) {
    // Convert y position to grid row
    final row = (y / gridCellHeight).round();
    // Convert back to pixel position
    return row * gridCellHeight;
  }

  bool _checkCollision(GemPair movingPair, GemPair stoppedPair) {
    // Check vertical collision (bottom of moving pair touching top of stopped pair)
    final movingBottom = movingPair.yPosition + totalGemPairHeight;
    final stoppedTop = stoppedPair.yPosition;

    // Check horizontal alignment (x-positions are close enough)
    final horizontalOverlap =
        (movingPair.xPosition - stoppedPair.xPosition).abs() < gridCellWidth;

    // Add a small buffer to ensure gems don't overlap
    return horizontalOverlap && movingBottom >= stoppedTop - 2;
  }

  void _dropGemPair(GemPair pair) {
    setState(() {
      // Find the lowest possible position
      double lowestY = gameAreaHeight - totalGemPairHeight;

      // Check collisions with other stopped pairs
      for (var otherPair in gemPairs) {
        if (!otherPair.isMoving && otherPair != pair) {
          // Check if there's a horizontal overlap
          if ((pair.xPosition - otherPair.xPosition).abs() < gridCellWidth) {
            // Calculate the y position where collision would occur
            double collisionY = otherPair.yPosition - totalGemPairHeight;
            // Update lowestY if this collision point is higher than our current lowest
            if (collisionY < lowestY) {
              lowestY = collisionY;
            }
          }
        }
      }

      // Move the pair to the lowest possible position
      pair.yPosition = lowestY;
      pair.isMoving = false;

      // Check for game over
      if (pair.yPosition <= 0) {
        isGameOver = true;
        _stopGame();
      }
    });
  }

  void _handleTap(TapUpDetails details) {
    if (!isPlaying || isGameOver) return;

    setState(() {
      final newGemPairs = List<GemPair>.from(gemPairs);

      // Find the currently moving pair
      final movingPair = newGemPairs.firstWhere(
        (pair) => pair.isMoving,
        orElse: () => newGemPairs.last,
      );

      // Simple left/right detection based on tap position
      if (details.globalPosition.dx < MediaQuery.of(context).size.width / 2) {
        // Move left
        movingPair.xPosition = (movingPair.xPosition - gridCellWidth).clamp(
          16.0,
          gameAreaWidth - gridCellWidth - 16,
        );
      } else {
        // Move right
        movingPair.xPosition = (movingPair.xPosition + gridCellWidth).clamp(
          16.0,
          gameAreaWidth - gridCellWidth - 16,
        );
      }

      gemPairs = newGemPairs;
    });
  }

  void _handleVerticalDrag(DragEndDetails details) {
    if (!isPlaying || isGameOver) return;

    // Check if it's a downward swipe
    if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
      final newGemPairs = List<GemPair>.from(gemPairs);
      final movingPair = newGemPairs.firstWhere(
        (pair) => pair.isMoving,
        orElse: () => newGemPairs.last,
      );
      _dropGemPair(movingPair);
    }
  }

  void togglePlayPause() {
    if (isGameOver) {
      // Reset game when game is over
      setState(() {
        isGameOver = false;
        gemPairs = [];
        isPlaying = false;
      });
      return;
    }

    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        _startGame();
      } else {
        _stopGame();
      }
    });
  }

  void _startGame() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        final newGemPairs = List<GemPair>.from(gemPairs);

        // First, handle movement of existing pairs
        for (var pair in newGemPairs) {
          if (pair.isMoving) {
            // Check for collision with stopped pairs
            bool hasCollision = false;

            // Check collision with other stopped pairs
            for (var otherPair in newGemPairs) {
              if (!otherPair.isMoving && otherPair != pair) {
                if (_checkCollision(pair, otherPair)) {
                  hasCollision = true;
                  break;
                }
              }
            }

            // Check collision with bottom of game area
            if (pair.yPosition >= gameAreaHeight - totalGemPairHeight) {
              hasCollision = true;
            }

            if (!hasCollision) {
              pair.yPosition +=
                  gridCellHeight / 8; // Move by 1/8 of a grid cell
            } else {
              pair.isMoving = false;
              // Snap to grid
              pair.yPosition = _snapToGridY(pair.yPosition);
              // Check if the stopped pair is at the top
              if (pair.yPosition <= 0) {
                isGameOver = true;
                _stopGame();
                return;
              }
            }
          }
        }

        // Then, check if we need to add a new pair
        if (newGemPairs.isEmpty || !newGemPairs.last.isMoving) {
          final newPair = GemPair.random(size: gridCellWidth);
          newPair.xPosition = 16; // Start at left edge
          newGemPairs.add(newPair);
        }

        gemPairs = newGemPairs;
      });
    });
  }

  void _stopGame() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isGameOver ? 'Game Over' : 'Game',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: togglePlayPause,
                    icon: Icon(
                      isGameOver
                          ? Icons.refresh
                          : (isPlaying ? Icons.pause : Icons.play_arrow),
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate the maximum width that maintains 8:16 aspect ratio
                    final maxWidth = constraints.maxWidth * 0.9;
                    final maxHeight = constraints.maxHeight;
                    final cellWidth = maxWidth / gridColumns;
                    final cellHeight = cellWidth;
                    final gameHeight = cellHeight * 16;

                    // Scale down if height is too large
                    final scale =
                        gameHeight > maxHeight ? maxHeight / gameHeight : 1.0;
                    final scaledWidth = maxWidth * scale;
                    final scaledHeight = gameHeight * scale;

                    return SizedBox(
                      width: scaledWidth,
                      height: scaledHeight,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.purple,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                CustomPaint(
                                  painter: GridPainter(
                                    width: scaledWidth,
                                    height: scaledHeight,
                                    cellWidth: cellWidth * scale,
                                    cellHeight: cellHeight * scale,
                                    columns: gridColumns,
                                  ),
                                ),
                                GestureDetector(
                                  onTapUp: _handleTap,
                                  onVerticalDragEnd: _handleVerticalDrag,
                                  behavior: HitTestBehavior.opaque,
                                  child: Stack(
                                    children: [
                                      for (var pair in gemPairs)
                                        Positioned(
                                          left:
                                              _snapToGridX(pair.xPosition) *
                                              scale,
                                          top:
                                              _snapToGridY(pair.yPosition) *
                                              scale,
                                          child: Column(
                                            children: [
                                              pair.gem1.build(context),
                                              SizedBox(
                                                height: gemPairSpacing * scale,
                                              ),
                                              pair.gem2.build(context),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isGameOver)
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              child: const Center(
                                child: Text(
                                  'Game Over',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double width;
  final double height;
  final double cellWidth;
  final double cellHeight;
  final int columns;

  GridPainter({
    required this.width,
    required this.height,
    required this.cellWidth,
    required this.cellHeight,
    required this.columns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..strokeWidth = 1;

    // Draw vertical lines
    for (var i = 0; i <= columns; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
    }

    // Draw horizontal lines
    final rows = (height / cellHeight).ceil();
    for (var i = 0; i <= rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      width != oldDelegate.width ||
      height != oldDelegate.height ||
      cellWidth != oldDelegate.cellWidth ||
      cellHeight != oldDelegate.cellHeight ||
      columns != oldDelegate.columns;
}
