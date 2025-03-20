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
  List<Gem> gems = [];
  double gameAreaHeight = 0;
  double gameAreaWidth = 0;
  static const int gridColumns = 8; // Number of columns in the grid
  late double gridCellWidth; // Width of each grid cell
  late double gridCellHeight; // Height of each grid cell

  void _updateGridDimensions(double width, double height) {
    gameAreaWidth = width;
    gridCellWidth = width / gridColumns;
    gridCellHeight = gridCellWidth; // Make cells square
    gameAreaHeight = gridCellHeight * 16; // Exactly 16 rows
  }

  double _snapToGridX(double x) {
    final column = (x / gridCellWidth).round();
    return column * gridCellWidth;
  }

  double _snapToGridY(double y) {
    final row = (y / gridCellHeight).round();
    return row * gridCellHeight;
  }

  bool _checkCollision(Gem movingGem, Gem stoppedGem) {
    // Check if gems are in the same column
    if (movingGem.gridX != stoppedGem.gridX) {
      return false;
    }

    // Check if moving gem is one row above stopped gem
    return movingGem.gridY + 1 == stoppedGem.gridY;
  }

  void _handleTap(TapUpDetails details) {
    if (!isPlaying || isGameOver) return;

    setState(() {
      final newGems = List<Gem>.from(gems);

      // Find the currently moving gem
      final movingGem = newGems.firstWhere(
        (gem) => gem.isMoving,
        orElse: () => newGems.last,
      );

      // Calculate new column position based on tap
      int newX = movingGem.gridX;
      if (details.globalPosition.dx < MediaQuery.of(context).size.width / 2) {
        newX = movingGem.gridX - 1;
      } else {
        newX = movingGem.gridX + 1;
      }

      // Clamp to game area bounds
      newX = newX.clamp(0, gridColumns - 1);

      // Check for collisions with other stopped gems
      bool hasCollision = false;
      for (var otherGem in newGems) {
        if (!otherGem.isMoving && otherGem != movingGem) {
          if (newX == otherGem.gridX) {
            hasCollision = true;
            break;
          }
        }
      }

      // Only move if there's no collision
      if (!hasCollision) {
        movingGem.gridX = newX;
      }

      gems = newGems;
    });
  }

  void _startGameLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        final newGems = List<Gem>.from(gems);

        // First, handle movement of existing gems
        for (var gem in newGems) {
          if (gem.isMoving) {
            // Check for collision with stopped gems
            bool hasCollision = false;

            // Check collision with other stopped gems
            for (var otherGem in newGems) {
              if (!otherGem.isMoving && otherGem != gem) {
                if (_checkCollision(gem, otherGem)) {
                  hasCollision = true;
                  break;
                }
              }
            }

            // Check collision with bottom of game area
            if (gem.gridY >= 15) {
              // Last row
              hasCollision = true;
            }

            if (!hasCollision) {
              gem.gridY += 1; // Move down one row
            } else {
              gem.isMoving = false;
              // Check if the stopped gem is at the top
              if (gem.gridY <= 0) {
                isGameOver = true;
                _stopGame();
                return;
              }
            }
          }
        }

        // Then, check if we need to add a new gem
        if (newGems.isEmpty || !newGems.last.isMoving) {
          final newGem = Gem.random(size: gridCellWidth);
          newGem.gridX = 0; // Start at leftmost column
          newGem.gridY = 0; // Start at top row
          newGem.isMoving = true;
          newGems.add(newGem);
        }

        gems = newGems;
      });
    });
  }

  void _startGame() {
    // Initialize grid dimensions
    final maxWidth = MediaQuery.of(context).size.width * 0.9;
    final cellWidth = maxWidth / gridColumns;
    final cellHeight = cellWidth;
    final gameHeight = cellHeight * 16;

    // Scale down if height is too large
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final scale = gameHeight > maxHeight ? maxHeight / gameHeight : 1.0;
    final scaledWidth = maxWidth * scale;
    final scaledHeight = gameHeight * scale;

    _updateGridDimensions(scaledWidth, scaledHeight);

    // Add initial gem
    setState(() {
      final newGem = Gem.random(size: gridCellWidth);
      newGem.gridX = 0; // Leftmost column
      newGem.gridY = 0; // Top row
      newGem.isMoving = true;
      gems = [newGem];
    });

    _startGameLoop();
  }

  void togglePlayPause() {
    if (isGameOver) {
      // Reset game when game is over
      setState(() {
        isGameOver = false;
        gems = [];
        isPlaying = false;
      });
      return;
    }

    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        if (gems.isEmpty) {
          _startGame();
        } else {
          _startGameLoop();
        }
      } else {
        _stopGame();
      }
    });
  }

  void _stopGame() {
    _timer?.cancel();
  }

  void _resetGame() {
    setState(() {
      isGameOver = false;
      gems = [];
      isPlaying = false;
    });
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: _resetGame,
                        icon: const Icon(
                          Icons.refresh,
                          size: 32,
                          color: Colors.black,
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
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate the maximum possible size while maintaining 8:16 aspect ratio
                    final maxWidth = constraints.maxWidth * 0.9;
                    final maxHeight = constraints.maxHeight;

                    // Calculate cell size based on width
                    final cellWidth = maxWidth / gridColumns;
                    final cellHeight = cellWidth;
                    final gameHeight = cellHeight * 16;

                    // Scale down if height is too large
                    final scale =
                        gameHeight > maxHeight ? maxHeight / gameHeight : 1.0;
                    final scaledWidth = maxWidth * scale;
                    final scaledHeight = gameHeight * scale;
                    final scaledCellWidth = cellWidth * scale;
                    final scaledCellHeight = cellHeight * scale;

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
                                    cellWidth: scaledCellWidth,
                                    cellHeight: scaledCellHeight,
                                    columns: gridColumns,
                                  ),
                                ),
                                GestureDetector(
                                  onTapUp: _handleTap,
                                  behavior: HitTestBehavior.opaque,
                                  child: Stack(
                                    children: [
                                      for (var gem in gems)
                                        Positioned(
                                          left: gem.gridX * scaledCellWidth,
                                          top: gem.gridY * scaledCellHeight,
                                          child: SizedBox(
                                            width: scaledCellWidth,
                                            height: scaledCellHeight,
                                            child: Center(
                                              child: gem.build(context),
                                            ),
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
