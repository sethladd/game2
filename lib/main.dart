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
  static const double gemHeight = 40; // Size of a single gem
  static const double gemWidth = 40;
  static const double gemPairSpacing = 8; // Spacing between gems in a pair
  static const double totalGemPairHeight =
      gemHeight * 2 +
      gemPairSpacing; // Total height of a gem pair including spacing

  bool _checkCollision(GemPair movingPair, GemPair stoppedPair) {
    // Check vertical collision (bottom of moving pair touching top of stopped pair)
    final movingBottom = movingPair.yPosition + totalGemPairHeight;
    final stoppedTop = stoppedPair.yPosition;

    // Check horizontal alignment (x-positions are close enough)
    final horizontalOverlap =
        (movingPair.xPosition - stoppedPair.xPosition).abs() < gemWidth;

    // Add a small buffer to ensure gems don't overlap
    return horizontalOverlap && movingBottom >= stoppedTop - 2;
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
        movingPair.xPosition = (movingPair.xPosition - gemWidth).clamp(
          16.0,
          gameAreaWidth - gemWidth - 16,
        );
      } else {
        // Move right
        movingPair.xPosition = (movingPair.xPosition + gemWidth).clamp(
          16.0,
          gameAreaWidth - gemWidth - 16,
        );
      }

      gemPairs = newGemPairs;
    });
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
              pair.yPosition += 2;
            } else {
              pair.isMoving = false;
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
          final newPair = GemPair.random();
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
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple, width: 2),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            gameAreaHeight = constraints.maxHeight;
                            gameAreaWidth = constraints.maxWidth;
                            return GestureDetector(
                              onTapUp: _handleTap,
                              behavior: HitTestBehavior.opaque,
                              child: Stack(
                                children: [
                                  for (var pair in gemPairs)
                                    Positioned(
                                      left: pair.xPosition,
                                      top: pair.yPosition,
                                      child: Column(
                                        children: [
                                          pair.gem1.build(context),
                                          SizedBox(height: gemPairSpacing),
                                          pair.gem2.build(context),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
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
