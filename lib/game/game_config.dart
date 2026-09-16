import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// 게임의 물리·난이도 수치를 한곳에 모아 둔 설정값.
///
/// 길이 단위는 전부 "월드 단위"다. 카메라가 [worldWidth] x [worldHeight] 영역을
/// 화면 크기에 맞춰 늘려 주므로, 기기 해상도가 달라도 체감 난이도는 같다.
/// 게임 손맛을 바꾸고 싶으면 이 파일의 숫자만 건드리면 된다.
@immutable
class GameConfig {
  const GameConfig({
    this.worldWidth = 640,
    this.worldHeight = 360,
    this.groundHeight = 60,
    this.playerWidth = 30,
    this.playerHeight = 42,
    this.playerXRatio = 0.22,
    this.gravity = 2000,
    this.fallGravityScale = 1.35,
    this.jumpSpeed = 640,
    this.doubleJumpSpeed = 555,
    this.maxJumps = 2,
    this.jumpCutFactor = 0.45,
    this.minJumpHeight = 72,
    this.coyoteSeconds = 0.10,
    this.jumpBufferSeconds = 0.12,
    this.startSpeed = 210,
    this.maxSpeed = 470,
    this.speedGain = 8,
    this.metersPerUnit = 0.05,
    this.coinBonusMeters = 25,
    this.firstSpawnDistance = 120,
    this.spawnMargin = 30,
    this.minGapSecondsStart = 1.20,
    this.minGapSecondsEnd = 0.95,
    this.maxGapSecondsStart = 2.20,
    this.maxGapSecondsEnd = 1.45,
    this.aerialGapSeconds = 1.35,
    this.aerialUnlockAt = 0.55,
    this.aerialMinHeight = 50,
    this.aerialHeightRange = 10,
    this.coinArcChance = 0.45,
    this.coinArcCount = 5,
    this.coinArcSpacing = 32,
    this.restartLockSeconds = 0.55,
    this.readySpeedFactor = 0.35,
  }) : assert(maxSpeed > startSpeed, '최고 속도는 시작 속도보다 빨라야 합니다.'),
       assert(
         minJumpHeight > 0 &&
             minJumpHeight < jumpSpeed * jumpSpeed / (2 * gravity),
         '최소 점프 높이는 최대 점프 높이보다 낮아야 합니다.',
       ),
       assert(
         aerialMinHeight > playerHeight,
         '새가 서 있는 플레이어보다 낮게 날면 피할 방법이 없습니다.',
       ),
       assert(maxJumps >= 1, '점프는 최소 한 번은 할 수 있어야 합니다.'),
       assert(
         minGapSecondsEnd <= maxGapSecondsEnd,
         '최소 간격이 최대 간격보다 넓을 수는 없습니다.',
       );

  /// 카메라가 담아내는 월드의 가로 크기.
  final double worldWidth;

  /// 카메라가 담아내는 월드의 세로 크기.
  final double worldHeight;

  /// 화면 아래쪽 바닥 띠의 높이.
  final double groundHeight;

  final double playerWidth;
  final double playerHeight;

  /// 플레이어가 서 있는 가로 위치를 [worldWidth]에 대한 비율로 나타낸 값.
  final double playerXRatio;

  /// 상승 중에 적용되는 중력.
  final double gravity;

  /// 하강할 때 중력에 곱하는 값. 1보다 크면 더 빨리 떨어져 조작이 경쾌해진다.
  final double fallGravityScale;

  /// 지면에서 점프할 때의 초기 상승 속도.
  final double jumpSpeed;

  /// 공중에서 한 번 더 점프할 때의 상승 속도.
  final double doubleJumpSpeed;

  /// 착지 전까지 쓸 수 있는 점프 횟수.
  final int maxJumps;

  /// 점프 키를 일찍 떼면 상승 속도에 곱하는 값. 짧게 눌러 낮게 뛸 수 있다.
  final double jumpCutFactor;

  /// 아무리 짧게 눌러도 보장해 주는 점프 높이.
  ///
  /// 휴대폰에서 탭은 길어야 0.1초라, 상승을 그대로 잘라 버리면 장애물을 넘지
  /// 못한다. 가장 높은 지상 장애물은 넘을 수 있는 높이를 바닥으로 깔아 둔다.
  final double minJumpHeight;

  /// 발판에서 막 벗어난 뒤에도 점프를 받아 주는 유예 시간.
  final double coyoteSeconds;

  /// 착지 직전에 미리 누른 점프를 기억해 두는 시간.
  final double jumpBufferSeconds;

  /// 게임을 시작할 때의 스크롤 속도.
  final double startSpeed;

