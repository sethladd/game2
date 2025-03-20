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

  Gem({required this.type, required this.color, this.size = 40});

  Color get colorValue {
    switch (color) {
      case GemColor.blue:
        return Colors.blue;
      case GemColor.green:
        return Colors.green;
      case GemColor.red:
        return Colors.red;
      case GemColor.yellow:
        return Colors.yellow;
    }
  }

  Widget build(BuildContext context) {
    if (type == GemType.diamond) {
      return Transform.rotate(
        angle: math.pi / 4, // 45 degrees
        child: Container(
          width: size / math.sqrt(2), // Scale down to match width of other gems
          height:
              size / math.sqrt(2), // Scale down to match width of other gems
          decoration: BoxDecoration(
            color: colorValue,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorValue,
        shape: type == GemType.bomb ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            type == GemType.standard ? BorderRadius.circular(8) : null,
      ),
    );
  }
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

  static GemPair random() {
    final random = math.Random();
    final types = GemType.values;
    final colors = GemColor.values;

    final type1 = types[random.nextInt(types.length)];
    final type2 = types[random.nextInt(types.length)];
    final color1 = colors[random.nextInt(colors.length)];
    final color2 = colors[random.nextInt(colors.length)];

    return GemPair(
      gem1: Gem(type: type1, color: color1),
      gem2: Gem(type: type2, color: color2),
    );
  }
}
