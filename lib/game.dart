import 'dart:math';

import 'package:autogengame/class.dart';
import 'package:autogengame/enum.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localpkg/logger.dart';

List<Tile> tiles = [];
double screenHeight = 0;
late Offset offset;
late Vector2 globalSize;

void buildBlocks(List tiles, {required Canvas canvas, required MyGame game, Offset? offset}) {
  offset ??= Offset(0, 0);
  if (offset.zoom <= 0) offset.zoom = 0.01;

  for (Tile tile in tiles) {
    double size = tile.size * offset.zoom;
    if (tile is BlockTile) {
      BlockTile block = tile;
      canvas.drawRect(Rect.fromLTWH((block.position!.build().x - offset.x) * offset.zoom, (block.position!.build().y + offset.y) * offset.zoom, size, size), Paint()..color = block.color);
    }
  }
}

Future<void> highlightTile(TilePosition position, {int? timeout = 5}) async {
  tiles.add(BlockTile(position: position, color: Colors.grey));
  if (timeout != null) {
    await Future.delayed(Duration(seconds: timeout));
    tiles.removeWhere(
      (tile) => tile.position?.x == position.x && tile.position?.y == position.y,
    );
  }
}

Tile? lookupTile(double x, double y, {List<BlockIdentifier> identifiers = const [], bool highlight = true}) {
  //if (highlight) highlightTile(TilePosition(x, y));

  try {
    Tile tile = tiles.firstWhere(
      (tile) => tile.position?.x == x && tile.position?.y == y && identifiers.every((item) => tile.identifiers.contains(item)),
    );
    return tile;
  } catch (e) {
    return null;
  }
}

List<Tile> generateBlocks({int count = 2000, TilePosition? startingPosition, int? seed, required MyGame game}) {
  startingPosition ??= TilePosition(0, 0);
  seed ??= Random().nextInt(4294967296);
  print("generating tiles... (seed: $seed)");

  List<Tile> tiles = [];
  List<TilePosition> positionsTaken = [];

  double x = startingPosition.x;
  double y = startingPosition.y;
  int trajectory = 0;
  int lastPit = 0;
  int lastSpike = 0;
  int lastPlatform = 0;

  void addTile(Tile block) {
    tiles.add(block);
    if (block.position != null) positionsTaken.add(block.position!);
  }
  
  for (var i = 0; i < count; i++) {
    int generateSeed([int change = 0]) {
      int number = int.parse("$seed$i$change");
      return number;
    }

    x++;

    if (Random(generateSeed(14)).nextInt(15) == 0 && (i - lastSpike) > 3 && (i - lastPit) > 2) {
      print("adding enemy at ($x,${y + 1})");
      game.add(SimpleEnemy1(position: TilePosition(x, y + 1)));
      addTile(BlockTile(position: TilePosition(x, y + 1), color: Colors.yellow));
    }

    if (Random(generateSeed(1)).nextInt(2) == 0) {
      trajectory = trajectory + (trajectory == 3 ? -1 : (trajectory == -3 ? 1 : (Random(generateSeed(3)).nextBool() ? 1 : -1)));
    }

    if (trajectory != 0) {
      if (trajectory.abs() == 1) {
        if (i % 3 == 0) {
          y = y + (Random(generateSeed(2)).nextBool() ? 1 : -1);
        }
      }

      if (trajectory.abs() == 2) {
        if (i % 2 == 0) {
          y + (Random(generateSeed(4)).nextBool() ? 1 : -1);
        }
      }

      if (trajectory.abs() == 3) {
        y + (Random(generateSeed(5)).nextBool() ? 1 : -1);
      }
    }

    if (Random(generateSeed(6)).nextInt(Random(generateSeed(11)).nextInt(30) + 10) == 0 && (i - lastPit) > 3) {
      x = x + (Random(generateSeed(8)).nextInt(5) + 2);
      lastPit = x.toInt();
    }

    if (Random(generateSeed(7)).nextInt(10) == 0 && (i - lastSpike) > 3 && (i - lastPit) > 3) {
      int x2 = x.toInt();
      for (var i2 = 0; i2 < Random(generateSeed(10)).nextInt(2) + 1; i2++) {
        x2++;
        lastSpike = x2;
        addTile(BlockTile(position: TilePosition(x2.toDouble(), y + 1), color: Colors.red, identifiers: [BlockIdentifier.solid]));
        addTile(BlockTile(position: TilePosition(x, y), color: Colors.green, identifiers: [BlockIdentifier.solid]));
        x++;
      }
    }

    if (Random(generateSeed(12)).nextInt(10) == 0 && (i - lastPlatform) > 10) {
      int x2 = x.toInt();
      for (var i2 = 0; i2 < Random(generateSeed(10)).nextInt(4) + 3; i2++) {
        x2++;
        lastPlatform = x2;
        addTile(BlockTile(position: TilePosition(x2.toDouble(), y + (Random(generateSeed(13)).nextInt(3) + 4)), color: Colors.blue, identifiers: [BlockIdentifier.solid]));
      }
    }

    addTile(BlockTile(position: TilePosition(x, y), color: Colors.green, identifiers: [BlockIdentifier.solid]));
  }

  print("generated tiles");
  return tiles;
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
    tiles = generateBlocks(game: this);
    offset = Offset(0, 0, zoom: 1);
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
    buildBlocks(tiles, canvas: canvas, offset: offset, game: this);
  }

  @override
  Future<void> update(double dt) async {
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
      if (_keysPressed.contains(LogicalKeyboardKey.keyQ)) {
        tiles = generateBlocks(game: this);
      }
    } else if (event is KeyUpEvent) {
      _keysPressed.remove(event.logicalKey);
    }

    return KeyEventResult.handled;
  }
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