  /// 아무리 빨라져도 넘지 않는 스크롤 속도.
  final double maxSpeed;

  /// 1초마다 붙는 스크롤 속도.
  final double speedGain;

  /// 월드 1단위를 몇 미터로 셀지. 점수 표시에만 쓴다.
  final double metersPerUnit;

  /// 코인 하나를 먹을 때 더해 주는 점수(미터).
  final double coinBonusMeters;

  /// 게임 시작 후 첫 장애물이 나오기까지 달리는 거리.
  final double firstSpawnDistance;

  /// 화면 오른쪽 밖 어느 정도 거리에서 장애물을 만들지.
  final double spawnMargin;

  /// 난이도 0(시작)일 때 장애물 사이 최소/최대 간격을 초로 나타낸 값.
  final double minGapSecondsStart;
  final double maxGapSecondsStart;

  /// 난이도 1(최고 속도)일 때의 최소/최대 간격.
  final double minGapSecondsEnd;
  final double maxGapSecondsEnd;

  /// 새(공중 장애물) 앞뒤로 반드시 확보하는 간격.
  ///
  /// 새는 점프하면 오히려 맞으므로, 바로 앞 장애물을 넘느라 뜬 상태로
  /// 새를 만나는 일이 없도록 넉넉히 띄운다.
  final double aerialGapSeconds;

  /// 새가 등장하기 시작하는 난이도(0~1).
  final double aerialUnlockAt;

  /// 새가 나는 높이. 바닥에서 새의 아랫면까지의 거리다.
  ///
  /// 서 있는 플레이어([playerHeight])보다는 높고, 점프 정점([jumpHeight])
  /// 보다는 낮아야 "뛰지 않고 지나간다"가 정답이 된다.
  final double aerialMinHeight;
  final double aerialHeightRange;

  /// 지상 장애물 위에 코인 아치를 놓을 확률.
  final double coinArcChance;

  /// 코인 아치 하나에 들어가는 코인 수와 코인 사이 간격.
  final int coinArcCount;
  final double coinArcSpacing;

  /// 게임 오버 직후 입력을 막아 두는 시간. 연타로 바로 재시작되는 걸 막는다.
  final double restartLockSeconds;

  /// 시작 화면에서 배경이 흐르는 속도를 [startSpeed]에 대한 비율로 나타낸 값.
  /// 멈춰 있는 그림보다 이쪽이 "달리는 게임"이라는 게 바로 보인다.
  final double readySpeedFactor;

  /// 바닥의 윗면 y 좌표. 플레이어와 장애물이 이 선 위에 선다.
  double get groundTop => worldHeight - groundHeight;

  /// 플레이어가 서 있는 x 좌표.
  double get playerX => worldWidth * playerXRatio;

  /// 장애물이 생성되는 x 좌표.
  double get spawnX => worldWidth + spawnMargin;

  /// 한 번 점프해서 올라갈 수 있는 최대 높이.
  double get jumpHeight => (jumpSpeed * jumpSpeed) / (2 * gravity);

  /// 점프해서 다시 착지할 때까지 공중에 떠 있는 시간.
  double get airSeconds {
    final riseTime = jumpSpeed / gravity;
    final fallTime = math.sqrt(2 * jumpHeight / (gravity * fallGravityScale));
    return riseTime + fallTime;
  }

  /// [elapsed]초 동안 달렸을 때의 스크롤 속도.
  double speedAt(double elapsed) =>
      math.min(maxSpeed, startSpeed + speedGain * elapsed);

  /// 현재 [speed]가 시작 속도와 최고 속도 사이 어디쯤인지를 0~1로 나타낸 값.
  double difficultyAt(double speed) =>
      ((speed - startSpeed) / (maxSpeed - startSpeed)).clamp(0.0, 1.0);

  /// 방금 만든 장애물 뒤에 비워 둘 거리. [roll]은 0~1 사이의 난수다.
  ///
  /// 간격을 거리가 아니라 "몇 초 뒤에 도착하는가"로 잡기 때문에, 속도가
  /// 빨라져도 반응할 시간이 정해진 만큼은 남는다.
  double gapAfter(double speed, double roll) {
    final t = difficultyAt(speed);
    final minSeconds = _lerp(minGapSecondsStart, minGapSecondsEnd, t);
    final maxSeconds = _lerp(maxGapSecondsStart, maxGapSecondsEnd, t);
    return speed * _lerp(minSeconds, maxSeconds, roll.clamp(0.0, 1.0));
  }

  /// 달린 거리 [distance]를 점수판에 띄울 미터로 바꾼다.
  int metersFor(double distance) => (distance * metersPerUnit).floor();
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
