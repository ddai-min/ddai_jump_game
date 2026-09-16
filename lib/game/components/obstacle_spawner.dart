import 'dart:math' as math;

import 'package:flame/components.dart';

import '../jump_game.dart';
import 'coin.dart';
import 'obstacle.dart';

/// 장애물과 코인을 만들어 내보내는 역할.
///
/// 시간이 아니라 "달린 거리"를 세서 다음 장애물을 만든다. 속도가 빨라져도
/// 장애물 사이를 지나는 데 걸리는 시간이 [GameConfig.gapAfter]가 정한 범위
/// 안에 있으므로, 반응할 틈이 사라지지 않는다.
class ObstacleSpawner extends Component with HasGameReference<JumpGame> {
  ObstacleSpawner({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  double _distanceToNext = 0;
  bool _lastWasAerial = false;

  /// 다음 장애물까지 남은 거리를 처음 상태로 돌린다.
  void reset() {
    _distanceToNext = game.config.firstSpawnDistance;
    _lastWasAerial = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.state.isPlaying) {
      return;
    }

    _distanceToNext -= game.scrollSpeed * dt;
    if (_distanceToNext <= 0) {
      _spawn();
    }
  }

  void _spawn() {
    final config = game.config;
    final speed = game.scrollSpeed;
    final kind = _pickKind(config.difficultyAt(speed));

    final bottomY = kind.isAerial
        ? config.groundTop -
              (config.aerialMinHeight +
                  _random.nextDouble() * config.aerialHeightRange)
        : config.groundTop;
    game.world.add(Obstacle(kind: kind, x: config.spawnX, bottomY: bottomY));

    if (!kind.isAerial && _random.nextDouble() < config.coinArcChance) {
      _spawnCoinArc(config.spawnX + kind.width / 2);
    }

    var gap = config.gapAfter(speed, _random.nextDouble());
    if (kind.isAerial || _lastWasAerial) {
      // 새 앞뒤로는 넉넉히 비운다. 앞 장애물을 넘느라 뜬 채로 새를 만나면
      // 피할 방법이 없기 때문이다.
      gap = math.max(gap, speed * config.aerialGapSeconds);
    }

    // 넘어간 만큼을 남겨 두고 더해야 간격이 조금씩 밀리지 않는다.
    _distanceToNext += gap + kind.width;
    _lastWasAerial = kind.isAerial;
  }

  /// 현재 난이도에서 나올 수 있는 장애물 중 하나를 뽑는다.
  ObstacleKind _pickKind(double difficulty) {
    final pool = <ObstacleKind>[
      ObstacleKind.smallRock,
      ObstacleKind.smallRock,
      ObstacleKind.tallRock,
    ];
    if (difficulty > 0.2) {
      pool
        ..add(ObstacleKind.spikes)
        ..add(ObstacleKind.tallRock);
    }
    if (difficulty > 0.4) {
      pool.add(ObstacleKind.cluster);
    }
    if (difficulty > game.config.aerialUnlockAt && !_lastWasAerial) {
      pool.add(ObstacleKind.bird);
    }
    return pool[_random.nextInt(pool.length)];
  }

  /// 장애물을 넘는 점프 궤적을 따라가도록 코인을 아치로 늘어놓는다.
  void _spawnCoinArc(double centerX) {
    final config = game.config;
    final count = config.coinArcCount;
    final spacing = config.coinArcSpacing;
    final startX = centerX - spacing * (count - 1) / 2;

    for (var i = 0; i < count; i++) {
      final t = count == 1 ? 0.5 : i / (count - 1);
      final height = 58 + math.sin(math.pi * t) * 56;
      game.world.add(
        Coin(
          position: Vector2(startX + spacing * i, config.groundTop - height),
        ),
      );
    }
  }
}
