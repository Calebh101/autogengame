import 'package:autogengame/enum.dart';
import 'package:autogengame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

final double tilemultiplier = 60;

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

class Tile {
  final TilePosition? position;
  final double size;
  final List<BlockIdentifier> identifiers;
  const Tile({this.position, this.size = 50, this.identifiers = const []});
}

class BlockTile extends Tile {
  final Color color;
  const BlockTile({required super.position, this.color = Colors.red, super.size = 50, super.identifiers = const []});
}

class TilePosition {
  bool reverse = false;
  final double x;
  final double y;

  TilePosition(this.x, this.y);
  TilePosition.reverse(this.x, this.y) {reverse = true;}

  Vector2 build() {
    if (reverse) {
      return Vector2((x / tilemultiplier).round().toDouble(), (screenHeight - tilemultiplier) - (y / tilemultiplier).round().toDouble());
    } else {
      return Vector2(x * tilemultiplier, (screenHeight - tilemultiplier) - (y * tilemultiplier));
    }
  }
}

class EnemyComponent extends Component {
  SpriteAnimationComponent? sprite;
  TilePosition position;
  EnemyComponent({this.sprite, required this.position});
}

class SimpleEnemy1 extends EnemyComponent {
  SimpleEnemy1({super.sprite, required super.position});
  double xPos = 0;
  double yPos = 0;
  double xTrajectory = 1;
  double yTrajectory = 0;

  @override
  Future<void> onLoad() async {
    print("enemy loaded: ${position.y}");
    super.onLoad();
    sprite = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList([
        await Sprite.load("sprites/enemies/SimpleEnemy1/walk1.png"),
        await Sprite.load("sprites/enemies/SimpleEnemy1/walk2.png"),
      ], stepTime: 0.5),
    );
    xPos = position.x;
    yPos = position.y;
    add(sprite!);
  }

  @override
  void render(Canvas canvas) {
    final Vector2 currentTilePosition = TilePosition.reverse(xPos, yPos).build();

    Tile? ground = lookupTile(xPos, yPos - 1);
    if (ground != null) {
      yTrajectory++;
    } else {
      yTrajectory = 0;
    }

    if (xTrajectory < 0) {
      Tile? leftBlock = lookupTile(xPos - 1, yPos);
      if (leftBlock != null) {
        xTrajectory = 1;
      }
    }

    if (xTrajectory > 0) {
      Tile? rightBlock = lookupTile(xPos + 1, yPos);
      if (rightBlock != null) {
        xTrajectory = -1;
      }
    }

    xPos = xPos + xTrajectory;
    yPos = yPos - yTrajectory;

    double sizeX = TilePosition(offset.zoom, offset.zoom).build().x;
    sprite?.position = Vector2((xPos - offset.x) * offset.zoom, (yPos + offset.y) * offset.zoom);
    sprite?.size = Vector2(sizeX, sizeX);
    super.render(canvas);
  }
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

class Position {
  int position;
  int maxPosition;
  Trajectory trajectory;
  Position(this.position, {required this.trajectory, required this.maxPosition});

  void change(int amount) {
    if (position.abs() >= maxPosition) {
      trajectory = (trajectory == Trajectory.positive ? Trajectory.negative : Trajectory.positive);
    }
    position = position + (amount * (trajectory == Trajectory.positive ? 1 : -1));
    print("changed position to $position ($trajectory)");
  }
}