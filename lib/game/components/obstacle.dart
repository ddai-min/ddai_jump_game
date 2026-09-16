import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../ui/game_theme.dart';
import '../jump_game.dart';

/// 장애물의 종류. 크기와 공중 여부를 같이 들고 다닌다.
enum ObstacleKind {
  /// 한 번 점프로 가볍게 넘는 작은 바위.
  smallRock(width: 20, height: 32),

  /// 조금 높은 돌기둥.
  tallRock(width: 22, height: 54),

  /// 낮고 넓은 가시밭. 높이보다 폭이 부담스럽다.
  spikes(width: 54, height: 20),

  /// 높이가 제각각인 돌무더기.
  cluster(width: 46, height: 38),

  /// 공중을 날아오는 새. 뛰면 오히려 부딪히니 그냥 달려서 지나가야 한다.
  bird(width: 36, height: 22, isAerial: true);

  const ObstacleKind({
    required this.width,
    required this.height,
    this.isAerial = false,
  });

  final double width;
  final double height;

  /// 공중에 떠 있어서 점프가 정답이 아닌 장애물인지.
  final bool isAerial;
}

/// 오른쪽에서 왼쪽으로 흘러오는 장애물.
class Obstacle extends PositionComponent with HasGameReference<JumpGame> {
  Obstacle({required this.kind, required double x, required double bottomY})
    : _baseY = bottomY,
      super(
        position: Vector2(x, bottomY),
        size: Vector2(kind.width, kind.height),
        anchor: Anchor.bottomLeft,
        priority: 15,
      );

  final ObstacleKind kind;
  final double _baseY;

  double _wingPhase = 0;

  final Paint _paint = Paint();

  @override
  Future<void> onLoad() async {
    // 뾰족한 끝까지 판정을 잡으면 억울하게 죽으니, 크기 대비 비율만큼 줄여 둔다.
    final (left, top, right, bottom) = switch (kind) {
      ObstacleKind.spikes => (0.06, 0.28, 0.06, 0.0),
      ObstacleKind.bird => (0.14, 0.16, 0.16, 0.14),
      _ => (0.12, 0.2, 0.12, 0.0),
    };

    add(
      RectangleHitbox(
        position: Vector2(size.x * left, size.y * top),
        size: Vector2(size.x * (1 - left - right), size.y * (1 - top - bottom)),
        collisionType: CollisionType.passive,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= game.scrollSpeed * dt;

    if (kind.isAerial) {
      _wingPhase += dt * 11;
      // 위아래로 살짝 일렁이며 날아온다.
      position.y = _baseY + math.sin(_wingPhase * 0.45) * 4;
    }

    if (position.x + size.x < -40) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    switch (kind) {
      case ObstacleKind.smallRock || ObstacleKind.tallRock:
        _renderSpire(canvas, Rect.fromLTWH(0, 0, size.x, size.y));
      case ObstacleKind.spikes:
        _renderSpikes(canvas);
      case ObstacleKind.cluster:
        _renderCluster(canvas);
      case ObstacleKind.bird:
        _renderBird(canvas);
    }
  }

  /// 아래는 넓고 위로 갈수록 뾰족해지는 돌기둥 하나.
  void _renderSpire(Canvas canvas, Rect rect) {
    final path = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left + rect.width * 0.12, rect.top + rect.height * 0.3)
      ..lineTo(rect.center.dx, rect.top)
      ..lineTo(rect.right - rect.width * 0.12, rect.top + rect.height * 0.3)
      ..lineTo(rect.right, rect.bottom)
      ..close();

    _paint.color = GamePalette.obstacle;
    canvas.drawPath(path, _paint);

    // 오른쪽 절반을 어둡게 덮어 빛이 왼쪽에서 오는 것처럼 보이게 한다.
    canvas.save();
    canvas.clipPath(path);
    _paint.color = GamePalette.obstacleShade;
    canvas.drawRect(
      Rect.fromLTRB(rect.center.dx, rect.top, rect.right, rect.bottom),
      _paint,
    );
    canvas.restore();
  }

  void _renderSpikes(Canvas canvas) {
    const count = 4;
    final step = size.x / count;
    final path = Path();
    for (var i = 0; i < count; i++) {
      path
        ..moveTo(i * step, size.y)
        ..lineTo(i * step + step / 2, 0)
        ..lineTo((i + 1) * step, size.y)
        ..close();
    }

    _paint.color = GamePalette.obstacle;
    canvas.drawPath(path, _paint);

    canvas.save();
    canvas.clipPath(path);
    _paint.color = GamePalette.obstacleShade;
    canvas.drawRect(Rect.fromLTRB(0, size.y * 0.55, size.x, size.y), _paint);
    canvas.restore();
  }

  void _renderCluster(Canvas canvas) {
    const heights = <double>[0.62, 1, 0.78];
    final step = size.x / heights.length;
    for (var i = 0; i < heights.length; i++) {
      final height = size.y * heights[i];
      _renderSpire(
        canvas,
        Rect.fromLTWH(i * step, size.y - height, step * 0.92, height),
      );
    }
  }

  void _renderBird(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    _paint.color = GamePalette.bird;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.1, h * 0.28, w * 0.66, h * 0.52),
      _paint,
    );
    canvas.drawCircle(Offset(w * 0.76, h * 0.42), h * 0.26, _paint);

    // 부리
    final beak = Path()
      ..moveTo(w * 0.9, h * 0.34)
      ..lineTo(w, h * 0.46)
      ..lineTo(w * 0.9, h * 0.54)
      ..close();
    _paint.color = GamePalette.coin;
    canvas.drawPath(beak, _paint);

    // 날개. 위아래로 퍼덕인다.
    final flap = math.sin(_wingPhase);
    final wing = Path()
      ..moveTo(w * 0.24, h * 0.42)
      ..lineTo(w * 0.46, h * 0.42 - flap * h * 0.75)
      ..lineTo(w * 0.66, h * 0.46)
      ..close();
    _paint.color = GamePalette.birdShade;
    canvas.drawPath(wing, _paint);

    _paint.color = GamePalette.playerEye;
    canvas.drawCircle(Offset(w * 0.82, h * 0.38), 1.8, _paint);
  }
}
