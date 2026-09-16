import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../ui/game_theme.dart';
import '../jump_game.dart';

/// 점프 궤적 위에 놓이는 보너스 코인.
///
/// 굳이 먹지 않아도 되지만, 잘 넘을수록 자연스럽게 지나가는 자리에 놓이기
/// 때문에 점프 높이를 다듬게 만드는 역할을 한다.
class Coin extends PositionComponent
    with HasGameReference<JumpGame>, CollisionCallbacks {
  Coin({required super.position})
    : super(size: Vector2.all(18), anchor: Anchor.center, priority: 14);

  bool isCollected = false;
  double _spin = 0;

  final Paint _paint = Paint();

  @override
  Future<void> onLoad() async {
    // 같은 아치 안에서도 조금씩 다른 각도로 돌게 해 줄지어 도는 티를 없앤다.
    _spin = position.x * 0.03;
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= game.scrollSpeed * dt;
    _spin += dt * 3.4;

    if (position.x + size.x < -40) {
      removeFromParent();
    }
  }

  /// 플레이어가 먹었다.
  void collect() {
    if (isCollected) {
      return;
    }
    isCollected = true;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    final center = Offset(radius, radius);

    // 가로 폭만 줄였다 늘리면 제자리에서 도는 동전처럼 보인다.
    final squeeze = math.max(0.16, math.cos(_spin).abs());
    final width = size.x * squeeze;

    _paint.color = GamePalette.coinShade;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: size.y),
      _paint,
    );

    _paint.color = GamePalette.coin;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: math.max(0, width - 3.2),
        height: size.y - 3.2,
      ),
      _paint,
    );

    // 옆으로 많이 돌아간 순간에는 가운데 홈이 보이지 않는다.
    if (squeeze > 0.5) {
      _paint.color = GamePalette.coinShade;
      canvas.drawRect(
        Rect.fromCenter(
          center: center,
          width: 2.6 * squeeze,
          height: size.y * 0.44,
        ),
        _paint,
      );
    }
  }
}
