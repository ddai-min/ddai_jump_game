import 'dart:math' as math;

import 'package:ddai_jump_game/app.dart';
import 'package:ddai_jump_game/data/score_store.dart';
import 'package:ddai_jump_game/game/components/obstacle.dart';
import 'package:ddai_jump_game/game/game_state.dart';
import 'package:ddai_jump_game/game/jump_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 앱을 띄우고, 로딩이 끝난 게임 인스턴스를 돌려준다.
Future<JumpGame> pumpApp(WidgetTester tester, ScoreStore store) async {
  await tester.pumpWidget(JumpApp(scoreStore: store));
  // onLoad와 컴포넌트 mount가 끝나도록 몇 프레임 돌린다.
  await advance(tester, 0.1);
  return tester
      .widget<GameWidget<JumpGame>>(find.byType(GameWidget<JumpGame>))
      .game!;
}

/// 게임 루프를 [seconds]초만큼 돌린다.
Future<void> advance(WidgetTester tester, double seconds) async {
  const step = Duration(milliseconds: 16);
  final frames = (seconds * 1000 / step.inMilliseconds).round();
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

/// 플레이어가 다시 바닥에 닿을 때까지 돌리며 가장 높이 올라간 높이를 잰다.
Future<double> measureApex(WidgetTester tester, JumpGame game) async {
  var apex = 0.0;
  for (var i = 0; i < 80; i++) {
    await advance(tester, 0.016);
    apex = math.max(apex, game.config.groundTop - game.player.position.y);
    if (i > 4 && game.player.isOnGround) {
      break;
    }
  }
  return apex;
}

/// 게임 루프 타이머가 남지 않도록 화면을 걷어낸다.
Future<void> teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  testWidgets('시작 화면이 뜨고, 빈 곳을 탭하면 달리기 시작한다', (tester) async {
    final game = await pumpApp(tester, InMemoryScoreStore());

    expect(find.text('DDAI JUMP'), findsOneWidget);
    expect(game.state, GameState.ready);

    // 카드 밖 아무 데나 누르면 시작한다.
    await tester.tapAt(const Offset(40, 560));
    await advance(tester, 0.1);

    expect(game.state, GameState.playing);
    expect(find.text('DDAI JUMP'), findsNothing);

    await teardown(tester);
  });

  testWidgets('달리는 동안 점수가 오른다', (tester) async {
    final game = await pumpApp(tester, InMemoryScoreStore());
    game.startGame();

    await advance(tester, 0.5);
    final early = game.score.value;
    await advance(tester, 1.0);

    expect(early, greaterThan(0));
    expect(game.score.value, greaterThan(early));

    await teardown(tester);
  });

  testWidgets('점프하면 떴다가 바닥으로 돌아온다', (tester) async {
    final game = await pumpApp(tester, InMemoryScoreStore());
    final groundTop = game.config.groundTop;
    game.startGame();
    await advance(tester, 0.2);

    expect(game.player.position.y, closeTo(groundTop, 0.001));

    game.onJumpPressed();
    await advance(tester, 0.16);
    expect(game.player.position.y, lessThan(groundTop - 50));

    await advance(tester, 0.8);
    expect(game.player.position.y, closeTo(groundTop, 0.001));
    expect(game.player.isOnGround, isTrue);

    await teardown(tester);
  });

  testWidgets('짧게 탭해도 가장 높은 장애물을 넘을 만큼은 뛴다', (tester) async {
    final game = await pumpApp(tester, InMemoryScoreStore());
    final config = game.config;
    game.startGame();
    await advance(tester, 0.1);

    // 휴대폰에서 탭하듯 아주 잠깐만 눌렀다 뗀다.
    game.onJumpPressed();
    await advance(tester, 0.048);
    game.onJumpReleased();

    final shortTapApex = await measureApex(tester, game);
    expect(shortTapApex, greaterThanOrEqualTo(config.minJumpHeight - 1));
    expect(shortTapApex, lessThan(config.jumpHeight));

    // 계속 누르고 있으면 더 높이 뛴다.
    game.onJumpPressed();
    final heldApex = await measureApex(tester, game);
    expect(heldApex, greaterThan(shortTapApex + 10));

    await teardown(tester);
  });

  testWidgets('점프는 공중에서 한 번까지만 더 된다', (tester) async {
    final game = await pumpApp(tester, InMemoryScoreStore());
    game.startGame();
    await advance(tester, 0.1);

    game.onJumpPressed();
    await advance(tester, 0.1);

    // 두 번째 점프는 받아 준다. 위로 다시 튀므로 속도가 더 음수가 된다.
    final beforeSecond = game.player.velocityY;
    game.onJumpPressed();
    await advance(tester, 0.016);
    expect(game.player.velocityY, lessThan(beforeSecond));

    // 세 번째는 무시된다. 중력만 작용해 속도가 다시 커진다.
    final beforeThird = game.player.velocityY;
    game.onJumpPressed();
    await advance(tester, 0.016);
    expect(game.player.velocityY, greaterThan(beforeThird));

    await teardown(tester);
  });

  testWidgets('장애물에 부딪히면 게임 오버가 되고 최고 기록이 남는다', (tester) async {
    final store = InMemoryScoreStore();
    final game = await pumpApp(tester, store);
    game.startGame();
    await advance(tester, 1);

    final scoreBeforeHit = game.score.value;
    expect(scoreBeforeHit, greaterThan(0));

    game.world.add(
      Obstacle(
        kind: ObstacleKind.tallRock,
        x: game.config.playerX - 6,
        bottomY: game.config.groundTop,
      ),
    );
    await advance(tester, 0.1);

    expect(game.state, GameState.gameOver);
    expect(game.isNewRecord.value, isTrue);
    expect(store.bestScore, game.score.value);

    // 잠깐 쓰러지는 모습을 보여 준 뒤 결과창이 뜬다.
    await advance(tester, 0.7);
    expect(find.text('게임 오버'), findsOneWidget);

    await teardown(tester);
  });

  testWidgets('결과창에서 다시 하기를 누르면 점수가 0부터 시작한다', (tester) async {
    final game = await pumpApp(tester, InMemoryScoreStore());
    game.startGame();
    await advance(tester, 1);
    game.onPlayerHit();
    await advance(tester, 0.7);

    expect(find.text('다시 하기'), findsOneWidget);
    await tester.tap(find.text('다시 하기'));
    await advance(tester, 0.05);

    expect(game.state, GameState.playing);
    expect(game.score.value, 0);
    expect(find.text('게임 오버'), findsNothing);

    await teardown(tester);
  });

  testWidgets('일시정지하면 게임이 멈추고, 계속하기로 다시 달린다', (tester) async {
    final game = await pumpApp(tester, InMemoryScoreStore());
    game.startGame();
    await advance(tester, 0.5);

    game.pauseGame();
    await advance(tester, 0.05);
    expect(find.text('일시정지'), findsOneWidget);

    final frozen = game.score.value;
    await advance(tester, 0.5);
    expect(game.score.value, frozen);

    await tester.tap(find.text('계속하기'));
    await advance(tester, 0.5);
    expect(game.state, GameState.playing);
    expect(game.score.value, greaterThan(frozen));

    await teardown(tester);
  });
}
