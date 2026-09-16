import 'dart:math' as math;
import 'dart:ui';

import '../../ui/game_theme.dart';
import 'background.dart';

/// 플레이어가 달리는 바닥.
///
/// 바닥 띠 자체는 고정이고, 그 위의 잔돌·풀·줄무늬만 스크롤 속도에 맞춰
/// 흘러간다. 실제로 앞으로 나아가고 있다는 느낌은 이 디테일이 만든다.
class GroundLayer extends ScrollingLayer {
  GroundLayer() : super(speedFactor: 1, tileWidth: 140, priority: 5);

  static const int _variantCount = 5;

  final List<List<_GroundDetail>> _variants = <List<_GroundDetail>>[];
  final Paint _fillPaint = Paint()..color = GamePalette.groundFill;
  final Paint _edgePaint = Paint()..color = GamePalette.groundEdge;
  final Paint _stripePaint = Paint()..color = GamePalette.groundStripe;
  final Paint _pebblePaint = Paint()..color = GamePalette.groundPebble;

  late Rect _fillRect;
  late Rect _edgeRect;
  late double _groundTop;

  @override
  Future<void> onLoad() async {
    final config = game.config;
    _groundTop = config.groundTop;
    _fillRect = Rect.fromLTWH(
      0,
      _groundTop,
      config.worldWidth,
      config.groundHeight,
    );
    _edgeRect = Rect.fromLTWH(0, _groundTop, config.worldWidth, 2.5);

    for (var variant = 0; variant < _variantCount; variant++) {
      final random = math.Random(3301 + variant);
      _variants.add(_buildDetails(random, tileWidth));
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(_fillRect, _fillPaint);
    canvas.drawRect(_edgeRect, _edgePaint);
    super.render(canvas);
  }

  @override
  void renderTile(Canvas canvas, int index) {
    for (final detail in _variants[variantOf(index, _variantCount)]) {
      switch (detail.kind) {
        case _GroundDetailKind.stripe:
          canvas.drawRRect(
            RRect.fromLTRBR(
              detail.x,
              _groundTop + detail.offsetY,
              detail.x + detail.size,
              _groundTop + detail.offsetY + 3,
              const Radius.circular(1.5),
            ),
            _stripePaint,
          );
        case _GroundDetailKind.pebble:
          canvas.drawCircle(
            Offset(detail.x, _groundTop + detail.offsetY),
            detail.size,
            _pebblePaint,
          );
        case _GroundDetailKind.grass:
          // 바닥선 위로 삐죽 솟은 풀. 지면을 스치듯 지나가는 느낌을 준다.
          final path = Path()
            ..moveTo(detail.x, _groundTop)
            ..lineTo(detail.x + detail.size * 0.5, _groundTop - detail.size)
            ..lineTo(detail.x + detail.size, _groundTop)
            ..close();
          canvas.drawPath(path, _edgePaint);
      }
    }
  }

  static List<_GroundDetail> _buildDetails(math.Random random, double width) {
    final details = <_GroundDetail>[
      _GroundDetail(
        kind: _GroundDetailKind.stripe,
        x: random.nextDouble() * width * 0.4,
        offsetY: 16 + random.nextDouble() * 8,
        size: 30 + random.nextDouble() * 34,
      ),
      _GroundDetail(
        kind: _GroundDetailKind.stripe,
        x: width * 0.5 + random.nextDouble() * width * 0.4,
        offsetY: 34 + random.nextDouble() * 14,
        size: 22 + random.nextDouble() * 30,
      ),
    ];

    final pebbleCount = 2 + random.nextInt(3);
    for (var i = 0; i < pebbleCount; i++) {
      details.add(
        _GroundDetail(
          kind: _GroundDetailKind.pebble,
          x: random.nextDouble() * width,
          offsetY: 10 + random.nextDouble() * 50,
          size: 1.2 + random.nextDouble() * 2,
        ),
      );
    }

    final grassCount = random.nextInt(3);
    for (var i = 0; i < grassCount; i++) {
      details.add(
        _GroundDetail(
          kind: _GroundDetailKind.grass,
          x: random.nextDouble() * (width - 10),
          offsetY: 0,
          size: 4 + random.nextDouble() * 5,
        ),
      );
    }

    return details;
  }
}

enum _GroundDetailKind { stripe, pebble, grass }

class _GroundDetail {
  const _GroundDetail({
    required this.kind,
    required this.x,
    required this.offsetY,
    required this.size,
  });

  final _GroundDetailKind kind;
  final double x;

  /// 바닥 윗면에서 아래로 얼마나 떨어져 있는지.
  final double offsetY;
  final double size;
}
