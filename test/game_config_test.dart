import 'dart:math' as math;

import 'package:ddai_jump_game/game/components/obstacle.dart';
import 'package:ddai_jump_game/game/game_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = GameConfig();

  group('속도와 난이도', () {
    test('시작 속도에서 출발해 최고 속도에서 멈춘다', () {
      expect(config.speedAt(0), config.startSpeed);
      expect(config.speedAt(1), config.startSpeed + config.speedGain);
      expect(config.speedAt(10000), config.maxSpeed);
    });

    test('난이도는 0과 1 사이로 잘린다', () {
      expect(config.difficultyAt(config.startSpeed), 0);
      expect(config.difficultyAt(config.maxSpeed), 1);
      expect(config.difficultyAt(config.maxSpeed * 2), 1);
      expect(config.difficultyAt(0), 0);
    });
  });

  group('장애물 간격', () {
    test('속도가 빨라져도 장애물 사이를 지나는 시간은 정해진 범위 안이다', () {
      for (final speed in <double>[config.startSpeed, 300, config.maxSpeed]) {
        for (final roll in <double>[0, 0.5, 1]) {
          final seconds = config.gapAfter(speed, roll) / speed;
          expect(
            seconds,
            inInclusiveRange(
              config.minGapSecondsEnd - 1e-9,
              config.maxGapSecondsStart + 1e-9,
            ),
            reason: '속도 $speed, roll $roll',
          );
        }
      }
    });

    test('난수가 클수록 간격이 넓어진다', () {
      expect(config.gapAfter(300, 0), lessThan(config.gapAfter(300, 1)));
    });

    test('빨라질수록 간격이 촘촘해진다', () {
      final startGap =
          config.gapAfter(config.startSpeed, 0.5) / config.startSpeed;
      final endGap = config.gapAfter(config.maxSpeed, 0.5) / config.maxSpeed;
      expect(endGap, lessThan(startGap));
    });
  });

  group('점프 높이와 장애물 크기', () {
    test('한 번 점프로 가장 높은 지상 장애물을 넘을 수 있다', () {
      final tallest = ObstacleKind.values
          .where((kind) => !kind.isAerial)
          .map((kind) => kind.height)
          .reduce(math.max);
      expect(config.jumpHeight, greaterThan(tallest + 20));
    });

    test('짧게 탭해도 보장되는 높이로 가장 높은 지상 장애물을 넘을 수 있다', () {
      final tallest = ObstacleKind.values
          .where((kind) => !kind.isAerial)
          .map((kind) => kind.height)
          .reduce(math.max);
      expect(config.minJumpHeight, greaterThan(tallest + 10));
      expect(config.minJumpHeight, lessThan(config.jumpHeight));
    });

    test('새는 서 있으면 지나가지만 점프하면 닿는 높이로 난다', () {
      expect(config.aerialMinHeight, greaterThan(config.playerHeight));
      expect(
        config.aerialMinHeight + config.aerialHeightRange,
        lessThan(config.jumpHeight),
      );
    });

    test('공중에 떠 있는 시간은 반응할 만큼은 짧다', () {
      expect(config.airSeconds, inInclusiveRange(0.4, 0.9));
    });
  });

  group('점수', () {
    test('달린 거리를 미터로 바꾼다', () {
      expect(config.metersFor(0), 0);
      expect(config.metersFor(100), (100 * config.metersPerUnit).floor());
      expect(config.metersFor(1999), lessThan(config.metersFor(2000)));
    });
  });
}
