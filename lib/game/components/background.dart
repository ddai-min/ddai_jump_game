import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../ui/game_theme.dart';
import '../jump_game.dart';

/// 배경을 가로로 무한히 이어 붙여 그리는 레이어의 공통 뼈대.
///
/// 타일 한 칸을 [renderTile]에서 그려 두면 화면을 덮을 만큼만 반복해서 그린다.
/// 같은 그림이 계속 나오지 않도록 미리 만들어 둔 변형 여러 개를 타일 번호에
/// 따라 돌려 쓴다. 타일 양 끝을 바닥선에 붙여 두기 때문에 이음매가 보이지 않는다.
abstract class ScrollingLayer extends PositionComponent
    with HasGameReference<JumpGame> {
  ScrollingLayer({
    required this.speedFactor,
    required this.tileWidth,
    super.priority,
  });

  /// 스크롤 속도에 곱하는 값. 작을수록 멀리 있는 것처럼 천천히 흐른다.
  final double speedFactor;

  /// 타일 한 칸의 가로 길이.
  final double tileWidth;

  double _scrolled = 0;

  @override
  void update(double dt) {
    _scrolled += game.scrollSpeed * speedFactor * dt;
  }

  @override
  void render(Canvas canvas) {
    final firstTile = (_scrolled / tileWidth).floor();
    final offset = _scrolled - firstTile * tileWidth;
    final tileCount = (game.config.worldWidth / tileWidth).ceil() + 1;
    for (var i = 0; i < tileCount; i++) {
      canvas.save();
      canvas.translate(i * tileWidth - offset, 0);
      renderTile(canvas, firstTile + i);
      canvas.restore();
    }
  }

  /// 타일 한 칸을 (0, 0)이 왼쪽 위가 되도록 그린다.
  void renderTile(Canvas canvas, int index);

  /// 타일 번호를 변형 개수 안으로 접어 넣는다.
  int variantOf(int index, int variantCount) =>
      ((index % variantCount) + variantCount) % variantCount;
}

/// 움직이지 않는 밤하늘과 달.
class SkyLayer extends PositionComponent with HasGameReference<JumpGame> {
  SkyLayer() : super(priority: 0);

  final Paint _skyPaint = Paint();
  final Paint _moonPaint = Paint()..color = GamePalette.moon;
  final Paint _glowPaint = Paint();

  late Rect _skyRect;
  late Offset _moonCenter;

  @override
  Future<void> onLoad() async {
    final config = game.config;
    _skyRect = Rect.fromLTWH(0, 0, config.worldWidth, config.worldHeight);
    _skyPaint.shader = Gradient.linear(
      Offset(0, 0),
      Offset(0, config.groundTop),
      const [GamePalette.skyTop, GamePalette.skyBottom],
    );
    _moonCenter = Offset(config.worldWidth * 0.8, config.worldHeight * 0.2);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(_skyRect, _skyPaint);

    // 달무리는 반투명 원을 겹쳐 흉내 낸다.
    for (var i = 3; i >= 1; i--) {
      _glowPaint.color = GamePalette.moonGlow.withValues(alpha: 0.10 * i);
      canvas.drawCircle(_moonCenter, 26.0 + i * 9, _glowPaint);
    }
    canvas.drawCircle(_moonCenter, 22, _moonPaint);

    // 달의 분화구. 하늘색으로 살짝 파 내 입체감을 준다.
    _glowPaint.color = GamePalette.skyBottom.withValues(alpha: 0.45);
    canvas.drawCircle(_moonCenter.translate(-7, -5), 4.5, _glowPaint);
    canvas.drawCircle(_moonCenter.translate(6, 4), 3.2, _glowPaint);
    canvas.drawCircle(_moonCenter.translate(2, -9), 2.4, _glowPaint);
  }
}

/// 아주 느리게 흐르며 깜빡이는 별.
class StarLayer extends ScrollingLayer {
  StarLayer() : super(speedFactor: 0.03, tileWidth: 320, priority: 1);

  static const int _variantCount = 4;
  static const int _starsPerTile = 16;

  final List<List<_Star>> _variants = <List<_Star>>[];
  final Paint _paint = Paint();
  double _time = 0;

  @override
  Future<void> onLoad() async {
    final skyHeight = game.config.groundTop - 40;
    for (var variant = 0; variant < _variantCount; variant++) {
      final random = math.Random(9101 + variant);
      _variants.add(
        List<_Star>.generate(_starsPerTile, (_) {
          return _Star(
            x: random.nextDouble() * tileWidth,
            y: random.nextDouble() * skyHeight,
            radius: 0.6 + random.nextDouble() * 1.2,
            phase: random.nextDouble() * math.pi * 2,
          );
        }),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void renderTile(Canvas canvas, int index) {
    for (final star in _variants[variantOf(index, _variantCount)]) {
      final blink = 0.55 + 0.45 * math.sin(_time * 1.8 + star.phase);
      _paint.color = GamePalette.star.withValues(alpha: 0.25 + 0.45 * blink);
      canvas.drawCircle(Offset(star.x, star.y), star.radius, _paint);
    }
  }
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
  });

  final double x;
  final double y;
  final double radius;
  final double phase;
}

/// 저 멀리 보이는 산줄기.
class MountainLayer extends ScrollingLayer {
  MountainLayer() : super(speedFactor: 0.12, tileWidth: 300, priority: 2);

