import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localpkg/logger.dart';

List<Block> blocks = [];
double screenHeight = 0;
late Offset offset;
late Vector2 globalSize;

void buildBlocks(List blocks, {required Canvas canvas, Offset? offset}) {
  offset ??= Offset(0, 0);

  for (Block block in blocks) {
    double size = block.size * offset.zoom;
    canvas.drawRect(Rect.fromLTWH((block.position.build().x - offset.x) * offset.zoom, (block.position.build().y + offset.y) * offset.zoom, size, size), Paint()..color = block.color);
  }
}

List<Block> generateBlocks({int count = 2000, int minX = 0, int maxX = 100, int minY = 20, int maxY = 20, BlockPosition startingPosition = const BlockPosition(0, 0)}) {
  List<Block> blocks = [];
  List<BlockPosition> positionsTaken = [];

  double x = startingPosition.x;
  double y = startingPosition.y;
  int trajectory = 0;

  void addBlock(Block block) {
    blocks.add(block);
    positionsTaken.add(block.position);
  }
  
  for (var i = 0; i < count; i++) {
    x++;
    if (Random().nextInt(2) == 0) {
      trajectory = trajectory + (trajectory == 3 ? -1 : (trajectory == -3 ? 1 : (Random().nextBool() ? 1 : -1)));
    }

    if (trajectory != 0) {
      if (trajectory.abs() == 1) {
        if (i % 3 == 0) {
          y = y + (Random().nextBool() ? 1 : -1);
        }
      }

      if (trajectory.abs() == 2) {
        if (i % 2 == 0) {
          y + (Random().nextBool() ? 1 : -1);
        }
      }

      if (trajectory.abs() == 3) {
        y + (Random().nextBool() ? 1 : -1);
      }
    }

    addBlock(Block(position: BlockPosition(x, y), color: Colors.red));
  }

  print("generated blocks");
  return blocks;
}

/// Offsets have an x, a y, and a zoom.
/// - x goes right if positive
/// - y goes up if positive
/// - zoom will increase size if more than 1, decrease size if less than 1, and hide everything if 0
class Offset {
  double x;
  double y;
  double zoom;

  Offset(this.x, this.y, {this.zoom = 1});
}

bool isShiftPressed({required List keys}) {
  return keys.contains(LogicalKeyboardKey.shiftLeft) || keys.contains(LogicalKeyboardKey.shiftRight);
}

class MyGame extends FlameGame with KeyboardEvents, ScrollDetector {
  late SpriteComponent player;
  List _keysPressed = [];

  @override
  Future<void> onLoad() async {
    print("loading game...");
    screenHeight = size.y;
    blocks = generateBlocks();
    offset = Offset(0, 0, zoom: 0.25);
    super.onLoad();
  }

  @override
  void onScroll(PointerScrollInfo info) {
    double speed = 0.05;
    offset.zoom = offset.zoom + ((info.scrollDelta.global.y < 0 ? speed : (0 - speed)) * (isShiftPressed(keys: _keysPressed) ? 1.5 : 1));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    buildBlocks(blocks, canvas: canvas, offset: offset);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_keysPressed.contains(LogicalKeyboardKey.arrowUp) || _keysPressed.contains(LogicalKeyboardKey.keyW)) {
      moveScreen(Direction.up, fast: isShiftPressed(keys: _keysPressed));
    }

    if (_keysPressed.contains(LogicalKeyboardKey.arrowDown) || _keysPressed.contains(LogicalKeyboardKey.keyS)) {
      moveScreen(Direction.down, fast: isShiftPressed(keys: _keysPressed));
    }

    if (_keysPressed.contains(LogicalKeyboardKey.arrowLeft) || _keysPressed.contains(LogicalKeyboardKey.keyA)) {
      moveScreen(Direction.left, fast: isShiftPressed(keys: _keysPressed));
    }

    if (_keysPressed.contains(LogicalKeyboardKey.arrowRight) || _keysPressed.contains(LogicalKeyboardKey.keyD)) {
      moveScreen(Direction.right, fast: isShiftPressed(keys: _keysPressed));
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _keysPressed.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _keysPressed.remove(event.logicalKey);
    }

    return KeyEventResult.handled;
  }
}

enum Direction {
  up,
  down,
  left,
  right,
}

void moveScreen(Direction direction, {double speed = 2, bool fast = false}) {
  double getSpeed() {
    return (speed * (fast ? 2 : 1)) / offset.zoom;
  }

  switch (direction) {
    case Direction.up: offset.y = offset.y + getSpeed();
    case Direction.down: offset.y = offset.y - getSpeed();
    case Direction.right: offset.x = offset.x + getSpeed();
    case Direction.left: offset.x = offset.x - getSpeed();
  }
}

class BlockComponent extends PositionComponent {
  final Color color;

  BlockComponent({
    required this.color,
    required Vector2 position,
    required Vector2 size,
  }) {
    this.position = position;
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = color;
    canvas.drawRect(size.toRect(), paint);
  }
}

class Block {
  final BlockPosition position;
  final Color color;
  final double size;
  const Block({required this.position, this.color = Colors.red, this.size = 50});
}

class BlockPosition {
  final double x;
  final double y;

  const BlockPosition(this.x, this.y);
  final double multiplier = 60;

  Vector2 build() {
    return Vector2(x * multiplier, (screenHeight - multiplier) - (y * multiplier));
  }
}