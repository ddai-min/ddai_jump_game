import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../ui/game_theme.dart';
import '../jump_game.dart';
import 'coin.dart';
import 'obstacle.dart';

/// 플레이어 캐릭터.
///
/// 가로로는 움직이지 않는다. 화면 왼쪽 고정 위치에서 점프만 하고, 앞으로
/// 나아가는 느낌은 배경과 장애물이 왼쪽으로 흐르며 만들어 낸다.
///
/// 조작감을 위해 세 가지 장치를 둔다.
/// - 코요테 타임: 바닥에서 막 떨어진 직후에도 잠깐은 점프를 받아 준다.
/// - 점프 버퍼: 착지 직전에 누른 점프를 기억했다가 닿자마자 뛴다.
/// - 가변 점프: 키를 일찍 떼면 상승 속도를 깎아 낮게 뛴다.
class Player extends PositionComponent
    with HasGameReference<JumpGame>, CollisionCallbacks {
  Player() : super(anchor: Anchor.bottomCenter, priority: 20);

  /// 세로 속도. 아래로 향할 때가 양수다.
  double velocityY = 0;

  bool isOnGround = true;
  bool isDead = false;

  int _jumpsUsed = 0;
  double _coyoteLeft = 0;
  double _bufferLeft = 0;

  /// 찌그러짐 정도. 1이면 납작, -1이면 길쭉하다.
  double _squash = 0;
  double _runPhase = 0;
  double _deathAngle = 0;

  final Paint _paint = Paint();

  @override
  Future<void> onLoad() async {
    final config = game.config;
    size = Vector2(config.playerWidth, config.playerHeight);

    // 눈에 보이는 몸집보다 판정을 조금 작게 잡아 억울한 충돌을 줄인다.
    add(
      RectangleHitbox(
        position: Vector2(size.x * 0.17, size.y * 0.10),
        size: Vector2(size.x * 0.66, size.y * 0.84),
      ),
    );
    reset();
  }

  /// 시작 위치로 되돌린다.
  void reset() {
    final config = game.config;
    position = Vector2(config.playerX, config.groundTop);
    velocityY = 0;
    isOnGround = true;
    isDead = false;
    _jumpsUsed = 0;
    _coyoteLeft = config.coyoteSeconds;
    _bufferLeft = 0;
    _squash = 0;
    _runPhase = 0;
    _deathAngle = 0;
  }

  /// 지금 점프를 시작할 수 있는지.
  bool get canJump =>
      _jumpsUsed < game.config.maxJumps &&
      (_jumpsUsed > 0 || isOnGround || _coyoteLeft > 0);

  /// 점프 입력이 들어왔다.
  ///
  /// 당장 뛸 수 없으면 입력을 잠시 기억해 뒀다가 착지하는 순간 대신 뛰어 준다.
  void onJumpPressed() {
    if (isDead) {
      return;
    }
    if (canJump) {
      _startJump();
    } else {
      _bufferLeft = game.config.jumpBufferSeconds;
    }
  }

  /// 점프 입력을 뗐다. 아직 올라가는 중이면 속도를 깎아 낮게 뛴다.
  ///
  /// 다만 [GameConfig.minJumpHeight]까지는 반드시 올라가게 둔다. 그러지
  /// 않으면 짧게 탭한 것만으로 장애물을 못 넘는 상황이 생긴다.
  void onJumpReleased() {
    if (isDead || velocityY >= -80) {
      return;
    }

    final config = game.config;
    final currentHeight = config.groundTop - position.y;
    final remaining = math.max(0.0, config.minJumpHeight - currentHeight);
    final keepSpeed = math.sqrt(2 * config.gravity * remaining);
    final cutSpeed = -velocityY * config.jumpCutFactor;

    // 부호를 뒤집어 다루다가 마지막에만 되돌린다. 원래 속도보다 빨라지지는 않는다.
    velocityY = -math.min(math.max(cutSpeed, keepSpeed), -velocityY);
  }

  /// 장애물에 부딪혔다. 위로 한 번 튕겼다가 화면 밖으로 떨어진다.
  void kill() {
    if (isDead) {
      return;
    }
    isDead = true;
    isOnGround = false;
    velocityY = -360;
    _squash = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 찌그러짐은 매 프레임 조금씩 원래대로 돌아간다.
    _squash *= 1 - math.min(1, dt * 9);

    if (isDead) {
      _updateDeath(dt);
      return;
    }

    final config = game.config;

    if (isOnGround) {
      _coyoteLeft = config.coyoteSeconds;
      _runPhase += dt * game.scrollSpeed / 26;
    } else {
      _coyoteLeft = math.max(0, _coyoteLeft - dt);
    }

    if (_bufferLeft > 0) {
      _bufferLeft = math.max(0, _bufferLeft - dt);
      if (canJump) {
        _startJump();
      }
    }

    // 떨어질 때 중력을 더 세게 주면 점프가 붕 뜨지 않고 경쾌해진다.
    final gravity = velocityY > 0
        ? config.gravity * config.fallGravityScale
        : config.gravity;

    // 속도를 먼저 더하고 위치를 옮기면 프레임마다 조금씩 높이를 잃는다.
    // 60Hz와 120Hz에서 점프 높이가 달라지지 않도록 등가속도 구간을 그대로
    // 적분한다.
    position.y += (velocityY + 0.5 * gravity * dt) * dt;
    velocityY += gravity * dt;

    if (position.y >= config.groundTop) {
      final landingSpeed = velocityY;
      position.y = config.groundTop;
      velocityY = 0;
      if (!isOnGround) {
        isOnGround = true;
        _jumpsUsed = 0;
        if (landingSpeed > 150) {
          _squash = 0.7;
          game.emitDust(position.clone(), count: 9);
        }
      }
    } else {
      isOnGround = false;
    }
  }

  void _updateDeath(double dt) {
    final gravity = game.config.gravity;
    position.y += (velocityY + 0.5 * gravity * dt) * dt;
    velocityY += gravity * dt;
    // 부딪힌 자리에서 뒤로 밀려나며 굴러 떨어진다.
    position.x -= 60 * dt;
    _deathAngle += 7 * dt;
  }

  void _startJump() {
    final config = game.config;
    final isFirstJump = _jumpsUsed == 0;

    velocityY = -(isFirstJump ? config.jumpSpeed : config.doubleJumpSpeed);
    _jumpsUsed++;
    isOnGround = false;
    _coyoteLeft = 0;
    _bufferLeft = 0;
    _squash = -0.6;

    game.emitDust(
      position.clone(),
      count: isFirstJump ? 7 : 5,
      color: isFirstJump ? GamePalette.dust : GamePalette.playerScarf,
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (isDead) {
      return;
    }
    if (other is Obstacle) {
      game.onPlayerHit();
    } else if (other is Coin && !other.isCollected) {
      // 떼어낸 뒤에는 좌표를 믿을 수 없으니 먼저 읽어 둔다.
      final at = other.absoluteCenter;
      other.collect();
      game.onCoinCollected(at);
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    if (!isDead) {
      _renderShadow(canvas, w, h);
    }

    canvas.save();
    if (isDead) {
      canvas.translate(w / 2, h / 2);
      canvas.rotate(_deathAngle);
      canvas.translate(-w / 2, -h / 2);
    } else {
      // 발밑을 축으로 눌렸다 펴져야 바닥에 붙어 있는 것처럼 보인다.
      canvas.translate(w / 2, h);
      canvas.scale(1 + _squash * 0.3, 1 - _squash * 0.3);
      canvas.translate(-w / 2, -h);
    }

    _renderScarf(canvas, w);
    _renderLegs(canvas, w, h);
    _renderBody(canvas, w, h);
    _renderFace(canvas, w);

    canvas.restore();
  }

  /// 바닥에 드리우는 그림자. 높이 뜰수록 작고 옅어져 높이를 가늠하게 해 준다.
  void _renderShadow(Canvas canvas, double w, double h) {
    final heightAboveGround = math.max(0.0, game.config.groundTop - position.y);
    final t = (heightAboveGround / game.config.jumpHeight).clamp(0.0, 1.0);
    final width = w * (0.9 - 0.42 * t);

    _paint.color = GamePalette.background.withValues(
      alpha: 0.5 * (1 - t * 0.6),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h + heightAboveGround - 1),
        width: width,
        height: width * 0.26,
      ),
      _paint,
    );
  }

  void _renderScarf(Canvas canvas, double w) {
    final wave = math.sin(_runPhase * 1.7) * 3;
    final lift = isOnGround ? 0.0 : -4.0;
    final path = Path()
      ..moveTo(w * 0.2, 10)
      ..quadraticBezierTo(-6, 9 + wave + lift, -15, 15 + wave * 1.6 + lift)
      ..quadraticBezierTo(-6, 16 + wave + lift, w * 0.2, 19);

    _paint.color = GamePalette.playerScarf;
    canvas.drawPath(path, _paint);
  }

  void _renderLegs(Canvas canvas, double w, double h) {
    // 바닥에 있을 때만 다리를 번갈아 흔들고, 공중에서는 몸쪽으로 접는다.
    final swing = isOnGround ? math.sin(_runPhase) * 5.5 : 0.0;
    final tuck = isOnGround ? 0.0 : 4.0;
    final top = h - 13;
    const legWidth = 7.0;

    _paint.color = GamePalette.playerShade;
    for (final left in <double>[w * 0.24 - swing, w * 0.55 + swing]) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          top,
          left + legWidth,
          h - tuck,
          const Radius.circular(3),
        ),
        _paint,
      );
    }
  }

  void _renderBody(Canvas canvas, double w, double h) {
    final bodyBottom = h - 8;
    final body = RRect.fromLTRBR(
      0,
      0,
      w,
      bodyBottom,
      const Radius.circular(10),
    );

    _paint.color = GamePalette.player;
    canvas.drawRRect(body, _paint);

    // 아래쪽에 어두운 띠를 한 겹 깔아 입체감을 준다.
    canvas.save();
    canvas.clipRRect(body);
    _paint.color = GamePalette.playerShade;
    canvas.drawRect(Rect.fromLTRB(0, bodyBottom - 9, w, bodyBottom), _paint);
    canvas.restore();
  }

  void _renderFace(Canvas canvas, double w) {
    _paint.color = GamePalette.textPrimary;
    canvas.drawCircle(Offset(w * 0.66, 14), 5.4, _paint);

    // 죽으면 눈이 뒤집힌다.
    _paint.color = GamePalette.playerEye;
    if (isDead) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(w * 0.66, 14), width: 7, height: 1.8),
        _paint,
      );
    } else {
      canvas.drawCircle(Offset(w * 0.66 + 1.6, 14.4), 2.5, _paint);
    }
  }
}