  static const int _variantCount = 3;

  final List<_MountainTile> _variants = <_MountainTile>[];
  final Paint _bodyPaint = Paint()..color = GamePalette.mountain;
  final Paint _capPaint = Paint()..color = GamePalette.mountainCap;

  @override
  Future<void> onLoad() async {
    final baseY = game.config.groundTop;
    for (var variant = 0; variant < _variantCount; variant++) {
      _variants.add(
        _MountainTile.generate(
          random: math.Random(4201 + variant),
          tileWidth: tileWidth,
          baseY: baseY,
        ),
      );
    }
  }

  @override
  void renderTile(Canvas canvas, int index) {
    final tile = _variants[variantOf(index, _variantCount)];
    canvas.drawPath(tile.body, _bodyPaint);
    canvas.drawPath(tile.caps, _capPaint);
  }
}

class _MountainTile {
  const _MountainTile(this.body, this.caps);

  /// 타일 하나 분량의 산줄기를 만든다.
  ///
  /// 양쪽 끝을 바닥선에 붙여 닫아 두면 타일끼리 이어 붙여도 경계가 보이지 않는다.
  factory _MountainTile.generate({
    required math.Random random,
    required double tileWidth,
    required double baseY,
  }) {
    const peakCount = 3;
    final body = Path()..moveTo(0, baseY);
    final caps = Path();
    final step = tileWidth / peakCount;

    for (var i = 0; i < peakCount; i++) {
      final left = i * step;
      final peakX = left + step * (0.35 + random.nextDouble() * 0.3);
      final height = 44 + random.nextDouble() * 48;
      final peakY = baseY - height;
      final right = left + step;

      body
        ..lineTo(peakX, peakY)
        ..lineTo(right, baseY - random.nextDouble() * 10);

      // 봉우리 위 눈밭. 꼭대기에서 조금 내려온 만큼만 밝게 칠한다.
      final capDrop = height * 0.28;
      final capRatio = capDrop / height;
      caps
        ..moveTo(peakX, peakY)
        ..lineTo(peakX + (right - peakX) * capRatio, peakY + capDrop)
        ..lineTo(peakX - (peakX - left) * capRatio, peakY + capDrop)
        ..close();
    }

    body
      ..lineTo(tileWidth, baseY)
      ..close();
    return _MountainTile(body, caps);
  }

  final Path body;
  final Path caps;
}

/// 산보다 가까이 있는 언덕과 나무.
class HillLayer extends ScrollingLayer {
  HillLayer() : super(speedFactor: 0.32, tileWidth: 220, priority: 3);

  static const int _variantCount = 4;

  final List<Path> _variants = <Path>[];
  final Paint _paint = Paint()..color = GamePalette.hill;

  @override
  Future<void> onLoad() async {
    final baseY = game.config.groundTop + 2;
    for (var variant = 0; variant < _variantCount; variant++) {
      _variants.add(
        _buildHill(
          random: math.Random(7777 + variant),
          tileWidth: tileWidth,
          baseY: baseY,
        ),
      );
    }
  }

  @override
  void renderTile(Canvas canvas, int index) {
    canvas.drawPath(_variants[variantOf(index, _variantCount)], _paint);
  }

  static Path _buildHill({
    required math.Random random,
    required double tileWidth,
    required double baseY,
  }) {
    final path = Path()..moveTo(0, baseY);
    final bumpCount = 2 + random.nextInt(2);
    final step = tileWidth / bumpCount;

    for (var i = 0; i < bumpCount; i++) {
      final left = i * step;
      final height = 26 + random.nextDouble() * 30;
      path.quadraticBezierTo(
        left + step / 2,
        baseY - height,
        left + step,
        baseY,
      );
    }

    // 언덕 사이사이에 삼각형 소나무를 세워 실루엣에 변화를 준다.
    final treeCount = 1 + random.nextInt(3);
    for (var i = 0; i < treeCount; i++) {
      final x = 16 + random.nextDouble() * (tileWidth - 32);
      final height = 20 + random.nextDouble() * 16;
      final halfWidth = height * 0.34;
      path
        ..moveTo(x - halfWidth, baseY)
        ..lineTo(x, baseY - height)
        ..lineTo(x + halfWidth, baseY)
        ..close();
    }

    path.close();
    return path;
  }
}
