// Copyright 2025 Seth Ladd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'dart:math' as math;

enum GemType { standard, bomb, diamond }

enum GemColor { blue, green, red, yellow }

class Gem {
  final GemType type;
  final GemColor color;
  final double size;
  int gridX = 0; // Column position (0-7)
  int gridY = 0; // Row position (0-15)
  bool isMoving = true;

  Gem({required this.type, required this.color, required this.size});

  Color get colorValue {
    switch (color) {
      case GemColor.red:
        return Colors.red;
      case GemColor.blue:
        return Colors.blue;
      case GemColor.green:
        return Colors.green;
      case GemColor.yellow:
        return Colors.yellow;
    }
  }

  static Gem random({required double size}) {
    final random = math.Random();
    final types = GemType.values;
    final colors = GemColor.values;

    final type = types[random.nextInt(types.length)];
    final color = colors[random.nextInt(colors.length)];

    return Gem(type: type, color: color, size: size);
  }

  Widget build(BuildContext context) {
    if (type == GemType.diamond) {
      return CustomPaint(
        size: Size(
          size * 0.8,
          size * 0.8,
        ), // Make diamond slightly smaller than cell
        painter: DiamondPainter(color: colorValue),
      );
    }

    return Container(
      width: size * 0.8, // Make gems slightly smaller than cell
      height: size * 0.8, // Make gems slightly smaller than cell
      decoration: BoxDecoration(
        color: colorValue,
        shape: type == GemType.bomb ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            type == GemType.standard ? BorderRadius.circular(4) : null,
      ),
    );
  }
}

class DiamondPainter extends CustomPainter {
  final Color color;

  DiamondPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final width = size.width;
    final height = size.height;

    path.moveTo(centerX, centerY - height / 2); // Top
    path.lineTo(centerX + width / 2, centerY); // Right
    path.lineTo(centerX, centerY + height / 2); // Bottom
    path.lineTo(centerX - width / 2, centerY); // Left
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DiamondPainter oldDelegate) => color != oldDelegate.color;
}

class GemPair {
  final Gem gem1;
  final Gem gem2;
  double yPosition;
  double xPosition;
  bool isMoving;

  GemPair({
    required this.gem1,
    required this.gem2,
    this.yPosition = 0,
    this.xPosition = 0,
    this.isMoving = true,
  });

  static GemPair random({required double size}) {
    final random = math.Random();
    final types = GemType.values;
    final colors = GemColor.values;

    final type1 = types[random.nextInt(types.length)];
    final type2 = types[random.nextInt(types.length)];
    final color1 = colors[random.nextInt(colors.length)];
    final color2 = colors[random.nextInt(colors.length)];

    return GemPair(
      gem1: Gem(type: type1, color: color1, size: size),
      gem2: Gem(type: type2, color: color2, size: size),
    );
  }
}
