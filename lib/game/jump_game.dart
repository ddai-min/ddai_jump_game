import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../data/score_store.dart';
import '../ui/game_theme.dart';
import 'components/background.dart';
import 'components/coin.dart';
import 'components/ground.dart';
import 'components/obstacle.dart';
import 'components/obstacle_spawner.dart';
import 'components/player.dart';
import 'game_config.dart';
import 'game_state.dart';

/// 점프해서 장애물을 넘으며 계속 달리는 무한 러너.
///
/// 플레이어는 화면 왼쪽 고정 위치에 서 있고, 배경과 장애물이 왼쪽으로 흐른다.
/// 그래서 "얼마나 나아갔는가"는 [scrollSpeed]를 쌓아 만든 [_distance] 하나로
/// 표현되고, 모든 스크롤 컴포넌트는 이 속도만 보고 움직인다.
class JumpGame extends FlameGame
    with HasCollisionDetection, TapCallbacks, KeyboardEvents {
  JumpGame({
    required this.scoreStore,
    this.config = const GameConfig(),
    math.Random? random,
  }) : _random = random ?? math.Random();

  static const String hudOverlay = 'hud';
  static const String startOverlay = 'start';
  static const String pauseOverlay = 'pause';
  static const String gameOverOverlay = 'gameOver';

  final GameConfig config;
  final ScoreStore scoreStore;
  final math.Random _random;

  /// 점수판이 구독하는 값들. 바뀔 때만 오버레이가 다시 그려진다.
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScore = ValueNotifier<int>(0);
  final ValueNotifier<int> coinCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> isNewRecord = ValueNotifier<bool>(false);

  /// 현재 진행 단계. 오버레이가 이 값을 구독해 버튼을 바꿔 단다.
  final ValueNotifier<GameState> stateNotifier = ValueNotifier<GameState>(
    GameState.ready,
  );

  GameState get state => stateNotifier.value;
  set state(GameState value) => stateNotifier.value = value;

  /// 월드가 왼쪽으로 흐르는 속도. 스크롤하는 컴포넌트는 모두 이 값을 본다.
  double scrollSpeed = 0;

  final Player player = Player();
  late final ObstacleSpawner spawner = ObstacleSpawner(random: _random);

  double _elapsed = 0;
  double _distance = 0;
  double _shake = 0;
  double _inputLock = 0;

  /// 지금까지 달린 거리(미터).
  int get meters => config.metersFor(_distance);

  @override
  Future<void> onLoad() async {
    // 어떤 화면에서도 같은 넓이를 보여 줘야 난이도가 같아진다. 화면 비율이
    // 다르면 위아래(또는 좌우)에 여백이 생기는 대신, 보이는 범위는 고정된다.
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(config.worldWidth, config.worldHeight),
    );
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();

    world.addAll(<Component>[
      SkyLayer(),
      StarLayer(),
      MountainLayer(),
      HillLayer(),
      GroundLayer(),
      player,
      spawner,
    ]);

    bestScore.value = scoreStore.bestScore;
    scrollSpeed = config.startSpeed * config.readySpeedFactor;
  }

  @override
  void update(double dt) {
    if (state.isPlaying) {
      _elapsed += dt;
      scrollSpeed = config.speedAt(_elapsed);
      _distance += scrollSpeed * dt;
    }

    super.update(dt);

    if (state.isPlaying) {
      final value = meters + (coinCount.value * config.coinBonusMeters).round();
      if (value != score.value) {
        score.value = value;
      }
    }

    if (_inputLock > 0) {
      _inputLock = math.max(0, _inputLock - dt);
    }
    _updateShake(dt);
  }

  // ---------------------------------------------------------------- 진행 제어

  /// 새 게임을 시작한다. 시작 화면과 게임 오버 양쪽에서 부른다.
  void startGame() {
    for (final component in world.children.toList()) {
      if (component is Obstacle ||
          component is Coin ||
          component is ParticleSystemComponent) {
        component.removeFromParent();
      }
    }
    // 결과창을 띄우려고 걸어 둔 타이머가 남아 있으면 같이 걷어낸다.
    for (final component in children.toList()) {
      if (component is TimerComponent) {
        component.removeFromParent();
      }
    }

    _elapsed = 0;
    _distance = 0;
    _shake = 0;
    _inputLock = 0;
    scrollSpeed = config.startSpeed;
    score.value = 0;
    coinCount.value = 0;
    isNewRecord.value = false;
    camera.viewfinder.position = Vector2.zero();

    player.reset();
    spawner.reset();

    state = GameState.playing;
    paused = false;
    overlays
      ..remove(startOverlay)
      ..remove(gameOverOverlay)
      ..remove(pauseOverlay);
  }

  /// 장애물에 부딪혔다.
  void onPlayerHit() {
    if (!state.isPlaying) {
      return;
    }

    state = GameState.gameOver;
    scrollSpeed = 0;
    _shake = 1;
    _inputLock = config.restartLockSeconds;
    player.kill();
    emitDust(player.absoluteCenter, count: 16, color: GamePalette.obstacle);

    final finalScore = score.value;
    isNewRecord.value = finalScore > bestScore.value;
    if (isNewRecord.value) {
      bestScore.value = finalScore;
      unawaited(scoreStore.saveBestScore(finalScore));
    }

    // 쓰러지는 모습을 잠깐 보여 준 뒤에 결과창을 띄운다.
    add(
      TimerComponent(
        period: config.restartLockSeconds,
        removeOnFinish: true,
        onTick: () => overlays.add(gameOverOverlay),
      ),
    );
  }

  /// 코인을 먹었다.
  void onCoinCollected(Vector2 at) {
    coinCount.value += 1;
    emitDust(at, count: 8, color: GamePalette.coin);
  }

  void pauseGame() {
    if (!state.isPlaying) {
      return;
    }
    state = GameState.paused;
    paused = true;
    overlays.add(pauseOverlay);
  }

  void resumeGame() {
    if (state != GameState.paused) {
      return;
    }
    overlays.remove(pauseOverlay);
    state = GameState.playing;
    paused = false;
  }

  void togglePause() {
    if (state.isPlaying) {
      pauseGame();
    } else if (state == GameState.paused) {
      resumeGame();
    }
  }

  // -------------------------------------------------------------------- 입력

  /// 점프 입력이 눌렸다. 상황에 따라 시작/점프/재시작으로 갈린다.
  void onJumpPressed() {
    switch (state) {
      case GameState.ready:
        startGame();
      case GameState.playing:
        player.onJumpPressed();
      case GameState.paused:
        resumeGame();
      case GameState.gameOver:
        if (_inputLock <= 0) {
          startGame();
        }
    }
  }

  /// 점프 입력을 뗐다. 짧게 누르면 낮게 뛰도록 상승을 끊는다.
  void onJumpReleased() {
    if (state.isPlaying) {
      player.onJumpReleased();
    }
  }

  @override
  void onTapDown(TapDownEvent event) => onJumpPressed();

  @override
  void onTapUp(TapUpEvent event) => onJumpReleased();

  @override
  void onTapCancel(TapCancelEvent event) => onJumpReleased();

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isJumpKey =
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.keyW;

    // 키를 누르고 있을 때 오는 반복 이벤트로 연속 점프가 되면 곤란하다.
    if (event is KeyDownEvent) {
      if (isJumpKey) {
        onJumpPressed();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.keyP) {
        togglePause();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          state == GameState.gameOver &&
          _inputLock <= 0) {
        startGame();
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent && isJumpKey) {
      onJumpReleased();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ------------------------------------------------------------------- 연출

  /// [at] 자리에 작은 알갱이를 흩뿌린다. 착지 먼지와 충돌 파편에 쓴다.
  void emitDust(Vector2 at, {int count = 8, Color color = GamePalette.dust}) {
    world.add(
      ParticleSystemComponent(
        position: at.clone(),
        priority: 25,
        particle: Particle.generate(
          count: count,
          lifespan: 0.5,
          generator: (_) => AcceleratedParticle(
            acceleration: Vector2(0, 520),
            // 바닥이 흐르는 속도를 조금 물려받아야 제자리에 뜬 것처럼 보이지 않는다.
            speed: Vector2(
              -scrollSpeed * 0.3 - _random.nextDouble() * 70,
              -60 - _random.nextDouble() * 110,
            ),
            child: CircleParticle(
              radius: 1.2 + _random.nextDouble() * 2.2,
              paint: Paint()..color = color.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }

  /// 부딪힌 순간 화면을 잠깐 흔든다.
  void _updateShake(double dt) {
    if (_shake <= 0) {
      return;
    }
    _shake = math.max(0, _shake - dt * 3.2);
    final amount = _shake * _shake * 8;
    camera.viewfinder.position = Vector2(
      (_random.nextDouble() * 2 - 1) * amount,
      (_random.nextDouble() * 2 - 1) * amount,
    );
  }

  @override
  void onDispose() {
    score.dispose();
    bestScore.dispose();
    coinCount.dispose();
    isNewRecord.dispose();
    stateNotifier.dispose();
    super.onDispose();
  }
}
